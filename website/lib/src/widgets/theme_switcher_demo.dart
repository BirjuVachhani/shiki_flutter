import 'package:flutter/material.dart';

import '../data/snippets.dart';
import '../highlight/highlighter_service.dart';
import 'code_block.dart';
import 'theme_dropdown.dart';

/// Renders one Dart snippet and lets the visitor flip it through several real
/// VS Code themes, all tokenized live by shiki_flutter. Theme selection uses the
/// diffs.com-style [ThemeDropdown].
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
        Align(
          alignment: Alignment.centerLeft,
          child: ThemeDropdown(
            choices: [
              for (final t in themes) (id: t.id, isDark: t.isDark),
            ],
            selectedId: theme.id,
            onSelected: (id) => setState(
              () => _selected = themes.indexWhere((t) => t.id == id),
            ),
          ),
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
