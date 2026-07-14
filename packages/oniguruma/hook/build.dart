// Build hook for the `package:oniguruma/oniguruma_ffi` code asset that the
// FFI `@Native` bindings in lib/src/bindings.dart resolve against.
//
// Two strategies, in order:
//
//   A. Prebuilt (default). If `prebuilt/<platform>/<arch>/<lib>` exists for the
//      target, it is bundled directly as the code asset — no compiler, no
//      network. These blobs ship inside the published package (see
//      prebuilt/README.md for the layout and how CI produces them). Integrity
//      is inherent: they live in pub's immutable, hash-recorded archive.
//
//   C. Build from source (fallback). When no prebuilt exists for the target —
//      or the consumer opts out via a user-define (see below) — the upstream
//      Oniguruma source tarball is downloaded from its GitHub release,
//      verified against a pinned SHA-256, extracted, and compiled together
//      with our shim exactly as before. Oniguruma is archived, so the pinned
//      version/hash never change. The C sources are intentionally NOT shipped
//      in the package; they are fetched on demand here.
//
// Force the source path (e.g. to avoid trusting the prebuilt blobs) with:
//
//   # pubspec.yaml (of the app, or the workspace root)
//   hooks:
//     user_defines:
//       oniguruma:
//         from_source: true

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

// ---------------------------------------------------------------------------
// Upstream source pin. Oniguruma is archived at v6.9.10, so these are fixed.
// The SHA-256 matches the release's published `.sha256` sidecar.
// ---------------------------------------------------------------------------
const _onigVersion = '6.9.10';
const _onigTarballUrl =
    'https://github.com/kkos/oniguruma/releases/download/'
    'v$_onigVersion/onig-$_onigVersion.tar.gz';
const _onigSha256 =
    '2a5cfc5ae259e4e97f86b68dfffc152cdaffe94e2060b770cb827238d769fc05';
// Top-level directory inside the tarball.
const _onigRoot = 'onig-$_onigVersion';

// The exact set that makes up libonig (from src/Makefile.am's
// libonig_la_SOURCES), plus our shim. The `unicode_*_data.c` files are
// #included by unicode.c, so they are present on disk but not compiled here.
const _onigSources = [
  'regparse.c', 'regcomp.c', 'regexec.c', 'regenc.c', 'regerror.c', 'regext.c',
  'regsyntax.c', 'regtrav.c', 'regversion.c', 'st.c', 'reggnu.c', 'onig_init.c',
  'unicode.c', 'unicode_unfold_key.c', 'unicode_fold1_key.c',
  'unicode_fold2_key.c', 'unicode_fold3_key.c',
  'ascii.c', 'utf8.c', 'utf16_be.c', 'utf16_le.c', 'utf32_be.c', 'utf32_le.c',
  'euc_jp.c', 'euc_jp_prop.c', 'sjis.c', 'sjis_prop.c',
  'iso8859_1.c', 'iso8859_2.c', 'iso8859_3.c', 'iso8859_4.c', 'iso8859_5.c',
  'iso8859_6.c', 'iso8859_7.c', 'iso8859_8.c', 'iso8859_9.c', 'iso8859_10.c',
  'iso8859_11.c', 'iso8859_13.c', 'iso8859_14.c', 'iso8859_15.c',
  'iso8859_16.c',
  'euc_tw.c', 'euc_kr.c', 'big5.c', 'gb18030.c', 'koi8_r.c', 'cp1251.c',
];

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final code = input.config.code;
    final os = code.targetOS;
    final arch = code.targetArchitecture;
    final fromSource = input.userDefines['from_source'] == true;

    // --- A. Prebuilt ---------------------------------------------------------
    if (!fromSource) {
      final prebuilt = _prebuiltLibraryUri(input, os, arch);
      if (prebuilt != null && File.fromUri(prebuilt).existsSync()) {
        stderr.writeln('oniguruma: using prebuilt ${prebuilt.pathSegments.last} '
            'for $os/${arch.name}');
        output.assets.code.add(
          CodeAsset(
            package: input.packageName,
            name: 'oniguruma_ffi',
            linkMode: DynamicLoadingBundled(),
            file: prebuilt,
          ),
        );
        output.dependencies.add(prebuilt);
        return;
      }
    }

    // --- C. Build from downloaded, SHA-verified source -----------------------
    stderr.writeln('oniguruma: no prebuilt for $os/${arch.name}'
        '${fromSource ? ' (from_source)' : ''}; building from source');
    final srcRoot = await _fetchVerifiedSource(input, output);
    _installConfigHeader(input, os, arch, srcRoot);

    final srcDir = srcRoot.resolve('src/');
    final cbuilder = CBuilder.library(
      name: 'oniguruma',
      assetName: 'oniguruma_ffi',
      sources: [
        input.packageRoot.resolve('src/oniguruma_shim.c').toFilePath(),
        for (final s in _onigSources) srcDir.resolve(s).toFilePath(),
      ],
      includes: [srcDir.toFilePath()],
      // Use the config.h we install per-platform above.
      defines: {'HAVE_CONFIG_H': '1'},
      // Oniguruma is warning-heavy; keep hook output clean.
      flags: ['-w'],
    );
    await cbuilder.run(input: input, output: output);
  });
}

/// Resolves the bundled prebuilt library for [os]/[arch], or null if this
/// target isn't covered by a prebuilt (then the source fallback runs).
///
/// Layout (see prebuilt/README.md):
///   prebuilt/macos/<arch>/liboniguruma_ffi.dylib
///   prebuilt/linux/<arch>/liboniguruma_ffi.so
///   prebuilt/windows/<arch>/oniguruma_ffi.dll
///   prebuilt/android/<arch>/liboniguruma_ffi.so
///   prebuilt/ios/{device,simulator}/<arch>/liboniguruma_ffi.dylib
Uri? _prebuiltLibraryUri(BuildInput input, OS os, Architecture arch) {
  final archDir = _archDir(arch);
  if (archDir == null) return null;

  final String platformDir;
  if (os == OS.macOS) {
    platformDir = 'macos/$archDir';
  } else if (os == OS.linux) {
    platformDir = 'linux/$archDir';
  } else if (os == OS.windows) {
    platformDir = 'windows/$archDir';
  } else if (os == OS.android) {
    platformDir = 'android/$archDir';
  } else if (os == OS.iOS) {
    final sdk = input.config.code.iOS.targetSdk == IOSSdk.iPhoneOS
        ? 'device'
        : 'simulator';
    platformDir = 'ios/$sdk/$archDir';
  } else {
    return null;
  }

  final fileName = os.dylibFileName('oniguruma_ffi');
  return input.packageRoot.resolve('prebuilt/$platformDir/$fileName');
}

String? _archDir(Architecture arch) {
  if (arch == Architecture.arm64) return 'arm64';
  if (arch == Architecture.x64) return 'x64';
  if (arch == Architecture.arm) return 'arm';
  if (arch == Architecture.ia32) return 'ia32';
  if (arch == Architecture.riscv64) return 'riscv64';
  return null;
}

/// Copies the correct pre-generated `config.h` into the extracted source tree.
/// The release tarball ships only `config.h.in`; we supply per-platform
/// variants from src/config/ so the fallback never needs autotools/cmake.
void _installConfigHeader(
    BuildInput input, OS os, Architecture arch, Uri srcRoot) {
  final variant = os == OS.windows
      ? (arch == Architecture.ia32 ? 'config.h.win32' : 'config.h.win64')
      : 'config.h';
  final from = File.fromUri(input.packageRoot.resolve('src/config/$variant'));
  final to = File.fromUri(srcRoot.resolve('src/config.h'));
  to.writeAsBytesSync(from.readAsBytesSync());
}

/// Downloads the pinned Oniguruma source tarball into the (persistent) shared
/// output directory, verifies its SHA-256, and extracts it. Cached across
/// builds via a `.verified` marker. Returns the extracted `onig-<version>/`
/// root URI.
Future<Uri> _fetchVerifiedSource(
    BuildInput input, BuildOutputBuilder output) async {
  final shared = input.outputDirectoryShared;
  final srcRoot = shared.resolve('$_onigRoot/');
  final marker = File.fromUri(srcRoot.resolve('.verified'));

  output.dependencies.add(marker.uri);
  if (marker.existsSync()) return srcRoot;

  final bytes = await _downloadWithRetry(Uri.parse(_onigTarballUrl));
  final digest = sha256.convert(bytes).toString();
  if (digest != _onigSha256) {
    throw StateError(
      'Oniguruma source integrity check failed for $_onigTarballUrl\n'
      '  expected sha256: $_onigSha256\n'
      '  actual   sha256: $digest',
    );
  }

  final tar = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
  for (final entry in tar) {
    if (!entry.isFile) continue;
    final out = File.fromUri(shared.resolve(entry.name));
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(entry.content as List<int>);
  }

  marker.writeAsStringSync('$_onigVersion $_onigSha256\n');
  return srcRoot;
}

/// Fetches [url] following redirects, retrying with linear backoff. Throws
/// after [attempts] failures so the build surfaces the real error.
Future<Uint8List> _downloadWithRetry(Uri url, {int attempts = 3}) async {
  final client = HttpClient();
  try {
    Object? lastError;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final request = await client.getUrl(url);
        final response = await request.close();
        if (response.statusCode != 200) {
          throw HttpException('HTTP ${response.statusCode}', uri: url);
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      } catch (error) {
        lastError = error;
        stderr.writeln('oniguruma: download attempt $attempt/$attempts '
            'failed: $error');
        if (attempt < attempts) {
          await Future<void>.delayed(Duration(seconds: attempt));
        }
      }
    }
    throw StateError(
        'Failed to download $url after $attempts attempts: $lastError');
  } finally {
    client.close(force: true);
  }
}
