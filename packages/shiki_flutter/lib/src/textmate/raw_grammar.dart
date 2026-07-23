// The raw grammar data model (the deserialized form of a `.tmLanguage.json`
// file), ported from `vscode-textmate`'s `rawGrammar.ts`.
//
// Unlike the TypeScript original, which manipulates plain objects dynamically,
// this port uses typed classes with explicit `clone`/`merge` helpers.

/// A map of capture-id (`"0"`, `"1"`, ...) to the rule describing that capture.
typedef RawCaptures = Map<String, RawRule>;

/// A single rule node from a raw grammar's `patterns`/`repository`, e.g. a
/// `match` rule or a `begin`/`end` (or `begin`/`while`) rule. Mirrors
/// vscode-textmate's `IRawRule`.
class RawRule {
  /// Creates a [RawRule]; all fields are optional and correspond directly
  /// to the matching keys in a `.tmLanguage.json` rule object.
  RawRule({
    this.id,
    this.include,
    this.name,
    this.contentName,
    this.match,
    this.captures,
    this.begin,
    this.beginCaptures,
    this.end,
    this.endCaptures,
    this.whilePattern,
    this.whileCaptures,
    this.patterns,
    this.repository,
    this.applyEndPatternLast,
  });

  /// Internal, assigned during compilation (not part of the grammar file).
  int? id;

  /// A reference to another rule: `#name` (local [repository]), `$self`,
  /// `$base`, or an external grammar's scope name to include.
  String? include;

  /// The scope name pushed onto the token's scope stack for this rule's
  /// entire match.
  String? name;

  /// The scope name pushed only for the content between a `begin`/`end`
  /// pair, excluding the begin and end matches themselves.
  String? contentName;

  /// A single-line regular expression that matches this rule directly.
  /// Mutually exclusive with [begin]/[end]/[whilePattern].
  String? match;

  /// Per-capture-group scope names for [match].
  RawCaptures? captures;

  /// The regular expression that starts a multi-line `begin`/`end` (or
  /// `begin`/`while`) rule.
  String? begin;

  /// Per-capture-group scope names for [begin].
  RawCaptures? beginCaptures;

  /// The regular expression that closes a `begin`/`end` rule. May reference
  /// capture groups from [begin] (e.g. `\1`).
  String? end;

  /// Per-capture-group scope names for [end].
  RawCaptures? endCaptures;

  /// The regular expression tested at the start of each subsequent line to
  /// decide whether a `begin`/`while` rule keeps consuming lines. Stored
  /// under the JSON key `while`.
  String? whilePattern;

  /// Per-capture-group scope names for [whilePattern].
  RawCaptures? whileCaptures;

  /// Nested rules considered at this point in the grammar, tried in order.
  List<RawRule>? patterns;

  /// Rules local to this node, addressable from [patterns]/[include] via
  /// `#name`.
  RawRepository? repository;

  /// When `true`, [end] is tested after [patterns] instead of before, so
  /// nested patterns get first chance to match at the same position.
  bool? applyEndPatternLast;

  /// Deserializes a [RawRule] from its decoded `.tmLanguage.json` object.
  static RawRule fromJson(Map<String, dynamic> json) {
    return RawRule(
      include: json['include'] as String?,
      name: json['name'] as String?,
      contentName: json['contentName'] as String?,
      match: json['match'] as String?,
      captures: _capturesFromJson(json['captures']),
      begin: json['begin'] as String?,
      beginCaptures: _capturesFromJson(json['beginCaptures']),
      end: json['end'] as String?,
      endCaptures: _capturesFromJson(json['endCaptures']),
      whilePattern: json['while'] as String?,
      whileCaptures: _capturesFromJson(json['whileCaptures']),
      patterns: _patternsFromJson(json['patterns']),
      repository: json['repository'] == null
          ? null
          : RawRepository.fromJson(json['repository'] as Map<String, dynamic>),
      applyEndPatternLast: _asBool(json['applyEndPatternLast']),
    );
  }

  /// Returns a deep copy of this rule, including nested [patterns],
  /// [repository], and capture maps.
  RawRule clone() {
    return RawRule(
      id: id,
      include: include,
      name: name,
      contentName: contentName,
      match: match,
      captures: _cloneCaptures(captures),
      begin: begin,
      beginCaptures: _cloneCaptures(beginCaptures),
      end: end,
      endCaptures: _cloneCaptures(endCaptures),
      whilePattern: whilePattern,
      whileCaptures: _cloneCaptures(whileCaptures),
      patterns: patterns == null
          ? null
          : [for (final p in patterns!) p.clone()],
      repository: repository?.clone(),
      applyEndPatternLast: applyEndPatternLast,
    );
  }
}

RawCaptures? _capturesFromJson(dynamic json) {
  if (json is! Map) return null;
  final result = <String, RawRule>{};
  json.forEach((key, value) {
    final k = key.toString();
    if (k == r'$vscodeTextmateLocation') return;
    if (value is Map) {
      result[k] = RawRule.fromJson(value.cast<String, dynamic>());
    }
  });
  return result;
}

List<RawRule>? _patternsFromJson(dynamic json) {
  if (json is! List) return null;
  return [
    for (final item in json)
      if (item is Map) RawRule.fromJson(item.cast<String, dynamic>()),
  ];
}

RawCaptures? _cloneCaptures(RawCaptures? captures) {
  if (captures == null) return null;
  return {for (final e in captures.entries) e.key: e.value.clone()};
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  return null;
}

/// A grammar's `repository` plus the special `$self` / `$base` entries.
class RawRepository {
  /// Creates a [RawRepository], optionally seeded from an existing [map].
  RawRepository([Map<String, RawRule>? map]) : _map = map ?? {};

  final Map<String, RawRule> _map;

  /// Deserializes a [RawRepository] from a grammar's decoded `repository`
  /// JSON object.
  static RawRepository fromJson(Map<String, dynamic> json) {
    final map = <String, RawRule>{};
    json.forEach((key, value) {
      if (key == r'$vscodeTextmateLocation') return;
      if (value is Map) {
        map[key] = RawRule.fromJson(value.cast<String, dynamic>());
      }
    });
    return RawRepository(map);
  }

  /// Looks up the rule named [key] in this repository.
  RawRule? operator [](String key) => _map[key];

  /// Adds or replaces the rule named [key].
  void operator []=(String key, RawRule value) => _map[key] = value;

  /// Whether this repository contains a rule named [key].
  bool has(String key) => _map.containsKey(key);

  /// The special `$self` entry: a synthetic rule wrapping the grammar's own
  /// top-level [RawGrammar.patterns], used when a rule includes `$self`.
  RawRule? get self => _map[r'$self'];

  /// Sets or removes (when `null`) the [self] entry.
  set self(RawRule? value) {
    if (value == null) {
      _map.remove(r'$self');
    } else {
      _map[r'$self'] = value;
    }
  }

  /// The special `$base` entry: the root grammar of the current
  /// tokenization, used when a rule includes `$base`. Defaults to [self]
  /// unless an embedding grammar overrides it.
  RawRule? get base => _map[r'$base'];

  /// Sets or removes (when `null`) the [base] entry.
  set base(RawRule? value) {
    if (value == null) {
      _map.remove(r'$base');
    } else {
      _map[r'$base'] = value;
    }
  }

  /// Returns a deep copy of this repository.
  RawRepository clone() {
    return RawRepository({
      for (final e in _map.entries) e.key: e.value.clone(),
    });
  }

  /// Returns a new repository with [this] entries overlaid by [other] entries
  /// (mirrors `mergeObjects({}, repository, desc.repository)`).
  RawRepository mergedWith(RawRepository? other) {
    final map = <String, RawRule>{..._map};
    if (other != null) {
      map.addAll(other._map);
    }
    return RawRepository(map);
  }
}

/// A raw grammar (`.tmLanguage.json`).
class RawGrammar {
  /// Creates a [RawGrammar]; [scopeName] and [patterns] are required, the
  /// rest mirror the remaining optional keys of a `.tmLanguage.json` file.
  RawGrammar({
    required this.scopeName,
    required this.patterns,
    RawRepository? repository,
    this.injections,
    this.injectionSelector,
    this.name,
    this.fileTypes,
    this.firstLineMatch,
  }) : repository = repository ?? RawRepository();

  /// This grammar's local rule repository, addressable via `#name`
  /// includes. Mutable so [RawRepository.self]/[RawRepository.base]
  /// entries can be installed during grammar initialization.
  RawRepository repository;

  /// This grammar's unique TextMate scope name, e.g. `source.dart`.
  final String scopeName;

  /// The top-level rules applied at the start of tokenization.
  List<RawRule> patterns;

  /// Injection rules keyed by selector expression, merged into matching
  /// scopes anywhere in the document regardless of nesting.
  Map<String, RawRule>? injections;

  /// When this grammar is itself injected into other grammars, the
  /// selector describing which scopes it applies to.
  String? injectionSelector;

  /// A human-readable display name for the grammar (not a scope name).
  String? name;

  /// File extensions associated with this grammar; informational only.
  List<String>? fileTypes;

  /// A regular expression matched against a file's first line, used to
  /// help auto-detect this grammar; informational only.
  String? firstLineMatch;

  /// Deserializes a [RawGrammar] from a decoded `.tmLanguage.json` object.
  static RawGrammar fromJson(Map<String, dynamic> json) {
    Map<String, RawRule>? injections;
    final rawInjections = json['injections'];
    if (rawInjections is Map) {
      injections = <String, RawRule>{};
      rawInjections.forEach((key, value) {
        if (value is Map) {
          injections![key.toString()] = RawRule.fromJson(
            value.cast<String, dynamic>(),
          );
        }
      });
    }

    return RawGrammar(
      scopeName: json['scopeName'] as String,
      patterns: _patternsFromJson(json['patterns']) ?? [],
      repository: json['repository'] == null
          ? RawRepository()
          : RawRepository.fromJson(json['repository'] as Map<String, dynamic>),
      injections: injections,
      injectionSelector: json['injectionSelector'] as String?,
      name: json['name'] as String?,
      fileTypes: (json['fileTypes'] as List?)?.cast<String>(),
      firstLineMatch: json['firstLineMatch'] as String?,
    );
  }

  /// Returns a deep copy of this grammar, including its repository,
  /// patterns, and injections.
  RawGrammar clone() {
    Map<String, RawRule>? clonedInjections;
    if (injections != null) {
      clonedInjections = {
        for (final e in injections!.entries) e.key: e.value.clone(),
      };
    }
    return RawGrammar(
      scopeName: scopeName,
      patterns: [for (final p in patterns) p.clone()],
      repository: repository.clone(),
      injections: clonedInjections,
      injectionSelector: injectionSelector,
      name: name,
      fileTypes: fileTypes == null ? null : [...fileTypes!],
      firstLineMatch: firstLineMatch,
    );
  }
}
