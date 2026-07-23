// Include-reference parsing, ported from the relevant part of
// `vscode-textmate`'s `grammar/grammarDependencies.ts`.

/// The shape of an `include` string, as classified by [parseInclude].
enum IncludeReferenceKind {
  /// `$base`: the root grammar of the current tokenization.
  base,

  /// `$self`: this grammar's own top-level patterns.
  self,

  /// `#name`: a rule in the current grammar's repository.
  relativeReference,

  /// `scopeName`: another grammar's top-level patterns.
  topLevelReference,

  /// `scopeName#name`: a named rule in another grammar's repository.
  topLevelRepositoryReference,
}

/// A parsed `include` string, identifying which grammar/rule it points to.
class IncludeReference {
  /// Creates an [IncludeReference] of the given [kind], with [scopeName]
  /// and/or [ruleName] set as applicable to that kind.
  IncludeReference(this.kind, {this.scopeName, this.ruleName});

  /// Which form of include this is.
  final IncludeReferenceKind kind;

  /// The referenced grammar's scope name, for [IncludeReferenceKind.topLevelReference]
  /// and [IncludeReferenceKind.topLevelRepositoryReference].
  final String? scopeName;

  /// The referenced repository rule's name, for
  /// [IncludeReferenceKind.relativeReference] and
  /// [IncludeReferenceKind.topLevelRepositoryReference].
  final String? ruleName;
}

/// Parses a raw `include` string (from [RawRule.include]) into a structured
/// [IncludeReference].
IncludeReference parseInclude(String include) {
  if (include == r'$base') {
    return IncludeReference(IncludeReferenceKind.base);
  } else if (include == r'$self') {
    return IncludeReference(IncludeReferenceKind.self);
  }

  final indexOfSharp = include.indexOf('#');
  if (indexOfSharp == -1) {
    return IncludeReference(
      IncludeReferenceKind.topLevelReference,
      scopeName: include,
    );
  } else if (indexOfSharp == 0) {
    return IncludeReference(
      IncludeReferenceKind.relativeReference,
      ruleName: include.substring(1),
    );
  } else {
    return IncludeReference(
      IncludeReferenceKind.topLevelRepositoryReference,
      scopeName: include.substring(0, indexOfSharp),
      ruleName: include.substring(indexOfSharp + 1),
    );
  }
}
