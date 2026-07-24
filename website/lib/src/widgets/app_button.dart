import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_icon.dart';

enum AppButtonVariant { primary, secondary, ghost }

enum AppButtonSize { md, sm }

/// A compact, shadcn-style button with hover feedback and an optional leading
/// icon. Use [variant] to pick the visual weight.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.leadingDiffIcon,
    this.trailingDiffIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;

  /// A Pierre leading glyph; takes precedence over [icon] when set.
  final DiffIcon? leadingDiffIcon;

  /// A Pierre trailing glyph; takes precedence over [trailingIcon] when set.
  final DiffIcon? trailingDiffIcon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onPressed != null;
    final isSm = widget.size == AppButtonSize.sm;

    late final Color bg;
    late final Color fg;
    Border? border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = _hovered ? colors.primary.withValues(alpha: 0.88) : colors.primary;
        fg = colors.onPrimary;
      case AppButtonVariant.secondary:
        bg = _hovered
            ? Color.alphaBlend(
                colors.foreground.withValues(alpha: 0.06),
                colors.surfaceInset,
              )
            : colors.surfaceInset;
        fg = colors.foreground;
      case AppButtonVariant.ghost:
        bg = _hovered
            ? colors.foreground.withValues(alpha: 0.06)
            : Colors.transparent;
        fg = colors.foreground;
    }

    final fontSize = isSm ? 13.5 : 15.0;
    final iconSize = isSm ? 15.0 : 18.0;
    final padding = EdgeInsets.symmetric(
      horizontal: isSm ? 14 : 20,
      vertical: isSm ? 8 : 14,
    );

    final Widget button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: padding,
          decoration: BoxDecoration(
            color: enabled ? bg : bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leadingDiffIcon != null) ...[
                AppIcon(widget.leadingDiffIcon!, size: iconSize, color: fg),
                const SizedBox(width: 7),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: iconSize, color: fg),
                const SizedBox(width: 7),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              if (widget.trailingDiffIcon != null) ...[
                const SizedBox(width: 6),
                AppIcon(widget.trailingDiffIcon!, size: iconSize, color: fg),
              ] else if (widget.trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(widget.trailingIcon, size: iconSize, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: button);
  }
}
