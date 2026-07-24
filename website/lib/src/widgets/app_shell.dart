import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'nav_bar.dart';
import 'nav_sheet.dart';

/// Page scaffold shared by every route: a pinned, translucent [NavBar] over a
/// full-bleed [child] that scrolls behind it. On compact widths the nav's menu
/// button opens the app-wide navigation popup (see [showAppNavSheet]).
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
  /// Whether the page has scrolled off the top. Drives the nav's bottom border,
  /// which is invisible at the top of the page and fades in on
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
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final scrolled = notification.metrics.pixels > 0.5;
      if (scrolled != _scrolled.value) _scrolled.value = scrolled;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
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
              onMenu: () =>
                  showAppNavSheet(context, currentRoute: widget.currentRoute),
            ),
          ),
        ],
      ),
    );
  }
}
