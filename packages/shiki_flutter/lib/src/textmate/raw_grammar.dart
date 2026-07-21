// The raw grammar data model (the deserialized form of a `.tmLanguage.json`
// file), ported from `vscode-textmate`'s `rawGrammar.ts`.
//
// Unlike the TypeScript original, which manipulates plain objects dynamically,
// this port uses typed classes with explicit `clone`/`merge` helpers.

/// A map of capture-id (`"0"`, `"1"`, ...) to the rule describing that capture.
typedef RawCaptures = Map<String, RawRule>;

class RawRule {
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

  String? include;
  String? name;
  String? contentName;
  String? match;
  RawCaptures? captures;
  String? begin;
  RawCaptures? beginCaptures;
  String? end;
  RawCaptures? endCaptures;
  String? whilePattern;
  RawCaptures? whileCaptures;
  List<RawRule>? patterns;
  RawRepository? repository;
  bool? applyEndPatternLast;

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
  RawRepository([Map<String, RawRule>? map]) : _map = map ?? {};

  final Map<String, RawRule> _map;

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

  RawRule? operator [](String key) => _map[key];
  void operator []=(String key, RawRule value) => _map[key] = value;
  bool has(String key) => _map.containsKey(key);

  RawRule? get self => _map[r'$self'];
  set self(RawRule? value) {
    if (value == null) {
      _map.remove(r'$self');
    } else {
      _map[r'$self'] = value;
    }
  }

  RawRule? get base => _map[r'$base'];
  set base(RawRule? value) {
    if (value == null) {
      _map.remove(r'$base');
    } else {
      _map[r'$base'] = value;
    }
  }

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

  RawRepository repository;
  final String scopeName;
  List<RawRule> patterns;
  Map<String, RawRule>? injections;
  String? injectionSelector;
  String? name;
  List<String>? fileTypes;
  String? firstLineMatch;

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
