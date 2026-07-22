import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

import '../data/snippets.dart';
import '../highlight/highlighter_service.dart';
import '../theme/tokens.dart';
import 'copy_button.dart';

/// An interactive explorer for every bundled theme: a searchable, dark/light
/// grouped list on the left, and a live preview of the selected theme on the
/// right - the same Dart sample, tokenized by the gallery highlighter (see
/// [HighlighterService.gallerySpan]).
class ThemeGallery extends StatefulWidget {
  const ThemeGallery({super.key});

  @override
  State<ThemeGallery> createState() => _ThemeGalleryState();
}

class _ThemeGalleryState extends State<ThemeGallery> {
  static const String _defaultId = 'github-dark';

  /// The Dart sample previewed in every theme.
  static final String _sample = Snippets.byLanguage['dart']!.trim();

  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _selectedId = _defaultId;

  List<ShikiTheme> get _all => HighlighterService.instance.galleryThemes;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ShikiTheme> _filtered(String type) {
    final q = _query.trim().toLowerCase();
    return _all
        .where((t) => t.type == type && (q.isEmpty || t.id.contains(q)))
        .toList();
  }

  void _select(String id) => setState(() => _selectedId = id);

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final dark = _filtered('dark');
    final light = _filtered('light');

    final list = _ThemeList(
      dark: dark,
      light: light,
      selectedId: _selectedId,
      onSelect: _select,
      search: _searchField(context),
    );

    final preview = _ThemePreview(themeId: _selectedId, sample: _sample);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 260, child: list),
          const SizedBox(height: 16),
          SizedBox(height: 360, child: preview),
        ],
      );
    }

    return SizedBox(
      height: 460,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 264, child: list),
          const SizedBox(width: 20),
          Expanded(child: preview),
        ],
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final colors = context.colors;
    return SelectionContainer.disabled(
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        cursorColor: colors.foreground,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 13.5,
          fontFamily: AppFonts.mono,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search ${_all.length} themes…',
          hintStyle: TextStyle(color: colors.mutedForeground, fontSize: 13.5),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: colors.mutedForeground,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 38,
          ),
          filled: true,
          fillColor: colors.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 11,
            horizontal: 4,
          ),
          border: _searchBorder(colors.border),
          enabledBorder: _searchBorder(colors.border),
          focusedBorder: _searchBorder(colors.borderStrong),
        ),
      ),
    );
  }

  OutlineInputBorder _searchBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide(color: color),
  );
}

/// The left rail: search field pinned on top, then a scrollable dark/light
/// grouped list of theme rows.
class _ThemeList extends StatelessWidget {
  const _ThemeList({
    required this.dark,
    required this.light,
    required this.selectedId,
    required this.onSelect,
    required this.search,
  });

  final List<ShikiTheme> dark;
  final List<ShikiTheme> light;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final Widget search;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final empty = dark.isEmpty && light.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 10),
          Expanded(
            child: empty
                ? _empty(colors)
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (dark.isNotEmpty) ...[
                        _GroupHeader(label: 'DARK', count: dark.length),
                        for (final t in dark)
                          _ThemeRow(
                            theme: t,
                            selected: t.id == selectedId,
                            onTap: () => onSelect(t.id),
                          ),
                      ],
                      if (light.isNotEmpty) ...[
                        if (dark.isNotEmpty) const SizedBox(height: 8),
                        _GroupHeader(label: 'LIGHT', count: light.length),
                        for (final t in light)
                          _ThemeRow(
                            theme: t,
                            selected: t.id == selectedId,
                            onTap: () => onSelect(t.id),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppColors colors) => Center(
    child: Text(
      'No themes match',
      style: TextStyle(color: colors.mutedForeground, fontSize: 13),
    ),
  );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Text(
        '$label · $count',
        style: TextStyle(
          color: colors.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// A single theme row: a dark/light dot (filled = dark, hollow = light) and the
/// theme id in mono. Wrapped in [SelectionContainer.disabled] so a tap isn't
/// captured by the page's [SelectionArea].
class _ThemeRow extends StatefulWidget {
  const _ThemeRow({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ShikiTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeRow> createState() => _ThemeRowState();
}

class _ThemeRowState extends State<_ThemeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;
    final isDark = widget.theme.type == 'dark';

    final bg = selected
        ? colors.surfaceInset
        : (_hovered
              ? colors.foreground.withValues(alpha: 0.04)
              : Colors.transparent);
    final fg = selected ? colors.foreground : colors.mutedForeground;

    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                _TypeDot(isDark: isDark, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.theme.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontFamily: AppFonts.mono,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 9px dot: filled for dark themes, a hollow ring for light themes.
class _TypeDot extends StatelessWidget {
  const _TypeDot({required this.isDark, required this.color});

  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? color : Colors.transparent,
        border: Border.all(color: color, width: 1.4),
      ),
    );
  }
}

/// The right pane: the sample rendered in the selected theme, painted with the
/// theme's own background, plus a caption showing the exact `theme:` id.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.themeId, required this.sample});

  final String themeId;
  final String sample;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final service = HighlighterService.instance;
    final bg = service.galleryBackground(themeId, colors.surface);
    final onBg = bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final border = onBg.withValues(alpha: 0.10);

    // gallerySpan now takes the resolved theme object; find it by the selected
    // id (galleryThemes is the gallery highlighter's full theme set).
    final theme = service.galleryThemes.firstWhere((t) => t.id == themeId);
    final span = service.gallerySpan(sample, theme: theme);
    final lineCount = '\n'.allMatches(sample).length + 1;
    final numberStyle = TextStyle(
      fontFamily: AppFonts.mono,
      fontSize: 13.5,
      height: 1.55,
      color: onBg.withValues(alpha: 0.32),
    );

    final scroller = SingleChildScrollView(
      // Vertical: the sample can be taller than the fixed pane.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectionContainer.disabled(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 1; i <= lineCount; i++)
                      Text('$i', style: numberStyle),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text.rich(span, softWrap: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Only add our own SelectionArea when there isn't one already above us (e.g.
    // the docs page's). Nesting SelectionAreas breaks keyboard copy (Cmd/Ctrl+C),
    // so an ancestor SelectionArea keeps driving selection here.
    final code = SelectionContainer.maybeOf(context) == null
        ? SelectionArea(child: scroller)
        : scroller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: border),
            ),
            child: code,
          ),
        ),
        const SizedBox(height: 10),
        _Caption(themeId: themeId),
      ],
    );
  }
}

/// `theme: '<id>'` under the preview, with a copy button - the exact string a
/// consumer passes when rendering.
class _Caption extends StatelessWidget {
  const _Caption({required this.themeId});

  final String themeId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: SelectionContainer.disabled(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 12.5,
                  color: colors.mutedForeground,
                ),
                children: [
                  const TextSpan(text: 'theme: '),
                  TextSpan(
                    text: "'$themeId'",
                    style: TextStyle(color: colors.foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
        CopyButton(text: themeId, size: 14, tooltip: 'Copy id'),
      ],
    );
  }
}
