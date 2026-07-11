import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/links.dart';
import '../theme/theme_controller.dart';
import '../theme/tokens.dart';
import 'brand.dart';
import 'section.dart';

/// The sticky top navigation, matching diffs.com's header 1:1.
///
/// It has a solid background and **no** bottom border while the page is at the
/// top; once the user scrolls, a hairline border fades in over 200ms (diffs.com
/// uses `border-transparent` + `transition-[border-color] duration-200`). The
/// control row is 36px tall inside 12px (`py-3`) padding. Below the compact
/// breakpoint the links collapse into a menu button.
class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    required this.currentRoute,
    this.onMenu,
    this.scrolled,
  });

  final String currentRoute;
  final VoidCallback? onMenu;

  /// Whether the page has scrolled past the top; drives the bottom border.
  final ValueListenable<bool>? scrolled;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    final row = ContentContainer(
      child: Row(
        children: [
          Brand(onTap: () => context.go('/')),
          const Spacer(),
          if (!compact) ...[
            _NavLink(
              label: 'Home',
              active: currentRoute == '/',
              onTap: () => context.go('/'),
            ),
            _NavLink(
              label: 'Docs',
              active: currentRoute.startsWith('/docs'),
              onTap: () => context.go('/docs'),
            ),
            _NavLink(
              label: 'pub.dev',
              external: true,
              onTap: () => Links.open(Links.pubDev),
            ),
            const _NavDivider(),
            _IconAction(
              icon: Icons.code_rounded,
              tooltip: 'GitHub',
              onTap: () => Links.open(Links.github),
            ),
            const _ThemeToggle(),
          ] else ...[
            const _ThemeToggle(),
            _IconAction(
              icon: Icons.menu_rounded,
              tooltip: 'Menu',
              onTap: onMenu,
            ),
          ],
        ],
      ),
    );

    final listenable = scrolled;
    if (listenable == null) return _bar(context, row, false);
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, isScrolled, child) => _bar(context, child!, isScrolled),
      child: row,
    );
  }

  Widget _bar(BuildContext context, Widget child, bool isScrolled) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: AppLayout.navHeight,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(
            color: isScrolled ? colors.border : Colors.transparent,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// A button-styled nav link (diffs.com `h-8 px-2 rounded-md text-sm`): the
/// active route is `foreground` + medium weight; others are muted + normal and
/// brighten to `foreground` on hover over a subtle pill. External links carry a
/// small up-right arrow.
class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.onTap,
    this.active = false,
    this.external = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool external;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = widget.active || _hovered
        ? colors.foreground
        : colors.mutedForeground;

    final link = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.foreground.withValues(alpha: 0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight:
                      widget.active ? FontWeight.w500 : FontWeight.w400,
                  height: 1.0,
                ),
              ),
              if (widget.external) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 15,
                  color: colors.mutedForeground,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: link);
  }
}

/// The thin vertical rule between the text links and the icon buttons
/// (diffs.com `mx-2 h-5 w-px border-l`).
class _NavDivider extends StatelessWidget {
  const _NavDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: context.colors.border,
    );
  }
}

/// A square 36px (`size-9`) icon button with a `rounded-md` hover pill.
class _IconAction extends StatefulWidget {
  const _IconAction({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final action = Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? colors.foreground.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(widget.icon, size: 18, color: colors.foreground),
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: action);
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = AppTheme.of(context);
    return _IconAction(
      icon: controller.isDark
          ? Icons.light_mode_outlined
          : Icons.dark_mode_outlined,
      tooltip: controller.isDark ? 'Light mode' : 'Dark mode',
      onTap: controller.toggle,
    );
  }
}
