import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'app_icon.dart';

/// An icon button that copies [text] to the clipboard and briefly shows a
/// checkmark as confirmation. Uses the Pierre copy/check glyphs.
class CopyButton extends StatefulWidget {
  const CopyButton({
    super.key,
    required this.text,
    this.color,
    this.hoverColor,
    this.size = 16,
    this.tooltip = 'Copy',
  });

  final String text;
  final Color? color;

  /// Color on hover. Defaults to the site `foreground`; pass a code block's
  /// `onBg` so the button stays legible when floating over a light-themed block
  /// in dark mode (or vice versa).
  final Color? hoverColor;

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
    final hoverColor = widget.hoverColor ?? context.colors.foreground;
    final color = _copied
        ? context.colors.accent
        : (_hovered ? hoverColor : baseColor);

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
            child: AppIcon(
              _copied ? DiffIcon.check : DiffIcon.copy,
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
