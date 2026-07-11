import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// An icon button that copies [text] to the clipboard and briefly shows a
/// checkmark as confirmation.
class CopyButton extends StatefulWidget {
  const CopyButton({
    super.key,
    required this.text,
    this.color,
    this.size = 16,
    this.tooltip = 'Copy',
  });

  final String text;
  final Color? color;
  final double size;
  final String tooltip;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;
  bool _hovered = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? context.colors.mutedForeground;
    final color = _copied
        ? context.colors.accent
        : (_hovered ? context.colors.foreground : baseColor);

    final Widget button = Tooltip(
      message: _copied ? 'Copied!' : widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _copy,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              _copied ? Icons.check_rounded : Icons.content_copy_rounded,
              size: widget.size,
              color: color,
            ),
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: button);
  }
}
