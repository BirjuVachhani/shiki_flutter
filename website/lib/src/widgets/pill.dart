import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'copy_button.dart';

/// A small static label chip (e.g. a language name or platform tag).
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.icon, this.accent = false});

  final String label;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = accent ? colors.accent : colors.mutedForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A selectable pill used by the theme/language switchers.
class SelectPill extends StatefulWidget {
  const SelectPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SelectPill> createState() => _SelectPillState();
}

class _SelectPillState extends State<SelectPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;

    final bg = selected
        ? colors.foreground
        : (_hovered ? colors.surfaceInset : colors.surface);
    final fg = selected ? colors.background : colors.mutedForeground;
    final border = selected ? colors.foreground : colors.border;

    final Widget pill = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: pill);
  }
}

/// The install-command pill: `$ flutter pub add shiki_flutter` with a copy
/// button.
class InstallCommand extends StatelessWidget {
  const InstallCommand({super.key, required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // diffs.com keeps the install pill dark in both modes (black / neutral-900).
    final bg = isDark ? const Color(0xFF000000) : const Color(0xFF171717);
    return SelectionContainer.disabled(
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 20, right: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              command,
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 15,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            CopyButton(text: command, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
