// Include-reference parsing, ported from the relevant part of
// `vscode-textmate`'s `grammar/grammarDependencies.ts`.

enum IncludeReferenceKind {
  base,
  self,
  relativeReference,
  topLevelReference,
  topLevelRepositoryReference,
}

class IncludeReference {
  IncludeReference(this.kind, {this.scopeName, this.ruleName});

  final IncludeReferenceKind kind;
  final String? scopeName;
  final String? ruleName;
}

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
