import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/links.dart';
import '../theme/tokens.dart';

/// Body copy with a single occurrence of [linkLabel] turned into a tappable
/// link to [url]. Owns (and disposes) its gesture recognizer, so callers can
/// stay stateless. Falls back to plain text if [linkLabel] isn't found.
class InlineLinkText extends StatefulWidget {
  const InlineLinkText(
    this.text, {
    super.key,
    required this.linkLabel,
    required this.url,
    required this.style,
  });

  final String text;
  final String linkLabel;
  final String url;
  final TextStyle style;

  @override
  State<InlineLinkText> createState() => _InlineLinkTextState();
}

class _InlineLinkTextState extends State<InlineLinkText> {
  late final TapGestureRecognizer _recognizer =
      TapGestureRecognizer()..onTap = () => Links.open(widget.url);

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = widget.text.indexOf(widget.linkLabel);
    if (index < 0) {
      return Text(widget.text, style: widget.style);
    }

    final before = widget.text.substring(0, index);
    final after = widget.text.substring(index + widget.linkLabel.length);
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: widget.linkLabel,
            style: TextStyle(
              color: colors.foreground,
              decoration: TextDecoration.underline,
              decorationColor: colors.mutedForeground,
              decorationThickness: 1,
            ),
            recognizer: _recognizer,
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}
