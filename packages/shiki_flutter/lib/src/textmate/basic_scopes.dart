// Basic scope attributes (language id + standard token type), ported from
// `vscode-textmate`'s `grammar/basicScopesAttributeProvider.ts`.

import 'encoded_token_metadata.dart';
import 'utils.dart';

/// Maps embedded-language scope names to language ids.
typedef EmbeddedLanguagesMap = Map<String, int>;

/// The language id and [StandardTokenType] implied by a scope name alone,
/// before any theme or grammar rule is applied.
class BasicScopeAttributes {
  /// Creates a [BasicScopeAttributes] pairing [languageId] with [tokenType].
  const BasicScopeAttributes(this.languageId, this.tokenType);

  /// The embedded language id for this scope, or `0` if none applies.
  final int languageId;

  /// A [StandardTokenType] (encoded as [OptionalStandardTokenType]) implied
  /// by the scope name, e.g. `comment` for scopes containing `comment`.
  final int tokenType;
}

/// Derives [BasicScopeAttributes] for a scope name by matching it against
/// the grammar's embedded-language map and a fixed set of well-known scope
/// substrings (`comment`, `string`, `regex`, `meta.embedded`). Results are
/// memoised since scope names repeat heavily during tokenization.
class BasicScopeAttributesProvider {
  /// Creates a provider whose default attributes use [initialLanguageId],
  /// with [embeddedLanguages] used to resolve language ids for included
  /// embedded-language scopes.
  BasicScopeAttributesProvider(
    int initialLanguageId,
    EmbeddedLanguagesMap? embeddedLanguages,
  ) : _defaultAttributes = BasicScopeAttributes(
        initialLanguageId,
        OptionalStandardTokenType.notSet,
      ),
      _embeddedLanguagesMatcher = _ScopeMatcher(
        (embeddedLanguages ?? {}).entries.toList(),
      );

  final BasicScopeAttributes _defaultAttributes;
  final _ScopeMatcher _embeddedLanguagesMatcher;

  static const _nullScopeMetadata = BasicScopeAttributes(0, 0);

  /// The attributes used before any scope-specific match applies: the
  /// grammar's initial language id and no standard token type.
  BasicScopeAttributes getDefaultAttributes() => _defaultAttributes;

  late final CachedFn<String, BasicScopeAttributes> _getBasicScopeAttributes =
      CachedFn((scopeName) {
        final languageId = _scopeToLanguage(scopeName);
        final standardTokenType = _toStandardTokenType(scopeName);
        return BasicScopeAttributes(languageId, standardTokenType);
      });

  /// Returns the (cached) [BasicScopeAttributes] for [scopeName], or the
  /// null attributes (`languageId: 0, tokenType: 0`) when `scopeName` is
  /// `null`.
  BasicScopeAttributes getBasicScopeAttributes(String? scopeName) {
    if (scopeName == null) return _nullScopeMetadata;
    return _getBasicScopeAttributes.get(scopeName);
  }

  int _scopeToLanguage(String scope) =>
      _embeddedLanguagesMatcher.match(scope) ?? 0;

  static final RegExp _standardTokenTypeRegExp = RegExp(
    r'\b(comment|string|regex|meta\.embedded)\b',
  );

  int _toStandardTokenType(String scopeName) {
    final m = _standardTokenTypeRegExp.firstMatch(scopeName);
    if (m == null) return OptionalStandardTokenType.notSet;
    switch (m[1]) {
      case 'comment':
        return OptionalStandardTokenType.comment;
      case 'string':
        return OptionalStandardTokenType.string;
      case 'regex':
        return OptionalStandardTokenType.regEx;
      case 'meta.embedded':
        return OptionalStandardTokenType.other;
    }
    throw StateError('Unexpected match for standard token type!');
  }
}

class _ScopeMatcher {
  _ScopeMatcher(List<MapEntry<String, int>> values) {
    if (values.isEmpty) {
      _values = null;
      _scopesRegExp = null;
    } else {
      _values = {for (final e in values) e.key: e.value};
      final escapedScopes = values
          .map((e) => escapeRegExpCharacters(e.key))
          .toList();
      escapedScopes.sort();
      final reversed = escapedScopes.reversed.toList(); // longest scope first
      _scopesRegExp = RegExp('^((${reversed.join(")|(")}))(\$|\\.)');
    }
  }

  Map<String, int>? _values;
  RegExp? _scopesRegExp;

  int? match(String scope) {
    if (_scopesRegExp == null) return null;
    final m = _scopesRegExp!.firstMatch(scope);
    if (m == null) return null;
    return _values![m[1]];
  }
}
