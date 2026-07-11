// Theme parsing and scope-selector matching, ported from `vscode-textmate`'s
// `theme.ts`.
library;

import 'utils.dart';

/// Font-style bit flags. [notSet] (-1) means "inherit".
class FontStyle {
  static const int notSet = -1;
  static const int none = 0;
  static const int italic = 1;
  static const int bold = 2;
  static const int underline = 4;
  static const int strikethrough = 8;
}

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
  RawThemeSetting({this.name, this.scope, required this.settings});

  final String? name;

  /// Either a `String` (comma-separated) or a `List<String>`.
  final Object? scope;
  final ThemeSettingStyle settings;
}

class ThemeSettingStyle {
  ThemeSettingStyle({this.fontStyle, this.foreground, this.background});

  final String? fontStyle;
  final String? foreground;
  final String? background;
}

/// A raw TextMate theme.
class RawTheme {
  RawTheme({this.name, required this.settings});

  final String? name;
  final List<RawThemeSetting> settings;
}

/// Resolved style attributes for a token.
class StyleAttributes {
  StyleAttributes(this.fontStyle, this.foregroundId, this.backgroundId);

  final int fontStyle;
  final int foregroundId;
  final int backgroundId;
}

/// A stack of scope names (`foo.bar` segments), as a linked list.
class ScopeStack {
  ScopeStack(this.parent, this.scopeName);

  final ScopeStack? parent;
  final String scopeName;

  static ScopeStack? push(ScopeStack? path, List<String> scopeNames) {
    var result = path;
    for (final name in scopeNames) {
      result = ScopeStack(result, name);
    }
    return result;
  }

  static ScopeStack? from(List<String> segments) {
    ScopeStack? result;
    for (final segment in segments) {
      result = ScopeStack(result, segment);
    }
    return result;
  }

  ScopeStack pushScope(String scopeName) => ScopeStack(this, scopeName);

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

  bool extendsStack(ScopeStack other) {
    if (identical(this, other)) return true;
    if (parent == null) return false;
    return parent!.extendsStack(other);
  }
}

bool _scopePathMatchesParentScopes(
    ScopeStack? scopePath, List<String> parentScopes) {
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
  ParsedThemeRule(
    this.scope,
    this.parentScopes,
    this.index,
    this.fontStyle,
    this.foreground,
    this.background,
  );

  final String scope;
  final List<String>? parentScopes;
  final int index;
  final int fontStyle;
  final String? foreground;
  final String? background;
}

final RegExp _leadingCommas = RegExp(r'^,+');
final RegExp _trailingCommas = RegExp(r',+$');

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
      result.add(ParsedThemeRule(
        scopeName,
        parentScopes,
        i,
        fontStyle,
        foreground,
        background,
      ));
    }
  }
  return result;
}

/// Maps hex color strings to small integer ids and back.
class ColorMap {
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

  List<String> getColorMap() {
    final maxId = _id2color.keys.isEmpty
        ? -1
        : _id2color.keys.reduce((a, b) => a > b ? a : b);
    return [for (var i = 0; i <= maxId; i++) _id2color[i] ?? ''];
  }
}

const List<String> _emptyParentScopes = [];

class ThemeTrieElementRule {
  ThemeTrieElementRule(
    this.scopeDepth,
    List<String>? parentScopes,
    this.fontStyle,
    this.foreground,
    this.background,
  ) : parentScopes = parentScopes ?? _emptyParentScopes;

  int scopeDepth;
  List<String> parentScopes;
  int fontStyle;
  int foreground;
  int background;

  ThemeTrieElementRule clone() => ThemeTrieElementRule(
      scopeDepth, parentScopes, fontStyle, foreground, background);

  static List<ThemeTrieElementRule> cloneArr(List<ThemeTrieElementRule> arr) =>
      [for (final r in arr) r.clone()];

  void acceptOverwrite(
      int scopeDepth, int fontStyle, int foreground, int background) {
    if (this.scopeDepth <= scopeDepth) {
      this.scopeDepth = scopeDepth;
    }
    if (fontStyle != FontStyle.notSet) this.fontStyle = fontStyle;
    if (foreground != 0) this.foreground = foreground;
    if (background != 0) this.background = background;
  }
}

class ThemeTrieElement {
  ThemeTrieElement(
    this._mainRule, [
    List<ThemeTrieElementRule>? rulesWithParentScopes,
    Map<String, ThemeTrieElement>? children,
  ])  : _rulesWithParentScopes = rulesWithParentScopes ?? [],
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
      final diff = b.parentScopes[bParentIndex].length -
          a.parentScopes[aParentIndex].length;
      if (diff != 0) return diff;
      aParentIndex++;
      bParentIndex++;
    }

    return b.parentScopes.length - a.parentScopes.length;
  }

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

  void insert(int scopeDepth, String scope, List<String>? parentScopes,
      int fontStyle, int foreground, int background) {
    if (scope == '') {
      _doInsertHere(scopeDepth, parentScopes, fontStyle, foreground, background);
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
        scopeDepth + 1, tail, parentScopes, fontStyle, foreground, background);
  }

  void _doInsertHere(int scopeDepth, List<String>? parentScopes, int fontStyle,
      int foreground, int background) {
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

    _rulesWithParentScopes.add(ThemeTrieElementRule(
        scopeDepth, parentScopes, fontStyle, foreground, background));
  }
}

/// A resolved theme: color map, defaults, and a scope-matching trie.
class Theme {
  Theme(this._colorMap, this._defaults, this._root);

  final ColorMap _colorMap;
  final StyleAttributes _defaults;
  final ThemeTrieElement _root;

  late final CachedFn<String, List<ThemeTrieElementRule>> _cachedMatchRoot =
      CachedFn((scopeName) => _root.match(scopeName));

  static Theme createFromRawTheme(RawTheme? source, [List<String>? colorMap]) {
    return createFromParsedTheme(parseTheme(source), colorMap);
  }

  static Theme createFromParsedTheme(List<ParsedThemeRule> source,
      [List<String>? colorMap]) {
    return _resolveParsedThemeRules(source, colorMap);
  }

  List<String> getColorMap() => _colorMap.getColorMap();

  StyleAttributes getDefaults() => _defaults;

  StyleAttributes? match(ScopeStack? scopePath) {
    if (scopePath == null) return _defaults;
    final scopeName = scopePath.scopeName;
    final matchingTrieElements = _cachedMatchRoot.get(scopeName);

    for (final rule in matchingTrieElements) {
      if (_scopePathMatchesParentScopes(scopePath.parent, rule.parentScopes)) {
        return StyleAttributes(
            rule.fontStyle, rule.foreground, rule.background);
      }
    }
    return null;
  }
}

Theme _resolveParsedThemeRules(
    List<ParsedThemeRule> parsedThemeRules, List<String>? colorMapArg) {
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
  final defaults = StyleAttributes(defaultFontStyle,
      colorMap.getId(defaultForeground), colorMap.getId(defaultBackground));

  final root = ThemeTrieElement(
      ThemeTrieElementRule(0, null, FontStyle.notSet, 0, 0), []);
  for (final rule in parsedThemeRules) {
    root.insert(0, rule.scope, rule.parentScopes, rule.fontStyle,
        colorMap.getId(rule.foreground), colorMap.getId(rule.background));
  }

  return Theme(colorMap, defaults, root);
}
