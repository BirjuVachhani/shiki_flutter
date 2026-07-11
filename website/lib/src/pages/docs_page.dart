import 'package:flutter/material.dart';

import '../data/snippets.dart';
import '../data/supported.dart';
import '../theme/tokens.dart';
import '../widgets/code_block.dart';
import '../widgets/section.dart';
import '../widgets/theme_gallery.dart';
import 'docs_content.dart';

/// Metadata for one docs section (used for the sidebar and anchors).
class _SectionMeta {
  const _SectionMeta(this.id, this.title);
  final String id;
  final String title;
}

const _sections = <_SectionMeta>[
  _SectionMeta('introduction', 'Introduction'),
  _SectionMeta('installation', 'Installation'),
  _SectionMeta('quick-start', 'Quick start'),
  _SectionMeta('rendering', 'Rendering code'),
  _SectionMeta('themes', 'Themes'),
  _SectionMeta('languages', 'Languages'),
  _SectionMeta('bundle-size', 'Bundle size'),
  _SectionMeta('shikicodeview', 'The widget'),
  _SectionMeta('custom', 'Custom grammars'),
  _SectionMeta('limitations', 'Limitations'),
];

/// The documentation page: a sticky section sidebar beside a scrolling reading
/// column. On compact widths the sidebar becomes a contents card at the top.
class DocsPage extends StatefulWidget {
  const DocsPage({super.key, this.initialSection});

  /// A section id (e.g. `themes`) to scroll to on first load — set from the
  /// `?section=` query param so other pages can deep-link into the docs.
  final String? initialSection;

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  final ScrollController _controller = ScrollController();
  final List<GlobalKey> _keys =
      List.generate(_sections.length, (_) => GlobalKey());
  int _active = 0;

  static const double _anchorGap = AppLayout.navHeight + 24;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    final target = widget.initialSection;
    if (target != null) {
      final index = _sections.indexWhere((s) => s.id == target);
      if (index != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollTo(index);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = AppLayout.navHeight + 72;
    var active = 0;
    for (var i = 0; i < _keys.length; i++) {
      final ctx = _keys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= threshold) {
        active = i;
      } else {
        break;
      }
    }
    if (active != _active) setState(() => _active = active);
  }

  void _scrollTo(int index) {
    final ctx = _keys[index].currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final dy = box.localToGlobal(Offset.zero).dy;
    final target = (_controller.offset + dy - _anchorGap)
        .clamp(0.0, _controller.position.maxScrollExtent);
    setState(() => _active = index);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return context.isCompact ? _buildCompact(context) : _buildWide(context);
  }

  Widget _buildWide(BuildContext context) {
    // One page-level scroll view so the scrollbar sits on the viewport's right
    // edge and the whole page scrolls from anywhere; the sidebar is pinned to
    // stay in view (CSS `position: sticky` equivalent).
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SelectionArea(
        child: SingleChildScrollView(
          controller: _controller,
          child: Padding(
            padding: const EdgeInsets.only(top: AppLayout.navHeight + 24),
            child: ContentContainer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StickyBox(
                    controller: _controller,
                    child: _Sidebar(active: _active, onTap: _scrollTo),
                  ),
                  const SizedBox(width: 48),
                  Expanded(child: _sectionsColumn(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        controller: _controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppLayout.navHeight + 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _CompactToc(onTap: _scrollTo),
            ),
            _sectionsColumn(context),
          ],
        ),
      ),
    );
  }

  Widget _sectionsColumn(BuildContext context) {
    final compact = context.isCompact;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 0,
        compact ? 8 : 0,
        compact ? 20 : 0,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _sections.length; i++)
            Padding(
              key: _keys[i],
              // diffs.com separates sections with `space-y-8` (32px).
              padding: EdgeInsets.only(top: i == 0 ? 0 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(_sections[i].title),
                  const SizedBox(height: 16),
                  ..._content(_sections[i].id),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.foreground,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        // diffs.com headings use `tracking-tight` (-0.025em ≈ -0.75px @30px).
        letterSpacing: -0.75,
        height: 1.2,
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.active, required this.onTap});

  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 48),
        child: Column(
          // Stretch so the selected pill spans the full rail width (like
          // diffs.com), rather than shrink-wrapping the label.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _sections.length; i++)
              _SidebarItem(
                label: _sections[i].title,
                active: i == active,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pins its [child] to a fixed screen position while [controller] scrolls, by
/// translating it downward by the current scroll offset — the equivalent of
/// CSS `position: sticky` for a short left rail inside a page-level scroll.
class _StickyBox extends StatelessWidget {
  const _StickyBox({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, sticky) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        return Transform.translate(offset: Offset(0, offset), child: sticky);
      },
      child: child,
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = widget.active;
    // diffs.com: selection changes colour + a subtle pill only — never weight.
    // Active = foreground on an accent pill; others muted, brightening on hover.
    final color = active || _hovered
        ? colors.foreground
        : colors.mutedForeground;
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
                : (_hovered
                    ? colors.foreground.withValues(alpha: 0.05)
                    : Colors.transparent),
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

class _CompactToc extends StatelessWidget {
  const _CompactToc({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ON THIS PAGE',
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _sections.length; i++)
                SelectionContainer.disabled(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surfaceInset,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        _sections[i].title,
                        style: TextStyle(
                          color: colors.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Section content ------------------------------------------------------

List<Widget> _content(String id) {
  switch (id) {
    case 'introduction':
      return const [
        DocProse(
          'shiki_flutter is a syntax highlighter for Flutter. It tokenizes '
          'source code with real VS Code TextMate grammars and themes and '
          'renders it as styled `TextSpan`s, so highlighted code looks exactly '
          'like it does in VS Code.',
        ),
        DocProse(
          "It's pure Dart — no WebView, no JavaScript, and no bundled JSON "
          'assets — so it runs everywhere Flutter runs: iOS, Android, web, '
          'macOS, Windows, and Linux.',
        ),
        DocProse(
          '**~250 languages and 65 themes are built in.** You import only the '
          'ones you use, and everything else is tree-shaken out of your app. '
          'Reach for the `ShikiCodeView` widget for the common case, or drop '
          'down to `codeToTextSpan` and raw tokens when you need more control.',
        ),
      ];
    case 'installation':
      return const [
        DocProse('Add shiki_flutter to your `pubspec.yaml`:'),
        CodeBlock(
          code: Snippets.pubspec,
          lang: 'yaml',
          filename: 'pubspec.yaml',
        ),
        DocProse('Or add it from the command line:'),
        CodeBlock(
          code: Snippets.install,
          lang: 'shellscript',
          filename: 'shell',
        ),
        DocProse(
          '**Batteries included:** ~250 languages and ~65 VS Code themes ship '
          'inside the package. You never bundle JSON assets — you import the '
          'ones you use.',
        ),
      ];
    case 'quick-start':
      return const [
        DocProse(
          'Import the specific bundled languages and themes you need, create a '
          'highlighter, and hand it to `ShikiCodeView`:',
        ),
        CodeBlock(
          code: Snippets.quickStart,
          lang: 'dart',
          filename: 'main.dart',
        ),
      ];
    case 'rendering':
      return const [
        DocProse('There are three ways to render tokenized code.'),
        DocH3('As a TextSpan'),
        DocProse(
          'Use `codeToTextSpan` to build an `InlineSpan` for any `Text.rich` or '
          '`RichText`:',
        ),
        CodeBlock(
          code: Snippets.renderTextSpan,
          lang: 'dart',
          filename: 'text_span.dart',
        ),
        DocH3('With the widget'),
        DocProse(
          '`ShikiCodeView` paints the theme background and handles horizontal '
          'scrolling for you:',
        ),
        CodeBlock(
          code: Snippets.renderWidget,
          lang: 'dart',
          filename: 'widget.dart',
        ),
        DocH3('Raw tokens'),
        DocProse(
          'For full control, read the `ThemedToken`s directly. Pass '
          '`includeExplanation: true` in `TokenizeOptions` to also get each '
          "token's TextMate scopes.",
        ),
        CodeBlock(
          code: Snippets.renderTokens,
          lang: 'dart',
          filename: 'tokens.dart',
        ),
      ];
    case 'themes':
      return const [
        DocProse(
          'A theme is a real VS Code / TextMate theme: foreground, background, '
          'and font styles resolve through scope-selector specificity, exactly '
          'like Shiki. There are two ways to get one — pick from the **65 '
          'bundled themes**, or load your own JSON at runtime.',
        ),
        DocH3('Using a bundled theme'),
        DocProse(
          'Import a theme by symbol, pass it to `createHighlighter`, and '
          'reference it by id when you render. Load several and switch per '
          'render:',
        ),
        CodeBlock(
          code: Snippets.themesUsage,
          lang: 'dart',
          filename: 'themes.dart',
        ),
        DocNote(
          'Each theme is its own library, so importing one pulls in only that '
          'theme — the other 64 are tree-shaken away. Import '
          '`themes/all.dart` only for playgrounds that genuinely need every '
          'theme.',
        ),
        DocH3('Bring your own theme'),
        DocProse(
          "Shiki doesn't own the themes — they're plain VS Code theme JSON. So "
          'any theme works: grab one from a VS Code marketplace extension, the '
          'textmate-grammars-themes source, or hand-write your own, and load '
          'it live. Four entry points take a theme and return its id:',
        ),
        DocTable(
          headers: ['Method', 'Accepts', 'Use when'],
          rows: [
            [
              '`loadBundledTheme(t)`',
              '`BundledTheme`',
              'Using a theme that ships with the package.',
            ],
            [
              '`loadThemeFromJson(s)`',
              '`String`',
              'You have raw theme JSON (asset, network, a `.json` file).',
            ],
            [
              '`loadTheme(m)`',
              '`Map<String, dynamic>`',
              'You already decoded the JSON to a map.',
            ],
            [
              '`loadThemeRegistration(r)`',
              '`ThemeRegistration`',
              'You built a theme programmatically.',
            ],
          ],
        ),
        CodeBlock(
          code: Snippets.themesBringYourOwn,
          lang: 'dart',
          filename: 'byo_theme.dart',
        ),
        DocH3('Browse all 65 themes'),
        DocProse(
          'Every bundled theme, tokenizing the same Dart sample live. Search '
          'by name and pick one to preview — the id shown is the exact value '
          'you pass as `theme:`.',
        ),
        ThemeGallery(),
      ];
    case 'languages':
      return const [
        DocProse(
          'Each bundled grammar is its own library exporting a single symbol '
          '(e.g. `dart`, `typescript`, `python`). Import the ones you use and '
          'list them in `createHighlighter`. The value you pass to `lang` is '
          "the language's id (shown in the list below).",
        ),
        DocH3('Embedded languages'),
        DocProse(
          'Grammars that embed others load their dependencies automatically. '
          'Importing `html` also pulls in `css` and `javascript`, so `<style>` '
          'and `<script>` blocks are highlighted:',
        ),
        CodeBlock(
          code: Snippets.embedded,
          lang: 'dart',
          filename: 'embedded.dart',
        ),
        DocProse(
          'Aliases work too — the `shellscript` grammar answers to `bash`, '
          '`sh`, `zsh`, and `shell`.',
        ),
        DocH3('Supported languages'),
        DocProse(
          'shiki_flutter bundles grammars for **253 languages**. Pass any of '
          'these ids as `lang`:',
        ),
        DocLangList(supportedLanguages),
      ];
    case 'bundle-size':
      return const [
        DocProse(
          'Even though the whole catalog ships in the package, only the '
          'languages and themes you actually import end up in your app. Each '
          'grammar and theme is a separate Dart library referenced by symbol, '
          'so the compiler tree-shakes away everything unreferenced.',
        ),
        DocBullets([
          '**Do** import specific entries: `import '
              "'package:shiki_flutter/langs/dart.dart';`.",
          "**Don't** import the `all.dart` barrels unless you truly want every "
              'grammar — they reference everything and defeat tree-shaking.',
        ]),
        DocProse(
          'The barrels exist for tools and playgrounds that genuinely need '
          'everything:',
        ),
        CodeBlock(
          code: Snippets.treeShakeAll,
          lang: 'dart',
          filename: 'everything.dart',
        ),
        DocNote(
          'Measured on a release web build: adding the package with one '
          'language + one theme grows the app download by ~55 KB gzipped '
          '(~180 KB uncompressed), while importing the entire catalog adds '
          '~1.35 MB gzipped (~8.6 MB uncompressed). Everything you never '
          'import is tree-shaken out.',
        ),
      ];
    case 'shikicodeview':
      return const [
        DocProse(
          '`ShikiCodeView` is the quickest way to display highlighted code. '
          'The highlighter must already have the language and theme loaded.',
        ),
        DocTable(
          headers: ['Property', 'Type', 'Description'],
          rows: [
            ['`highlighter`', '`ShikiHighlighter`', 'Loaded highlighter.'],
            ['`code`', '`String`', 'Source to render.'],
            ['`lang`', '`String`', 'Language id, e.g. `dart`.'],
            ['`theme`', '`String`', 'Theme id, e.g. `github-dark`.'],
            ['`textStyle`', '`TextStyle?`', 'Base style; use a monospace font.'],
            ['`padding`', '`EdgeInsetsGeometry`', 'Defaults to `16` all round.'],
            ['`paintBackground`', '`bool`', "Paint the theme's background."],
            ['`textScaler`', '`TextScaler?`', 'Optional text scaling.'],
          ],
        ),
      ];
    case 'custom':
      return const [
        DocProse(
          'Beyond the bundled catalog, you can load any TextMate grammar or VS '
          'Code theme JSON at runtime:',
        ),
        CodeBlock(
          code: Snippets.customGrammar,
          lang: 'dart',
          filename: 'custom.dart',
        ),
      ];
    case 'limitations':
      return const [
        DocProse('A couple of things worth knowing:'),
        DocBullets([
          'A few very rare grammar constructs are unsupported. When one is '
              'hit it is skipped gracefully — highlighting keeps going rather '
              'than failing, so at worst a small span is left uncolored.',
          'Unicode property classes (`\\p{...}`) use pragmatic approximations '
              '(ASCII is exact); full Unicode category tables are not bundled, '
              'which can affect a handful of non-Latin edge cases.',
        ]),
      ];
    default:
      return const [];
  }
}
