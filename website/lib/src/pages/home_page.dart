import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

import '../data/links.dart';
import '../data/snippets.dart';
import '../highlight/highlighter_service.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/code_block.dart';
import '../widgets/footer.dart';
import '../widgets/lang_switcher_demo.dart';
import '../widgets/pill.dart';
import '../widgets/section.dart';
import '../widgets/theme_switcher_demo.dart';

/// The landing page: hero, language strip, feature sections, CTA, footer.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _Hero(),
            _ThemesFeature(),
            _LanguagesFeature(),
            _TreeShakeFeature(),
            _WidgetFeature(),
            _EngineFeature(),
            _CtaBand(),
            Footer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  late final TapGestureRecognizer _shikiTap =
      TapGestureRecognizer()..onTap = () => Links.open(Links.shiki);

  @override
  void dispose() {
    _shikiTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final compact = context.isCompact;

    final headlineSize = compact ? 36.0 : 60.0;

    Widget headline = Text(
      'A syntax highlighter for Flutter.',
      maxLines: compact ? null : 1,
      softWrap: compact,
      style: TextStyle(
        color: colors.foreground,
        fontSize: headlineSize,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: headlineSize * -0.025,
      ),
    );
    if (!compact) {
      // Keep the headline on a single line on wide viewports, scaling it down
      // only if the window is too narrow to fit it at full size.
      headline = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: headline,
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: AppLayout.navHeight + (compact ? 48 : 80),
        bottom: compact ? 40 : 80,
      ),
      child: ContentContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroMark(),
            const SizedBox(height: 20),
            headline,
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: compact ? 16 : 20,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'shiki_flutter',
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        color: colors.foreground,
                        fontSize: compact ? 14.5 : 18,
                      ),
                    ),
                    const TextSpan(text: ' is a pure-Dart port of '),
                    TextSpan(
                      text: 'Shiki',
                      style: TextStyle(
                        color: colors.foreground,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.mutedForeground,
                        decorationThickness: 1,
                      ),
                      recognizer: _shikiTap,
                    ),
                    const TextSpan(
                      text: '. It brings the exact VS Code grammars and themes '
                          'to Flutter — tokenized token-for-token and rendered '
                          'as native TextSpans, with no WebView, JavaScript, or '
                          'asset bundles.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const InstallCommand(command: Snippets.install),
                AppButton(
                  label: 'Documentation',
                  icon: Icons.menu_book_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go('/docs'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Currently v0.2.0',
              style: TextStyle(color: colors.mutedForeground, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.foreground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.palette_rounded, size: 27, color: colors.background),
    );
  }
}

/// Shared layout for a feature section: heading then content.
class _FeatureBlock extends StatelessWidget {
  const _FeatureBlock({
    required this.title,
    required this.subtitle,
    required this.child,
    this.subtitleLink,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final (String label, String url)? subtitleLink;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 28 : 44),
      child: ContentContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              title: title,
              subtitle: subtitle,
              subtitleLink: subtitleLink,
            ),
            SizedBox(height: compact ? 28 : 40),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThemesFeature extends StatelessWidget {
  const _ThemesFeature();

  @override
  Widget build(BuildContext context) {
    return _FeatureBlock(
      title: 'Every theme you already love.',
      subtitle:
          'Load any VS Code or TextMate theme. Foreground, background and font '
          'styles resolve through scope-selector specificity — exactly like '
          'Shiki. Flip through a few below, or browse all 65.',
      subtitleLink: ('Shiki', Links.shiki),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThemeSwitcherDemo(),
          const SizedBox(height: 24),
          AppButton(
            label: 'View all 65 themes',
            variant: AppButtonVariant.secondary,
            trailingIcon: Icons.arrow_forward,
            onPressed: () => context.go('/docs?section=themes'),
          ),
        ],
      ),
    );
  }
}

class _LanguagesFeature extends StatelessWidget {
  const _LanguagesFeature();

  @override
  Widget build(BuildContext context) {
    return const _FeatureBlock(
      title: 'One tokenizer, every grammar.',
      subtitle:
          'The same faithful TextMate engine drives every language — rules, '
          'repositories, injections, and embedded grammars included.',
      child: LangSwitcherDemo(),
    );
  }
}

class _TreeShakeFeature extends StatelessWidget {
  const _TreeShakeFeature();

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final code = const CodeBlock(
      code: Snippets.treeShakeGood,
      lang: 'dart',
      filename: 'import.dart',
    );
    final bars = const _SizeComparison();

    return _FeatureBlock(
      title: 'Ship the whole catalog. Bundle only what you use.',
      subtitle:
          'Grammars and themes are separate libraries referenced by symbol, so '
          'the Dart compiler tree-shakes away everything you never import.',
      child: compact
          ? Column(children: [code, const SizedBox(height: 28), bars])
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: code),
                  const SizedBox(width: 28),
                  Expanded(child: bars),
                ],
              ),
            ),
    );
  }
}

class _SizeComparison extends StatelessWidget {
  const _SizeComparison();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Size added to your app',
            style: TextStyle(
              color: colors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _SizeBar(
            label: '1 language + 1 theme',
            value: '~55 KB',
            fraction: 0.055 / 1.35,
            color: colors.accent,
          ),
          const SizedBox(height: 16),
          _SizeBar(
            label: 'Entire catalog imported',
            value: '~1.35 MB',
            fraction: 1,
            color: colors.mutedForeground,
          ),
          const SizedBox(height: 18),
          Text(
            "Gzipped download the package adds (~180 KB–8.6 MB uncompressed). "
            "Everything you don't import is tree-shaken away.",
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeBar extends StatelessWidget {
  const _SizeBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.foreground, fontSize: 13.5),
            ),
            Text(
              value,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 13.5,
                fontFamily: AppFonts.mono,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: colors.surfaceInset,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _WidgetFeature extends StatelessWidget {
  const _WidgetFeature();

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final code = const CodeBlock(
      code: Snippets.renderWidget,
      lang: 'dart',
      filename: 'code_card.dart',
    );
    final preview = const _WidgetPreview();

    return _FeatureBlock(
      title: 'From source to screen in one widget.',
      subtitle:
          'Hand ShikiCodeView your code, a language and a theme. It paints the '
          'theme background and renders selectable, highlighted text.',
      child: compact
          ? Column(children: [code, const SizedBox(height: 24), preview])
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: code),
                  const SizedBox(width: 28),
                  Expanded(child: preview),
                ],
              ),
            ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeId =
        HighlighterService.themeForBrightness(Theme.of(context).brightness);
    // Fill the whole card with the theme background and let ShikiCodeView paint
    // only the text — otherwise its background spans just the text width and
    // leaves a mismatched strip on the right.
    final bg = HighlighterService.instance.displayBackground(
      themeId,
      colors.surface,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: ShikiCodeView(
        highlighter: HighlighterService.instance.highlighter,
        code: Snippets.widgetSample.trim(),
        lang: 'dart',
        theme: themeId,
        paintBackground: false,
        textStyle: const TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 13.5,
          height: 1.55,
        ),
        padding: const EdgeInsets.all(20),
      ),
    );
  }
}

class _EngineFeature extends StatelessWidget {
  const _EngineFeature();

  static const _platforms = [
    ('iOS', Icons.phone_iphone_rounded),
    ('Android', Icons.android_rounded),
    ('Web', Icons.language_rounded),
    ('macOS', Icons.laptop_mac_rounded),
    ('Windows', Icons.desktop_windows_rounded),
    ('Linux', Icons.computer_rounded),
  ];

  static const _features = [
    'Capture-group offsets',
    r'\A / \G / \z / \Z anchors',
    'Look-around & atomic groups',
    'Possessive quantifiers',
    'POSIX & nested char classes',
    r'\p{…} Unicode properties',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _FeatureBlock(
      title: 'A regex engine built from scratch.',
      subtitle:
          'Shiki leans on Oniguruma via WASM. shiki_flutter ships its own '
          'Oniguruma-subset backtracking engine in Dart — so it runs anywhere '
          'Flutter runs, with no native code.',
      subtitleLink: ('Shiki', Links.shiki),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, icon) in _platforms)
                AppBadge(label, icon: icon),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 28,
            runSpacing: 14,
            children: [
              for (final f in _features)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 18, color: colors.accent),
                    const SizedBox(width: 10),
                    Text(
                      f,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 14.5,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CtaBand extends StatelessWidget {
  const _CtaBand();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final compact = context.isCompact;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 56 : 104),
      child: ContentContainer(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 28 : 64,
            vertical: compact ? 44 : 72,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Text(
                'Highlight your first snippet in minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: compact ? 26 : 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppButton(
                    label: 'Read the docs',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () => context.go('/docs'),
                  ),
                  AppButton(
                    label: 'pub.dev',
                    icon: Icons.open_in_new_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Links.open(Links.pubDev),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
