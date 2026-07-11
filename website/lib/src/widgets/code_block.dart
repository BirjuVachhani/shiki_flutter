import 'package:flutter/material.dart';

import '../highlight/highlighter_service.dart';
import '../theme/tokens.dart';
import 'copy_button.dart';

/// A rounded, bordered code card highlighted live by shiki_flutter.
///
/// When [theme] is null the block follows the site's light/dark mode. There is
/// no header chrome — a subtle copy button floats in the top-right. The block
/// grows to fit its content vertically (no inner vertical scroll) so it never
/// traps the page's scroll; long lines scroll horizontally.
class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.code,
    required this.lang,
    this.theme,
    this.filename,
    this.showCopy = true,
    this.showLineNumbers = true,
    this.fontSize = 13.5,
  });

  final String code;
  final String lang;

  /// Shiki theme id. Defaults to the theme matching the site brightness.
  final String? theme;

  /// Reserved label; not currently rendered (no header bar).
  final String? filename;

  final bool showCopy;

  /// Show a right-aligned line-number gutter (like diffs.com).
  final bool showLineNumbers;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final service = HighlighterService.instance;
    final themeId = theme ??
        HighlighterService.themeForBrightness(Theme.of(context).brightness);

    final trimmed = code.trim();
    final bg = service.displayBackground(themeId, colors.surface);
    final onBg = bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final border = onBg.withValues(alpha: 0.10);

    final span = service.span(
      trimmed,
      lang: lang,
      theme: themeId,
      fontSize: fontSize,
    );

    const vPad = 18.0;

    // The code, in a horizontal scroller so long lines never wrap.
    final codeArea = SelectionArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text.rich(span, softWrap: false),
        ),
      ),
    );

    Widget body;
    if (showLineNumbers) {
      final lineCount = '\n'.allMatches(trimmed).length + 1;
      // Same font size + line height as the code so numbers align row-for-row.
      final numberStyle = TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: fontSize,
        height: 1.55,
        color: onBg.withValues(alpha: 0.32),
      );
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: vPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectionContainer.disabled(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 1; i <= lineCount; i++)
                      Text('$i', style: numberStyle),
                  ],
                ),
              ),
            ),
            Expanded(child: codeArea),
          ],
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.only(left: 20, top: vPad, bottom: vPad),
        child: codeArea,
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: border),
      ),
      child: Stack(
        children: [
          body,
          if (showCopy)
            Positioned(
              top: 8,
              right: 8,
              child: _CopyChip(text: trimmed, onBg: onBg, bg: bg),
            ),
        ],
      ),
    );
  }
}

/// A small copy button that stays legible when floating over code.
class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.text, required this.onBg, required this.bg});

  final String text;
  final Color onBg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(onBg.withValues(alpha: 0.06), bg),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: onBg.withValues(alpha: 0.10)),
      ),
      child: CopyButton(
        text: text,
        color: onBg.withValues(alpha: 0.55),
        size: 15,
      ),
    );
  }
}
