// Pierre theme collection (built by Pierre, pierre.co).
//
// A self-contained, opt-in set of 10 custom Shiki themes (VS Code / TextMate
// JSON). Each theme is a [BundledTheme] with the same shape as the package's
// own lib/themes/*.dart. Import a single theme (e.g.
// `package:shiki_flutter/pierre_themes/pierre_dark.dart`) or this barrel's
// `pierreThemes` list. These are not part of `themes/all.dart`.
//
// MIT licensed, © The Pierre Computer Company. See lib/pierre_themes/LICENSE.
import '../src/bundled/bundled_theme.dart';

import 'pierre_dark.dart';
import 'pierre_dark_protanopia_deuteranopia.dart';
import 'pierre_dark_soft.dart';
import 'pierre_dark_tritanopia.dart';
import 'pierre_dark_vibrant.dart';
import 'pierre_light.dart';
import 'pierre_light_protanopia_deuteranopia.dart';
import 'pierre_light_soft.dart';
import 'pierre_light_tritanopia.dart';
import 'pierre_light_vibrant.dart';

export '../src/bundled/bundled_theme.dart' show BundledTheme;
export 'pierre_dark.dart';
export 'pierre_dark_protanopia_deuteranopia.dart';
export 'pierre_dark_soft.dart';
export 'pierre_dark_tritanopia.dart';
export 'pierre_dark_vibrant.dart';
export 'pierre_light.dart';
export 'pierre_light_protanopia_deuteranopia.dart';
export 'pierre_light_soft.dart';
export 'pierre_light_tritanopia.dart';
export 'pierre_light_vibrant.dart';

/// Every Pierre theme, ready to pass to `createHighlighter(themes: ...)`.
final List<BundledTheme> pierreThemes = [
  pierreDark,
  pierreDarkProtanopiaDeuteranopia,
  pierreDarkSoft,
  pierreDarkTritanopia,
  pierreDarkVibrant,
  pierreLight,
  pierreLightProtanopiaDeuteranopia,
  pierreLightSoft,
  pierreLightTritanopia,
  pierreLightVibrant,
];
