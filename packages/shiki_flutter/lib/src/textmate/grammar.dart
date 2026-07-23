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
  /// Creates a token spanning `[startIndex, endIndex)` with the given
  /// [scopes] stack (outermost first).
  Token(this.startIndex, this.endIndex, this.scopes);

  /// Start offset (inclusive) into the tokenized line, in UTF-16 code units.
  int startIndex;

  /// End offset (exclusive) into the tokenized line, in UTF-16 code units.
  final int endIndex;

  /// The full scope stack active at this token, outermost first.
  final List<String> scopes;

  @override
  String toString() => '($startIndex-$endIndex ${scopes.join(', ')})';
}

/// The result of [Grammar.tokenizeLine]: per-token [Token]s plus the state
/// to feed into the next line.
class TokenizeLineResult {
  /// Creates a tokenize-line result.
  TokenizeLineResult(this.tokens, this.ruleStack, this.stoppedEarly);

  /// The tokens produced for the line.
  final List<Token> tokens;

  /// The tokenizer state to pass as `prevState` for the following line.
  final StateStack ruleStack;

  /// Whether tokenization stopped early because a `timeLimit` was hit.
  final bool stoppedEarly;
}

/// The result of [Grammar.tokenizeLine2]: a compact binary encoding of
/// tokens plus the state to feed into the next line.
class TokenizeLineResult2 {
  /// Creates a binary tokenize-line result.
  TokenizeLineResult2(this.tokens, this.ruleStack, this.stoppedEarly);

  /// Packed as pairs: [startIndex, metadata, startIndex, metadata, ...].
  final List<int> tokens;

  /// The tokenizer state to pass as `prevState` for the following line.
  final StateStack ruleStack;

  /// Whether tokenization stopped early because a `timeLimit` was hit.
  final bool stoppedEarly;
}

/// Maps a scope selector to a `standard-tokens.json`-style numeric token
/// type override, as configured on a grammar's `tokenTypes`.
typedef TokenTypeMap = Map<String, int>;

/// Resolves scope stacks to styles. Implemented by [Theme] (via
/// `Grammar.themeProvider`).
abstract class ThemeProvider {
  /// Returns the style for [scopePath], or `null` if nothing matches.
  StyleAttributes? themeMatch(ScopeStack scopePath);

  /// The style to use when nothing more specific matches.
  StyleAttributes getDefaults();
}

/// Resolves scope names to other grammars, so grammars can `include` one
/// another and inject into each other via scope-selector injections.
abstract class GrammarRepository {
  /// Returns the raw grammar registered for [scopeName], or `null` if
  /// unknown.
  RawGrammar? lookup(String scopeName);

  /// Returns the scope names of grammars that inject into [scopeName], if
  /// any.
  List<String>? injections(String scopeName);
}

/// A repository that can resolve both included grammars and theme styles;
/// what a [Grammar] needs from its host to tokenize.
abstract class GrammarAndThemeRepository
    implements GrammarRepository, ThemeProvider {}

/// A compiled scope-selector injection: a rule that gets tried against
/// every scope stack, regardless of the grammar's normal include tree.
class Injection {
  /// Creates an injection for [debugSelector], compiled to [matcher], with
  /// its resolved [priority], the [ruleId] to apply, and the [grammar] it
  /// came from.
  Injection(
    this.debugSelector,
    this.matcher,
    this.priority,
    this.ruleId,
    this.grammar,
  );

  /// The raw scope selector this injection was compiled from, for debugging.
  final String debugSelector;

  /// Matches a scope stack (outermost first) against the compiled selector.
  final Matcher<List<String>> matcher;

  /// -1 for 'L', 1 for 'R', 0 default.
  final int priority;

  /// The rule to apply when this injection matches.
  final RuleId ruleId;

  /// The grammar the injected rule belongs to.
  final RawGrammar grammar;
}

/// Constructs a [Grammar] for a top-level scope; a thin wrapper around
/// [Grammar]'s constructor.
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

/// The default `MatcherContext` for scope-selector matching: true if
/// [scopes] contains, in order, a scope matching (equal to, or a
/// dot-suffixed descendant of) each of [identifiers].
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

/// A compiled TextMate grammar: the entry point for tokenizing lines of
/// source text. Mirrors vscode-textmate's `Grammar` class, and implements
/// [GrammarRules] to serve as the rule registry/lookup for its own
/// compiled [Rule]s.
class Grammar implements GrammarRules {
  /// Compiles [grammar] for [_rootScopeName]. [initialLanguage] and
  /// [embeddedLanguages] configure per-scope language ids (for embedded
  /// languages like `<script>` in HTML); [tokenTypes] and
  /// [_balancedBracketSelectors] configure `tokenizeLine2`'s binary token
  /// metadata; [_grammarRepository] resolves `include`d/injected grammars
  /// and theme styles; [_onigLib] provides the regex engine.
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

  /// The repository used to resolve scope stacks to styles.
  ThemeProvider get themeProvider => _grammarRepository;

  /// This grammar's root scope name, e.g. `source.dart`.
  String get name => _rootScopeName;

  /// The balanced-bracket configuration used by `tokenizeLine2`, if any.
  BalancedBracketSelectors? get balancedBracketSelectors =>
      _balancedBracketSelectors;

  @override
  OnigScanner createScanner(List<String> sources) =>
      _onigLib.createScanner(sources);

  /// Wraps [str] for use with the Oniguruma-backed scanner/matcher.
  OnigString createString(String str) => _onigLib.createString(str);

  /// Returns the language id and token type baked into [scope] by this
  /// grammar's `embeddedLanguages`/`tokenTypes` configuration.
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

  /// Returns this grammar's compiled injections (both its own `injections`
  /// and those declared by other grammars targeting it), computing and
  /// caching them on first use.
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

  /// Tokenizes [lineText] into human-readable [Token]s. Pass the previous
  /// line's `ruleStack` as [prevState] (or `null` for the first line); a
  /// nonzero [timeLimit] (in milliseconds) bounds worst-case pathological
  /// regex backtracking, after which [TokenizeLineResult.stoppedEarly] is
  /// set.
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

  /// Like [tokenizeLine] but returns tokens as compact binary-encoded
  /// metadata (see [EncodedTokenMetadata]) instead of [Token] objects.
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

/// Clones [grammar] and wires up its repository's synthetic `self`/`base`
/// entries (used to resolve `$self`/`$base` includes), so it's ready to
/// compile rules against. [base] overrides `$base` for externally-included
/// grammars; the grammar's own `self` is used when `base` is `null`.
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

/// A [ScopeStack] paired with its resolved, merged binary token metadata
/// (see [EncodedTokenMetadata]), so encoded attributes don't have to be
/// recomputed from scratch every time a scope is pushed. Mirrors
/// vscode-textmate's `AttributedScopeStack`.
class AttributedScopeStack {
  AttributedScopeStack._(this.parent, this.scopePath, this.tokenAttributes);

  /// The stack with the innermost scope popped, or `null` at the root.
  final AttributedScopeStack? parent;

  /// The plain scope-name stack this wraps.
  final ScopeStack scopePath;

  /// The merged, binary-encoded token metadata for this stack; see
  /// [EncodedTokenMetadata].
  final int tokenAttributes;

  /// The innermost scope name; delegates to [ScopeStack.scopeName].
  String get scopeName => scopePath.scopeName;

  /// Creates a root stack for [scopeName] with [tokenAttributes] as-is,
  /// without looking up theme/scope metadata (used for [StateStack.nullState]
  /// where no grammar/theme is available yet).
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

  /// Creates a root stack for [scopeName], resolving [grammar]'s scope
  /// metadata and theme style for it and merging them into
  /// [tokenAttributes].
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

  /// Returns this stack's scope names, outermost first; delegates to
  /// [ScopeStack.getSegments].
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

  /// Pushes [scopePath] (a single scope, or several space-separated
  /// scopes, each pushed in turn) onto this stack, merging in each scope's
  /// metadata/theme style along the way. Returns this stack unchanged if
  /// [scopePath] is `null`.
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
  /// Pushes a new frame onto [parent] for the rule [_ruleId], entered at
  /// [enterPos] with anchor position [anchorPos]. Mirrors
  /// vscode-textmate's `StateStackImpl` constructor.
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

  /// The empty initial state, passed as `prevState` to tokenize the very
  /// first line of a document.
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

  /// The enclosing frame, or `null` at the bottom of the stack.
  final StateStack? parent;
  final RuleId _ruleId;
  int _enterPos;
  int _anchorPos;

  /// This frame's distance from the bottom of the stack (`1` for the root
  /// frame).
  final int depth;

  /// Whether this frame's `begin` match consumed the end of the line
  /// (affects whether `\G` can match on the next line).
  final bool beginRuleCapturedEOL;

  /// The (possibly back-reference-resolved) `end` regex source for this
  /// frame's [BeginEndRule], or `null` if not applicable.
  final String? endRule;

  /// The scope stack (with `name` applied) active for this frame.
  final AttributedScopeStack? nameScopesList;

  /// The scope stack (with `contentName` also applied, when inside the
  /// rule's content region) active for this frame.
  final AttributedScopeStack? contentNameScopesList;

  /// Invalidates cached anchor positions through the whole stack (called
  /// when tokenizing a new line, since `\G` positions don't carry over).
  void reset() {
    StateStack? el = this;
    while (el != null) {
      el._enterPos = -1;
      el._anchorPos = -1;
      el = el.parent;
    }
  }

  /// Returns the enclosing frame, i.e. [parent].
  StateStack? pop() => parent;

  /// Returns [parent], or this frame itself if already at the bottom of
  /// the stack (guards against popping past the root).
  StateStack safePop() => parent ?? this;

  /// Pushes a new frame for [ruleId] on top of this one.
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

  /// This frame's `enterPos`: the offset in the line where its rule began
  /// matching, or `-1` if unset/reset for a new line.
  int getEnterPos() => _enterPos;

  /// This frame's `\G` anchor position, or `-1` if unset/reset for a new
  /// line.
  int getAnchorPos() => _anchorPos;

  /// Looks up this frame's compiled rule via [grammar].
  Rule getRule(RuleFactoryHelper grammar) => grammar.getRule(_ruleId);

  /// Returns a copy of this frame with [contentNameScopeStack] substituted
  /// for [contentNameScopesList] (a no-op, returning `this`, if identical).
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

  /// Returns a copy of this frame with [endRule] substituted for the
  /// current `end`/`while` pattern's resolved source (a no-op, returning
  /// `this`, if unchanged); used once back-references in `end`/`while`
  /// have been resolved against a `begin` match.
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

  /// Whether this stack and [other] share a common ancestor frame with the
  /// same `enterPos` and rule id, walking up from each while their
  /// `enterPos`s match; used to detect a `while` clause failing to consume
  /// input (infinite loop guard).
  bool hasSameRuleAs(StateStack other) {
    StateStack? el = this;
    while (el != null && el._enterPos == other._enterPos) {
      if (el._ruleId == other._ruleId) return true;
      el = el.parent;
    }
    return false;
  }
}

/// Which scopes' brackets should be tracked for auto-closing-pair balance
/// detection, driven by a grammar's `balancedBracketSelectors`/
/// `unbalancedBracketSelectors` config. Used only by `tokenizeLine2`'s
/// binary token metadata.
class BalancedBracketSelectors {
  /// Compiles [balancedBracketScopes] and [unbalancedBracketScopes]
  /// selector lists into matchers. A `'*'` entry in
  /// [balancedBracketScopes] means "all scopes" (see [matchesAlways]).
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

  /// Whether every scope counts as balanced-bracket-tracked (a `'*'`
  /// selector with no exclusions), so [match] can be skipped entirely.
  bool get matchesAlways => _allowAny && _unbalancedBracketScopes.isEmpty;

  /// Whether no scope counts as balanced-bracket-tracked, so [match] can
  /// be skipped entirely.
  bool get matchesNever => _balancedBracketScopes.isEmpty && !_allowAny;

  /// Whether [scopes] should have its brackets tracked as balanced:
  /// excluded if any unbalanced selector matches, otherwise included if
  /// any balanced selector (or the `'*'` wildcard) matches.
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

/// Accumulates tokens for one line as the tokenizer scans it, in either
/// [Token] form or (if [_emitBinaryTokens]) packed binary metadata form.
/// Mirrors vscode-textmate's `LineTokens`.
class LineTokens {
  /// Creates a token accumulator for a line of [lineText]. [_emitBinaryTokens]
  /// selects [Token] output vs. packed binary output; [_tokenTypeOverrides]
  /// and [_balancedBracketSelectors] are only consulted in binary mode.
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

  /// Closes out a token ending at [endIndex], using [stack]'s current
  /// content-name scope stack.
  void produce(StateStack stack, int endIndex) {
    produceFromScopes(stack.contentNameScopesList, endIndex);
  }

  /// Closes out a token spanning from the last produced token's end to
  /// [endIndex], with scopes/metadata taken from [scopesList]. A no-op if
  /// the span would be empty (or negative).
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

  /// Finalizes and returns the accumulated [Token]s for the line, dropping
  /// a trailing token for the synthetic newline and normalizing the first
  /// token to start at `0`.
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

  /// Finalizes and returns the accumulated binary token metadata (see
  /// [TokenizeLineResult2.tokens]) for the line, dropping a trailing entry
  /// for the synthetic newline and normalizing the first entry's start
  /// index to `0`.
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
