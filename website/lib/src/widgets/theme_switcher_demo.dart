import 'package:flutter/material.dart';

import '../data/snippets.dart';
import '../highlight/highlighter_service.dart';
import 'code_block.dart';
import 'pill.dart';

/// Renders one Dart snippet and lets the visitor flip it through several real
/// VS Code themes — all tokenized live by shiki_flutter.
class ThemeSwitcherDemo extends StatefulWidget {
  const ThemeSwitcherDemo({super.key});

  @override
  State<ThemeSwitcherDemo> createState() => _ThemeSwitcherDemoState();
}

class _ThemeSwitcherDemoState extends State<ThemeSwitcherDemo> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final themes = HighlighterService.demoThemes;
    final theme = themes[_selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < themes.length; i++)
              SelectPill(
                label: themes[i].label,
                selected: i == _selected,
                onTap: () => setState(() => _selected = i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        CodeBlock(
          code: Snippets.byLanguage['dart']!,
          lang: 'dart',
          theme: theme.id,
        ),
      ],
    );
  }
}
