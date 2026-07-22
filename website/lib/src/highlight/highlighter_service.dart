import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import '../theme/tokens.dart';

/// A language the demos can switch between, with a display label and sample.
class DemoLanguage {
  const DemoLanguage(this.language, this.label, this.filename);

  final CodeLanguage language;
  final String label;
  final String filename;

  String get id => language.id;
}

/// A theme the demos can switch between.
class DemoTheme {
  const DemoTheme(this.theme, this.label);

  final ShikiTheme theme;
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
  //
  // The languages a code block can reference by id (see [languageForId]); the
  // shared highlighter registers exactly this set.
  /// The site-wide default theme for code blocks: the Pierre light/dark pair.
  /// Used when a [CodeBlock]/widget is not given an explicit `theme:`.
  static const ShikiThemeBase defaultTheme = ShikiDualTheme(
    light: PierreThemes.pierreLight,
    dark: PierreThemes.pierreDark,
  );

  static final List<CodeLanguage> _bundledLanguages = [
    CodeLanguages.dart,
    CodeLanguages.typescript,
    CodeLanguages.tsx,
    CodeLanguages.javascript,
    CodeLanguages.python,
    CodeLanguages.rust,
    CodeLanguages.go,
    CodeLanguages.json,
    CodeLanguages.yaml,
    CodeLanguages.html,
    CodeLanguages.css,
    CodeLanguages.shellscript,
    CodeLanguages.markdown,
    CodeLanguages.sql,
  ];

  /// Maps a language id (as passed to a code block) to its bundled
  /// [CodeLanguage]. Every id the site uses is in [_bundledLanguages].
  static final Map<String, CodeLanguage> _languagesById = {
    for (final lang in _bundledLanguages) lang.id: lang,
  };

  /// The bundled [CodeLanguage] registered under [id] (e.g. `'dart'`). The
  /// widgets now take a [CodeLanguage] object, so string-id call sites resolve
  /// through here.
  static CodeLanguage languageForId(String id) => _languagesById[id]!;

  late final ShikiHighlighter _highlighter = ShikiHighlighter()
    ..preload(
      langs: _bundledLanguages,
      themes: [
        ShikiThemes.githubDark,
        ShikiThemes.githubLight,
        ShikiThemes.oneDarkPro,
        ShikiThemes.dracula,
        ShikiThemes.nord,
        ShikiThemes.vitesseDark,
        ShikiThemes.vitesseLight,
        ShikiThemes.vesper,
        PierreThemes.pierreDark,
        PierreThemes.pierreLight,
      ],
    );

  /// The shared highlighter, e.g. for passing straight to a [ShikiCodeView].
  ShikiHighlighter get highlighter => _highlighter;

  final Map<String, Color> _bgCache = {};

  /// Themes offered in the "any VS Code theme" switcher.
  static final List<DemoTheme> demoThemes = [
    DemoTheme(ShikiThemes.githubDark, 'GitHub Dark'),
    DemoTheme(ShikiThemes.oneDarkPro, 'One Dark Pro'),
    DemoTheme(ShikiThemes.dracula, 'Dracula'),
    DemoTheme(ShikiThemes.nord, 'Nord'),
    DemoTheme(ShikiThemes.vesper, 'Vesper'),
    DemoTheme(ShikiThemes.vitesseDark, 'Vitesse Dark'),
    DemoTheme(ShikiThemes.githubLight, 'GitHub Light'),
    DemoTheme(ShikiThemes.vitesseLight, 'Vitesse Light'),
  ];

  /// Languages offered in the "~250 languages" switcher.
  static final List<DemoLanguage> demoLanguages = [
    DemoLanguage(CodeLanguages.dart, 'Dart', 'main.dart'),
    DemoLanguage(CodeLanguages.typescript, 'TypeScript', 'server.ts'),
    DemoLanguage(CodeLanguages.python, 'Python', 'model.py'),
    DemoLanguage(CodeLanguages.rust, 'Rust', 'lib.rs'),
    DemoLanguage(CodeLanguages.go, 'Go', 'main.go'),
  ];

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
    if (theme == ShikiThemes.githubDark.id) return AppColors.dark.background;
    return backgroundOf(theme, fallback);
  }

  // ---- Docs theme gallery -------------------------------------------------
  //
  // A SEPARATE highlighter that loads every bundled theme, so the docs gallery
  // can preview all of them. It's `late final`, so it isn't built until the
  // gallery is first rendered. The shared [_highlighter] above stays lean.

  late final ShikiHighlighter _galleryHighlighter = ShikiHighlighter()
    ..preload(
      // Only Dart is needed: the gallery always previews one Dart sample.
      langs: [CodeLanguages.dart],
      themes: ShikiThemes.all,
    );

  final Map<String, TextSpan> _gallerySpanCache = {};

  /// Every bundled theme, in package order: the source of truth for the docs
  /// gallery's list (so it stays in sync when themes are regenerated).
  List<ShikiTheme> get galleryThemes => ShikiThemes.all;

  /// Highlights [code] in a bundled [theme] via the gallery highlighter.
  TextSpan gallerySpan(
    String code, {
    required ShikiTheme theme,
    double fontSize = 13.5,
  }) {
    final key = '${theme.id} $fontSize $code';
    return _gallerySpanCache.putIfAbsent(key, () {
      return codeToTextSpan(
        _galleryHighlighter,
        code,
        lang: CodeLanguages.dart,
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
