import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

// Import ONLY the bundled languages/themes the site actually demonstrates. This
// is exactly how a consumer app dogfoods the package: everything not imported
// here is tree-shaken out of the build.
import 'package:shiki_flutter/langs/css.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/langs/go.dart';
import 'package:shiki_flutter/langs/html.dart';
import 'package:shiki_flutter/langs/javascript.dart';
import 'package:shiki_flutter/langs/json.dart';
import 'package:shiki_flutter/langs/markdown.dart';
import 'package:shiki_flutter/langs/python.dart';
import 'package:shiki_flutter/langs/rust.dart';
import 'package:shiki_flutter/langs/shellscript.dart';
import 'package:shiki_flutter/langs/sql.dart';
import 'package:shiki_flutter/langs/tsx.dart';
import 'package:shiki_flutter/langs/typescript.dart';
import 'package:shiki_flutter/langs/yaml.dart';

import 'package:shiki_flutter/themes/dracula.dart';
import 'package:shiki_flutter/themes/github_dark.dart';
import 'package:shiki_flutter/themes/github_light.dart';
import 'package:shiki_flutter/themes/nord.dart';
import 'package:shiki_flutter/themes/one_dark_pro.dart';
import 'package:shiki_flutter/themes/vesper.dart';
import 'package:shiki_flutter/themes/vitesse_dark.dart';
import 'package:shiki_flutter/themes/vitesse_light.dart';

// The docs theme gallery previews EVERY bundled theme, so it legitimately needs
// the `all.dart` barrel. This is the one intentional exception to the site's
// lean-imports dogfooding, kept off the main shared highlighter and isolated to
// a separate, lazily-built gallery highlighter so the bundle-size docs stay
// truthful.
import 'package:shiki_flutter/themes/all.dart';

// The custom "Pierre" theme collection now lives in the package as a separate,
// opt-in set (package:shiki_flutter/pierre_themes/), dogfooded here.
import 'package:shiki_flutter/pierre_themes/pierre_themes.dart';

import '../theme/tokens.dart';

/// A language the demos can switch between, with a display label and sample.
class DemoLanguage {
  const DemoLanguage(this.language, this.label, this.filename);
  final BundledLanguage language;
  final String label;
  final String filename;

  String get id => language.id;
}

/// A theme the demos can switch between.
class DemoTheme {
  const DemoTheme(this.theme, this.label);
  final BundledTheme theme;
  final String label;

  String get id => theme.id;
  bool get isDark => theme.type == 'dark';
}

/// Wraps a single, shared [ShikiHighlighter] for the whole site.
///
/// Code blocks highlight asynchronously (see main.dart), so tokenization runs
/// off the UI thread and the highlighter's own token cache keeps rebuilds
/// instant, no hand-rolled span cache needed here. This service just owns the
/// shared highlighter, the theme background colors, and the docs theme gallery.
class HighlighterService {
  HighlighterService._();

  static final HighlighterService instance = HighlighterService._();

  // Bundled `dart`, `githubDark`, ... symbols are top-level `final`s (not
  // `const`), so these lists can't be `const`.
  late final ShikiHighlighter _highlighter = createHighlighter(
    langs: [
      dart,
      typescript,
      tsx,
      javascript,
      python,
      rust,
      go,
      json,
      yaml,
      html,
      css,
      shellscript,
      markdown,
      sql,
    ],
    themes: [
      githubDark,
      githubLight,
      oneDarkPro,
      dracula,
      nord,
      vitesseDark,
      vitesseLight,
      vesper,
      // Site-wide defaults for code blocks. These are the custom Pierre themes
      // (package:shiki_flutter/pierre_themes/, an opt-in collection, not part
      // of the package's `allThemes`). Only the two defaults are registered
      // here; the other variants are tree-shaken out of the build.
      pierreDark,
      pierreLight,
    ],
  );

  /// The shared highlighter, e.g. for passing straight to a [ShikiCodeView].
  ShikiHighlighter get highlighter => _highlighter;

  final Map<String, Color> _bgCache = {};

  /// Themes offered in the "any VS Code theme" switcher.
  static final List<DemoTheme> demoThemes = [
    DemoTheme(githubDark, 'GitHub Dark'),
    DemoTheme(oneDarkPro, 'One Dark Pro'),
    DemoTheme(dracula, 'Dracula'),
    DemoTheme(nord, 'Nord'),
    DemoTheme(vesper, 'Vesper'),
    DemoTheme(vitesseDark, 'Vitesse Dark'),
    DemoTheme(githubLight, 'GitHub Light'),
    DemoTheme(vitesseLight, 'Vitesse Light'),
  ];

  /// Languages offered in the "~250 languages" switcher.
  static final List<DemoLanguage> demoLanguages = [
    DemoLanguage(dart, 'Dart', 'main.dart'),
    DemoLanguage(typescript, 'TypeScript', 'server.ts'),
    DemoLanguage(python, 'Python', 'model.py'),
    DemoLanguage(rust, 'Rust', 'lib.rs'),
    DemoLanguage(go, 'Go', 'main.go'),
  ];

  /// The Shiki theme id that pairs with the current site [brightness]. Code
  /// blocks default to the custom Pierre themes (the opt-in
  /// package:shiki_flutter/pierre_themes collection); the theme-switcher
  /// showcase overrides this to demo the package's bundled `allThemes`.
  static String themeForBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? pierreDark.id : pierreLight.id;

  /// The background color declared by [theme], falling back to [fallback].
  Color backgroundOf(String theme, Color fallback) {
    return _bgCache.putIfAbsent(theme, () {
      final reg = _highlighter.getThemeRegistration(theme);
      return parseColor(reg.bg) ?? fallback;
    });
  }

  /// The background to paint for [theme] on the site. GitHub Dark blends into
  /// the page (black) instead of using its own lighter editor background; every
  /// other theme keeps its native background.
  Color displayBackground(String theme, Color fallback) {
    if (theme == githubDark.id) return AppColors.dark.background;
    return backgroundOf(theme, fallback);
  }

  // ---- Docs theme gallery -------------------------------------------------
  //
  // A SEPARATE highlighter that loads every bundled theme, so the docs gallery
  // can preview all of them. It's `late final`, so it isn't built until the
  // gallery is first rendered. The shared [_highlighter] above stays lean.

  late final ShikiHighlighter _galleryHighlighter = createHighlighter(
    // Only Dart is needed: the gallery always previews one Dart sample.
    langs: [dart],
    themes: allThemes,
  );

  final Map<String, TextSpan> _gallerySpanCache = {};

  /// Every bundled theme, in package order: the source of truth for the docs
  /// gallery's list (so it stays in sync when themes are regenerated).
  List<BundledTheme> get galleryThemes => allThemes;

  /// Highlights [code] in a bundled [theme] via the gallery highlighter.
  TextSpan gallerySpan(
    String code, {
    required String theme,
    double fontSize = 13.5,
  }) {
    final key = '$theme $fontSize $code';
    return _gallerySpanCache.putIfAbsent(key, () {
      return codeToTextSpan(
        _galleryHighlighter,
        code,
        lang: 'dart',
        theme: theme,
        baseStyle: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: fontSize,
          height: 1.55,
        ),
      );
    });
  }

  /// The native editor background declared by a bundled [theme] (only the
  /// selected theme is resolved, and the result is cached).
  Color galleryBackground(String theme, Color fallback) {
    return _bgCache.putIfAbsent('gallery:$theme', () {
      final reg = _galleryHighlighter.getThemeRegistration(theme);
      return parseColor(reg.bg) ?? fallback;
    });
  }
}
