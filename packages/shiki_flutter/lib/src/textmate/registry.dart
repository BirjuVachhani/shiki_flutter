// Grammar registry, ported from `vscode-textmate`'s `registry.ts`.

import '../onig/onig.dart';
import 'basic_scopes.dart';
import 'grammar.dart';
import 'raw_grammar.dart';
import 'theme.dart';

/// A synchronous registry of raw grammars and the active theme.
class SyncRegistry implements GrammarAndThemeRepository {
  SyncRegistry(this._theme, this._onigLib);

  final Map<String, Grammar> _grammars = {};
  final Map<String, RawGrammar> _rawGrammars = {};
  final Map<String, List<String>> _injectionGrammars = {};
  Theme _theme;
  final ShikiHighlighterEngine _onigLib;

  void setTheme(Theme theme) {
    _theme = theme;
  }

  List<String> getColorMap() => _theme.getColorMap();

  /// Adds [grammar] to the registry.
  void addGrammar(RawGrammar grammar, [List<String>? injectionScopeNames]) {
    _rawGrammars[grammar.scopeName] = grammar;
    if (injectionScopeNames != null) {
      _injectionGrammars[grammar.scopeName] = injectionScopeNames;
    }
  }

  @override
  RawGrammar? lookup(String scopeName) => _rawGrammars[scopeName];

  @override
  List<String>? injections(String targetScope) =>
      _injectionGrammars[targetScope];

  @override
  StyleAttributes getDefaults() => _theme.getDefaults();

  @override
  StyleAttributes? themeMatch(ScopeStack scopePath) => _theme.match(scopePath);

  /// Looks up (and lazily instantiates) a grammar for [scopeName].
  Grammar? grammarForScopeName(
    String scopeName,
    int initialLanguage,
    EmbeddedLanguagesMap? embeddedLanguages,
    TokenTypeMap? tokenTypes,
    BalancedBracketSelectors? balancedBracketSelectors,
  ) {
    if (!_grammars.containsKey(scopeName)) {
      final rawGrammar = _rawGrammars[scopeName];
      if (rawGrammar == null) return null;
      _grammars[scopeName] = createGrammar(
        scopeName,
        rawGrammar,
        initialLanguage,
        embeddedLanguages,
        tokenTypes,
        balancedBracketSelectors,
        this,
        _onigLib,
      );
    }
    return _grammars[scopeName];
  }
}
