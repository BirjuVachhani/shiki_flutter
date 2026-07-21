// The grammar interpreter, ported from `vscode-textmate`'s `grammar/grammar.ts`.

import '../onig/onig.dart';
import 'basic_scopes.dart';
import 'encoded_token_metadata.dart';
import 'matcher.dart';
import 'raw_grammar.dart';
import 'rule.dart';
import 'theme.dart';
import 'tokenize_string.dart';

/// A token with its scope stack. Mirrors `IToken`.
class Token {
  Token(this.startIndex, this.endIndex, this.scopes);

  int startIndex;
  final int endIndex;
  final List<String> scopes;

  @override
  String toString() => '($startIndex-$endIndex ${scopes.join(', ')})';
}

class TokenizeLineResult {
  TokenizeLineResult(this.tokens, this.ruleStack, this.stoppedEarly);

  final List<Token> tokens;
  final StateStack ruleStack;
  final bool stoppedEarly;
}

class TokenizeLineResult2 {
  TokenizeLineResult2(this.tokens, this.ruleStack, this.stoppedEarly);

  /// Packed as pairs: [startIndex, metadata, startIndex, metadata, ...].
  final List<int> tokens;
  final StateStack ruleStack;
  final bool stoppedEarly;
}

typedef TokenTypeMap = Map<String, int>;

abstract class ThemeProvider {
  StyleAttributes? themeMatch(ScopeStack scopePath);
  StyleAttributes getDefaults();
}

abstract class GrammarRepository {
  RawGrammar? lookup(String scopeName);
  List<String>? injections(String scopeName);
}

abstract class GrammarAndThemeRepository
    implements GrammarRepository, ThemeProvider {}

class Injection {
  Injection(
    this.debugSelector,
    this.matcher,
    this.priority,
    this.ruleId,
    this.grammar,
  );

  final String debugSelector;
  final Matcher<List<String>> matcher;

  /// -1 for 'L', 1 for 'R', 0 default.
  final int priority;
  final RuleId ruleId;
  final RawGrammar grammar;
}

Grammar createGrammar(
  String scopeName,
  RawGrammar grammar,
  int initialLanguage,
  EmbeddedLanguagesMap? embeddedLanguages,
  TokenTypeMap? tokenTypes,
  BalancedBracketSelectors? balancedBracketSelectors,
  GrammarAndThemeRepository grammarRepository,
  ShikiHighlighterEngine onigLib,
) {
  return Grammar(
    scopeName,
    grammar,
    initialLanguage,
    embeddedLanguages,
    tokenTypes,
    balancedBracketSelectors,
    grammarRepository,
    onigLib,
  );
}

void _collectInjections(
  List<Injection> result,
  String selector,
  RawRule rule,
  RuleFactoryHelper ruleFactoryHelper,
  RawGrammar grammar,
) {
  final matchers = createMatchers<List<String>>(selector, nameMatcher);
  final ruleId = RuleFactory.getCompiledRuleId(
    rule,
    ruleFactoryHelper,
    grammar.repository,
  );
  for (final matcher in matchers) {
    result.add(
      Injection(selector, matcher.matcher, matcher.priority, ruleId, grammar),
    );
  }
}

bool nameMatcher(List<String> identifiers, List<String> scopes) {
  if (scopes.length < identifiers.length) return false;
  var lastIndex = 0;
  return identifiers.every((identifier) {
    for (var i = lastIndex; i < scopes.length; i++) {
      if (_scopesAreMatching(scopes[i], identifier)) {
        lastIndex = i + 1;
        return true;
      }
    }
    return false;
  });
}

bool _scopesAreMatching(String thisScopeName, String scopeName) {
  if (thisScopeName.isEmpty) return false;
  if (thisScopeName == scopeName) return true;
  final len = scopeName.length;
  return thisScopeName.length > len &&
      thisScopeName.substring(0, len) == scopeName &&
      thisScopeName[len] == '.';
}

class Grammar implements GrammarRules {
  Grammar(
    this._rootScopeName,
    RawGrammar grammar,
    int initialLanguage,
    EmbeddedLanguagesMap? embeddedLanguages,
    TokenTypeMap? tokenTypes,
    this._balancedBracketSelectors,
    this._grammarRepository,
    this._onigLib,
  ) {
    _basicScopeAttributesProvider = BasicScopeAttributesProvider(
      initialLanguage,
      embeddedLanguages,
    );
    _grammar = initGrammar(grammar, null);

    if (tokenTypes != null) {
      for (final selector in tokenTypes.keys) {
        final matchers = createMatchers<List<String>>(selector, nameMatcher);
        for (final matcher in matchers) {
          _tokenTypeMatchers.add(
            _TokenTypeMatcher(matcher.matcher, tokenTypes[selector]!),
          );
        }
      }
    }
  }

  final String _rootScopeName;
  RuleId _rootId = -1;
  int _lastRuleId = 0;
  final List<Rule?> _ruleId2desc = [null];
  final Map<String, RawGrammar> _includedGrammars = {};
  final GrammarAndThemeRepository _grammarRepository;
  late RawGrammar _grammar;
  List<Injection>? _injections;
  late final BasicScopeAttributesProvider _basicScopeAttributesProvider;
  final List<_TokenTypeMatcher> _tokenTypeMatchers = [];
  final BalancedBracketSelectors? _balancedBracketSelectors;
  final ShikiHighlighterEngine _onigLib;

  ThemeProvider get themeProvider => _grammarRepository;
  String get name => _rootScopeName;
  BalancedBracketSelectors? get balancedBracketSelectors =>
      _balancedBracketSelectors;

  @override
  OnigScanner createScanner(List<String> sources) =>
      _onigLib.createScanner(sources);

  OnigString createString(String str) => _onigLib.createString(str);

  BasicScopeAttributes getMetadataForScope(String scope) =>
      _basicScopeAttributesProvider.getBasicScopeAttributes(scope);

  List<Injection> _doCollectInjections() {
    final result = <Injection>[];
    final scopeName = _rootScopeName;

    RawGrammar? lookup(String s) =>
        s == _rootScopeName ? _grammar : getExternalGrammar(s);

    final grammar = lookup(scopeName);
    if (grammar != null) {
      final rawInjections = grammar.injections;
      if (rawInjections != null) {
        rawInjections.forEach((expression, rule) {
          _collectInjections(result, expression, rule, this, grammar);
        });
      }

      final injectionScopeNames = _grammarRepository.injections(scopeName);
      if (injectionScopeNames != null) {
        for (final injectionScopeName in injectionScopeNames) {
          final injectionGrammar = getExternalGrammar(injectionScopeName);
          if (injectionGrammar != null) {
            final selector = injectionGrammar.injectionSelector;
            if (selector != null) {
              _collectInjections(
                result,
                selector,
                RawRule(
                  patterns: injectionGrammar.patterns,
                  name: injectionGrammar.scopeName,
                ),
                this,
                injectionGrammar,
              );
            }
          }
        }
      }
    }

    result.sort((a, b) => a.priority - b.priority);
    return result;
  }

  List<Injection> getInjections() {
    _injections ??= _doCollectInjections();
    return _injections!;
  }

  @override
  T registerRule<T extends Rule>(T Function(RuleId id) factory) {
    final id = ++_lastRuleId;
    final result = factory(id);
    // Ensure the list is large enough.
    while (_ruleId2desc.length <= id) {
      _ruleId2desc.add(null);
    }
    _ruleId2desc[id] = result;
    return result;
  }

  @override
  Rule getRule(RuleId ruleId) => _ruleId2desc[ruleId]!;

  @override
  Rule? getRuleOrNull(RuleId ruleId) =>
      ruleId >= 0 && ruleId < _ruleId2desc.length ? _ruleId2desc[ruleId] : null;

  @override
  RawGrammar? getExternalGrammar(
    String scopeName, [
    RawRepository? repository,
  ]) {
    if (_includedGrammars.containsKey(scopeName)) {
      return _includedGrammars[scopeName];
    }
    final rawIncludedGrammar = _grammarRepository.lookup(scopeName);
    if (rawIncludedGrammar != null) {
      _includedGrammars[scopeName] = initGrammar(
        rawIncludedGrammar,
        repository?.base,
      );
      return _includedGrammars[scopeName];
    }
    return null;
  }

  TokenizeLineResult tokenizeLine(
    String lineText,
    StateStack? prevState, [
    int timeLimit = 0,
  ]) {
    final r = _tokenize(lineText, prevState, false, timeLimit);
    return TokenizeLineResult(
      r.lineTokens.getResult(r.ruleStack, r.lineLength),
      r.ruleStack,
      r.stoppedEarly,
    );
  }

  TokenizeLineResult2 tokenizeLine2(
    String lineText,
    StateStack? prevState, [
    int timeLimit = 0,
  ]) {
    final r = _tokenize(lineText, prevState, true, timeLimit);
    return TokenizeLineResult2(
      r.lineTokens.getBinaryResult(r.ruleStack, r.lineLength),
      r.ruleStack,
      r.stoppedEarly,
    );
  }

  _TokenizeResult _tokenize(
    String lineText,
    StateStack? prevState,
    bool emitBinaryTokens,
    int timeLimit,
  ) {
    if (_rootId == -1) {
      _rootId = RuleFactory.getCompiledRuleId(
        _grammar.repository.self!,
        this,
        _grammar.repository,
      );
      getInjections();
    }

    bool isFirstLine;
    StateStack state;
    if (prevState == null || identical(prevState, StateStack.nullState)) {
      isFirstLine = true;
      final rawDefaultMetadata = _basicScopeAttributesProvider
          .getDefaultAttributes();
      final defaultStyle = themeProvider.getDefaults();
      final defaultMetadata = EncodedTokenMetadata.set(
        0,
        rawDefaultMetadata.languageId,
        rawDefaultMetadata.tokenType,
        null,
        defaultStyle.fontStyle,
        defaultStyle.foregroundId,
        defaultStyle.backgroundId,
      );

      final rootScopeName = getRule(_rootId).getName(null, null);

      AttributedScopeStack scopeList;
      if (rootScopeName != null) {
        scopeList = AttributedScopeStack.createRootAndLookUpScopeName(
          rootScopeName,
          defaultMetadata,
          this,
        );
      } else {
        scopeList = AttributedScopeStack.createRoot('unknown', defaultMetadata);
      }

      state = StateStack(
        null,
        _rootId,
        -1,
        -1,
        false,
        null,
        scopeList,
        scopeList,
      );
    } else {
      isFirstLine = false;
      prevState.reset();
      state = prevState;
    }

    final line = '$lineText\n';
    final onigLineText = createString(line);
    final lineLength = line.length;
    final lineTokens = LineTokens(
      emitBinaryTokens,
      line,
      _tokenTypeMatchers,
      _balancedBracketSelectors,
    );
    final r = tokenizeString(
      this,
      onigLineText,
      isFirstLine,
      0,
      state,
      lineTokens,
      true,
      timeLimit,
    );

    return _TokenizeResult(lineLength, lineTokens, r.stack, r.stoppedEarly);
  }
}

class _TokenizeResult {
  _TokenizeResult(
    this.lineLength,
    this.lineTokens,
    this.ruleStack,
    this.stoppedEarly,
  );
  final int lineLength;
  final LineTokens lineTokens;
  final StateStack ruleStack;
  final bool stoppedEarly;
}

RawGrammar initGrammar(RawGrammar grammar, RawRule? base) {
  grammar = grammar.clone();
  grammar.repository.self = RawRule(
    patterns: grammar.patterns,
    name: grammar.scopeName,
  );
  grammar.repository.base = base ?? grammar.repository.self;
  return grammar;
}

class _TokenTypeMatcher {
  _TokenTypeMatcher(this.matcher, this.type);
  final Matcher<List<String>> matcher;
  final int type;
}

class AttributedScopeStack {
  AttributedScopeStack._(this.parent, this.scopePath, this.tokenAttributes);

  final AttributedScopeStack? parent;
  final ScopeStack scopePath;
  final int tokenAttributes;

  String get scopeName => scopePath.scopeName;

  static AttributedScopeStack createRoot(
    String scopeName,
    int tokenAttributes,
  ) {
    return AttributedScopeStack._(
      null,
      ScopeStack(null, scopeName),
      tokenAttributes,
    );
  }

  static AttributedScopeStack createRootAndLookUpScopeName(
    String scopeName,
    int tokenAttributes,
    Grammar grammar,
  ) {
    final rawRootMetadata = grammar.getMetadataForScope(scopeName);
    final scopePath = ScopeStack(null, scopeName);
    final rootStyle = grammar.themeProvider.themeMatch(scopePath);

    final resolvedTokenAttributes = _mergeAttributes(
      tokenAttributes,
      rawRootMetadata,
      rootStyle,
    );

    return AttributedScopeStack._(null, scopePath, resolvedTokenAttributes);
  }

  List<String> getScopeNames() => scopePath.getSegments();

  @override
  String toString() => getScopeNames().join(' ');

  static int _mergeAttributes(
    int existingTokenAttributes,
    BasicScopeAttributes basicScopeAttributes,
    StyleAttributes? styleAttributes,
  ) {
    var fontStyle = FontStyle.notSet;
    var foreground = 0;
    var background = 0;

    if (styleAttributes != null) {
      fontStyle = styleAttributes.fontStyle;
      foreground = styleAttributes.foregroundId;
      background = styleAttributes.backgroundId;
    }

    return EncodedTokenMetadata.set(
      existingTokenAttributes,
      basicScopeAttributes.languageId,
      basicScopeAttributes.tokenType,
      null,
      fontStyle,
      foreground,
      background,
    );
  }

  AttributedScopeStack pushAttributed(String? scopePath, Grammar grammar) {
    if (scopePath == null) return this;
    if (!scopePath.contains(' ')) {
      return _pushAttributed(this, scopePath, grammar);
    }
    final scopes = scopePath.split(' ');
    var result = this;
    for (final scope in scopes) {
      result = _pushAttributed(result, scope, grammar);
    }
    return result;
  }

  static AttributedScopeStack _pushAttributed(
    AttributedScopeStack target,
    String scopeName,
    Grammar grammar,
  ) {
    final rawMetadata = grammar.getMetadataForScope(scopeName);
    final newPath = target.scopePath.pushScope(scopeName);
    final scopeThemeMatchResult = grammar.themeProvider.themeMatch(newPath);
    final metadata = _mergeAttributes(
      target.tokenAttributes,
      rawMetadata,
      scopeThemeMatchResult,
    );
    return AttributedScopeStack._(target, newPath, metadata);
  }
}

/// A "pushed" state on the tokenizer stack (a linked list element).
class StateStack {
  StateStack(
    this.parent,
    this._ruleId,
    int enterPos,
    int anchorPos,
    this.beginRuleCapturedEOL,
    this.endRule,
    this.nameScopesList,
    this.contentNameScopesList,
  ) : _enterPos = enterPos,
      _anchorPos = anchorPos,
      depth = parent != null ? parent.depth + 1 : 1;

  static final StateStack nullState = StateStack(
    null,
    0,
    0,
    0,
    false,
    null,
    null,
    null,
  );

  final StateStack? parent;
  final RuleId _ruleId;
  int _enterPos;
  int _anchorPos;
  final int depth;
  final bool beginRuleCapturedEOL;
  final String? endRule;
  final AttributedScopeStack? nameScopesList;
  final AttributedScopeStack? contentNameScopesList;

  void reset() {
    StateStack? el = this;
    while (el != null) {
      el._enterPos = -1;
      el._anchorPos = -1;
      el = el.parent;
    }
  }

  StateStack? pop() => parent;

  StateStack safePop() => parent ?? this;

  StateStack push(
    RuleId ruleId,
    int enterPos,
    int anchorPos,
    bool beginRuleCapturedEOL,
    String? endRule,
    AttributedScopeStack? nameScopesList,
    AttributedScopeStack? contentNameScopesList,
  ) {
    return StateStack(
      this,
      ruleId,
      enterPos,
      anchorPos,
      beginRuleCapturedEOL,
      endRule,
      nameScopesList,
      contentNameScopesList,
    );
  }

  int getEnterPos() => _enterPos;
  int getAnchorPos() => _anchorPos;

  Rule getRule(RuleFactoryHelper grammar) => grammar.getRule(_ruleId);

  StateStack withContentNameScopesList(
    AttributedScopeStack contentNameScopeStack,
  ) {
    if (identical(contentNameScopesList, contentNameScopeStack)) return this;
    return parent!.push(
      _ruleId,
      _enterPos,
      _anchorPos,
      beginRuleCapturedEOL,
      endRule,
      nameScopesList,
      contentNameScopeStack,
    );
  }

  StateStack withEndRule(String endRule) {
    if (this.endRule == endRule) return this;
    return StateStack(
      parent,
      _ruleId,
      _enterPos,
      _anchorPos,
      beginRuleCapturedEOL,
      endRule,
      nameScopesList,
      contentNameScopesList,
    );
  }

  bool hasSameRuleAs(StateStack other) {
    StateStack? el = this;
    while (el != null && el._enterPos == other._enterPos) {
      if (el._ruleId == other._ruleId) return true;
      el = el.parent;
    }
    return false;
  }
}

class BalancedBracketSelectors {
  BalancedBracketSelectors(
    List<String> balancedBracketScopes,
    List<String> unbalancedBracketScopes,
  ) : _balancedBracketScopes = [],
      _unbalancedBracketScopes = [] {
    for (final selector in balancedBracketScopes) {
      if (selector == '*') {
        _allowAny = true;
      } else {
        for (final m in createMatchers<List<String>>(selector, nameMatcher)) {
          _balancedBracketScopes.add(m.matcher);
        }
      }
    }
    for (final selector in unbalancedBracketScopes) {
      for (final m in createMatchers<List<String>>(selector, nameMatcher)) {
        _unbalancedBracketScopes.add(m.matcher);
      }
    }
  }

  final List<Matcher<List<String>>> _balancedBracketScopes;
  final List<Matcher<List<String>>> _unbalancedBracketScopes;
  bool _allowAny = false;

  bool get matchesAlways => _allowAny && _unbalancedBracketScopes.isEmpty;
  bool get matchesNever => _balancedBracketScopes.isEmpty && !_allowAny;

  bool match(List<String> scopes) {
    for (final excluder in _unbalancedBracketScopes) {
      if (excluder(scopes)) return false;
    }
    for (final includer in _balancedBracketScopes) {
      if (includer(scopes)) return true;
    }
    return _allowAny;
  }
}

class LineTokens {
  LineTokens(
    this._emitBinaryTokens,
    String lineText,
    this._tokenTypeOverrides,
    this._balancedBracketSelectors,
  );

  final bool _emitBinaryTokens;
  final List<Token> _tokens = [];
  final List<int> _binaryTokens = [];
  int _lastTokenEndIndex = 0;
  final List<_TokenTypeMatcher> _tokenTypeOverrides;
  final BalancedBracketSelectors? _balancedBracketSelectors;

  void produce(StateStack stack, int endIndex) {
    produceFromScopes(stack.contentNameScopesList, endIndex);
  }

  void produceFromScopes(AttributedScopeStack? scopesList, int endIndex) {
    if (_lastTokenEndIndex >= endIndex) return;

    if (_emitBinaryTokens) {
      var metadata = scopesList?.tokenAttributes ?? 0;
      var containsBalancedBrackets = false;
      if (_balancedBracketSelectors?.matchesAlways ?? false) {
        containsBalancedBrackets = true;
      }

      if (_tokenTypeOverrides.isNotEmpty ||
          (_balancedBracketSelectors != null &&
              !_balancedBracketSelectors.matchesAlways &&
              !_balancedBracketSelectors.matchesNever)) {
        final scopes = scopesList?.getScopeNames() ?? [];
        for (final tokenType in _tokenTypeOverrides) {
          if (tokenType.matcher(scopes)) {
            metadata = EncodedTokenMetadata.set(
              metadata,
              0,
              toOptionalTokenType(tokenType.type),
              null,
              FontStyle.notSet,
              0,
              0,
            );
          }
        }
        if (_balancedBracketSelectors != null) {
          containsBalancedBrackets = _balancedBracketSelectors.match(scopes);
        }
      }

      if (containsBalancedBrackets) {
        metadata = EncodedTokenMetadata.set(
          metadata,
          0,
          OptionalStandardTokenType.notSet,
          containsBalancedBrackets,
          FontStyle.notSet,
          0,
          0,
        );
      }

      if (_binaryTokens.isNotEmpty && _binaryTokens.last == metadata) {
        _lastTokenEndIndex = endIndex;
        return;
      }

      _binaryTokens.add(_lastTokenEndIndex);
      _binaryTokens.add(metadata);
      _lastTokenEndIndex = endIndex;
      return;
    }

    final scopes = scopesList?.getScopeNames() ?? [];
    _tokens.add(Token(_lastTokenEndIndex, endIndex, scopes));
    _lastTokenEndIndex = endIndex;
  }

  List<Token> getResult(StateStack stack, int lineLength) {
    if (_tokens.isNotEmpty && _tokens.last.startIndex == lineLength - 1) {
      _tokens.removeLast();
    }
    if (_tokens.isEmpty) {
      _lastTokenEndIndex = -1;
      produce(stack, lineLength);
      _tokens.last.startIndex = 0;
    }
    return _tokens;
  }

  List<int> getBinaryResult(StateStack stack, int lineLength) {
    if (_binaryTokens.isNotEmpty &&
        _binaryTokens[_binaryTokens.length - 2] == lineLength - 1) {
      _binaryTokens.removeLast();
      _binaryTokens.removeLast();
    }
    if (_binaryTokens.isEmpty) {
      _lastTokenEndIndex = -1;
      produce(stack, lineLength);
      _binaryTokens[_binaryTokens.length - 2] = 0;
    }
    return List<int>.from(_binaryTokens);
  }
}
