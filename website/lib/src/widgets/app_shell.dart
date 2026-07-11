import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/links.dart';
import '../theme/theme_controller.dart';
import '../theme/tokens.dart';
import 'brand.dart';
import 'nav_bar.dart';

/// Page scaffold shared by every route: a pinned, translucent [NavBar] over a
/// full-bleed [child] that scrolls behind it, plus an end drawer for compact
/// navigation.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Whether the page has scrolled off the top. Drives the nav's bottom border,
  /// which is invisible at the top of the page (like diffs.com) and fades in on
  /// scroll. Kept in a notifier so only the nav rebuilds, not the page body.
  final ValueNotifier<bool> _scrolled = ValueNotifier<bool>(false);

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new route starts at the top; clear any leftover scrolled state.
    if (oldWidget.currentRoute != widget.currentRoute) {
      _scrolled.value = false;
    }
  }

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    // Only track the page's own vertical scroll (depth 0), not nested
    // horizontal scrollers inside code blocks.
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical) {
      final scrolled = notification.metrics.pixels > 0.5;
      if (scrolled != _scrolled.value) _scrolled.value = scrolled;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.colors.background,
      endDrawer: _MobileMenu(currentRoute: widget.currentRoute),
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.child,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NavBar(
              currentRoute: widget.currentRoute,
              scrolled: _scrolled,
              onMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    void goThenClose(String route) {
      Navigator.of(context).pop();
      context.go(route);
    }

    return Drawer(
      backgroundColor: colors.surface,
      shape: Border(left: BorderSide(color: colors.border)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Brand(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.foreground),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MenuItem(
                label: 'Home',
                active: currentRoute == '/',
                onTap: () => goThenClose('/'),
              ),
              _MenuItem(
                label: 'Docs',
                active: currentRoute.startsWith('/docs'),
                onTap: () => goThenClose('/docs'),
              ),
              _MenuItem(
                label: 'GitHub',
                external: true,
                onTap: () => Links.open(Links.github),
              ),
              _MenuItem(
                label: 'pub.dev',
                external: true,
                onTap: () => Links.open(Links.pubDev),
              ),
              const Spacer(),
              _ThemeRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
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
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? colors.foreground : colors.mutedForeground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (external)
              Icon(
                Icons.north_east_rounded,
                size: 16,
                color: colors.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = AppTheme.of(context);
    return InkWell(
      onTap: controller.toggle,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(
              controller.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
              color: colors.foreground,
            ),
            const SizedBox(width: 12),
            Text(
              controller.isDark ? 'Light mode' : 'Dark mode',
              style: TextStyle(color: colors.foreground, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
