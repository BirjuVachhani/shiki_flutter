import 'package:flutter/material.dart';

import '../data/supported.dart';
import '../theme/tokens.dart';

/// Every bundled language, searchable, laid out as a horizontally-scrolling
/// column grid: each column holds [_rows] entries top-to-bottom, and columns
/// are added to the right as needed. A search field on top filters by both the
/// display name and the id. Tiles are static (informational) but their text
/// stays selectable via the page's [SelectionArea] - so this widget does not
/// wrap them in [SelectionContainer.disabled] (only the search field is).
class LanguageGrid extends StatefulWidget {
  const LanguageGrid({super.key});

  @override
  State<LanguageGrid> createState() => _LanguageGridState();
}

class _LanguageGridState extends State<LanguageGrid> {
  /// Entries per column before wrapping into the next column.
  static const int _rows = 5;

  /// Per-tile geometry. The band is exactly [_rows] tiles tall, so it never
  /// squeezes a tile (which would overflow its two lines of text).
  static const double _tileHeight = 40;
  static const double _rowSpacing = 8;
  static const double _columnWidth = 210;
  static const double _columnSpacing = 20;

  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<({String id, String name})> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return supportedLanguages;
    return supportedLanguages
        .where((l) => l.id.contains(q) || l.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    // +2 slack so a full column of fixed-height tiles never rounds past the
    // band and trips the overflow detector.
    final bandHeight = _rows * _tileHeight + (_rows - 1) * _rowSpacing + 2 + 32;
    final columnCount = (results.length / _rows).ceil();

    return Container(
      padding: const EdgeInsets.only(top: 2, bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: _searchField(context),
          ),
          const SizedBox(height: 8),
          Container(
            height: bandHeight,
            decoration: ShapeDecoration(
              // color: Theme.of(context).brightness == .dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              shape: RoundedSuperellipseBorder(
                borderRadius: .circular(16),
                side: BorderSide(
                  color: Theme.of(context).brightness == .dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: results.isEmpty
                ? _empty(context)
                : ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: .circular(16),
                      ),
                    ),
                    child: Scrollbar(
                      controller: _scroll,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scroll,
                        padding: .all(16),
                        scrollDirection: Axis.horizontal,
                        // padding: EdgeInsets.zero,
                        itemCount: columnCount,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: _columnSpacing),
                        itemBuilder: (context, col) {
                          final start = col * _rows;
                          final end = (start + _rows).clamp(0, results.length);
                          return SizedBox(
                            width: _columnWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = start; i < end; i++) ...[
                                  if (i != start)
                                    const SizedBox(height: _rowSpacing),
                                  SizedBox(
                                    height: _tileHeight,
                                    child: _LangTile(lang: results[i]),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
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
          hintText: 'Search ${supportedLanguages.length} languages…',
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

  Widget _empty(BuildContext context) => Center(
    child: Text(
      'No languages match',
      style: TextStyle(color: context.colors.mutedForeground, fontSize: 13),
    ),
  );
}

/// A single language entry, styled like a markdown bullet: a small dot, the
/// display name, and its mono id as a subtitle below. No background or border.
/// Static - no hover or tap - and intentionally not wrapped in
/// [SelectionContainer.disabled] so the text is selectable under the page's
/// [SelectionArea].
class _LangTile extends StatelessWidget {
  const _LangTile({required this.lang});

  final ({String id, String name}) lang;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The same 4px dot bullet used by DocBullets in the prose.
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 2, right: 12),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: colors.mutedForeground,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lang.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 12,
                  height: 1.2,
                  fontFamily: AppFonts.mono,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
