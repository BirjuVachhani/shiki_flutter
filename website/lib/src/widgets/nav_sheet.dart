import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/docs_sections.dart';
import '../data/links.dart';
import '../theme/theme_controller.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';
import 'brand.dart';

/// Implemented by a page that has an in-page section list (the docs page) so
/// the shared nav sheet can list those sections and scroll to them, no matter
/// which control opened the sheet.
abstract interface class DocsSectionNavigator {
  /// Index (into [docsSections]) of the section currently in view.
  int get activeSection;

  /// Scrolls the page to the section at [index].
  void scrollToSection(int index);
}

/// Bridges a [DocsSectionNavigator] up to the app-wide nav sheet. The docs page
/// registers itself while mounted; other pages leave [docs] null, so the sheet
/// then shows site links only.
class NavSheetController {
  DocsSectionNavigator? docs;
}

/// Exposes the single [NavSheetController] to the whole app. Placed above the
/// router so both the shell's nav bar and the docs page reach the same one.
class NavSheetScope extends InheritedWidget {
  const NavSheetScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final NavSheetController controller;

  static NavSheetController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NavSheetScope>();
    assert(scope != null, 'No NavSheetScope found in context.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(NavSheetScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Opens the app-wide navigation popup: the site links (plus the docs section
/// list when a docs page is on screen) as a centered, dismissible overlay. This
/// is the single mobile/tablet menu, replacing the old end drawer. [currentRoute]
/// drives which link is highlighted as active.
Future<void> showAppNavSheet(
  BuildContext context, {
  required String currentRoute,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => _AppNavSheet(currentRoute: currentRoute),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// The popup body: site links up top, then (only on the docs page) the grouped
/// section list with the active section highlighted. Links and the theme toggle
/// act in place; tapping a section closes the sheet and scrolls the page to it.
class _AppNavSheet extends StatelessWidget {
  const _AppNavSheet({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = AppTheme.of(context);
    final router = GoRouter.of(context);
    final docs = NavSheetScope.of(context).docs;

    void close() => Navigator.of(context).pop();
    void goRoute(String route) {
      close();
      router.go(route);
    }

    void openExternal(String url) {
      close();
      Links.open(url);
    }

    void selectSection(int index) {
      close();
      docs?.scrollToSection(index);
    }

    // Build the grouped section list only when a docs page is on screen. The
    // running index maps each tile back to the flattened section list.
    final sectionBlocks = <Widget>[];
    if (docs != null) {
      final active = docs.activeSection;
      var index = 0;
      for (var gi = 0; gi < docsGroups.length; gi++) {
        sectionBlocks.add(
          Padding(
            padding: EdgeInsets.only(top: gi == 0 ? 0 : 20, bottom: 8, left: 12),
            child: DocsGroupLabel(docsGroups[gi].title),
          ),
        );
        for (final section in docsGroups[gi].sections) {
          final i = index++;
          sectionBlocks.add(
            DocsSectionTile(
              label: section.title,
              active: i == active,
              onTap: () => selectSection(i),
            ),
          );
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 56, 12, 16),
        child: Align(
          // Anchor to the top so a short menu (e.g. on the home page) reads as
          // dropping from the nav rather than floating mid-screen.
          alignment: Alignment.topRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: sectionBlocks.isNotEmpty ? 280 : 220),
            // A Material both paints the panel surface and satisfies the
            // InkWell / IconButton descendants (showGeneralDialog inserts none).
            child: Material(
              color: colors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                side: BorderSide(color: colors.border),
              ),
              child: Column(
                // Shrink-wrap so short menus hug their content; the scroll view
                // below caps a long list (docs) at the available height.
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SheetNavItem(
                            label: 'Home',
                            active: currentRoute == '/',
                            onTap: () => goRoute('/'),
                          ),
                          _SheetNavItem(
                            label: 'Docs',
                            active: currentRoute.startsWith('/docs'),
                            onTap: () => goRoute('/docs'),
                          ),
                          _SheetNavItem(
                            label: 'GitHub',
                            external: true,
                            onTap: () => openExternal(Links.github),
                          ),
                          _SheetNavItem(
                            label: 'pub.dev',
                            external: true,
                            onTap: () => openExternal(Links.pubDev),
                          ),
                          _SheetNavItem(
                            label: theme.isDark ? 'Light mode' : 'Dark mode',
                            leading: theme.isDark ? DiffIcon.sun : DiffIcon.moon,
                            onTap: theme.toggle,
                          ),
                          if (sectionBlocks.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Divider(height: 1, thickness: 1, color: colors.border),
                            const SizedBox(height: 12),
                            ...sectionBlocks,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A nav row inside the popup: 16px label, optional leading glyph (theme
/// toggle) or trailing external arrow, with the active route in foreground.
class _SheetNavItem extends StatelessWidget {
  const _SheetNavItem({
    required this.label,
    required this.onTap,
    this.active = false,
    this.external = false,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool external;
  final DiffIcon? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SelectionContainer.disabled(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (leading != null) ...[
                AppIcon(leading!, size: 18, color: colors.foreground),
                const SizedBox(width: 12),
              ],
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
                AppIcon(
                  DiffIcon.arrowUpRight,
                  size: 16,
                  color: colors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small uppercase category label sitting above a group of section tiles.
/// Shared by the docs rail and the nav popup.
class DocsGroupLabel extends StatelessWidget {
  const DocsGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.colors.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          height: 1.4,
        ),
      ),
    );
  }
}

/// A single section entry (docs rail and nav popup). diffs.com: selection
/// changes colour + a subtle pill only, never weight. Active = foreground on an
/// accent pill; others muted, brightening on hover.
class DocsSectionTile extends StatefulWidget {
  const DocsSectionTile({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<DocsSectionTile> createState() => _DocsSectionTileState();
}

class _DocsSectionTileState extends State<DocsSectionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = widget.active;
    final color = active || _hovered ? colors.foreground : colors.mutedForeground;
    final Widget item = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? colors.surfaceInset
                : (_hovered ? colors.foreground.withValues(alpha: 0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: item);
  }
}
