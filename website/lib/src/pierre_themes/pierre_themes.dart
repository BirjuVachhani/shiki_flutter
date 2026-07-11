// Pierre theme collection extracted from diffs.com (Pierre, pierre.co).
//
// A self-contained set of 10 custom Shiki themes (VS Code / TextMate JSON).
// Each theme is a [BundledTheme] identical in shape to the package's own
// lib/themes/*.dart, so this whole folder can be copied into the package.
import 'package:shiki_flutter/shiki_flutter.dart';

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

export 'package:shiki_flutter/shiki_flutter.dart' show BundledTheme;
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
