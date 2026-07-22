import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/links.dart';
import '../theme/tokens.dart';

/// The wordmark, matching diffs.com's brand: a semibold sans "Shiki" that links
/// home, followed by a muted tagline (`for flutter by <author>`) whose author
/// name is a link. The tagline is hidden on compact layouts, exactly like
/// diffs' `hidden md:inline` treatment.
class Brand extends StatefulWidget {
  const Brand({super.key, this.onTap});

  /// Tapping the "Shiki" wordmark. Usually navigates home.
  final VoidCallback? onTap;

  @override
  State<Brand> createState() => _BrandState();
}

class _BrandState extends State<Brand> {
  late final TapGestureRecognizer _authorTap;
  bool _wordHovered = false;
  bool _authorHovered = false;

  @override
  void initState() {
    super.initState();
    _authorTap = TapGestureRecognizer()..onTap = () => Links.open(Links.author);
  }

  @override
  void dispose() {
    _authorTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showTagline = !context.isCompact;

    // "Shiki" - text-lg (18px) / leading-20 / semibold, dims on hover.
    final word = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _wordHovered = true),
      onExit: (_) => setState(() => _wordHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          'Shiki',
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 18,
            height: 20 / 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: _wordHovered
                ? colors.foreground.withValues(alpha: 0.8)
                : colors.foreground,
          ),
        ),
      ),
    );

    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        word,
        if (showTagline) ...[
          const SizedBox(width: 6),
          // Flexible so the tagline ellipsizes instead of overflowing when the
          // nav row is tight (e.g. near the compact/wide breakpoint).
          Flexible(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontSize: 14,
                  height: 20 / 14,
                  color: colors.mutedForeground,
                ),
                children: [
                  const TextSpan(text: 'for flutter by '),
                  TextSpan(
                    text: 'Birju Vachhani',
                    recognizer: _authorTap,
                    onEnter: (_) => setState(() => _authorHovered = true),
                    onExit: (_) => setState(() => _authorHovered = false),
                    mouseCursor: SystemMouseCursors.click,
                    style: TextStyle(
                      color: _authorHovered
                          ? colors.foreground.withValues(alpha: 0.8)
                          : colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    return SelectionContainer.disabled(child: brand);
  }
}

class FooterBrand extends StatefulWidget {
  const FooterBrand({super.key, this.onTap});

  /// Tapping the "Shiki" wordmark. Usually navigates home.
  final VoidCallback? onTap;

  @override
  State<FooterBrand> createState() => _FooterBrandState();
}

class _FooterBrandState extends State<FooterBrand> {
  late final TapGestureRecognizer _authorTap;
  bool _wordHovered = false;
  bool _authorHovered = false;

  @override
  void initState() {
    super.initState();
    _authorTap = TapGestureRecognizer()..onTap = () => Links.open(Links.author);
  }

  @override
  void dispose() {
    _authorTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // "Shiki" - text-lg (18px) / leading-20 / semibold, dims on hover.
    final word = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _wordHovered = true),
      onExit: (_) => setState(() => _wordHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          'Shiki',
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 18,
            height: 20 / 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: _wordHovered
                ? colors.foreground.withValues(alpha: 0.8)
                : colors.foreground,
          ),
        ),
      ),
    );

    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        word,
        const SizedBox(width: 6),
        // Flexible so the tagline wraps instead of overflowing when the brand
        // is laid out in a narrow column (mobile footer).
        Flexible(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 14,
                height: 20 / 14,
                color: colors.mutedForeground,
              ),
              children: [
                const TextSpan(text: 'for flutter by '),
                TextSpan(
                  text: 'Birju Vachhani',
                  recognizer: _authorTap,
                  onEnter: (_) => setState(() => _authorHovered = true),
                  onExit: (_) => setState(() => _authorHovered = false),
                  mouseCursor: SystemMouseCursors.click,
                  style: TextStyle(
                    color: _authorHovered
                        ? colors.foreground.withValues(alpha: 0.8)
                        : colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return SelectionContainer.disabled(child: brand);
  }
}
