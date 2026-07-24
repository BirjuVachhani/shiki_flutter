import 'package:flutter/material.dart';

import '../data/docs_sections.dart';
import '../data/snippets.dart';
import '../theme/tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/code_block.dart';
import '../widgets/docs_md_actions.dart';
import '../widgets/footer.dart';
import '../widgets/language_grid.dart';
import '../widgets/nav_sheet.dart';
import '../widgets/section.dart';
import '../widgets/theme_gallery.dart';
import 'docs_content.dart';

/// Height of the breadcrumb bar pinned under the nav on compact layouts, where
/// the section rail collapses into a popup. Sections scroll behind it, so the
/// scroll-spy and scroll-to math offset by both the nav and this bar.
const double _kCompactBarHeight = 52;

/// The documentation page: a sticky section sidebar beside a scrolling reading
/// column. On compact widths the sidebar becomes a contents card at the top.
class DocsPage extends StatefulWidget {
  const DocsPage({super.key, this.initialSection});

  /// A section id (e.g. `themes`) to scroll to on first load - set from the
  /// `?section=` query param so other pages can deep-link into the docs.
  final String? initialSection;

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> implements DocsSectionNavigator {
  final ScrollController _controller = ScrollController();
  final List<GlobalKey> _keys = List.generate(
    docsSections.length,
    (_) => GlobalKey(),
  );
  int _active = 0;

  /// The app-wide nav popup bridge; we register with it so its section list and
  /// scroll target come from this page whenever the popup is opened on docs.
  NavSheetController? _navSheet;

  static const double _anchorGap = AppLayout.navHeight + 24;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    final target = widget.initialSection;
    if (target != null) {
      final index = docsSections.indexWhere((s) => s.id == target);
      if (index != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollTo(index);
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navSheet = NavSheetScope.of(context)..docs = this;
  }

  @override
  void dispose() {
    if (_navSheet?.docs == this) _navSheet?.docs = null;
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  // DocsSectionNavigator: lets the shared nav popup read the active section and
  // scroll here, regardless of which control (nav bar or breadcrumb) opened it.
  @override
  int get activeSection => _active;

  @override
  void scrollToSection(int index) => _scrollTo(index);

  void _onScroll() {
    // On compact layouts the section headings scroll behind the pinned nav and
    // breadcrumb bar, so a heading counts as active once it passes below both.
    final threshold = context.isCompact
        ? AppLayout.navHeight + _kCompactBarHeight + 24
        : AppLayout.navHeight + 72;
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
    // Compact stacks the nav over the pinned breadcrumb bar; land the heading
    // just below both so it isn't hidden behind them.
    final gap = context.isCompact
        ? AppLayout.navHeight + _kCompactBarHeight + 16
        : _anchorGap;
    final target = (_controller.offset + dy - gap).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    setState(() => _active = index);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Opens the app-wide navigation popup (site links + this page's section
  /// list). The popup reads the active section and scrolls via this page's
  /// [DocsSectionNavigator] registration, so nothing is returned here.
  void _openNav() => showAppNavSheet(context, currentRoute: '/docs');

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
          child: Column(
            children: [
              Padding(
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
              const SimpleFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    // The section rail collapses into a popup: a breadcrumb bar pinned under the
    // nav opens it, and the reading column scrolls beneath both.
    return Column(
      children: [
        const SizedBox(height: AppLayout.navHeight),
        _CompactDocsBar(
          sectionTitle: docsSections[_active].title,
          onOpen: _openNav,
        ),
        Expanded(
          child: SelectionArea(
            child: SingleChildScrollView(
              controller: _controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionsColumn(context),
                  const SimpleFooter(),
                ],
              ),
            ),
          ),
        ),
      ],
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
          // Copy the whole page as Markdown (for feeding to an LLM) / download
          // it. Sits above the first section; web-only, and self-contained
          // (renders nothing, no spacing, off web). See web/docs.md, which this
          // page is kept in sync with.
          const DocsMarkdownActions(),
          for (var i = 0; i < docsSections.length; i++)
            Padding(
              key: _keys[i],
              // Sections are separated with `space-y-8` (32px).
              padding: EdgeInsets.only(top: i == 0 ? 0 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(docsSections[i].title),
                  const SizedBox(height: 16),
                  ..._content(context, docsSections[i].id),
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
        // Headings use `tracking-tight` (-0.025em ≈ -0.75px @30px).
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
    // Walk the groups in order, carrying a running index into the flattened
    // section list so active-state and taps map back to the right anchor.
    final children = <Widget>[];
    var index = 0;
    for (var gi = 0; gi < docsGroups.length; gi++) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: gi == 0 ? 0 : 22, bottom: 8, left: 12),
          child: DocsGroupLabel(docsGroups[gi].title),
        ),
      );
      for (final section in docsGroups[gi].sections) {
        final i = index++;
        children.add(
          DocsSectionTile(
            label: section.title,
            active: i == active,
            onTap: () => onTap(i),
          ),
        );
      }
    }
    return SizedBox(
      width: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 48),
        child: Column(
          // Stretch so the selected pill spans the full rail width,
          // rather than shrink-wrapping the label.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Pins its [child] to a fixed screen position while [controller] scrolls, by
/// translating it downward by the current scroll offset - the equivalent of
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
        // Guard on exactly one attached position: while resizing across the
        // compact/wide breakpoint the old and new scroll views can both be
        // attached to this controller for a frame, and `offset` throws when
        // more than one position exists.
        final offset = controller.positions.length == 1
            ? controller.offset
            : 0.0;
        return Transform.translate(offset: Offset(0, offset), child: sticky);
      },
      child: child,
    );
  }
}

/// The compact trigger: a breadcrumb bar pinned under the nav that shows where
/// you are (`Docs › <section>`) and opens the navigation popup on tap, styled
/// as a compact mobile docs header.
class _CompactDocsBar extends StatelessWidget {
  const _CompactDocsBar({required this.sectionTitle, required this.onOpen});

  final String sectionTitle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: Container(
            height: _kCompactBarHeight,
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: ContentContainer(
              child: Row(
                children: [
                  Text(
                    'Docs',
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // The icon set has no right chevron; a quarter-turn of the
                  // dropdown chevron points it at the section title.
                  RotatedBox(
                    quarterTurns: 3,
                    child: AppIcon(
                      DiffIcon.chevronDown,
                      size: 13,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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

// ---- Section content ------------------------------------------------------

List<Widget> _content(BuildContext context, String id) {
  switch (id) {
    case 'introduction':
      return [
        const DocProse(
          'shiki_flutter is a syntax highlighter for Flutter. It tokenizes '
          'source code with real VS Code TextMate grammars and Shiki themes '
          'and renders it as styled `TextSpan`s, so highlighted code looks '
          'exactly '
          'like it does in VS Code.',
        ),
        const DocProse(
          "Out of the box, it's pure Dart and runs everywhere Flutter runs: **iOS, Android, web, "
          'macOS, Windows, and Linux**. On native and desktop, highlighting runs '
          '**off the UI thread by default**, so the one-time grammar compile never '
          'freezes a frame (see **Async highlighting**).',
        ),
        // Wrap (not Row) so the two fixed-width stat cards stack instead of
        // overflowing once the reading column is narrower than both side by side.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              width: 200,
              padding: .symmetric(horizontal: 20, vertical: 16),
              decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedSuperellipseBorder(borderRadius: .circular(16)),
              ),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    '~250',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: .w600,
                      height: 1,
                    ),
                  ),
                  Text('Supported Languages'),
                ],
              ),
            ),
            Container(
              width: 200,
              padding: .symmetric(horizontal: 20, vertical: 16),
              decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedSuperellipseBorder(borderRadius: .circular(16)),
              ),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    '65+',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: .w600,
                      height: 1,
                    ),
                  ),
                  Text('Built-in Themes'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const DocProse(
          'From all the themes and languages, you import only the '
          'ones you use, and everything else is **tree-shaken** out of your app. '
          'Reach for the `ShikiCodeView` widget for the common case, '
          '`ShikiCodeListView` for large files, or drop down to '
          '`codeToTextSpan` and raw tokens when you need more control.',
        ),
      ];
    case 'features':
      return const [
        DocProse(
          'Everything shiki_flutter gives you at a glance. Each item links to '
          'the section that covers it in full.',
        ),
        DocBullets([
          '**Real Oniguruma engine.** A from-scratch, pure-Dart '
              'Oniguruma-subset regex engine by default (no native build, no '
              'WebAssembly), with optional native (`dart:ffi`) and WebAssembly '
              'backends when you want more speed. See **Engines**.',
          '**Injections and embedded languages.** A faithful port of '
              '`vscode-textmate` with begin/end/while rules, captures, '
              'injections, and cross-language embedding, so `<style>` and '
              '`<script>` in HTML, fenced code in Markdown, and the like all '
              'highlight. See **Languages**.',
          '**~250 languages and 75 themes.** The 65-theme Shiki catalog plus '
              'the 10 opt-in Pierre themes ship in the package; you import only '
              'the ones you use. See **Themes** and **Languages**.',
          '**Golden-tested VS Code parity.** Token output is verified against '
              'real Shiki output token-for-token, so the colors match VS Code '
              'exactly.',
          '**Off-main-thread async.** A background isolate on native (on by '
              'default) and an optional Web Worker on web, plus an LRU token '
              'cache and `preload` / `warmAsync` pre-warming, so the UI never '
              'freezes on the one-time grammar compile. See **Async '
              'highlighting** and **Pre-warming**.',
          '**Virtualized rendering for large files.** `ShikiCodeListView` lays '
              'out only the lines on screen, staying smooth on very large '
              'files. See **Large files**.',
          '**Adaptive light/dark themes.** A `ShikiDualTheme` pair follows the '
              "app's brightness and re-highlights when it toggles. See "
              '**Themes**.',
          '**Tree-shakeable bundling.** Every grammar and theme is a Dart '
              'library referenced by symbol (no Flutter assets), so everything '
              "you don't import is dropped from your build. See **Bundle "
              'size**.',
          '**Runtime custom grammars/themes.** Load any TextMate '
              "grammar or theme JSON at runtime; it's replicated to the async "
              'worker so the sync and async paths resolve identically. See '
              '**Custom grammars** and **Custom themes**.',
          '**Wide-gamut and colorblind-friendly themes.** The bundled Pierre '
              'themes include `display-p3` wide-gamut variants plus '
              'protanopia/deuteranopia and tritanopia sets. See **Extra '
              'themes**.',
        ]),
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
      ];
    case 'quick-start':
      return const [
        DocProse(
          'Reference the specific bundled languages and themes you need and '
          'pass them to `ShikiCodeView`. A `highlighter:` is optional (widgets '
          'fall back to a shared default), and an app-wide default theme set at '
          '`ShikiHighlighter.config.defaultTheme` lets you omit `theme:` as '
          'well:',
        ),
        CodeBlock(
          code: Snippets.quickStart,
          lang: 'dart',
          filename: 'main.dart',
        ),
      ];
    case 'rendering':
      return const [
        DocProse(
          'There are three ways to render tokenized code. The calls below are '
          'synchronous; for the non-blocking variants that keep the UI thread '
          'free, see **Async highlighting**. For very large files, see **Large '
          'files** for a lazily rendered, line-based option.',
        ),
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
          'A theme is a real TextMate theme: foreground, background, '
          'and font styles resolve through scope-selector specificity, exactly '
          'like Shiki. There are two ways to get one: pick from the **65 '
          'bundled themes**, or load your own JSON at runtime.',
        ),
        DocH3('Using a bundled theme'),
        DocProse(
          'Reference a bundled theme via `ShikiThemes` and pass it where you '
          'render; the highlighter loads it on demand. Load several and switch '
          'between them per render:',
        ),
        CodeBlock(
          code: Snippets.themesUsage,
          lang: 'dart',
          filename: 'themes.dart',
        ),
        DocNote(
          'Referencing a theme like `ShikiThemes.oneDarkPro` pulls in only that '
          'theme; the other 64 are tree-shaken away. Use `ShikiThemes.all` only '
          'for playgrounds that genuinely need every theme.',
        ),
        DocH3('Light and dark'),
        DocProse(
          'The widgets take a `ShikiThemeBase`: either a single `ShikiTheme`, '
          'or a `ShikiDualTheme` light/dark pair that follows the ambient '
          'brightness. (`ShikiThemeBase.dual(light:, dark:)` is an equivalent '
          '`const` factory.)',
        ),
        CodeBlock(
          code: Snippets.themesLightDark,
          lang: 'dart',
          filename: 'light_dark.dart',
        ),
        DocProse(
          'Set a **default** once and omit `theme:` on individual widgets. This '
          'is the natural home for a light/dark pair, so every code block '
          'follows the app:',
        ),
        CodeBlock(
          code: Snippets.defaultTheme,
          lang: 'dart',
          filename: 'default_theme.dart',
        ),
        DocH3('Browse all 75 themes'),
        DocProse(
          'Every bundled theme, tokenizing the same Dart sample live: all 75, '
          'the 65 Shiki themes plus the 10 opt-in Pierre themes. Search by name '
          'and pick one to preview. Each id identifies a theme; reference the '
          'matching `ShikiThemes.<name>` object (e.g. the id `one-dark-pro` is '
          '`ShikiThemes.oneDarkPro`), or `PierreThemes.<name>` for the Pierre '
          'set.',
        ),
        ThemeGallery(),
      ];
    case 'extra-themes':
      return const [
        DocProse(
          'Alongside the bundled Shiki themes, shiki_flutter ships the 10 '
          'custom **Pierre** themes built by Pierre Computer Company, the same '
          'set this site uses for its own code blocks. The collection spans '
          'light and dark, plus soft, vibrant, and color-blind-friendly '
          'variants:',
        ),
        DocBullets([
          '`pierre-dark` and `pierre-light`: the defaults.',
          '`pierre-dark-soft` and `pierre-light-soft`: gentler, lower '
              'contrast.',
          '`pierre-dark-vibrant` and `pierre-light-vibrant`: wide-gamut '
              '`display-p3` colors on supported displays.',
          '`pierre-dark-protanopia-deuteranopia` and '
              '`pierre-light-protanopia-deuteranopia`: tuned for red-green '
              'color blindness.',
          '`pierre-dark-tritanopia` and `pierre-light-tritanopia`: tuned for '
              'blue-yellow color blindness.',
        ]),
        DocProse(
          'They live under `pierre_themes/` and behave like any other bundled '
          "theme. Import one (or the whole set) and pass it to a widget's "
          '`theme:` (or set it as the default), like any bundled theme:',
        ),
        CodeBlock(
          code: Snippets.extraThemes,
          lang: 'dart',
          filename: 'pierre_themes.dart',
        ),
        DocNote(
          'These 10 round out the count to 75, but live in a separate, opt-in '
          '`PierreThemes` facade (not `ShikiThemes.all`), so they tree-shake '
          'independently: they add nothing to your build unless you reference '
          'them. The Pierre themes are MIT-licensed, © The Pierre Computer '
          'Company.',
        ),
      ];
    case 'custom-themes':
      return const [
        DocProse(
          'Themes are plain TextMate theme JSON, so any theme works: grab one '
          'from a VS Code marketplace extension, the textmate-grammars-themes '
          'source, or hand-write your own. Wrap the raw JSON in a `ShikiTheme` '
          'and pass it where you render, exactly like a bundled theme; the '
          'highlighter loads it on demand.',
        ),
        CodeBlock(
          code: Snippets.themesBringYourOwn,
          lang: 'dart',
          filename: 'byo_theme.dart',
        ),
      ];
    case 'languages':
      return const [
        DocProse(
          'Each bundled grammar is its own library, referenced via the '
          '`CodeLanguages` facade (e.g. `CodeLanguages.dart`, '
          '`CodeLanguages.python`); the highlighter loads them on demand and the '
          "rest tree-shake away. The id shown in the list below is each "
          "language's `.id`.",
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
          'Aliases work too: the `shellscript` grammar answers to `bash`, '
          '`sh`, `zsh`, and `shell`.',
        ),
        DocH3('Supported languages'),
        DocProse(
          'shiki_flutter bundles grammars for **253 languages**. Pass any of '
          'these ids as `lang`:',
        ),
        LanguageGrid(),
      ];
    case 'async':
      return const [
        DocProse(
          'Highlighting a file means compiling its grammar and running the '
          'regex engine over every line. The first time, that one-time compile '
          'can take long enough to drop a frame. Async highlighting moves that '
          'work off the UI thread so the app never freezes.',
        ),
        DocProse(
          'On native and desktop it is **on by default** (`asyncIO: true`). '
          '`ShikiCodeView` and `ShikiCodeListView` show your code immediately '
          "in the theme's base color, then swap in the fully highlighted result "
          'once the background isolate finishes. Results are cached (LRU) per '
          '`(code, lang, theme)`, so later rebuilds are instant and never flash '
          'a placeholder.',
        ),
        DocNote(
          'Web has no isolates, so async there is opt-in and runs in a browser '
          'Web Worker you install once. See **Web setup**. Everything below '
          'works the same on web once that worker is enabled.',
        ),
        DocH3('In the widgets'),
        DocProse(
          'Both view widgets take an optional `async:` flag that overrides the '
          'global default for that one widget. Leave it unset to follow the '
          'platform default (on for IO, off for web):',
        ),
        CodeBlock(
          code: Snippets.asyncWidget,
          lang: 'dart',
          filename: 'async_widget.dart',
        ),
        DocH3('Imperatively'),
        DocProse(
          'For raw tokens, `codeToTokensAsync` mirrors `codeToTokens` but returns '
          'a `Future`, tokenizing off the current isolate and caching the result. '
          'Identical in-flight requests are coalesced:',
        ),
        CodeBlock(
          code: Snippets.asyncTokens,
          lang: 'dart',
          filename: 'async_tokens.dart',
        ),
        DocProse(
          'Call `highlighter.dispose()` when a highlighter is no longer needed '
          'to tear down its background worker and clear the token cache. The '
          'highlighter still works synchronously afterward; a later async call '
          'spawns a fresh worker.',
        ),
      ];
    case 'engines':
      return const [
        DocProse(
          'Tokenization runs through a pluggable regex engine, chosen per '
          'platform. **The defaults are pure Dart**, so there is nothing to '
          'install: the embedded engine on web, the Oniguruma-port engine on '
          'native / VM. Every engine produces identical tokens (verified against '
          'golden Shiki output); they differ only in speed and setup.',
        ),
        DocTable(
          headers: ['Platform', 'Off-thread async', 'Default engine'],
          rows: [
            ['Android / iOS', 'Background isolate', 'Dart port'],
            ['macOS / Windows / Linux', 'Background isolate', 'Dart port'],
            ['Web', 'Web Worker (opt-in)', 'Embedded'],
          ],
        ),
        DocH3('The three engines'),
        DocTable(
          headers: ['Engine', 'Package', 'When to use'],
          rows: [
            [
              '`ShikiHighlighterEmbeddedEngine`',
              '`shiki_flutter` (built in)',
              '**Default on web.** Pure-Dart Oniguruma-subset engine with a '
                  'native-`RegExp` fast path. Fastest on web, zero setup.',
            ],
            [
              '`ShikiHighlighterDartEngine`',
              '`shiki_flutter_dart_engine`',
              '**Default on IO.** A faithful pure-Dart Oniguruma port with full '
                  'parity and no native build, so it runs everywhere.',
            ],
            [
              '`ShikiHighlighterNativeEngine`',
              '`shiki_flutter_native_engine`',
              '**Fastest on IO** (~2.4x the Dart port) via `dart:ffi`; full '
                  'parity. Best for large files or heavy re-highlighting.',
            ],
          ],
        ),
        DocH3('Switching engine'),
        DocProse(
          'For the best native performance, add `shiki_flutter_native_engine` and '
          'point IO at it in `main` (the native library builds automatically on '
          'first run). Guard with `kIsWeb` so the web build keeps the embedded '
          'engine, which is faster there:',
        ),
        CodeBlock(
          code: Snippets.engineNative,
          lang: 'dart',
          filename: 'main.dart',
        ),
        DocProse('Or override the engine for a single highlighter:'),
        CodeBlock(
          code: Snippets.enginePerHighlighter,
          lang: 'dart',
          filename: 'per_highlighter.dart',
        ),
        DocNote(
          'The native engine also runs on web as WebAssembly, but the embedded '
          'engine is ~2x faster there, so prefer embedded on web unless you '
          'specifically want the real Oniguruma engine everywhere.',
        ),
      ];
    case 'web':
      return const [
        DocProse(
          'The default web path needs no setup: the embedded pure-Dart engine '
          'runs on the main thread with no WebAssembly and no worker. That is '
          'fast enough for typical files. Two things are web-specific: moving '
          'the one-time compile off the main thread, and the release build.',
        ),
        DocH3('Off the main thread'),
        DocProse(
          'Web has no isolates, so `asyncWeb` is **off by default**. To move the '
          'cold grammar compile off the UI thread (worth it for large '
          'documents), install the prebuilt Web Worker once, then turn '
          '`asyncWeb` on. The worker is grammar-free (~53 KB gzipped) and '
          'receives your grammars and themes at runtime, so the same prebuilt '
          'script serves any app.',
        ),
        CodeBlock(
          code: Snippets.webInstall,
          lang: 'shellscript',
          filename: 'shell',
        ),
        CodeBlock(
          code: Snippets.webAsyncEnable,
          lang: 'dart',
          filename: 'main.dart',
        ),
        DocProse(
          'The default install command installs the worker for the embedded '
          'engine. If you set `webEngine` to another engine, install its '
          'matching worker with a flag:',
        ),
        DocTable(
          headers: ['Web engine', 'Install command'],
          rows: [
            [
              '`ShikiHighlighterEmbeddedEngine` (default)',
              '`dart run shiki_flutter:install`',
            ],
            [
              '`ShikiHighlighterDartEngine`',
              '`dart run shiki_flutter:install --dart`',
            ],
            [
              '`ShikiHighlighterNativeEngine`',
              '`dart run shiki_flutter:install --native`',
            ],
          ],
        ),
        DocNote(
          'If the worker is not installed (or a strict CSP blocks it), web async '
          'transparently falls back to inline tokenization, so nothing breaks. '
          'Re-run the install command after upgrading shiki_flutter to refresh '
          'the worker.',
        ),
        DocH3('Building for the web'),
        DocProse(
          'The only shiki_flutter-specific web step is installing the worker. '
          'Everything else is a standard Flutter web build; the optional '
          '`--wasm` flag opts into the WasmGC runtime:',
        ),
        CodeBlock(
          code: Snippets.webBuild,
          lang: 'shellscript',
          filename: 'shell',
        ),
      ];
    case 'configuration':
      return const [
        DocProse(
          'Engine and async defaults live in a single `ShikiHighlighterConfig`, '
          'split by platform so IO and web are configured independently. Set it '
          'once (e.g. in `main`) via `ShikiHighlighter.config`, overriding only '
          'the fields you need with `copyWith`:',
        ),
        CodeBlock(
          code: Snippets.configExample,
          lang: 'dart',
          filename: 'main.dart',
        ),
        DocTable(
          headers: ['Field', 'Type', 'Default', 'What it does'],
          rows: [
            [
              '`ioEngine`',
              '`ShikiHighlighterEngine`',
              '`ShikiHighlighterDartEngine`',
              'Engine used on native / VM (IO).',
            ],
            [
              '`webEngine`',
              '`ShikiHighlighterEngine`',
              '`ShikiHighlighterEmbeddedEngine`',
              'Engine used on web.',
            ],
            [
              '`asyncIO`',
              '`bool`',
              '`true`',
              'Highlight off the UI thread on IO (background isolate).',
            ],
            [
              '`asyncWeb`',
              '`bool`',
              '`false`',
              'Highlight off the UI thread on web (Web Worker; opt-in).',
            ],
            [
              '`defaultTheme`',
              '`ShikiThemeBase?`',
              '`null`',
              'Theme(s) the widgets use when `theme:` is omitted: a single '
                  'theme or a light/dark pair.',
            ],
            [
              '`defaultHighlighter`',
              '`ShikiHighlighter?`',
              '`null`',
              'The shared highlighter the widgets use when no `highlighter:` is '
                  'passed. When null, a lazily-created shared instance is used.',
            ],
          ],
        ),
        DocProse(
          'Two narrower overrides sit on top of the global config: '
          '`ShikiHighlighter(engine: ...)` sets the engine for a single '
          "highlighter, and a widget's `async:` argument sets async for a single "
          'widget.',
        ),
      ];
    case 'best-practices':
      return const [
        DocProse(
          'The pure-Dart defaults work everywhere with zero setup, so none of '
          'this is required. These are the settings we recommend for a '
          'production app: a little startup configuration buys the fastest, '
          'smoothest rendering. Each practice links to its full section.',
        ),
        DocBullets([
          '**Pre-warm at startup.** Build one shared highlighter, set it as '
              '`config.defaultHighlighter`, and '
              '`await highlighter.preload(..., warmAsync: true)` before '
              '`runApp`, so the first render pays no parse, isolate-spawn, or '
              'grammar-build cost. See **Pre-warming**.',
          '**Use a monospace font with tabular figures.** A fixed-width font '
              'keeps columns aligned; tabular figures keep every digit the same '
              'width, so line numbers and the gutter never jitter as content '
              "scrolls. Pass it through the widget's `textStyle:`.",
          '**Reference only the languages and themes you use.** Name them '
              'explicitly (e.g. `CodeLanguages.dart`, `ShikiThemes.githubDark`) '
              'in `preload` or the config, never the `.all` lists, so the '
              'compiler tree-shakes the rest out of your build. See '
              '**Bundle size**.',
          '**Install the Web Worker.** On web, run '
              '`dart run shiki_flutter:install` and set `asyncWeb: true` to move '
              'the one-time grammar compile off the main thread. Without it, web '
              'async falls back to inline, so nothing breaks. See **Web setup**.',
          '**Match the engine and async to each platform** (table below) for '
              'the best throughput and a UI thread that never blocks.',
        ]),
        DocTable(
          headers: ['Platform', 'Engine', 'Async', 'Why'],
          rows: [
            [
              'IO (mobile / desktop)',
              '`ShikiHighlighterNativeEngine` (optional)',
              '`asyncIO: true` (default)',
              'The native engine is ~2.4x faster; async keeps its one-time '
                  'compile off the UI thread. The pure-Dart default is the '
                  'zero-setup fallback.',
            ],
            [
              'Web',
              '`ShikiHighlighterEmbeddedEngine` (default)',
              '`asyncWeb: true` + installed worker',
              'The embedded engine is the fastest on web; the worker moves the '
                  'compile off the main thread (web has no isolates).',
            ],
          ],
        ),
        DocProse(
          'Putting it together, a production `main` sets the engine and async '
          'per platform, registers a shared pre-warmed highlighter and a '
          'default theme, then awaits the warm-up:',
        ),
        CodeBlock(
          code: Snippets.recommendedSetup,
          lang: 'dart',
          filename: 'main.dart',
        ),
        DocProse(
          'For the tabular-figures tip, pass a monospace font with the '
          '`tabularFigures` feature through the widget:',
        ),
        CodeBlock(code: Snippets.tabularFigures, lang: 'dart'),
        DocNote(
          'Start with just pre-warming and tree-shaking, the two that help '
          'every app, then add the native engine and Web Worker if you render '
          'large files or want to move the last of the compile off the main '
          'thread.',
        ),
      ];
    case 'pre-warming':
      return const [
        DocProse(
          'The first time you highlight with a given grammar, the highlighter '
          'pays a one-time cost: it decodes the grammar JSON, builds its model, '
          'then lazily compiles the TextMate regexes as tokenization reaches '
          'them. On native and desktop that already runs off the UI thread (see '
          '**Async highlighting**), but a synchronous first highlight (raw '
          '`codeToTokens`, `async: false`, or web without the worker) pays it on '
          'the main isolate, where a large grammar can drop a frame.',
        ),
        DocProse(
          'Pre-warming moves that cost to a moment where a brief pause is '
          'invisible, such as app startup or behind a splash screen, so the '
          'first real render is instant. The pattern is two steps: set your '
          'global defaults, then warm the shared highlighter and `await` it '
          'before `runApp`.',
        ),
        DocBullets([
          '**Set the config once.** Point `config.defaultHighlighter` at a '
              'single shared highlighter (and `config.defaultTheme` at your '
              'theme) so every widget reuses it with no `highlighter:` or '
              '`theme:`. Keep it alive for the app\'s lifetime; rebuilding it '
              'per frame or per screen throws the warm state away.',
          '**`await highlighter.preload(...)`.** It decodes each grammar\'s and '
              "theme's JSON and builds its model up front. Passing "
              '`warmAsync: true` also spawns the background worker that `async` '
              'widgets use, so awaiting the call means the first render pays no '
              'parse, isolate-spawn, or grammar-build cost.',
        ]),
        CodeBlock(
          code: Snippets.preWarm,
          lang: 'dart',
          filename: 'main.dart',
        ),
        DocNote(
          'Tokens are also cached (LRU) per `(code, lang, theme)`, so a later '
          'throwaway `codeToTokensAsync` with the exact source you will render '
          'turns that first paint into a cache hit too. On web, `warmAsync` '
          'warms the Web Worker (see **Web setup**) when one is installed; '
          'without a worker the warm-up still runs, just inline on the main '
          'thread.',
        ),
      ];
    case 'bundle-size':
      return const [
        DocProse(
          'Even though the whole catalog ships in the package, only the '
          'languages and themes you actually reference end up in your app. Each '
          'grammar and theme is a separate Dart library referenced by symbol, '
          'so the compiler tree-shakes away everything unreferenced.',
        ),
        DocBullets([
          '**Do** reference specific members: `CodeLanguages.dart`, '
              '`ShikiThemes.githubDark`. Only those (and their embedded deps) '
              'are bundled.',
          "**Don't** use the `.all` lists (`CodeLanguages.all` / "
              '`ShikiThemes.all`) unless you truly want every grammar/theme. '
              'They reference everything and defeat tree-shaking.',
        ]),
        DocProse(
          'The `.all` lists exist for tools and playgrounds that genuinely need '
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
    case 'widgets':
      return const [
        DocProse(
          'shiki_flutter ships two widgets for rendering highlighted code. '
          'Both take the same core inputs (the `code`, a `lang` object, and an '
          'optional `theme`; the `highlighter:` is optional too and falls back '
          'to a shared default) and share the same optional '
          'features: a '
          'line-number gutter (`showLineNumbers` + `gutterStyle`), text '
          'selection, and async highlighting. Pick the one that fits how much '
          'code you are showing.',
        ),
        DocH3('ShikiCodeView'),
        DocProse(
          'The quickest way to display a snippet. It builds the whole document '
          'as a single `Text.rich` and sizes to its content, scrolling '
          'horizontally for long lines, so it is best for small-to-medium '
          'blocks. On IO it highlights off the UI thread by default; see '
          '**Async highlighting**.',
        ),
        CodeBlock(
          code: Snippets.renderWidget,
          lang: 'dart',
          filename: 'code_view.dart',
        ),
        DocH3('ShikiCodeListView'),
        DocProse(
          'Renders one line per row in a lazily built `ListView`, laying out '
          'only the lines on screen, so it stays smooth on large files. Give '
          'it a bounded height like any `ListView`. See **Large files** for '
          'the full walkthrough.',
        ),
        CodeBlock(
          code: Snippets.codeListView,
          lang: 'dart',
          filename: 'code_list_view.dart',
        ),
        DocH3('Properties'),
        DocProse('Both widgets accept these core properties:'),
        DocTable(
          headers: ['Property', 'Type', 'Description'],
          rows: [
            [
              '`highlighter`',
              '`ShikiHighlighter?`',
              'Loads `lang`/`theme` on demand. Omit to use the shared default '
                  '(`ShikiHighlighter.config.defaultHighlighter`, or a '
                  'lazily-created one).',
            ],
            ['`code`', '`String`', 'Source to render.'],
            [
              '`lang`',
              '`CodeLanguage`',
              'Language to highlight, e.g. `CodeLanguages.dart`.',
            ],
            [
              '`theme`',
              '`ShikiThemeBase?`',
              'A single theme or a light/dark pair. Omit to use the global '
                  '`ShikiHighlighter.config.defaultTheme`.',
            ],
            [
              '`brightness`',
              '`Brightness?`',
              'Overrides the brightness used to pick a `dual` theme '
                  '(default: `Theme.of(context)`).',
            ],
            [
              '`textStyle`',
              '`TextStyle?`',
              'Base style; use a monospace font.',
            ],
            [
              '`padding`',
              '`EdgeInsetsGeometry`',
              'Defaults to `16` all round.',
            ],
            ['`paintBackground`', '`bool`', "Paint the theme's background."],
            [
              '`selectable`',
              '`bool`',
              'Wrap in a `SelectionArea` (default off).',
            ],
            [
              '`showLineNumbers`',
              '`bool`',
              'Show a line-number gutter (default off).',
            ],
            [
              '`gutterStyle`',
              '`GutterStyle`',
              'Gutter numbers, gap, and divider.',
            ],
            ['`async`', '`bool?`', 'Override the global async default.'],
            ['`textScaler`', '`TextScaler?`', 'Optional text scaling.'],
          ],
        ),
        DocProse(
          '`ShikiCodeListView` adds a few more for scrolling and wrapping:',
        ),
        DocTable(
          headers: ['Property', 'Type', 'Description'],
          rows: [
            ['`softWrap`', '`bool`', 'Wrap long lines instead of scrolling.'],
            [
              '`shrinkWrap`',
              '`bool`',
              'Grow to fit instead of filling its parent.',
            ],
            ['`physics`', '`ScrollPhysics?`', 'Physics for the vertical list.'],
            [
              '`controller`',
              '`ScrollController?`',
              'External vertical scroll controller.',
            ],
            [
              '`selectionColor`',
              '`Color?`',
              'Highlight color for selected code.',
            ],
            [
              '`lines`',
              '`List<List<TextSpan>>?`',
              'Pre-highlighted spans to skip tokenizing.',
            ],
          ],
        ),
        DocNote(
          '`showLineNumbers` requires `softWrap: false` on `ShikiCodeListView`: '
          'wrapped lines cannot align with a fixed-height gutter.',
        ),
      ];
    case 'large-files':
      return const [
        DocProse(
          'Rendering a whole file as one `TextSpan` (via `codeToTextSpan` or '
          '`ShikiCodeView`) lays out every line up front, which gets expensive '
          'for very large files. shiki_flutter can group the highlighting by '
          'line instead, so a `ListView.builder` renders only the lines '
          'currently on screen.',
        ),
        DocProse(
          '`ShikiCodeListView` (see **Widgets**) is the drop-in option. Give '
          'it a bounded height, like any `ListView`:',
        ),
        CodeBlock(
          code: Snippets.largeFileView,
          lang: 'dart',
          filename: 'large_file.dart',
        ),
        DocH3('Build your own list'),
        DocProse(
          'Prefer to build the list yourself? `codeToLineSpans` returns the '
          'spans grouped by line, as a `List<List<TextSpan>>` (one inner list '
          'per line), ready to feed straight into a `ListView.builder`:',
        ),
        CodeBlock(
          code: Snippets.renderLineSpans,
          lang: 'dart',
          filename: 'line_spans.dart',
        ),
        DocNote(
          'The file is still tokenized eagerly in one pass, because '
          'highlighting on one line can depend on earlier lines (multi-line '
          'strings and comments), so only the rendering is lazy. The horizontal '
          'extent assumes a monospace font; use `softWrap: true` for '
          'proportional fonts.',
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
              'hit it is skipped gracefully, and highlighting keeps going rather '
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
