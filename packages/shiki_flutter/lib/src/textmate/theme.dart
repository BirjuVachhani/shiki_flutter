// Theme parsing and scope-selector matching, ported from `vscode-textmate`'s
// `theme.ts`.

import 'utils.dart';

/// Font-style bit flags. [notSet] (-1) means "inherit".
class FontStyle {
  /// Sentinel meaning "not set"; the style should be inherited from a less
  /// specific matching rule.
  static const int notSet = -1;

  /// No font-style bits set.
  static const int none = 0;

  /// Italic bit flag.
  static const int italic = 1;

  /// Bold bit flag.
  static const int bold = 2;

  /// Underline bit flag.
  static const int underline = 4;

  /// Strikethrough bit flag.
  static const int strikethrough = 8;
}

/// Renders [fontStyle]'s bit flags (see [FontStyle]) as a space-separated
/// string, e.g. `'italic bold'`, or `'not set'`/`'none'`.
String fontStyleToString(int fontStyle) {
  if (fontStyle == FontStyle.notSet) return 'not set';
  var style = '';
  if (fontStyle & FontStyle.italic != 0) style += 'italic ';
  if (fontStyle & FontStyle.bold != 0) style += 'bold ';
  if (fontStyle & FontStyle.underline != 0) style += 'underline ';
  if (fontStyle & FontStyle.strikethrough != 0) style += 'strikethrough ';
  if (style == '') style = 'none';
  return style.trim();
}

/// A single raw theme setting (`{ name?, scope?, settings }`).
class RawThemeSetting {
  /// Creates a raw theme setting; [settings] is required, [name] and [scope]
  /// are optional as in the source theme JSON.
  RawThemeSetting({this.name, this.scope, required this.settings});

  /// A human-readable label for this rule, as authored in the theme.
  final String? name;

  /// Either a `String` (comma-separated) or a `List<String>`.
  final Object? scope;

  /// The style (font style, foreground, background) applied when [scope]
  /// matches.
  final ThemeSettingStyle settings;
}

/// The unresolved style block of a [RawThemeSetting], with colors still as
/// raw hex strings and font style still as a raw space-separated string.
class ThemeSettingStyle {
  /// Creates a raw style block; all fields are optional as in the source
  /// theme JSON.
  ThemeSettingStyle({this.fontStyle, this.foreground, this.background});

  /// Space-separated style keywords, e.g. `'italic bold'`. Parsed into
  /// [FontStyle] bit flags by [parseTheme].
  final String? fontStyle;

  /// A hex color string, e.g. `'#FF0000'`.
  final String? foreground;

  /// A hex color string, e.g. `'#FF0000'`.
  final String? background;
}

/// A raw TextMate theme.
class RawTheme {
  /// Creates a raw theme from its [name] and ordered [settings] rules.
  RawTheme({this.name, required this.settings});

  /// The theme's display name, if any.
  final String? name;

  /// The theme's scope-selector rules, in the order they should be applied
  /// (later entries win ties; see [parseTheme]).
  final List<RawThemeSetting> settings;
}

/// Resolved style attributes for a token.
class StyleAttributes {
  /// Creates a resolved style from a [FontStyle] bitmask and [ColorMap]
  /// ids for the foreground/background colors.
  StyleAttributes(this.fontStyle, this.foregroundId, this.backgroundId);

  /// [FontStyle] bit flags, or [FontStyle.notSet].
  final int fontStyle;

  /// Id into a [ColorMap], or `0` for "no color".
  final int foregroundId;

  /// Id into a [ColorMap], or `0` for "no color".
  final int backgroundId;
}

/// A stack of scope names (`foo.bar` segments), as a linked list.
class ScopeStack {
  /// Pushes [scopeName] onto [parent], forming a new innermost segment.
  ScopeStack(this.parent, this.scopeName);

  /// The enclosing scope, or `null` if this is the outermost segment.
  final ScopeStack? parent;

  /// This segment's scope name, e.g. `source.dart`.
  final String scopeName;

  /// Pushes each of [scopeNames] onto [path] in order, returning the new
  /// innermost [ScopeStack].
  static ScopeStack? push(ScopeStack? path, List<String> scopeNames) {
    var result = path;
    for (final name in scopeNames) {
      result = ScopeStack(result, name);
    }
    return result;
  }

  /// Builds a [ScopeStack] from [segments], outermost first.
  static ScopeStack? from(List<String> segments) {
    ScopeStack? result;
    for (final segment in segments) {
      result = ScopeStack(result, segment);
    }
    return result;
  }

  /// Returns a new [ScopeStack] with [scopeName] pushed on top of this one.
  ScopeStack pushScope(String scopeName) => ScopeStack(this, scopeName);

  /// Returns this stack's scope names as a list, outermost first.
  List<String> getSegments() {
    ScopeStack? item = this;
    final result = <String>[];
    while (item != null) {
      result.add(item.scopeName);
      item = item.parent;
    }
    return result.reversed.toList();
  }

  @override
  String toString() => getSegments().join(' ');

  /// Whether [other] is this stack or one of its ancestors, i.e. whether
  /// this stack was reached by pushing zero or more scopes onto [other].
  bool extendsStack(ScopeStack other) {
    if (identical(this, other)) return true;
    if (parent == null) return false;
    return parent!.extendsStack(other);
  }
}

bool _scopePathMatchesParentScopes(
  ScopeStack? scopePath,
  List<String> parentScopes,
) {
  if (parentScopes.isEmpty) return true;

  for (var index = 0; index < parentScopes.length; index++) {
    var scopePattern = parentScopes[index];
    var scopeMustMatch = false;

    if (scopePattern == '>') {
      if (index == parentScopes.length - 1) return false;
      scopePattern = parentScopes[++index];
      scopeMustMatch = true;
    }

    while (scopePath != null) {
      if (_matchesScope(scopePath.scopeName, scopePattern)) break;
      if (scopeMustMatch) return false;
      scopePath = scopePath.parent;
    }

    if (scopePath == null) return false;
    scopePath = scopePath.parent;
  }

  return true;
}

bool _matchesScope(String scopeName, String scopePattern) {
  return scopePattern == scopeName ||
      (scopeName.startsWith(scopePattern) &&
          scopeName.length > scopePattern.length &&
          scopeName[scopePattern.length] == '.');
}

/// A parsed theme rule (post-`parseTheme`).
class ParsedThemeRule {
  /// Creates a parsed theme rule; see the fields for the meaning of each
  /// component.
  ParsedThemeRule(
    this.scope,
    this.parentScopes,
    this.index,
    this.fontStyle,
    this.foreground,
    this.background,
  );

  /// The innermost scope name this rule matches, e.g. `string.quoted`.
  final String scope;

  /// Ancestor scope selectors that must also match, nearest-parent first
  /// (a `>` entry means the next selector must be the direct parent), or
  /// `null` if the rule had no parent scopes.
  final List<String>? parentScopes;

  /// This rule's position among the raw theme's settings, used to break
  /// ties between otherwise equally specific rules (later wins).
  final int index;

  /// [FontStyle] bit flags, or [FontStyle.notSet] if unspecified.
  final int fontStyle;

  /// A hex color string, or `null` if unspecified.
  final String? foreground;

  /// A hex color string, or `null` if unspecified.
  final String? background;
}

final RegExp _leadingCommas = RegExp(r'^,+');
final RegExp _trailingCommas = RegExp(r',+$');

/// Flattens [source]'s settings into [ParsedThemeRule]s: comma-separated
/// scope lists are split, and each rule's selector (`'foo bar'`) is split
/// into a matched [ParsedThemeRule.scope] plus reversed
/// [ParsedThemeRule.parentScopes]. Returns an empty list if [source] is
/// `null`.
List<ParsedThemeRule> parseTheme(RawTheme? source) {
  if (source == null) return [];
  final settings = source.settings;
  final result = <ParsedThemeRule>[];
  for (var i = 0; i < settings.length; i++) {
    final entry = settings[i];

    List<String> scopes;
    final scope = entry.scope;
    if (scope is String) {
      var s = scope.replaceAll(_leadingCommas, '');
      s = s.replaceAll(_trailingCommas, '');
      scopes = s.split(',');
    } else if (scope is List) {
      scopes = scope.cast<String>();
    } else {
      scopes = [''];
    }

    var fontStyle = FontStyle.notSet;
    final rawFontStyle = entry.settings.fontStyle;
    if (rawFontStyle is String) {
      fontStyle = FontStyle.none;
      for (final segment in rawFontStyle.split(' ')) {
        switch (segment) {
          case 'italic':
            fontStyle |= FontStyle.italic;
          case 'bold':
            fontStyle |= FontStyle.bold;
          case 'underline':
            fontStyle |= FontStyle.underline;
          case 'strikethrough':
            fontStyle |= FontStyle.strikethrough;
        }
      }
    }

    String? foreground;
    final fg = entry.settings.foreground;
    if (fg is String && isValidHexColor(fg)) foreground = fg;

    String? background;
    final bg = entry.settings.background;
    if (bg is String && isValidHexColor(bg)) background = bg;

    for (var j = 0; j < scopes.length; j++) {
      final trimmed = scopes[j].trim();
      final segments = trimmed.split(' ');
      final scopeName = segments.last;
      List<String>? parentScopes;
      if (segments.length > 1) {
        parentScopes = segments.sublist(0, segments.length - 1);
        parentScopes = parentScopes.reversed.toList();
      }
      result.add(
        ParsedThemeRule(
          scopeName,
          parentScopes,
          i,
          fontStyle,
          foreground,
          background,
        ),
      );
    }
  }
  return result;
}

/// Maps hex color strings to small integer ids and back.
class ColorMap {
  /// Creates a color map. If [colorMap] is given, the map is frozen with
  /// those colors pre-assigned to their indices (used when restoring a
  /// previously serialized theme); otherwise it starts empty and grows as
  /// [getId] assigns new colors.
  ColorMap([List<String>? colorMap]) {
    if (colorMap != null) {
      _isFrozen = true;
      for (var i = 0; i < colorMap.length; i++) {
        _color2id[colorMap[i]] = i;
        _id2color[i] = colorMap[i];
      }
    } else {
      _isFrozen = false;
    }
  }

  bool _isFrozen = false;
  int _lastColorId = 0;
  final Map<int, String> _id2color = {};
  final Map<String, int> _color2id = {};

  /// Returns the id for [color] (case-insensitive), assigning it a new id
  /// if it hasn't been seen before, or `0` if [color] is `null`. Throws a
  /// [StateError] if the map is frozen (constructed with an explicit color
  /// list) and [color] isn't already present.
  int getId(String? color) {
    if (color == null) return 0;
    final upper = color.toUpperCase();
    final value = _color2id[upper];
    if (value != null) return value;
    if (_isFrozen) {
      throw StateError('Missing color in color map - $upper');
    }
    final id = ++_lastColorId;
    _color2id[upper] = id;
    _id2color[id] = upper;
    return id;
  }

  /// Returns colors indexed by id (index `0` is always `''`, matching the
  /// "no color" sentinel used by [getId]).
  List<String> getColorMap() {
    final maxId = _id2color.keys.isEmpty
        ? -1
        : _id2color.keys.reduce((a, b) => a > b ? a : b);
    return [for (var i = 0; i <= maxId; i++) _id2color[i] ?? ''];
  }
}

const List<String> _emptyParentScopes = [];

/// A style rule attached to a [ThemeTrieElement] node: the style that
/// applies at that node's scope depth, optionally further conditioned on
/// [parentScopes].
class ThemeTrieElementRule {
  /// Creates a trie rule; `null` [parentScopes] is normalized to an empty
  /// list.
  ThemeTrieElementRule(
    this.scopeDepth,
    List<String>? parentScopes,
    this.fontStyle,
    this.foreground,
    this.background,
  ) : parentScopes = parentScopes ?? _emptyParentScopes;

  /// How many scope segments deep in the trie this rule was inserted at;
  /// deeper (more specific) rules are preferred when [ThemeTrieElement.match]
  /// ranks candidates.
  int scopeDepth;

  /// Ancestor scope selectors (nearest-parent first) that must also match
  /// the scope path's ancestors, or empty if this rule applies regardless
  /// of ancestors.
  List<String> parentScopes;

  /// [FontStyle] bit flags, or [FontStyle.notSet] if inherited.
  int fontStyle;

  /// Id into a [ColorMap], or `0` if inherited.
  int foreground;

  /// Id into a [ColorMap], or `0` if inherited.
  int background;

  /// Returns a copy of this rule (parent scopes list is shared, not deep
  /// copied, since it is never mutated in place).
  ThemeTrieElementRule clone() => ThemeTrieElementRule(
    scopeDepth,
    parentScopes,
    fontStyle,
    foreground,
    background,
  );

  /// Clones every rule in [arr].
  static List<ThemeTrieElementRule> cloneArr(List<ThemeTrieElementRule> arr) =>
      [for (final r in arr) r.clone()];

  /// Merges an incoming rule's attributes into this one in place: a deeper
  /// [scopeDepth] wins outright, while [fontStyle]/[foreground]/[background]
  /// are only overwritten when the incoming value isn't the "not set"
  /// sentinel.
  void acceptOverwrite(
    int scopeDepth,
    int fontStyle,
    int foreground,
    int background,
  ) {
    if (this.scopeDepth <= scopeDepth) {
      this.scopeDepth = scopeDepth;
    }
    if (fontStyle != FontStyle.notSet) this.fontStyle = fontStyle;
    if (foreground != 0) this.foreground = foreground;
    if (background != 0) this.background = background;
  }
}

/// A node in the trie [Theme] uses to resolve a scope name to style rules.
/// Each level of the trie corresponds to one dot-separated segment of a
/// scope name (e.g. `source.dart` descends through a `source` child to a
/// `dart` child).
class ThemeTrieElement {
  /// Creates a trie node with [_mainRule] as the rule that applies when no
  /// more specific child or [parentScopes]-qualified rule matches.
  ThemeTrieElement(
    this._mainRule, [
    List<ThemeTrieElementRule>? rulesWithParentScopes,
    Map<String, ThemeTrieElement>? children,
  ]) : _rulesWithParentScopes = rulesWithParentScopes ?? [],
       _children = children ?? {};

  final ThemeTrieElementRule _mainRule;
  final List<ThemeTrieElementRule> _rulesWithParentScopes;
  final Map<String, ThemeTrieElement> _children;

  static int _cmpBySpecificity(ThemeTrieElementRule a, ThemeTrieElementRule b) {
    if (a.scopeDepth != b.scopeDepth) return b.scopeDepth - a.scopeDepth;

    var aParentIndex = 0;
    var bParentIndex = 0;

    while (true) {
      if (aParentIndex < a.parentScopes.length &&
          a.parentScopes[aParentIndex] == '>') {
        aParentIndex++;
      }
      if (bParentIndex < b.parentScopes.length &&
          b.parentScopes[bParentIndex] == '>') {
        bParentIndex++;
      }
      if (aParentIndex >= a.parentScopes.length ||
          bParentIndex >= b.parentScopes.length) {
        break;
      }
      final diff =
          b.parentScopes[bParentIndex].length -
          a.parentScopes[aParentIndex].length;
      if (diff != 0) return diff;
      aParentIndex++;
      bParentIndex++;
    }

    return b.parentScopes.length - a.parentScopes.length;
  }

  /// Walks the trie by [scope]'s dot-separated segments and returns the
  /// candidate rules at the deepest matching node, most specific first
  /// (parent-scope-qualified rules before the node's [_mainRule]).
  List<ThemeTrieElementRule> match(String scope) {
    if (scope != '') {
      final dotIndex = scope.indexOf('.');
      String head;
      String tail;
      if (dotIndex == -1) {
        head = scope;
        tail = '';
      } else {
        head = scope.substring(0, dotIndex);
        tail = scope.substring(dotIndex + 1);
      }
      final child = _children[head];
      if (child != null) return child.match(tail);
    }

    final rules = [..._rulesWithParentScopes, _mainRule];
    rules.sort(_cmpBySpecificity);
    return rules;
  }

  /// Inserts a style rule at [scope] (descending into/creating child nodes
  /// for each dot-separated segment, newly created children inheriting a
  /// clone of their parent's current rules), applying [fontStyle],
  /// [foreground], and [background] either directly (if [parentScopes] is
  /// `null`) or as a new parent-scope-qualified rule.
  void insert(
    int scopeDepth,
    String scope,
    List<String>? parentScopes,
    int fontStyle,
    int foreground,
    int background,
  ) {
    if (scope == '') {
      _doInsertHere(
        scopeDepth,
        parentScopes,
        fontStyle,
        foreground,
        background,
      );
      return;
    }

    final dotIndex = scope.indexOf('.');
    String head;
    String tail;
    if (dotIndex == -1) {
      head = scope;
      tail = '';
    } else {
      head = scope.substring(0, dotIndex);
      tail = scope.substring(dotIndex + 1);
    }

    var child = _children[head];
    if (child == null) {
      child = ThemeTrieElement(
        _mainRule.clone(),
        ThemeTrieElementRule.cloneArr(_rulesWithParentScopes),
      );
      _children[head] = child;
    }

    child.insert(
      scopeDepth + 1,
      tail,
      parentScopes,
      fontStyle,
      foreground,
      background,
    );
  }

  void _doInsertHere(
    int scopeDepth,
    List<String>? parentScopes,
    int fontStyle,
    int foreground,
    int background,
  ) {
    if (parentScopes == null) {
      _mainRule.acceptOverwrite(scopeDepth, fontStyle, foreground, background);
      return;
    }

    for (final rule in _rulesWithParentScopes) {
      if (strArrCmp(rule.parentScopes, parentScopes) == 0) {
        rule.acceptOverwrite(scopeDepth, fontStyle, foreground, background);
        return;
      }
    }

    if (fontStyle == FontStyle.notSet) fontStyle = _mainRule.fontStyle;
    if (foreground == 0) foreground = _mainRule.foreground;
    if (background == 0) background = _mainRule.background;

    _rulesWithParentScopes.add(
      ThemeTrieElementRule(
        scopeDepth,
        parentScopes,
        fontStyle,
        foreground,
        background,
      ),
    );
  }
}

/// A resolved theme: color map, defaults, and a scope-matching trie.
class Theme {
  /// Wraps an already-resolved [ColorMap], default style, and matching
  /// trie. Prefer [createFromRawTheme] or [createFromParsedTheme].
  Theme(this._colorMap, this._defaults, this._root);

  final ColorMap _colorMap;
  final StyleAttributes _defaults;
  final ThemeTrieElement _root;

  late final CachedFn<String, List<ThemeTrieElementRule>> _cachedMatchRoot =
      CachedFn((scopeName) => _root.match(scopeName));

  /// Parses [source] (see [parseTheme]) and builds a [Theme] from it. If
  /// [colorMap] is given, colors are resolved against that fixed palette
  /// instead of building a new one.
  static Theme createFromRawTheme(RawTheme? source, [List<String>? colorMap]) {
    return createFromParsedTheme(parseTheme(source), colorMap);
  }

  /// Builds a [Theme] from already-parsed [source] rules. If [colorMap] is
  /// given, colors are resolved against that fixed palette instead of
  /// building a new one.
  static Theme createFromParsedTheme(
    List<ParsedThemeRule> source, [
    List<String>? colorMap,
  ]) {
    return _resolveParsedThemeRules(source, colorMap);
  }

  /// Returns this theme's colors indexed by id; see [ColorMap.getColorMap].
  List<String> getColorMap() => _colorMap.getColorMap();

  /// The style to use when no scope-specific rule matches.
  StyleAttributes getDefaults() => _defaults;

  /// Resolves the style for [scopePath] by matching its innermost scope
  /// against the trie, then confirming the first candidate rule whose
  /// [ThemeTrieElementRule.parentScopes] are satisfied by the path's
  /// ancestors. Returns [getDefaults] if [scopePath] is `null`, or `null`
  /// if no rule matches.
  StyleAttributes? match(ScopeStack? scopePath) {
    if (scopePath == null) return _defaults;
    final scopeName = scopePath.scopeName;
    final matchingTrieElements = _cachedMatchRoot.get(scopeName);

    for (final rule in matchingTrieElements) {
      if (_scopePathMatchesParentScopes(scopePath.parent, rule.parentScopes)) {
        return StyleAttributes(
          rule.fontStyle,
          rule.foreground,
          rule.background,
        );
      }
    }
    return null;
  }
}

Theme _resolveParsedThemeRules(
  List<ParsedThemeRule> parsedThemeRules,
  List<String>? colorMapArg,
) {
  parsedThemeRules.sort((a, b) {
    var r = strcmp(a.scope, b.scope);
    if (r != 0) return r;
    r = strArrCmp(a.parentScopes, b.parentScopes);
    if (r != 0) return r;
    return a.index - b.index;
  });

  var defaultFontStyle = FontStyle.none;
  var defaultForeground = '#000000';
  var defaultBackground = '#ffffff';
  while (parsedThemeRules.isNotEmpty && parsedThemeRules[0].scope == '') {
    final incoming = parsedThemeRules.removeAt(0);
    if (incoming.fontStyle != FontStyle.notSet) {
      defaultFontStyle = incoming.fontStyle;
    }
    if (incoming.foreground != null) defaultForeground = incoming.foreground!;
    if (incoming.background != null) defaultBackground = incoming.background!;
  }

  final colorMap = ColorMap(colorMapArg);
  final defaults = StyleAttributes(
    defaultFontStyle,
    colorMap.getId(defaultForeground),
    colorMap.getId(defaultBackground),
  );

  final root = ThemeTrieElement(
    ThemeTrieElementRule(0, null, FontStyle.notSet, 0, 0),
    [],
  );
  for (final rule in parsedThemeRules) {
    root.insert(
      0,
      rule.scope,
      rule.parentScopes,
      rule.fontStyle,
      colorMap.getId(rule.foreground),
      colorMap.getId(rule.background),
    );
  }

  return Theme(colorMap, defaults, root);
}
