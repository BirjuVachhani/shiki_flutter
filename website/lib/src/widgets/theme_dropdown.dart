import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_icon.dart';

/// One selectable theme in a [ThemeDropdown].
typedef ThemeChoice = ({String id, bool isDark});

/// The diffs.com (shadcn "neutral") dropdown palette for the active brightness -
/// the exact values read from diffs.com's stylesheet. The popup and the trigger
/// have *different* fills/borders there, so both are captured here:
///
/// - Popup content: `bg-popover` + `--border` (white/10 dark), rows use
///   `--accent` when selected/hovered.
/// - Trigger button: `bg-background` (the page color) + a solid
///   `border-neutral-800` (dark), hovering to a faint `bg-input/50`.
///
/// Text and icon colors come from [AppColors] (`--foreground` /
/// `--muted-foreground`), which already match.
typedef _Palette = ({
  Color popover,
  Color accent,
  Color triggerBg,
  Color triggerBorder,
  Color triggerHover,
});

_Palette _palette(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? (
          popover: const Color(0xFF171717), // --popover / neutral-900
          accent: const Color(0xFF262626), // --accent / neutral-800
          triggerBg: const Color(0xFF0A0A0A), // --background / neutral-950
          triggerBorder: const Color(0xFF262626), // dark:border-neutral-800
          triggerHover: const Color(0xFF1C1C1C), // bg-input/50 over background
        )
      : (
          popover: const Color(0xFFFFFFFF),
          accent: const Color(0xFFF5F5F5),
          triggerBg: const Color(0xFFFFFFFF),
          triggerBorder: const Color(0xFFE5E5E5), // --border
          triggerHover: const Color(0xFFF5F5F5), // hover:bg-secondary
        );
}

/// A theme selector modelled on the diffs.com dropdown: a compact trigger "pill"
/// (sun/moon icon + theme id + chevron) that opens a solid, bordered popup
/// listing themes with a checkmark on the selected row.
///
/// Built on a custom [OverlayPortal] (not `MenuAnchor`) so the popup has a real
/// opaque background and a controlled fade/scale open animation. The trigger and
/// popup are split into [ThemeDropdownTrigger] and [ThemeDropdownPanel] so they
/// can be golden-tested in isolation.
class ThemeDropdown extends StatefulWidget {
  const ThemeDropdown({
    super.key,
    required this.choices,
    required this.selectedId,
    required this.onSelected,
    this.menuWidth = 272,
  });

  final List<ThemeChoice> choices;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final double menuWidth;

  @override
  State<ThemeDropdown> createState() => _ThemeDropdownState();
}

class _ThemeDropdownState extends State<ThemeDropdown>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  // Initialized in initState (not as a `late final` inline field) so the Ticker
  // is created while the element is active - otherwise disposing the dropdown
  // without ever opening it lazily builds the controller during teardown, which
  // throws (a Ticker can't look up TickerMode on a deactivated element).
  late final AnimationController _anim;
  bool _open = false;

  ThemeChoice get _selected => widget.choices.firstWhere(
        (c) => c.id == widget.selectedId,
        orElse: () => widget.choices.first,
      );

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _openMenu() {
    setState(() => _open = true);
    _portal.show();
    _anim.forward(from: 0);
  }

  void _closeMenu() {
    if (!_open) return;
    _anim.reverse().then((_) {
      if (mounted) {
        _portal.hide();
        setState(() => _open = false);
      }
    });
  }

  void _select(String id) {
    widget.onSelected(id);
    _closeMenu();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => Positioned.fill(
          child: Stack(
            children: [
              // Outside-tap barrier.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeMenu,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 6),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) {
                      final t = Curves.easeOutCubic.transform(_anim.value);
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 4),
                          child: Transform.scale(
                            scale: 0.98 + 0.02 * t,
                            alignment: Alignment.topLeft,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: ThemeDropdownPanel(
                      choices: widget.choices,
                      selectedId: widget.selectedId,
                      width: widget.menuWidth,
                      onSelected: _select,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        child: ThemeDropdownTrigger(
          choice: _selected,
          open: _open,
          onTap: () => _open ? _closeMenu() : _openMenu(),
        ),
      ),
    );
  }
}

/// The pill that opens the menu: sun/moon icon + theme id + chevron.
class ThemeDropdownTrigger extends StatefulWidget {
  const ThemeDropdownTrigger({
    super.key,
    required this.choice,
    required this.open,
    required this.onTap,
  });

  final ThemeChoice choice;
  final bool open;
  final VoidCallback onTap;

  @override
  State<ThemeDropdownTrigger> createState() => _ThemeDropdownTriggerState();
}

class _ThemeDropdownTriggerState extends State<ThemeDropdownTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = _palette(context);
    final active = _hovered || widget.open;

    final Widget pill = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          // shadcn button: h-9 / px-3.5 / py-2 / rounded-lg (--radius 10px),
          // bg-background with a solid neutral-800 border in dark.
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? palette.triggerHover : palette.triggerBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.triggerBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                widget.choice.isDark ? DiffIcon.moon : DiffIcon.sun,
                size: 16,
                color: colors.mutedForeground,
              ),
              const SizedBox(width: 8), // gap-2
              Text(
                widget.choice.id,
                style: TextStyle(
                  color: colors.foreground,
                  fontFamily: AppFonts.sans,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              // The chevron is `ml-auto` in diffs (pinned to the pill's right
              // edge); emulate that separation on this content-sized pill.
              const SizedBox(width: 16),
              _ChevronDown(color: colors.mutedForeground),
            ],
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: pill);
  }
}

/// The popup: a solid, bordered, rounded card listing every [choice].
class ThemeDropdownPanel extends StatelessWidget {
  const ThemeDropdownPanel({
    super.key,
    required this.choices,
    required this.selectedId,
    required this.onSelected,
    this.width = 272,
    this.maxHeight = 360,
  });

  final List<ThemeChoice> choices;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _palette(context).popover,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.codeShadow,
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in choices)
                  _ThemeMenuItem(
                    id: c.id,
                    selected: c.id == selectedId,
                    onTap: () => onSelected(c.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single theme row: the id on the left, a checkmark on the right when
/// selected.
class _ThemeMenuItem extends StatefulWidget {
  const _ThemeMenuItem({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeMenuItem> createState() => _ThemeMenuItemState();
}

class _ThemeMenuItemState extends State<_ThemeMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;

    // Selected and hovered rows both use `--accent`, exactly like diffs.com; the
    // checkmark is what distinguishes the selected row.
    final bg = (selected || _hovered)
        ? _palette(context).accent
        : Colors.transparent;

    final Widget row = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 8, 11, 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.foreground,
                    fontFamily: AppFonts.sans,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                AppIcon(DiffIcon.check, size: 15, color: colors.foreground),
              ],
            ],
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: row);
  }
}

/// The exact chevron from diffs.com's trigger - a narrow, rounded "v" traced
/// from their SVG (viewBox `0 0 10 16`, ~1.5px stroke, round caps/joins),
/// rather than the chunkier Material chevron.
class _ChevronDown extends StatelessWidget {
  const _ChevronDown({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // Natural SVG size: 10 x 16.
    return CustomPaint(size: const Size(10, 16), painter: _ChevronPainter(color));
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 10;
    final sy = size.height / 16;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * sx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Centerline of diffs' filled chevron path, vertically centered in the box.
    final path = Path()
      ..moveTo(1.0 * sx, 6.2 * sy)
      ..lineTo(5.0 * sx, 9.7 * sy)
      ..lineTo(9.0 * sx, 6.2 * sy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}
