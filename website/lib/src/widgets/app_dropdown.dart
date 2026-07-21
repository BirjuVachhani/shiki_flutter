import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_icon.dart';

/// Builds the trigger, given whether the menu is [open] and a [toggle] callback.
typedef DropdownTriggerBuilder =
    Widget Function(BuildContext context, bool open, VoidCallback toggle);

/// Builds the popup content, given a [close] callback for menu items to call.
typedef DropdownOverlayBuilder =
    Widget Function(BuildContext context, VoidCallback close);

/// A reusable dropdown shell: a trigger that opens an anchored, animated popup.
///
/// Extracted from the theme dropdown so any menu (theme picker, docs actions,
/// ...) shares one overlay implementation. Built on [OverlayPortal] (not
/// `MenuAnchor`) so the popup has a real opaque background and a controlled
/// fade/scale open animation, and an outside tap closes it.
class AppDropdown extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.triggerBuilder,
    required this.overlayBuilder,
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.panelAlignment = Alignment.topLeft,
    this.scaleAlignment = Alignment.topLeft,
    this.offset = const Offset(0, 6),
  });

  final DropdownTriggerBuilder triggerBuilder;
  final DropdownOverlayBuilder overlayBuilder;

  /// Point on the trigger the popup is anchored to.
  final Alignment targetAnchor;

  /// Point on the popup pinned to [targetAnchor].
  final Alignment followerAnchor;

  /// Alignment of the popup within the follower box.
  final Alignment panelAlignment;

  /// Origin for the open scale animation (usually matches [followerAnchor]).
  final Alignment scaleAlignment;

  /// Extra offset from the anchor (e.g. a small gap below the trigger).
  final Offset offset;

  @override
  State<AppDropdown> createState() => _AppDropdownState();
}

class _AppDropdownState extends State<AppDropdown>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  // Initialized in initState (not `late final` inline) so the Ticker is created
  // while the element is active - otherwise disposing without ever opening lazily
  // builds the controller during teardown, which throws.
  late final AnimationController _anim;
  bool _open = false;

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

  void _toggle() => _open ? _closeMenu() : _openMenu();

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
                targetAnchor: widget.targetAnchor,
                followerAnchor: widget.followerAnchor,
                offset: widget.offset,
                child: Align(
                  alignment: widget.panelAlignment,
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
                            alignment: widget.scaleAlignment,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: widget.overlayBuilder(context, _closeMenu),
                  ),
                ),
              ),
            ],
          ),
        ),
        child: widget.triggerBuilder(context, _open, _toggle),
      ),
    );
  }
}

/// A solid, bordered, rounded popover card for [AppDropdown] menus. Matches the
/// diffs.com dropdown surface (bg-popover, `--border`, soft shadow).
class AppMenuPanel extends StatelessWidget {
  const AppMenuPanel({
    super.key,
    required this.children,
    this.width = 220,
    this.maxHeight = 360,
  });

  final List<Widget> children;
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
          color: colors.surface,
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
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

/// A single row in an [AppMenuPanel]: an optional leading glyph, a label, and an
/// optional trailing widget. Hover fills with `--accent`, like diffs.com menus.
class AppMenuItem extends StatefulWidget {
  const AppMenuItem({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingDiffIcon,
    this.leadingIcon,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final DiffIcon? leadingDiffIcon;
  final IconData? leadingIcon;
  final Widget? trailing;

  @override
  State<AppMenuItem> createState() => _AppMenuItemState();
}

class _AppMenuItemState extends State<AppMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = colors.mutedForeground;

    final row = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? colors.surfaceInset : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (widget.leadingDiffIcon != null) ...[
                AppIcon(widget.leadingDiffIcon!, size: 15, color: iconColor),
                const SizedBox(width: 10),
              ] else if (widget.leadingIcon != null) ...[
                Icon(widget.leadingIcon, size: 16, color: iconColor),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.label,
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
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: row);
  }
}
