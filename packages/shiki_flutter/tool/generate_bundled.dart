// Generates the bundled language/theme Dart libraries from `tm-grammars` and
// `tm-themes` (the canonical TextMate sources Shiki itself is built from).
//
// This is a build-time tool, not part of the published package.
//
// Output layout (everything the app imports is either a facade or in `src/`):
//   lib/langs.dart               exposed facade: `CodeLanguages`
//   lib/themes.dart              exposed facade: `ShikiThemes`
//   lib/pierre_themes.dart       exposed facade: `PierreThemes` (opt-in, @pierre/theme)
//   lib/src/langs/<id>.dart       one `const CodeLanguage` per grammar (incl. injections)
//   lib/src/themes/<id>.dart      one `const ShikiTheme` per theme
//   lib/src/pierre_themes/<id>.dart one `const ShikiTheme` per Pierre theme
//
// Each symbol is `const` so a `static const` facade member is a pure compile-time
// alias: referencing `CodeLanguages.dart` pulls in only that grammar and its
// embedded deps; everything else is tree-shaken away.
//
// Prerequisite (run once, or after bumping versions in tool/tm/package.json):
//   cd tool/tm && npm ci && node dump_meta.mjs
// then from the package root:
//   dart run tool/generate_bundled.dart
import 'dart:convert';
import 'dart:io';

// Maps each `tm-grammars` category string to its `GrammarCategory` enum member.
// Kept in lockstep with the enum in lib/src/core/code_language.dart; an upstream
// category missing from here is warned about and skipped (see the grammar loop).
const _categoryEnum = {
  'web': 'GrammarCategory.web',
  'markup': 'GrammarCategory.markup',
  'general': 'GrammarCategory.general',
  'scripting': 'GrammarCategory.scripting',
  'data': 'GrammarCategory.data',
  'dsl': 'GrammarCategory.dsl',
  'utility': 'GrammarCategory.utility',
  'config': 'GrammarCategory.config',
  'lisp': 'GrammarCategory.lisp',
};

const _reserved = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
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

String _fileFor(String id, Set<String> taken) {
  var s = id.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  var candidate = s;
  var n = 2;
  while (taken.contains(candidate)) {
    candidate = '${s}_$n';
    n++;
  }
  taken.add(candidate);
  return candidate;
}

/// Encodes [value] as a single-quoted Dart string literal.
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

typedef _Info = ({String ident, String file});

void main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('Run from the package root (lib/ not found).');
    exit(1);
  }
  final tm = args.isNotEmpty ? args[0] : 'tool/tm';
  final metaFile = File('$tm/meta.json');
  final grammarsSrc = Directory('$tm/node_modules/tm-grammars/grammars');
  final themesSrc = Directory('$tm/node_modules/tm-themes/themes');
  final pierreSrc = Directory('$tm/node_modules/@pierre/theme/themes');
  if (!metaFile.existsSync() ||
      !grammarsSrc.existsSync() ||
      !themesSrc.existsSync() ||
      !pierreSrc.existsSync()) {
    stderr.writeln(
      'Missing tm sources. Run:\n'
      '  cd $tm && npm ci && node dump_meta.mjs\n'
      'then re-run this generator from the package root.',
    );
    exit(1);
  }

  final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
  final topLevel = (meta['grammars'] as List).cast<Map<String, dynamic>>();
  final injections = (meta['injections'] as List).cast<Map<String, dynamic>>();
  final themes = (meta['themes'] as List).cast<Map<String, dynamic>>();

  // All grammars (top-level + injections) get generated as symbols so embedded
  // references resolve; only top-level ones are surfaced on the facade.
  final allGrammars = [...topLevel, ...injections]
    ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  themes.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

  // Assign stable idents/files up front so cross-references are consistent.
  final langIdents = <String>{};
  final langFiles = <String>{};
  final langInfo = <String, _Info>{};
  for (final g in allGrammars) {
    final name = g['name'] as String;
    langInfo[name] = (
      ident: _identFor(name, langIdents),
      file: _fileFor(name, langFiles),
    );
  }
  final themeIdents = <String>{};
  final themeFiles = <String>{};
  final themeInfo = <String, _Info>{};
  for (final t in themes) {
    final name = t['name'] as String;
    themeInfo[name] = (
      ident: _identFor(name, themeIdents),
      file: _fileFor(name, themeFiles),
    );
  }

  // Fresh output dirs. The old public per-file dirs (lib/langs, lib/themes) are
  // removed; grammars/themes now live under src/ and are reached via the facades.
  for (final d in ['lib/langs', 'lib/themes', 'lib/pierre_themes']) {
    final dir = Directory(d);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
  final langsOut = Directory('lib/src/langs');
  final themesOut = Directory('lib/src/themes');
  final pierreOut = Directory('lib/src/pierre_themes');
  for (final d in [langsOut, themesOut, pierreOut]) {
    if (d.existsSync()) d.deleteSync(recursive: true);
    d.createSync(recursive: true);
  }

  for (final g in allGrammars) {
    final name = g['name'] as String;
    final scopeName = g['scopeName'] as String;
    final displayName = (g['displayName'] as String?) ?? name;
    final aliases = (g['aliases'] as List).cast<String>();
    final embedded = (g['embedded'] as List)
        .cast<String>()
        .where((e) => langInfo.containsKey(e) && e != name)
        .toList();
    final categories = <String>[];
    for (final c in (g['categories'] as List?)?.cast<String>() ?? const []) {
      final member = _categoryEnum[c];
      if (member == null) {
        stderr.writeln(
          'WARNING: unknown grammar category "$c" on "$name"; skipping. '
          'Add it to GrammarCategory (lib/src/core/code_language.dart) and '
          '_categoryEnum (this file), then regenerate.',
        );
        continue;
      }
      categories.add(member);
    }
    final info = langInfo[name]!;
    final compact = jsonEncode(
      jsonDecode(
        File('${grammarsSrc.path}/$name.json').readAsStringSync(),
      ),
    );

    final b = StringBuffer()
      ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
      ..writeln("import '../core/code_language.dart';");
    for (final dep in embedded) {
      b.writeln("import '${langInfo[dep]!.file}.dart';");
    }
    b
      ..writeln()
      ..writeln('/// $displayName grammar (scope `$scopeName`).')
      ..writeln('const CodeLanguage ${info.ident} = CodeLanguage(')
      ..writeln('  id: ${_dartString(name)},')
      ..writeln('  scopeName: ${_dartString(scopeName)},')
      ..writeln('  displayName: ${_dartString(displayName)},')
      ..writeln('  json: _json,');
    if (embedded.isNotEmpty) b.writeln('  embeddedLanguages: _embedded,');
    if (aliases.isNotEmpty) {
      b.writeln('  aliases: [${aliases.map(_dartString).join(', ')}],');
    }
    if (categories.isNotEmpty) {
      b.writeln('  categories: [${categories.join(', ')}],');
    }
    b.writeln(');');
    if (embedded.isNotEmpty) {
      b
        ..writeln()
        ..writeln('List<CodeLanguage> _embedded() =>')
        ..writeln(
          '    [${embedded.map((d) => langInfo[d]!.ident).join(', ')}];',
        );
    }
    b
      ..writeln()
      ..writeln('const _json = ${_dartString(compact)};');
    File('${langsOut.path}/${info.file}.dart').writeAsStringSync(b.toString());
  }

  for (final t in themes) {
    final name = t['name'] as String;
    final type = t['type'] as String;
    final displayName = (t['displayName'] as String?) ?? name;
    final info = themeInfo[name]!;
    final compact = jsonEncode(
      jsonDecode(
        File('${themesSrc.path}/$name.json').readAsStringSync(),
      ),
    );
    final b = StringBuffer()
      ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
      ..writeln("import '../core/shiki_theme.dart';")
      ..writeln()
      ..writeln('/// $displayName ($type) theme.')
      ..writeln('const ShikiTheme ${info.ident} = ShikiTheme(')
      ..writeln('  id: ${_dartString(name)},')
      ..writeln('  type: ${_dartString(type)},')
      ..writeln('  json: _json,')
      ..writeln(');')
      ..writeln()
      ..writeln('const _json = ${_dartString(compact)};');
    File('${themesOut.path}/${info.file}.dart').writeAsStringSync(b.toString());
  }

  // Pierre themes: an opt-in collection sourced from @pierre/theme
  // (https://github.com/pierrecomputer/pierre/tree/main/packages/theme), MIT.
  // Same `const ShikiTheme` shape as the bundled themes, but kept separate from
  // `ShikiThemes` and surfaced via their own `PierreThemes` facade.
  final pierreThemes =
      pierreSrc
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map((f) {
            final o = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
            return {
              'name': o['name'],
              'type': o['type'],
              'displayName': o['displayName'],
            };
          })
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  final pierreIdents = <String>{};
  final pierreFiles = <String>{};
  final pierreInfo = <String, _Info>{};
  for (final t in pierreThemes) {
    final name = t['name'] as String;
    pierreInfo[name] = (
      ident: _identFor(name, pierreIdents),
      file: _fileFor(name, pierreFiles),
    );
  }
  for (final t in pierreThemes) {
    final name = t['name'] as String;
    final type = t['type'] as String;
    final displayName = (t['displayName'] as String?) ?? name;
    final info = pierreInfo[name]!;
    final compact = jsonEncode(
      jsonDecode(
        File('${pierreSrc.path}/$name.json').readAsStringSync(),
      ),
    );
    final b = StringBuffer()
      ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
      ..writeln("import '../core/shiki_theme.dart';")
      ..writeln()
      ..writeln(
        '/// $displayName ($type) theme. Pierre, MIT © The Pierre Computer Company.',
      )
      ..writeln('const ShikiTheme ${info.ident} = ShikiTheme(')
      ..writeln('  id: ${_dartString(name)},')
      ..writeln('  type: ${_dartString(type)},')
      ..writeln('  json: _json,')
      ..writeln(');')
      ..writeln()
      ..writeln('const _json = ${_dartString(compact)};');
    File('${pierreOut.path}/${info.file}.dart').writeAsStringSync(b.toString());
  }

  _writeLangFacade(topLevel, langInfo);
  _writeThemeFacade(themes, themeInfo);
  _writePierreFacade(pierreThemes, pierreInfo);
  _writeAttribution(tm);

  stdout.writeln(
    'Generated ${topLevel.length} languages '
    '(+${injections.length} injections), ${themes.length} themes, '
    'and ${pierreThemes.length} Pierre themes.',
  );
}

void _writeLangFacade(
  List<Map<String, dynamic>> topLevel,
  Map<String, _Info> info,
) {
  final entries = [...topLevel]
    ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
    ..writeln('//')
    ..writeln('// Typesafe, tree-shakeable access to the bundled languages.')
    ..writeln(
      '// Referencing a member (e.g. `CodeLanguages.dart`) pulls in only',
    )
    ..writeln(
      '// that grammar and its embedded deps; the rest are tree-shaken away.',
    )
    ..writeln()
    ..writeln("import 'src/core/code_language.dart';")
    ..writeln(
      "export 'src/core/code_language.dart' show CodeLanguage, GrammarCategory;",
    );
  for (final g in entries) {
    final i = info[g['name']]!;
    b.writeln("import 'src/langs/${i.file}.dart' as l_${i.file};");
  }
  b
    ..writeln()
    ..writeln('abstract final class CodeLanguages {');
  for (final g in entries) {
    final i = info[g['name']]!;
    b
      ..writeln('  /// ${(g['displayName'] as String?) ?? g['name']}.')
      ..writeln(
        '  static const CodeLanguage ${i.ident} = l_${i.file}.${i.ident};',
      );
  }
  b
    ..writeln()
    ..writeln(
      '  // CAUTION: referencing `all` pulls EVERY grammar into your build',
    )
    ..writeln(
      '  // (defeats tree-shaking). Prefer individual members; use this only',
    )
    ..writeln('  // when you truly need every language.')
    ..writeln('  static const List<CodeLanguage> all = [');
  for (final g in entries) {
    b.writeln('    ${info[g['name']]!.ident},');
  }
  b
    ..writeln('  ];')
    ..writeln('}');
  File('lib/langs.dart').writeAsStringSync(b.toString());
}

void _writeThemeFacade(
  List<Map<String, dynamic>> themes,
  Map<String, _Info> info,
) {
  final entries = [...themes]
    ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
    ..writeln('//')
    ..writeln('// Typesafe, tree-shakeable access to the bundled themes.')
    ..writeln(
      '// Referencing a member (e.g. `ShikiThemes.githubDark`) pulls in',
    )
    ..writeln('// only that theme; the rest are tree-shaken away.')
    ..writeln()
    ..writeln("import 'src/core/shiki_theme.dart';")
    ..writeln("export 'src/core/shiki_theme.dart' show ShikiTheme;");
  for (final t in entries) {
    final i = info[t['name']]!;
    b.writeln("import 'src/themes/${i.file}.dart' as t_${i.file};");
  }
  b
    ..writeln()
    ..writeln('abstract final class ShikiThemes {');
  for (final t in entries) {
    final i = info[t['name']]!;
    b
      ..writeln(
        '  /// ${(t['displayName'] as String?) ?? t['name']} (${t['type']}).',
      )
      ..writeln(
        '  static const ShikiTheme ${i.ident} = t_${i.file}.${i.ident};',
      );
  }
  b
    ..writeln()
    ..writeln(
      '  // CAUTION: referencing `all` pulls EVERY theme into your build.',
    )
    ..writeln('  // Prefer individual members.')
    ..writeln('  static const List<ShikiTheme> all = [');
  for (final t in entries) {
    b.writeln('    ${info[t['name']]!.ident},');
  }
  b
    ..writeln('  ];')
    ..writeln('}');
  File('lib/themes.dart').writeAsStringSync(b.toString());
}

void _writePierreFacade(
  List<Map<String, dynamic>> themes,
  Map<String, _Info> info,
) {
  final entries = [...themes]
    ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/generate_bundled.dart. Do not edit.')
    ..writeln('//')
    ..writeln(
      '// Pierre themes: an opt-in set of 10 custom themes by Pierre, MIT ©',
    )
    ..writeln(
      '// The Pierre Computer Company (https://pierre.co). Sourced from',
    )
    ..writeln(
      '// https://github.com/pierrecomputer/pierre/tree/main/packages/theme',
    )
    ..writeln(
      '// (npm: @pierre/theme). Separate from `ShikiThemes` and not counted',
    )
    ..writeln('// among the bundled Shiki themes.')
    ..writeln('//')
    ..writeln('// Typesafe and tree-shakeable: referencing a member (e.g.')
    ..writeln('// `PierreThemes.pierreDark`) pulls in only that theme.')
    ..writeln()
    ..writeln("import 'src/core/shiki_theme.dart';")
    ..writeln("export 'src/core/shiki_theme.dart' show ShikiTheme;");
  for (final t in entries) {
    final i = info[t['name']]!;
    b.writeln("import 'src/pierre_themes/${i.file}.dart' as p_${i.file};");
  }
  b
    ..writeln()
    ..writeln('abstract final class PierreThemes {');
  for (final t in entries) {
    final i = info[t['name']]!;
    b
      ..writeln(
        '  /// ${(t['displayName'] as String?) ?? t['name']} (${t['type']}).',
      )
      ..writeln(
        '  static const ShikiTheme ${i.ident} = p_${i.file}.${i.ident};',
      );
  }
  b
    ..writeln()
    ..writeln('  // CAUTION: referencing `all` pulls in all 10 Pierre themes.')
    ..writeln('  static const List<ShikiTheme> all = [');
  for (final t in entries) {
    b.writeln('    ${info[t['name']]!.ident},');
  }
  b
    ..writeln('  ];')
    ..writeln('}');
  File('lib/pierre_themes.dart').writeAsStringSync(b.toString());
}

/// Copies the upstream NOTICE files (per-grammar/theme source licenses) into a
/// combined attribution file at the package root, if present.
void _writeAttribution(String tm) {
  final sources = {
    'tm-grammars': '$tm/node_modules/tm-grammars/NOTICE',
    'tm-themes': '$tm/node_modules/tm-themes/NOTICE',
    '@pierre/theme (Pierre themes, github.com/pierrecomputer/pierre)':
        '$tm/node_modules/@pierre/theme/LICENSE',
  };
  final b = StringBuffer()
    ..writeln('# Third-party notices')
    ..writeln()
    ..writeln(
      'Bundled grammars/themes are sourced from `tm-grammars` and `tm-themes`;',
    )
    ..writeln(
      'the opt-in Pierre themes from `@pierre/theme`. Each redistributes under',
    )
    ..writeln('its original license, reproduced below.')
    ..writeln();
  var wrote = false;
  sources.forEach((name, path) {
    final f = File(path);
    if (!f.existsSync()) return;
    wrote = true;
    b
      ..writeln('## $name')
      ..writeln()
      ..writeln('```')
      ..writeln(f.readAsStringSync().trimRight())
      ..writeln('```')
      ..writeln();
  });
  if (wrote) File('THIRD_PARTY_NOTICES.md').writeAsStringSync(b.toString());
}
