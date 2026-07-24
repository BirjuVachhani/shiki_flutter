import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// The Pierre icon set, shipped as SVG assets under
/// `assets/icons/`.
///
/// The glyphs are traced from the reference design's own SVG icon set, so the
/// site matches it 1:1 rather than falling back to Material glyphs.
enum DiffIcon {
  /// Two overlapping rounded squares; the front square is drawn at 40% opacity
  /// for a subtle depth effect. Used by the copy button.
  copy,

  /// A single checkmark shown after a successful copy.
  check,

  /// A document with `</>` - the file-type glyph in the code-block header.
  fileCode,

  /// A downward chevron for dropdown triggers.
  chevronDown,

  /// A disc that is half-lit - the "follow system" (auto) theme.
  colorAuto,

  /// A filled crescent - the dark theme.
  colorDark,

  /// A filled sun disc - the light theme.
  colorLight,

  /// An outlined sun with rays.
  sun,

  /// An outlined crescent moon.
  moon,

  /// The GitHub mark.
  github,

  /// The Discord mark.
  discord,

  /// An arrow pointing up-and-to-the-right; marks links that open externally.
  arrowUpRight,

  /// A short rightward arrow.
  arrowRight,

  /// A close (✕) glyph.
  x,

  /// A three-line "hamburger" menu glyph.
  menu,

  /// A circular refresh arrow.
  refresh,

  /// Stacked folders.
  folders;

  /// Path to this icon's SVG asset. Enum names are camelCase; asset files are
  /// kebab-case (e.g. `fileCode` → `assets/icons/file-code.svg`).
  String get asset {
    final kebab = name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '-${m[0]!.toLowerCase()}',
    );
    return 'assets/icons/$kebab.svg';
  }
}

/// Renders a [DiffIcon] as a crisp, single-color vector.
///
/// The glyph is tinted with [ColorFilter.mode] + [BlendMode.srcIn], which
/// replaces its color while preserving each path's alpha - so multi-opacity
/// icons (e.g. [DiffIcon.copy]'s layered squares) keep their depth. Defaults to
/// the theme `foreground` color when [color] is omitted.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 16, this.color});

  final DiffIcon icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? context.colors.foreground,
        BlendMode.srcIn,
      ),
    );
  }
}
