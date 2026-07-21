// One-off: measures fast-path coverage across ALL bundled grammars, and how
// many patterns contain the newly-widened constructs.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:shiki_flutter/langs.dart';
import 'package:shiki_flutter/src/onig/regex_engine.dart';

void _collect(dynamic node, List<String> out) {
  if (node is Map) {
    for (final k in const ['match', 'begin', 'end', 'while']) {
      final v = node[k];
      if (v is String) out.add(v);
    }
    for (final v in node.values) {
      _collect(v, out);
    }
  } else if (node is List) {
    for (final v in node) {
      _collect(v, out);
    }
  }
}

void main() {
  var total = 0, fast = 0, err = 0, widenFast = 0;
  final widenRe = RegExp(r'\(\?>|\(\?i|\\A|\\z');
  for (final lang in CodeLanguages.all) {
    final pats = <String>[];
    _collect(jsonDecode(lang.json), pats);
    for (final p in pats) {
      total++;
      try {
        if (OnigRegex(p).hasFastPath) {
          fast++;
          if (widenRe.hasMatch(p)) widenFast++;
        }
      } catch (_) {
        err++;
      }
    }
  }
  print(
    'grammars=${CodeLanguages.all.length}  patterns=$total  compileErr=$err',
  );
  print(
    'fast-path coverage: $fast/$total = ${(100 * fast / total).toStringAsFixed(1)}%',
  );
  print(
    'fast-pathed patterns using a widened construct (atomic/(?i)/\\A/\\z): $widenFast',
  );
}
