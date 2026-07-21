// Basic scope attributes (language id + standard token type), ported from
// `vscode-textmate`'s `grammar/basicScopesAttributeProvider.ts`.

import 'encoded_token_metadata.dart';
import 'utils.dart';

/// Maps embedded-language scope names to language ids.
typedef EmbeddedLanguagesMap = Map<String, int>;

class BasicScopeAttributes {
  const BasicScopeAttributes(this.languageId, this.tokenType);

  final int languageId;
  final int tokenType;
}

class BasicScopeAttributesProvider {
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

  BasicScopeAttributes getDefaultAttributes() => _defaultAttributes;

  late final CachedFn<String, BasicScopeAttributes> _getBasicScopeAttributes =
      CachedFn((scopeName) {
        final languageId = _scopeToLanguage(scopeName);
        final standardTokenType = _toStandardTokenType(scopeName);
        return BasicScopeAttributes(languageId, standardTokenType);
      });

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
