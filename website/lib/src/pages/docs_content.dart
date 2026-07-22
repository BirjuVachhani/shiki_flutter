import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Prose components used to author the docs, matching diffs.com's `docs-prose`:
/// foreground body text at 16px/1.6, a ~72ch reading measure, and inline
/// `code` rendered as plain mono (no background box). Code blocks are left to
/// span the full content width.

/// The reading measure for prose. diffs.com caps docs prose at `max-w-3xl`
/// (48rem = 768px); code blocks span the full content column.
const double kProseWidth = 768;

/// A body paragraph. Wrap inline code in backticks.
class DocProse extends StatelessWidget {
  const DocProse(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      // diffs.com paragraphs sit ~20px apart (line pitch 25.5 + ~20 margin).
      padding: const EdgeInsets.only(bottom: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseWidth),
        child: Text.rich(
          TextSpan(children: inlineSpans(text, colors)),
          style: TextStyle(
            color: colors.foreground,
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

/// A second-level heading inside a docs section.
class DocH3 extends StatelessWidget {
  const DocH3(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.colors.foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}

/// A bulleted list; each item supports inline `code`.
class DocBullets extends StatelessWidget {
  const DocBullets(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 4,
                        right: 14,
                      ),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: inlineSpans(item, colors)),
                        style: TextStyle(
                          color: colors.foreground,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A borderless table with horizontal row rules (diffs style).
class DocTable extends StatelessWidget {
  const DocTable({super.key, required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseWidth),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: colors.border),
            bottom: BorderSide(color: colors.border),
          ),
          columnWidths: const {0: IntrinsicColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.mutedForeground),
                ),
              ),
              children: [
                for (final h in headers) _cell(context, h, header: true),
              ],
            ),
            for (final row in rows)
              TableRow(children: [for (final c in row) _cell(context, c)]),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String text, {bool header = false}) {
    final colors = context.colors;
    // A body cell that is exactly one inline-code token (e.g. the Property and
    // Type columns) renders as a code chip, so types read as code too.
    if (!header && _isCodeToken(text)) {
      return _codeChip(context, text.substring(1, text.length - 1));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12, right: 24),
      child: Text.rich(
        TextSpan(children: inlineSpans(text, colors)),
        style: TextStyle(
          color: colors.foreground,
          fontSize: 14,
          height: 1.5,
          fontWeight: header ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  /// Whether [text] is a single inline-code token, e.g. `` `String` ``.
  static bool _isCodeToken(String text) {
    return text.length >= 2 &&
        text.startsWith('`') &&
        text.endsWith('`') &&
        !text.substring(1, text.length - 1).contains('`');
  }

  /// A boxed inline-code chip, matching the `DocLangList` chip style.
  Widget _codeChip(BuildContext context, String label) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 13,
              height: 1.3,
              color: colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// A subtle callout box for tips.
class DocNote extends StatelessWidget {
  const DocNote(this.text, {super.key, this.icon = Icons.lightbulb_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseWidth),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: colors.mutedForeground),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: inlineSpans(text, colors)),
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 14.5,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Parses a small subset of Markdown inline syntax: `` `code` `` becomes plain
/// mono (no background box) and `**bold**` becomes semibold. Bold may wrap
/// inline code (`` **`code`** ``); the code then renders mono *and* semibold,
/// because a `TextSpan`'s style cascades to its children.
List<InlineSpan> inlineSpans(String text, AppColors colors) {
  // Match a bold run or an inline-code run, whichever starts first. `allMatches`
  // scans left to right, so a `**` that sits *inside* an earlier code run is
  // consumed as part of that run and never treated as bold (and vice versa).
  final pattern = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`');
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    final boldInner = m.group(1);
    if (boldInner != null) {
      // Recurse into the bold text for inline code; the w600 on this parent
      // cascades onto the code (and plain) children, keeping them bold.
      spans.add(
        TextSpan(
          style: const TextStyle(fontWeight: FontWeight.w600),
          children: _inlineCode(boldInner, colors),
        ),
      );
    } else {
      spans.add(_codeSpan(m.group(2)!, colors));
    }
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// Splits [text] into plain runs and inline-`code` runs. Sets no weight of its
/// own, so an enclosing bold [TextSpan] (see [inlineSpans]) cascades through.
List<InlineSpan> _inlineCode(String text, AppColors colors) {
  final code = RegExp(r'`([^`]+)`');
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in code.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(_codeSpan(m.group(1)!, colors));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// A single inline-code span: plain mono, no background box. Leaves `fontWeight`
/// unset so it inherits any enclosing bold.
TextSpan _codeSpan(String content, AppColors colors) => TextSpan(
  text: content,
  style: TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 14.5,
    color: colors.foreground,
  ),
);
