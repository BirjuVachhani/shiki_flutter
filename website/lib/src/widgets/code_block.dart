import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

import '../highlight/highlighter_service.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';
import 'copy_button.dart';

/// A rounded, bordered code card highlighted live by shiki_flutter.
///
/// When [theme] is null the block follows the site's light/dark mode. The block
/// grows to fit its content vertically (no inner vertical scroll) so it never
/// traps the page's scroll; long lines scroll horizontally.
///
/// If [filename] is given the block gains a diffs.com-style header - a file-code
/// glyph, the file name, and the copy button on the right - separated from the
/// code by a hairline. Without a filename there is no header chrome and a subtle
/// copy button floats in the top-right instead.
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

  /// When set, renders a header bar showing this file name and a file-code
  /// icon. The copy button moves into the header instead of floating.
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

    // Async highlighting: the block shows the plain code first and swaps to the
    // highlighted result when tokenization finishes, with the shared
    // highlighter's token cache making later rebuilds instant. A virtualized
    // line view gives a real (non-faked) line-number gutter that stays
    // row-aligned, plus horizontal scrolling for long lines. Shrink-wrapped so
    // the block grows to fit and never traps the page's vertical scroll.
    final body = SelectionArea(
      child: ShikiCodeListView(
        highlighter: service.highlighter,
        code: trimmed,
        lang: lang,
        theme: themeId,
        textStyle: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: fontSize,
          height: 1.55,
        ),
        showLineNumbers: showLineNumbers,
        lineNumberColor: onBg.withValues(alpha: 0.32),
        paintBackground: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, top: 18, bottom: 18, right: 20),
      ),
    );

    // With a header the copy button lives in the header; without one it floats
    // over the code in the top-right.
    final hasHeader = filename != null;

    final Widget content = hasHeader
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                filename: filename!,
                onBg: onBg,
                copyText: showCopy ? trimmed : null,
              ),
              body,
            ],
          )
        : Stack(
            children: [
              body,
              if (showCopy)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _CopyChip(text: trimmed, onBg: onBg, bg: bg),
                ),
            ],
          );

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: .only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: border),
      ),
      child: content,
    );
  }
}

/// The optional header bar: a file-code glyph + file name on the left and the
/// copy button on the right, matching diffs.com's `data-diffs-header` - the same
/// background as the code (no divider), `padding-inline: 16`, an 8px icon↔name
/// gap, and a min-height of roughly one line plus 24px.
class _Header extends StatelessWidget {
  const _Header({
    required this.filename,
    required this.onBg,
    required this.copyText,
  });

  final String filename;
  final Color onBg;

  /// Text to copy, or null to hide the button.
  final String? copyText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // padding-inline: 16 (right trimmed to 10 so the copy glyph's own 6px
      // padding lands ~16px from the edge). Vertical padding + minHeight give
      // diffs' `calc(1lh + 24px)` header height.
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Row(
          children: [
            AppIcon(
              DiffIcon.fileCode,
              size: 16,
              color: onBg.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectionContainer.disabled(
                child: Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                    height: 1.0,
                    // diffs' [data-title] uses full --diffs-fg (no dimming).
                    color: onBg,
                  ),
                ),
              ),
            ),
            if (copyText != null)
              CopyButton(
                text: copyText!,
                color: onBg.withValues(alpha: 0.55),
                hoverColor: onBg,
                size: 15,
              ),
          ],
        ),
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
        hoverColor: onBg,
        size: 15,
      ),
    );
  }
}
