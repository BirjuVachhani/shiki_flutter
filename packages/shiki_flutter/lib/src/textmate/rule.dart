// Grammar rule compilation, ported from `vscode-textmate`'s `rule.ts`.
library;

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

abstract class RuleFactoryHelper {
  Rule getRule(RuleId ruleId);

  /// Like [getRule] but returns null for rules that are still being constructed
  /// (self-references encountered mid-compilation).
  Rule? getRuleOrNull(RuleId ruleId);
  T registerRule<T extends Rule>(T Function(RuleId id) factory);
  RawGrammar? getExternalGrammar(String scopeName, [RawRepository? repository]);
}

abstract class OnigScannerFactory {
  OnigScanner createScanner(List<String> sources);
}

/// The context passed to compilation: rule lookup + scanner creation.
abstract class GrammarRules implements RuleFactoryHelper, OnigScannerFactory {}

abstract class Rule {
  Rule(this.id, String? name, String? contentName)
      : _name = name,
        _nameIsCapturing = RegexSource.hasCaptures(name),
        _contentName = contentName,
        _contentNameIsCapturing = RegexSource.hasCaptures(contentName);

  final RuleId id;
  final String? _name;
  final bool _nameIsCapturing;
  final String? _contentName;
  final bool _contentNameIsCapturing;

  String? getName(String? lineText, List<OnigCaptureIndex>? captureIndices) {
    if (!_nameIsCapturing ||
        _name == null ||
        lineText == null ||
        captureIndices == null) {
      return _name;
    }
    return RegexSource.replaceCaptures(_name, lineText, captureIndices);
  }

  String? getContentName(String lineText, List<OnigCaptureIndex> captureIndices) {
    if (!_contentNameIsCapturing || _contentName == null) {
      return _contentName;
    }
    return RegexSource.replaceCaptures(_contentName, lineText, captureIndices);
  }

  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out);
  CompiledRule compileAG(
      GrammarRules grammar, String? endRegexSource, bool allowA, bool allowG);
}

class CompilePatternsResult {
  CompilePatternsResult(this.patterns, this.hasMissingPatterns);
  final List<RuleId> patterns;
  final bool hasMissingPatterns;
}

class CaptureRule extends Rule {
  CaptureRule(super.id, super.name, super.contentName,
      this.retokenizeCapturedWithRuleId);

  /// 0 means "no retokenization".
  final RuleId retokenizeCapturedWithRuleId;

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    throw StateError('Not supported!');
  }

  @override
  CompiledRule compileAG(
      GrammarRules grammar, String? endRegexSource, bool allowA, bool allowG) {
    throw StateError('Not supported!');
  }
}

class MatchRule extends Rule {
  MatchRule(RuleId id, String? name, String match, this.captures)
      : _match = RegExpSource(match, id),
        super(id, name, null);

  final RegExpSource _match;
  final List<CaptureRule?> captures;
  RegExpSourceList? _cachedCompiledPatterns;

  String get debugMatchRegExp => _match.source;

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    out.push(_match);
  }

  @override
  CompiledRule compileAG(
      GrammarRules grammar, String? endRegexSource, bool allowA, bool allowG) {
    return _getCachedCompiledPatterns(grammar).compileAG(grammar, allowA, allowG);
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

class IncludeOnlyRule extends Rule {
  IncludeOnlyRule(super.id, super.name, super.contentName,
      CompilePatternsResult patterns)
      : patterns = patterns.patterns,
        hasMissingPatterns = patterns.hasMissingPatterns;

  final List<RuleId> patterns;
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
      GrammarRules grammar, String? endRegexSource, bool allowA, bool allowG) {
    return _getCachedCompiledPatterns(grammar).compileAG(grammar, allowA, allowG);
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

class BeginEndRule extends Rule {
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
  )   : _begin = RegExpSource(begin, id),
        _end = RegExpSource(end ?? '￿', -1),
        endHasBackReferences =
            RegExpSource(end ?? '￿', -1).hasBackReferences,
        applyEndPatternLast = applyEndPatternLast ?? false,
        patterns = patterns.patterns,
        hasMissingPatterns = patterns.hasMissingPatterns,
        super(id, name, contentName);

  final RegExpSource _begin;
  final List<CaptureRule?> beginCaptures;
  final RegExpSource _end;
  final bool endHasBackReferences;
  final List<CaptureRule?> endCaptures;
  final bool applyEndPatternLast;
  final bool hasMissingPatterns;
  final List<RuleId> patterns;
  RegExpSourceList? _cachedCompiledPatterns;

  String get debugBeginRegExp => _begin.source;
  String get debugEndRegExp => _end.source;

  String getEndWithResolvedBackReferences(
          String lineText, List<OnigCaptureIndex> captureIndices) =>
      _end.resolveBackReferences(lineText, captureIndices);

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    out.push(_begin);
  }

  @override
  CompiledRule compileAG(
      GrammarRules grammar, String? endRegexSource, bool allowA, bool allowG) {
    return _getCachedCompiledPatterns(grammar, endRegexSource)
        .compileAG(grammar, allowA, allowG);
  }

  RegExpSourceList _getCachedCompiledPatterns(
      RuleFactoryHelper grammar, String? endRegexSource) {
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
        _cachedCompiledPatterns!
            .setSource(_cachedCompiledPatterns!.length - 1, endRegexSource!);
      } else {
        _cachedCompiledPatterns!.setSource(0, endRegexSource!);
      }
    }
    return _cachedCompiledPatterns!;
  }
}

class BeginWhileRule extends Rule {
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
  )   : _begin = RegExpSource(begin, id),
        _while = RegExpSource(whilePattern, whileRuleId),
        whileHasBackReferences = RegExpSource(whilePattern, whileRuleId)
            .hasBackReferences,
        patterns = patterns.patterns,
        hasMissingPatterns = patterns.hasMissingPatterns,
        super(id, name, contentName);

  final RegExpSource _begin;
  final List<CaptureRule?> beginCaptures;
  final List<CaptureRule?> whileCaptures;
  final RegExpSource _while;
  final bool whileHasBackReferences;
  final bool hasMissingPatterns;
  final List<RuleId> patterns;
  RegExpSourceList? _cachedCompiledPatterns;
  RegExpSourceList? _cachedCompiledWhilePatterns;

  String getWhileWithResolvedBackReferences(
          String lineText, List<OnigCaptureIndex> captureIndices) =>
      _while.resolveBackReferences(lineText, captureIndices);

  @override
  void collectPatterns(RuleFactoryHelper grammar, RegExpSourceList out) {
    out.push(_begin);
  }

  @override
  CompiledRule compileAG(
      GrammarRules grammar, String? endRegexSource, bool allowA, bool allowG) {
    return _getCachedCompiledPatterns(grammar).compileAG(grammar, allowA, allowG);
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

  CompiledRule compileWhileAG(GrammarRules grammar, String? endRegexSource,
      bool allowA, bool allowG) {
    return _getCachedCompiledWhilePatterns(grammar, endRegexSource)
        .compileAG(grammar, allowA, allowG);
  }

  RegExpSourceList _getCachedCompiledWhilePatterns(
      RuleFactoryHelper grammar, String? endRegexSource) {
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

  late String source;
  final RuleId ruleId;
  late bool hasAnchor;
  late bool hasBackReferences;
  _AnchorCache? _anchorCache;

  RegExpSource clone() => RegExpSource(source, ruleId);

  void setSource(String newSource) {
    if (source == newSource) return;
    source = newSource;
    if (hasAnchor) {
      _anchorCache = _buildAnchorCache();
    }
  }

  String resolveBackReferences(
      String lineText, List<OnigCaptureIndex> captureIndices) {
    final capturedValues = [
      for (final capture in captureIndices)
        // Unset groups carry a sentinel start/end beyond the string; treat them
        // as the empty string (matching JavaScript's lenient `substring`).
        (capture.start >= 0 && capture.end <= lineText.length)
            ? lineText.substring(capture.start, capture.end)
            : ''
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

class RegExpSourceList {
  final List<RegExpSource> _items = [];
  bool _hasAnchors = false;
  CompiledRule? _cached;
  final _ListAnchorCache _anchorCache = _ListAnchorCache();

  int get length => _items.length;

  void push(RegExpSource item) {
    _items.add(item);
    _hasAnchors = _hasAnchors || item.hasAnchor;
  }

  void unshift(RegExpSource item) {
    _items.insert(0, item);
    _hasAnchors = _hasAnchors || item.hasAnchor;
  }

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

  CompiledRule compile(OnigScannerFactory factory) {
    _cached ??= CompiledRule(
      factory,
      [for (final e in _items) e.source],
      [for (final e in _items) e.ruleId],
    );
    return _cached!;
  }

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
      OnigScannerFactory factory, bool allowA, bool allowG) {
    return CompiledRule(
      factory,
      [for (final e in _items) e.resolveAnchors(allowA, allowG)],
      [for (final e in _items) e.ruleId],
    );
  }
}

class FindNextMatchResult {
  FindNextMatchResult(this.ruleId, this.captureIndices);
  final RuleId ruleId;
  final List<OnigCaptureIndex> captureIndices;
}

class CompiledRule {
  CompiledRule(OnigScannerFactory factory, this.regExps, this.rules)
      : scanner = factory.createScanner(regExps);

  final OnigScanner scanner;
  final List<String> regExps;
  final List<RuleId> rules;

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

class RuleFactory {
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
                desc.beginCaptures ?? desc.captures, helper, repository),
            desc.whilePattern!,
            _compileCaptures(
                desc.whileCaptures ?? desc.captures, helper, repository),
            _compilePatterns(desc.patterns, helper, repository),
          );
        }

        return BeginEndRule(
          desc.id!,
          desc.name,
          desc.contentName,
          desc.begin!,
          _compileCaptures(
              desc.beginCaptures ?? desc.captures, helper, repository),
          desc.end,
          _compileCaptures(
              desc.endCaptures ?? desc.captures, helper, repository),
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
          retokenizeCapturedWithRuleId =
              getCompiledRuleId(rule, helper, repository);
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
                ruleId =
                    getCompiledRuleId(localIncludedRule, helper, repository);
              }
            case IncludeReferenceKind.topLevelReference:
            case IncludeReferenceKind.topLevelRepositoryReference:
              final externalGrammarName = reference.scopeName!;
              final externalGrammarInclude = reference.kind ==
                      IncludeReferenceKind.topLevelRepositoryReference
                  ? reference.ruleName
                  : null;

              final externalGrammar =
                  helper.getExternalGrammar(externalGrammarName, repository);

              if (externalGrammar != null) {
                if (externalGrammarInclude != null) {
                  final externalIncludedRule =
                      externalGrammar.repository[externalGrammarInclude];
                  if (externalIncludedRule != null) {
                    ruleId = getCompiledRuleId(externalIncludedRule, helper,
                        externalGrammar.repository);
                  }
                } else {
                  ruleId = getCompiledRuleId(externalGrammar.repository.self!,
                      helper, externalGrammar.repository);
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
