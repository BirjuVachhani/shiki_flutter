// Generates the bundled language/theme Dart libraries under `lib/langs/` and
// `lib/themes/` from Shiki's `@shikijs/langs` and `@shikijs/themes` dist files.
//
// This is a build-time tool, not part of the published package. It reads the
// `.mjs` files (which embed the grammar/theme as `JSON.parse("...")`) and
// extracts that JSON with pure Dart string handling — no JavaScript is executed.
//
// Usage:
//   dart run tool/generate_bundled.dart <path-to-@shikijs-dir>
//
// where <path-to-@shikijs-dir> contains `langs/dist/*.mjs` and
// `themes/dist/*.mjs`.
import 'dart:convert';
import 'dart:io';

const _reserved = {
  'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case',
  'catch', 'class', 'const', 'continue', 'covariant', 'default', 'deferred',
  'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
  'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
  'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
  'return', 'sealed', 'set', 'show', 'static', 'super', 'switch', 'sync',
  'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'when', 'while',
  'with', 'yield',
};

// Common aliases (Shiki's installed data doesn't carry them). id -> aliases.
const _aliases = <String, List<String>>{
  'javascript': ['js'],
  'typescript': ['ts'],
  'python': ['py'],
  'ruby': ['rb'],
  'rust': ['rs'],
  'markdown': ['md'],
  'yaml': ['yml'],
  'shellscript': ['sh', 'shell', 'bash', 'zsh'],
  'csharp': ['cs', 'c#'],
  'cpp': ['c++'],
  'fsharp': ['fs', 'f#'],
  'kotlin': ['kt', 'kts'],
  'objective-c': ['objc'],
  'powershell': ['ps', 'ps1'],
  'json5': ['json5'],
  'jsonc': ['jsonc'],
  'docker': ['dockerfile'],
  'make': ['makefile'],
  'text': ['txt', 'plaintext'],
  'html': ['htm'],
  'vue': ['vue'],
};

String _identFor(String id, Set<String> taken) {
  // Build a lowerCamelCase identifier, e.g. `github-dark` -> `githubDark`.
  final parts = id.split(RegExp(r'[^A-Za-z0-9]+')).where((p) => p.isNotEmpty);
  final b = StringBuffer();
  var first = true;
  for (final part in parts) {
    if (first) {
      b.write(part[0].toLowerCase() + part.substring(1));
      first = false;
    } else {
      b.write(part[0].toUpperCase() + part.substring(1));
    }
  }
  var s = b.toString();
  if (s.isEmpty) s = 'lang';
  if (RegExp(r'^[0-9]').hasMatch(s)) s = 'x$s';
  if (_reserved.contains(s)) s = '${s}_';
  var candidate = s;
  var n = 2;
  while (taken.contains(candidate)) {
    candidate = '$s$n';
    n++;
  }
  taken.add(candidate);
  return candidate;
}

String _fileFor(String id) => id.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');

String _dartString(String value) {
  final b = StringBuffer("'");
  for (final unit in value.codeUnits) {
    switch (unit) {
      case 0x5c: // \
        b.write(r'\\');
      case 0x27: // '
        b.write(r"\'");
      case 0x24: // $
        b.write(r'\$');
      case 0x0a:
        b.write(r'\n');
      case 0x0d:
        b.write(r'\r');
      default:
        b.writeCharCode(unit);
    }
  }
  b.write("'");
  return b.toString();
}

/// Extracts the first `JSON.parse("...")` string body from an `.mjs` file and
/// returns the decoded JSON text.
String? _extractJson(String content) {
  const marker = 'JSON.parse("';
  final start = content.indexOf(marker);
  if (start == -1) return null;
  final bodyStart = start + marker.length;
  final buffer = StringBuffer();
  var i = bodyStart;
  while (i < content.length) {
    final ch = content[i];
    if (ch == r'\') {
      buffer.write(ch);
      if (i + 1 < content.length) buffer.write(content[i + 1]);
      i += 2;
      continue;
    }
    if (ch == '"') break;
    buffer.write(ch);
    i++;
  }
  // buffer holds the JS-escaped string body; decode it into the raw JSON text.
  return jsonDecode('"${buffer.toString()}"') as String;
}

void main(List<String> args) {
  final shikiDir = args.isNotEmpty
      ? args[0]
      : '/Users/birjuvachhani/Documents/Projects/mypub/sites/web/node_modules/@shikijs';
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Run from the package root (lib/ not found).');
    exit(1);
  }

  final langsOut = Directory('lib/langs');
  final themesOut = Directory('lib/themes');
  for (final d in [langsOut, themesOut]) {
    if (d.existsSync()) d.deleteSync(recursive: true);
    d.createSync(recursive: true);
  }

  final langIdents = <String>{};
  final langInfo = <String, ({String ident, String file})>{};
  final langFiles = Directory('$shikiDir/langs/dist')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.mjs') && !f.path.endsWith('index.mjs'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  // First pass: assign idents/files for every language id.
  for (final f in langFiles) {
    final id = f.uri.pathSegments.last.replaceAll('.mjs', '');
    final ident = _identFor(id, langIdents);
    langInfo[id] = (ident: ident, file: _fileFor(id));
  }

  final generatedLangIds = <String>[];
  var langCount = 0;
  for (final f in langFiles) {
    final id = f.uri.pathSegments.last.replaceAll('.mjs', '');
    final content = f.readAsStringSync();
    final jsonText = _extractJson(content);
    if (jsonText == null) {
      // Re-export/alias stub with no embedded grammar JSON; skip it.
      continue;
    }
    generatedLangIds.add(id);
    final obj = jsonDecode(jsonText) as Map<String, dynamic>;
    final scopeName = obj['scopeName'] as String? ?? 'source.$id';
    final embedded = (obj['embeddedLangs'] as List?)?.cast<String>() ?? const [];
    final info = langInfo[id]!;

    final deps = embedded
        .where((e) => langInfo.containsKey(e) && e != id)
        .toList();

    final imports = StringBuffer("import '../src/bundled/bundled_language.dart';");
    for (final dep in deps) {
      imports.write("\nimport '${langInfo[dep]!.file}.dart';");
    }

    final aliases = _aliases[id] ?? const [];
    final aliasStr =
        aliases.isEmpty ? '' : ', aliases: [${aliases.map((a) => "'$a'").join(', ')}]';
    final embeddedStr = deps.isEmpty
        ? ''
        : ', embeddedLanguages: () => [${deps.map((d) => langInfo[d]!.ident).join(', ')}]';

    final out = StringBuffer()
      ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
      ..writeln(imports.toString())
      ..writeln()
      ..writeln('/// TextMate grammar for `$id` (scope `$scopeName`).')
      ..writeln('final ${info.ident} = BundledLanguage(')
      ..writeln("  id: '$id',")
      ..writeln("  scopeName: '$scopeName',")
      ..writeln('  json: _json$embeddedStr$aliasStr,')
      ..writeln(');')
      ..writeln()
      ..writeln('const _json = ${_dartString(jsonText)};');

    File('${langsOut.path}/${info.file}.dart').writeAsStringSync(out.toString());
    langCount++;
  }

  // Themes.
  final themeIdents = <String>{};
  final themeEntries = <({String id, String ident, String file})>[];
  final themeFiles = Directory('$shikiDir/themes/dist')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.mjs') && !f.path.endsWith('index.mjs'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var themeCount = 0;
  for (final f in themeFiles) {
    final id = f.uri.pathSegments.last.replaceAll('.mjs', '');
    final content = f.readAsStringSync();
    final jsonText = _extractJson(content);
    if (jsonText == null) {
      stderr.writeln('skip theme $id (no JSON found)');
      continue;
    }
    final obj = jsonDecode(jsonText) as Map<String, dynamic>;
    final type = obj['type'] as String? ?? 'dark';
    final name = obj['name'] as String? ?? id;
    final ident = _identFor(id, themeIdents);
    final file = _fileFor(id);
    themeEntries.add((id: id, ident: ident, file: file));

    final out = StringBuffer()
      ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
      ..writeln("import '../src/bundled/bundled_theme.dart';")
      ..writeln()
      ..writeln('/// The `$name` theme.')
      ..writeln('final $ident = BundledTheme(')
      ..writeln("  id: '$name',")
      ..writeln("  type: '$type',")
      ..writeln('  json: _json,')
      ..writeln(');')
      ..writeln()
      ..writeln('const _json = ${_dartString(jsonText)};');

    File('${themesOut.path}/$file.dart').writeAsStringSync(out.toString());
    themeCount++;
  }

  // Barrels.
  _writeLangBarrel(langsOut, generatedLangIds, langInfo);
  _writeThemeBarrel(themesOut, themeEntries);

  stdout.writeln('Generated $langCount languages and $themeCount themes.');
}

void _writeLangBarrel(Directory dir, List<String> ids,
    Map<String, ({String ident, String file})> langInfo) {
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
    ..writeln('//')
    ..writeln('// Importing this file pulls EVERY bundled grammar into your')
    ..writeln('// build (defeats tree-shaking). Prefer importing only the')
    ..writeln('// specific `langs/<id>.dart` files you use.')
    ..writeln("import '../src/bundled/bundled_language.dart';");
  for (final id in ids) {
    b.writeln("import '${langInfo[id]!.file}.dart';");
  }
  b
    ..writeln()
    ..writeln('/// Every bundled language.')
    ..writeln('final List<BundledLanguage> allLanguages = [');
  for (final id in ids) {
    b.writeln('  ${langInfo[id]!.ident},');
  }
  b.writeln('];');
  File('${dir.path}/all.dart').writeAsStringSync(b.toString());
}

void _writeThemeBarrel(
    Directory dir, List<({String id, String ident, String file})> themes) {
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
    ..writeln('//')
    ..writeln('// Importing this file pulls EVERY bundled theme into your build.')
    ..writeln("import '../src/bundled/bundled_theme.dart';");
  for (final t in themes) {
    b.writeln("import '${t.file}.dart';");
  }
  b
    ..writeln()
    ..writeln('/// Every bundled theme.')
    ..writeln('final List<BundledTheme> allThemes = [');
  for (final t in themes) {
    b.writeln('  ${t.ident},');
  }
  b.writeln('];');
  File('${dir.path}/all.dart').writeAsStringSync(b.toString());
}
