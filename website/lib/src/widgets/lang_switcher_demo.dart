import 'package:flutter/material.dart';

import '../data/snippets.dart';
import '../highlight/highlighter_service.dart';
import 'code_block.dart';
import 'pill.dart';

/// Renders a per-language snippet and lets the visitor switch languages,
/// showing that the same tokenizer handles each grammar.
class LangSwitcherDemo extends StatefulWidget {
  const LangSwitcherDemo({super.key});

  @override
  State<LangSwitcherDemo> createState() => _LangSwitcherDemoState();
}

class _LangSwitcherDemoState extends State<LangSwitcherDemo> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final langs = HighlighterService.demoLanguages;
    final lang = langs[_selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < langs.length; i++)
              SelectPill(
                label: langs[i].label,
                selected: i == _selected,
                onTap: () => setState(() => _selected = i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        CodeBlock(
          code: Snippets.byLanguage[lang.id]!,
          lang: lang.id,
        ),
      ],
    );
  }
}
