import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'inline_link_text.dart';

/// Centers its [child] in a column no wider than [maxWidth], with responsive
/// horizontal gutters.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // diffs.com uses a constant 20px (`px-5`) gutter at every breakpoint.
    const gutter = 20.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + gutter * 2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          // Fill the full max width so every section shares the same left/right
          // edge (otherwise narrow content shrink-wraps and gets centered,
          // making sections look misaligned).
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// A vertically-padded page section.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
    this.top,
    this.bottom,
    this.background,
    this.border = false,
  });

  final Widget child;
  final double maxWidth;
  final double? top;
  final double? bottom;
  final Color? background;

  /// Draw a hairline divider on top of the section.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final v = compact ? 56.0 : 96.0;
    Widget content = Padding(
      padding: EdgeInsets.only(top: top ?? v, bottom: bottom ?? v),
      child: ContentContainer(maxWidth: maxWidth, child: child),
    );
    if (background != null || border) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: border
              ? Border(top: BorderSide(color: context.colors.border))
              : null,
        ),
        child: content,
      );
    }
    return content;
  }
}

/// A section title with an optional subtitle. Matches diffs.com: a `text-2xl`
/// (24px) medium title over a muted 16px subtitle, capped to a 768px column.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleLink,
  });

  final String title;
  final String? subtitle;

  /// Optional (label, url) pair - the first occurrence of `label` in
  /// [subtitle] is rendered as a link to `url`.
  final (String label, String url)? subtitleLink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitleStyle = TextStyle(
      color: colors.mutedForeground,
      fontSize: 16,
      height: 1.6,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 768),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            if (subtitleLink case (final label, final url))
              InlineLinkText(
                subtitle!,
                linkLabel: label,
                url: url,
                style: subtitleStyle,
              )
            else
              Text(subtitle!, style: subtitleStyle),
          ],
        ],
      ),
    );
  }
}
