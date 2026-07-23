// Grammar rule compilation, ported from `vscode-textmate`'s `rule.ts`.

import '../onig/onig.dart';
import 'grammar_dependencies.dart';
import 'raw_grammar.dart';
import 'utils.dart';

/// A rule id. Two negative values are reserved as sentinels.
typedef RuleId = int;

/// Indicates that the `end` regexp matched.
const int endRuleId = -1;

/// Indicates that the `while` regexp matched.
const int whileRuleId = -2;

final RegExp _hasBackReferences = RegExp(r'\\(\d+)');
final RegExp _backReferencingEnd = RegExp(r'\\(\d+)');

/// Rule registration and lookup, as needed while compiling [RawRule]s into
/// [Rule]s. Implemented by `Grammar` (see `grammar.dart`).
abstract class RuleFactoryHelper {
  /// Returns the compiled rule for [ruleId]. Throws if it doesn't exist.
  Rule getRule(RuleId ruleId);

  /// Like [getRule] but returns null for rules that are still being constructed
  /// (self-references encountered mid-compilation).
  Rule? getRuleOrNull(RuleId ruleId);

  /// Allocates a new [RuleId] and registers the [Rule] built by [factory]
  /// under it, so self-referential rules can look themselves up by id
  /// while still being constructed.
  T registerRule<T extends Rule>(T Function(RuleId id) factory);

  /// Resolves an `include`d external grammar by [scopeName], optionally
  /// merging in [repository] entries. Returns `null` if unknown.
  RawGrammar? getExternalGrammar(String scopeName, [RawRepository? repository]);
}

/// Creates an [OnigScanner] over a set of regex [sources]; the scanning
/// backend used to find the next matching rule.
abstract class OnigScannerFactory {
  /// Compiles [sources] into a scanner that can find the earliest/leftmost
  /// match among them.
  OnigScanner createScanner(List<String> sources);
}

/// The context passed to compilation: rule lookup + scanner creation.
abstract class GrammarRules implements RuleFactoryHelper, OnigScannerFactory {}

/// A compiled grammar rule. Mirrors vscode-textmate's `Rule` base class;
/// see the concrete subclasses ([MatchRule], [IncludeOnlyRule],
/// [BeginEndRule], [BeginWhileRule], [CaptureRule]) for the actual match
/// behaviors.
abstract class Rule {
  /// Creates a rule with the given [id] and raw `name`/`contentName`
  /// (capture-reference support for both is precomputed here).
  Rule(this.id, String? name, String? contentName)
    : _name = name,
      _nameIsCapturing = RegexSource.hasCaptures(name),
      _contentName = contentName,
      _contentNameIsCapturing = RegexSource.hasCaptures(contentName);

  /// This rule's unique id within its grammar, as assigned by
  /// [RuleFactoryHelper.registerRule].
  final RuleId id;
  final String? _name;
  final bool _nameIsCapturing;
  final String? _contentName;
  final bool _contentNameIsCapturing;

  /// Resolves this rule's `name` scope, substituting `$1`-style capture
  /// references from [captureIndices] against [lineText] if the name is
  /// capturing. Returns the raw name unresolved if [lineText] or
  /// [captureIndices] is `null`.
  String? getName(String? lineText, List<OnigCaptureIndex>? captureIndices) {
    if (!_nameIsCapturing ||
        _name == null ||
        lineText == null ||
        captureIndices == null) {
      return _name;
    }
    return RegexSource.replaceCaptures(_name, lineText, captureIndices);
  }

  /// Resolves this rule's `contentName` scope, substituting `$1`-style
  /// capture references from [captureIndices] against [lineText] if the
  /// content name is capturing.
  String? getContentName(
    String lineText,
    List<OnigCaptureIndex> captureIndices,
  ) {
    if (!_contentNameIsCapturing || _contentName == null) {
      return _contentName;
    }
    return RegexSource.replaceCaptures(_contentName, lineText, captureIndices);
  }

  /// Appends this rule's regex source(s) to [out] so they can be scanned
  /// for together with sibling patterns.
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out);

  /// Compiles (and caches) this rule's patterns into a [CompiledRule],
  /// resolving `\A`/`\G` anchors per [allowA]/[allowG] and substituting
  /// [endRegexSource] for back-referencing end/while patterns.
  CompiledRule compileAG(
    GrammarRules grammar,
    String? endRegexSource,
    bool allowA,
    bool allowG,
  );
}

/// The result of resolving a raw `patterns`/`include` list into compiled
/// rule ids; see [RuleFactory._compilePatterns].
class CompilePatternsResult {
  /// Creates a compile-patterns result.
  CompilePatternsResult(this.patterns, this.hasMissingPatterns);

  /// The successfully resolved child rule ids, in order.
  final List<RuleId> patterns;

  /// Whether one or more raw patterns failed to resolve (e.g. an `include`
  /// pointing at an unknown scope) and were dropped from [patterns].
  final bool hasMissingPatterns;
}

/// A pseudo-rule representing one numbered capture group of a [MatchRule]
/// or [BeginEndRule]/[BeginWhileRule]. Not directly matched against text;
/// used only to assign names/content-names (and optional retokenization)
/// to that capture's text range.
class CaptureRule extends Rule {
  /// Creates a capture rule for the given [name]/`contentName`, optionally
  /// retokenizing the captured text with [retokenizeCapturedWithRuleId].
  CaptureRule(
    super.id,
    super.name,
    super.contentName,
    this.retokenizeCapturedWithRuleId,
  );

  /// 0 means "no retokenization".
  final RuleId retokenizeCapturedWithRuleId;

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    throw StateError('Not supported!');
  }

  @override
  CompiledRule compileAG(
    GrammarRules grammar,
    String? endRegexSource,
    bool allowA,
    bool allowG,
  ) {
    throw StateError('Not supported!');
  }
}

/// A rule that matches a single regex against the current position, with no
/// nested patterns. Mirrors vscode-textmate's `MatchRule`.
class MatchRule extends Rule {
  /// Creates a match rule for the raw [match] regex, with [captures]
  /// indexed by capture group number.
  MatchRule(RuleId id, String? name, String match, this.captures)
    : _match = RegExpSource(match, id),
      super(id, name, null);

  final RegExpSource _match;

  /// Capture rules indexed by capture group number; a `null` entry means
  /// that group has no associated name/content-name.
  final List<CaptureRule?> captures;
  RegExpSourceList? _cachedCompiledPatterns;

  /// The raw `match` regex source, for debugging.
  String get debugMatchRegExp => _match.source;

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    out.push(_match);
  }

  @override
  CompiledRule compileAG(
    GrammarRules grammar,
    String? endRegexSource,
    bool allowA,
    bool allowG,
  ) {
    return _getCachedCompiledPatterns(
      grammar,
    ).compileAG(grammar, allowA, allowG);
  }

  RegExpSourceList _getCachedCompiledPatterns(RuleFactoryHelper grammar) {
    _cachedCompiledPatterns ??= () {
      final list = RegExpSourceList();
      collectPatterns(grammar, list);
      return list;
    }();
    return _cachedCompiledPatterns!;
  }
}

/// A rule with only nested `patterns` and no `begin`/`match` of its own
/// (e.g. the grammar root, or a `{ patterns: [...] }` group). Mirrors
/// vscode-textmate's `IncludeOnlyRule`.
class IncludeOnlyRule extends Rule {
  /// Creates an include-only rule from an already-resolved [patterns]
  /// result.
  IncludeOnlyRule(
    super.id,
    super.name,
    super.contentName,
    CompilePatternsResult patterns,
  ) : patterns = patterns.patterns,
      hasMissingPatterns = patterns.hasMissingPatterns;

  /// The resolved child rule ids to try, in order.
  final List<RuleId> patterns;

  /// Whether one or more child patterns failed to resolve; see
  /// [CompilePatternsResult.hasMissingPatterns].
  final bool hasMissingPatterns;
  RegExpSourceList? _cachedCompiledPatterns;

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    for (final pattern in patterns) {
      grammar.getRule(pattern).collectPatterns(grammar, out);
    }
  }

  @override
  CompiledRule compileAG(
    GrammarRules grammar,
    String? endRegexSource,
    bool allowA,
    bool allowG,
  ) {
    return _getCachedCompiledPatterns(
      grammar,
    ).compileAG(grammar, allowA, allowG);
  }

  RegExpSourceList _getCachedCompiledPatterns(RuleFactoryHelper grammar) {
    _cachedCompiledPatterns ??= () {
      final list = RegExpSourceList();
      collectPatterns(grammar, list);
      return list;
    }();
    return _cachedCompiledPatterns!;
  }
}

/// A rule with a `begin` regex, an `end` regex, and nested `patterns` that
/// apply between them. Mirrors vscode-textmate's `BeginEndRule`.
class BeginEndRule extends Rule {
  /// Creates a begin/end rule. `end` defaults to a regex that never matches
  /// (`'￿'`) when omitted, matching vscode-textmate's behavior for a
  /// missing `end`.
  // ignore: use_super_parameters
  BeginEndRule(
    RuleId id,
    String? name,
    String? contentName,
    String begin,
    this.beginCaptures,
    String? end,
    this.endCaptures,
    bool? applyEndPatternLast,
    CompilePatternsResult patterns,
  ) : _begin = RegExpSource(begin, id),
      _end = RegExpSource(end ?? '￿', -1),
      endHasBackReferences = RegExpSource(end ?? '￿', -1).hasBackReferences,
      applyEndPatternLast = applyEndPatternLast ?? false,
      patterns = patterns.patterns,
      hasMissingPatterns = patterns.hasMissingPatterns,
      super(id, name, contentName);

  final RegExpSource _begin;

  /// Capture rules for the `begin` match, indexed by capture group number.
  final List<CaptureRule?> beginCaptures;
  final RegExpSource _end;

  /// Whether the `end` pattern contains `\1`-style back-references to
  /// `begin`'s captures, requiring it to be recompiled per-match.
  final bool endHasBackReferences;

  /// Capture rules for the `end` match, indexed by capture group number.
  final List<CaptureRule?> endCaptures;

  /// Whether `end` should be tried after (rather than before) the nested
  /// [patterns] when scanning for the next match.
  final bool applyEndPatternLast;

  /// Whether one or more nested patterns failed to resolve; see
  /// [CompilePatternsResult.hasMissingPatterns].
  final bool hasMissingPatterns;

  /// The resolved nested rule ids to try between `begin` and `end`.
  final List<RuleId> patterns;
  RegExpSourceList? _cachedCompiledPatterns;

  /// The raw `begin` regex source, for debugging.
  String get debugBeginRegExp => _begin.source;

  /// The raw `end` regex source, for debugging.
  String get debugEndRegExp => _end.source;

  /// Substitutes `\1`-style back-references in `end` with the text
  /// captured by the `begin` match, given its [captureIndices] against
  /// [lineText].
  String getEndWithResolvedBackReferences(
    String lineText,
    List<OnigCaptureIndex> captureIndices,
  ) => _end.resolveBackReferences(lineText, captureIndices);

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    out.push(_begin);
  }

  @override
  CompiledRule compileAG(
    GrammarRules grammar,
    String? endRegexSource,
    bool allowA,
    bool allowG,
  ) {
    return _getCachedCompiledPatterns(
      grammar,
      endRegexSource,
    ).compileAG(grammar, allowA, allowG);
  }

  RegExpSourceList _getCachedCompiledPatterns(
    RuleFactoryHelper grammar,
    String? endRegexSource,
  ) {
    if (_cachedCompiledPatterns == null) {
      final list = RegExpSourceList();
      for (final pattern in patterns) {
        grammar.getRule(pattern).collectPatterns(grammar, list);
      }
      if (applyEndPatternLast) {
        list.push(_end.hasBackReferences ? _end.clone() : _end);
      } else {
        list.unshift(_end.hasBackReferences ? _end.clone() : _end);
      }
      _cachedCompiledPatterns = list;
    }
    if (_end.hasBackReferences) {
      if (applyEndPatternLast) {
        _cachedCompiledPatterns!.setSource(
          _cachedCompiledPatterns!.length - 1,
          endRegexSource!,
        );
      } else {
        _cachedCompiledPatterns!.setSource(0, endRegexSource!);
      }
    }
    return _cachedCompiledPatterns!;
  }
}

/// A rule with a `begin` regex and a per-line `while` regex that must keep
/// matching for the rule to remain active, with nested `patterns` applying
/// while it does. Mirrors vscode-textmate's `BeginWhileRule`.
class BeginWhileRule extends Rule {
  /// Creates a begin/while rule for the raw `begin` and [whilePattern]
  /// regexes.
  // ignore: use_super_parameters
  BeginWhileRule(
    RuleId id,
    String? name,
    String? contentName,
    String begin,
    this.beginCaptures,
    String whilePattern,
    this.whileCaptures,
    CompilePatternsResult patterns,
  ) : _begin = RegExpSource(begin, id),
      _while = RegExpSource(whilePattern, whileRuleId),
      whileHasBackReferences = RegExpSource(
        whilePattern,
        whileRuleId,
      ).hasBackReferences,
      patterns = patterns.patterns,
      hasMissingPatterns = patterns.hasMissingPatterns,
      super(id, name, contentName);

  final RegExpSource _begin;

  /// Capture rules for the `begin` match, indexed by capture group number.
  final List<CaptureRule?> beginCaptures;

  /// Capture rules for each line's `while` match, indexed by capture group
  /// number.
  final List<CaptureRule?> whileCaptures;
  final RegExpSource _while;

  /// Whether the `while` pattern contains `\1`-style back-references to
  /// `begin`'s captures, requiring it to be recompiled per-match.
  final bool whileHasBackReferences;

  /// Whether one or more nested patterns failed to resolve; see
  /// [CompilePatternsResult.hasMissingPatterns].
  final bool hasMissingPatterns;

  /// The resolved nested rule ids to try while the `while` pattern keeps
  /// matching.
  final List<RuleId> patterns;
  RegExpSourceList? _cachedCompiledPatterns;
  RegExpSourceList? _cachedCompiledWhilePatterns;

  /// Substitutes `\1`-style back-references in `while` with the text
  /// captured by the `begin` match, given its [captureIndices] against
  /// [lineText].
  String getWhileWithResolvedBackReferences(
    String lineText,
    List<OnigCaptureIndex> captureIndices,
  ) => _while.resolveBackReferences(lineText, captureIndices);

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    out.push(_begin);
  }

  @override
  CompiledRule compileAG(
    GrammarRules grammar,
    String? endRegexSource,
    bool allowA,
    bool allowG,
  ) {
    return _getCachedCompiledPatterns(
      grammar,
    ).compileAG(grammar, allowA, allowG);
  }

  RegExpSourceList _getCachedCompiledPatterns(RuleFactoryHelper grammar) {
    _cachedCompiledPatterns ??= () {
      final list = RegExpSourceList();
      for (final pattern in patterns) {
        grammar.getRule(pattern).collectPatterns(grammar, list);
      }
      return list;
    }();
    return _cachedCompiledPatterns!;
  }

  /// Compiles (and caches) the `while` pattern into a [CompiledRule],
  /// analogous to [compileAG] but for `while` instead of `end`.
  CompiledRule compileWhileAG(
    GrammarRules grammar,
    String? endRegexSource,
    bool allowA,
    bool allowG,
  ) {
    return _getCachedCompiledWhilePatterns(
      grammar,
      endRegexSource,
    ).compileAG(grammar, allowA, allowG);
  }

  RegExpSourceList _getCachedCompiledWhilePatterns(
    RuleFactoryHelper grammar,
    String? endRegexSource,
  ) {
    _cachedCompiledWhilePatterns ??= () {
      final list = RegExpSourceList();
      list.push(_while.hasBackReferences ? _while.clone() : _while);
      return list;
    }();
    if (_while.hasBackReferences) {
      _cachedCompiledWhilePatterns!.setSource(0, endRegexSource ?? '￿');
    }
    return _cachedCompiledWhilePatterns!;
  }
}

class _AnchorCache {
  _AnchorCache(this.a0G0, this.a0G1, this.a1G0, this.a1G1);
  final String a0G0;
  final String a0G1;
  final String a1G0;
  final String a1G1;
}

/// A single regexp source with anchor (`\A`/`\G`) and back-reference handling.
class RegExpSource {
  /// Parses [regExpSource], rewriting `\z` to a supported end-of-string
  /// equivalent, detecting `\A`/`\G` anchors (see [hasAnchor]), and
  /// pre-building the anchor-resolved variants if any are present. Matches
  /// found via this source are attributed to [ruleId].
  RegExpSource(String regExpSource, this.ruleId) {
    final len = regExpSource.length;
    var lastPushedPos = 0;
    final output = <String>[];
    var anchor = false;

    for (var pos = 0; pos < len; pos++) {
      final ch = regExpSource[pos];
      if (ch == r'\') {
        if (pos + 1 < len) {
          final nextCh = regExpSource[pos + 1];
          if (nextCh == 'z') {
            output.add(regExpSource.substring(lastPushedPos, pos));
            output.add(r'$(?!\n)(?<!\n)');
            lastPushedPos = pos + 2;
          } else if (nextCh == 'A' || nextCh == 'G') {
            anchor = true;
          }
          pos++;
        }
      }
    }

    hasAnchor = anchor;
    if (lastPushedPos == 0) {
      source = regExpSource;
    } else {
      output.add(regExpSource.substring(lastPushedPos, len));
      source = output.join('');
    }

    if (hasAnchor) {
      _anchorCache = _buildAnchorCache();
    } else {
      _anchorCache = null;
    }
    hasBackReferences = _hasBackReferences.hasMatch(source);
  }

  /// The (possibly `\z`-rewritten) regex source text.
  late String source;

  /// The rule id matches through this source should be attributed to.
  final RuleId ruleId;

  /// Whether [source] contains a `\A` (start-of-line) or `\G` (start-of-scan)
  /// anchor, requiring anchor-specific variants (see [resolveAnchors]).
  late bool hasAnchor;

  /// Whether [source] contains `\1`-style back-references that must be
  /// resolved against captured text before compiling (see
  /// [resolveBackReferences]).
  late bool hasBackReferences;
  _AnchorCache? _anchorCache;

  /// Returns a copy of this source with the same [ruleId].
  RegExpSource clone() => RegExpSource(source, ruleId);

  /// Replaces [source] with [newSource] (a no-op if unchanged), rebuilding
  /// the anchor cache if this source has an anchor.
  void setSource(String newSource) {
    if (source == newSource) return;
    source = newSource;
    if (hasAnchor) {
      _anchorCache = _buildAnchorCache();
    }
  }

  /// Substitutes `\1`-style back-references in [source] with the
  /// (regex-escaped) text captured by [captureIndices] within [lineText].
  String resolveBackReferences(
    String lineText,
    List<OnigCaptureIndex> captureIndices,
  ) {
    final capturedValues = [
      for (final capture in captureIndices)
        // Unset groups carry a sentinel start/end beyond the string; treat them
        // as the empty string (matching JavaScript's lenient `substring`).
        (capture.start >= 0 && capture.end <= lineText.length)
            ? lineText.substring(capture.start, capture.end)
            : '',
    ];
    return source.replaceAllMapped(_backReferencingEnd, (m) {
      final index = int.parse(m[1]!);
      final value = index < capturedValues.length ? capturedValues[index] : '';
      return escapeRegExpCharacters(value);
    });
  }

  _AnchorCache _buildAnchorCache() {
    final a0G0 = <String>[];
    final a0G1 = <String>[];
    final a1G0 = <String>[];
    final a1G1 = <String>[];

    for (var pos = 0, len = source.length; pos < len; pos++) {
      final ch = source[pos];
      a0G0.add(ch);
      a0G1.add(ch);
      a1G0.add(ch);
      a1G1.add(ch);

      if (ch == r'\' && pos + 1 < len) {
        final nextCh = source[pos + 1];
        if (nextCh == 'A') {
          a0G0.add('￿');
          a0G1.add('￿');
          a1G0.add('A');
          a1G1.add('A');
        } else if (nextCh == 'G') {
          a0G0.add('￿');
          a0G1.add('G');
          a1G0.add('￿');
          a1G1.add('G');
        } else {
          a0G0.add(nextCh);
          a0G1.add(nextCh);
          a1G0.add(nextCh);
          a1G1.add(nextCh);
        }
        pos++;
      }
    }

    return _AnchorCache(
      a0G0.join(''),
      a0G1.join(''),
      a1G0.join(''),
      a1G1.join(''),
    );
  }

  /// Returns [source] with its `\A`/`\G` anchors resolved for the current
  /// scan position: [allowA] is true only at the very start of the line,
  /// [allowG] is true only at the tokenizer's current anchor position.
  /// Returns [source] unchanged if it has no anchor.
  String resolveAnchors(bool allowA, bool allowG) {
    if (!hasAnchor || _anchorCache == null) return source;
    if (allowA) {
      return allowG ? _anchorCache!.a1G1 : _anchorCache!.a1G0;
    } else {
      return allowG ? _anchorCache!.a0G1 : _anchorCache!.a0G0;
    }
  }
}

class _ListAnchorCache {
  CompiledRule? a0G0;
  CompiledRule? a0G1;
  CompiledRule? a1G0;
  CompiledRule? a1G1;
}

/// An ordered, jointly-scanned list of [RegExpSource]s, compiled together
/// into a single [OnigScanner] via [compile]/[compileAG] so the scanner can
/// find whichever one matches earliest.
class RegExpSourceList {
  final List<RegExpSource> _items = [];
  bool _hasAnchors = false;
  CompiledRule? _cached;
  final _ListAnchorCache _anchorCache = _ListAnchorCache();

  /// The number of sources in this list.
  int get length => _items.length;

  /// Appends [item] to the end of the list.
  void push(RegExpSource item) {
    _items.add(item);
    _hasAnchors = _hasAnchors || item.hasAnchor;
  }

  /// Inserts [item] at the start of the list.
  void unshift(RegExpSource item) {
    _items.insert(0, item);
    _hasAnchors = _hasAnchors || item.hasAnchor;
  }

  /// Replaces the source text at [index] with [newSource] (a no-op if
  /// unchanged), invalidating cached compiled scanners.
  void setSource(int index, String newSource) {
    if (_items[index].source != newSource) {
      _disposeCaches();
      _items[index].setSource(newSource);
    }
  }

  void _disposeCaches() {
    _cached = null;
    _anchorCache.a0G0 = null;
    _anchorCache.a0G1 = null;
    _anchorCache.a1G0 = null;
    _anchorCache.a1G1 = null;
  }

  /// Compiles (and caches) all sources, unresolved, into a single
  /// [CompiledRule] scanner via [factory].
  CompiledRule compile(OnigScannerFactory factory) {
    _cached ??= CompiledRule(
      factory,
      [for (final e in _items) e.source],
      [for (final e in _items) e.ruleId],
    );
    return _cached!;
  }

  /// Compiles all sources into a [CompiledRule], resolving `\A`/`\G`
  /// anchors per [allowA]/[allowG] and caching the result per
  /// anchor-resolution combination. Falls back to the unresolved [compile]
  /// cache if no source has an anchor.
  CompiledRule compileAG(OnigScannerFactory factory, bool allowA, bool allowG) {
    if (!_hasAnchors) {
      return compile(factory);
    }
    if (allowA) {
      if (allowG) {
        return _anchorCache.a1G1 ??= _resolveAnchors(factory, allowA, allowG);
      } else {
        return _anchorCache.a1G0 ??= _resolveAnchors(factory, allowA, allowG);
      }
    } else {
      if (allowG) {
        return _anchorCache.a0G1 ??= _resolveAnchors(factory, allowA, allowG);
      } else {
        return _anchorCache.a0G0 ??= _resolveAnchors(factory, allowA, allowG);
      }
    }
  }

  CompiledRule _resolveAnchors(
    OnigScannerFactory factory,
    bool allowA,
    bool allowG,
  ) {
    return CompiledRule(
      factory,
      [for (final e in _items) e.resolveAnchors(allowA, allowG)],
      [for (final e in _items) e.ruleId],
    );
  }
}

/// The result of scanning for the next match among a [CompiledRule]'s
/// regexes: which rule matched and where its capture groups landed.
class FindNextMatchResult {
  /// Creates a match result for [ruleId] with its [captureIndices].
  FindNextMatchResult(this.ruleId, this.captureIndices);

  /// The id of the rule whose regex matched.
  final RuleId ruleId;

  /// The matched capture group ranges, index `0` being the whole match.
  final List<OnigCaptureIndex> captureIndices;
}

/// A set of regex sources compiled into a single [OnigScanner], paired
/// with the [RuleId] each one is attributed to.
class CompiledRule {
  /// Compiles [regExps] into a scanner via [factory]; [rules] must be the
  /// same length, giving each regex's owning rule id.
  CompiledRule(OnigScannerFactory factory, this.regExps, this.rules)
    : scanner = factory.createScanner(regExps);

  /// The underlying scanner used to find the next match.
  final OnigScanner scanner;

  /// The compiled regex sources, parallel to [rules].
  final List<String> regExps;

  /// The rule id owning each entry in [regExps].
  final List<RuleId> rules;

  /// Finds the earliest match among [regExps] at or after [startPosition]
  /// in [string], or `null` if none match.
  FindNextMatchResult? findNextMatch(Object string, int startPosition) {
    final result = scanner.findNextMatch(string, startPosition);
    if (result == null) return null;
    return FindNextMatchResult(rules[result.index], result.captureIndices);
  }

  @override
  String toString() {
    final r = <String>[];
    for (var i = 0; i < rules.length; i++) {
      r.add('   - ${rules[i]}: ${regExps[i]}');
    }
    return r.join('\n');
  }
}

/// Compiles [RawRule]s (parsed grammar JSON/YAML) into registered [Rule]s.
/// Mirrors vscode-textmate's `RuleFactory`.
class RuleFactory {
  /// Registers and returns a new [CaptureRule] via [helper].
  static CaptureRule createCaptureRule(
    RuleFactoryHelper helper,
    String? name,
    String? contentName,
    RuleId retokenizeCapturedWithRuleId,
  ) {
    return helper.registerRule(
      (id) => CaptureRule(id, name, contentName, retokenizeCapturedWithRuleId),
    );
  }

  /// Compiles [desc] into the appropriate [Rule] subclass (chosen by which
  /// of `match`/`begin`/`whilePattern` are present, defaulting to
  /// [IncludeOnlyRule]) and returns its id, memoizing the result on [desc]
  /// itself so repeated references to the same raw rule reuse one compiled
  /// [Rule].
  static RuleId getCompiledRuleId(
    RawRule desc,
    RuleFactoryHelper helper,
    RawRepository repository,
  ) {
    if (desc.id == null) {
      helper.registerRule<Rule>((id) {
        desc.id = id;

        if (desc.match != null) {
          return MatchRule(
            desc.id!,
            desc.name,
            desc.match!,
            _compileCaptures(desc.captures, helper, repository),
          );
        }

        if (desc.begin == null) {
          var repo = repository;
          if (desc.repository != null) {
            repo = repository.mergedWith(desc.repository);
          }
          var patterns = desc.patterns;
          if (patterns == null && desc.include != null) {
            patterns = [RawRule(include: desc.include)];
          }
          return IncludeOnlyRule(
            desc.id!,
            desc.name,
            desc.contentName,
            _compilePatterns(patterns, helper, repo),
          );
        }

        if (desc.whilePattern != null) {
          return BeginWhileRule(
            desc.id!,
            desc.name,
            desc.contentName,
            desc.begin!,
            _compileCaptures(
              desc.beginCaptures ?? desc.captures,
              helper,
              repository,
            ),
            desc.whilePattern!,
            _compileCaptures(
              desc.whileCaptures ?? desc.captures,
              helper,
              repository,
            ),
            _compilePatterns(desc.patterns, helper, repository),
          );
        }

        return BeginEndRule(
          desc.id!,
          desc.name,
          desc.contentName,
          desc.begin!,
          _compileCaptures(
            desc.beginCaptures ?? desc.captures,
            helper,
            repository,
          ),
          desc.end,
          _compileCaptures(
            desc.endCaptures ?? desc.captures,
            helper,
            repository,
          ),
          desc.applyEndPatternLast,
          _compilePatterns(desc.patterns, helper, repository),
        );
      });
    }
    return desc.id!;
  }

  static List<CaptureRule?> _compileCaptures(
    RawCaptures? captures,
    RuleFactoryHelper helper,
    RawRepository repository,
  ) {
    final result = <CaptureRule?>[];
    if (captures != null) {
      var maximumCaptureId = 0;
      for (final captureId in captures.keys) {
        final numericCaptureId = int.tryParse(captureId);
        if (numericCaptureId != null && numericCaptureId > maximumCaptureId) {
          maximumCaptureId = numericCaptureId;
        }
      }

      for (var i = 0; i <= maximumCaptureId; i++) {
        result.add(null);
      }

      captures.forEach((captureId, rule) {
        final numericCaptureId = int.tryParse(captureId);
        if (numericCaptureId == null) return;
        var retokenizeCapturedWithRuleId = 0;
        if (rule.patterns != null) {
          retokenizeCapturedWithRuleId = getCompiledRuleId(
            rule,
            helper,
            repository,
          );
        }
        result[numericCaptureId] = createCaptureRule(
          helper,
          rule.name,
          rule.contentName,
          retokenizeCapturedWithRuleId,
        );
      });
    }
    return result;
  }

  static CompilePatternsResult _compilePatterns(
    List<RawRule>? patterns,
    RuleFactoryHelper helper,
    RawRepository repository,
  ) {
    final result = <RuleId>[];

    if (patterns != null) {
      for (final pattern in patterns) {
        RuleId ruleId = -1;

        if (pattern.include != null) {
          final reference = parseInclude(pattern.include!);
          switch (reference.kind) {
            case IncludeReferenceKind.base:
            case IncludeReferenceKind.self:
              final target = repository[pattern.include!];
              if (target != null) {
                ruleId = getCompiledRuleId(target, helper, repository);
              }
            case IncludeReferenceKind.relativeReference:
              final localIncludedRule = repository[reference.ruleName!];
              if (localIncludedRule != null) {
                ruleId = getCompiledRuleId(
                  localIncludedRule,
                  helper,
                  repository,
                );
              }
            case IncludeReferenceKind.topLevelReference:
            case IncludeReferenceKind.topLevelRepositoryReference:
              final externalGrammarName = reference.scopeName!;
              final externalGrammarInclude =
                  reference.kind ==
                      IncludeReferenceKind.topLevelRepositoryReference
                  ? reference.ruleName
                  : null;

              final externalGrammar = helper.getExternalGrammar(
                externalGrammarName,
                repository,
              );

              if (externalGrammar != null) {
                if (externalGrammarInclude != null) {
                  final externalIncludedRule =
                      externalGrammar.repository[externalGrammarInclude];
                  if (externalIncludedRule != null) {
                    ruleId = getCompiledRuleId(
                      externalIncludedRule,
                      helper,
                      externalGrammar.repository,
                    );
                  }
                } else {
                  ruleId = getCompiledRuleId(
                    externalGrammar.repository.self!,
                    helper,
                    externalGrammar.repository,
                  );
                }
              }
          }
        } else {
          ruleId = getCompiledRuleId(pattern, helper, repository);
        }

        if (ruleId != -1) {
          final rule = helper.getRuleOrNull(ruleId);
          var skipRule = false;
          if (rule is IncludeOnlyRule) {
            if (rule.hasMissingPatterns && rule.patterns.isEmpty) {
              skipRule = true;
            }
          } else if (rule is BeginEndRule) {
            if (rule.hasMissingPatterns && rule.patterns.isEmpty) {
              skipRule = true;
            }
          } else if (rule is BeginWhileRule) {
            if (rule.hasMissingPatterns && rule.patterns.isEmpty) {
              skipRule = true;
            }
          }
          if (skipRule) continue;
          result.add(ruleId);
        }
      }
    }

    return CompilePatternsResult(
      result,
      (patterns?.length ?? 0) != result.length,
    );
  }
}
