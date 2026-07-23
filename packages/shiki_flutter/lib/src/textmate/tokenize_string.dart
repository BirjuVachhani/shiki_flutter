// The core tokenization loop, ported from `vscode-textmate`'s
// `grammar/tokenizeString.ts`.

import '../onig/onig.dart';
import 'grammar.dart';
import 'rule.dart';

/// The result of running [tokenizeString] over a single line.
class TokenizeStringResult {
  /// Creates a [TokenizeStringResult] with the resulting [stack] and
  /// whether it [stoppedEarly] due to the time limit.
  TokenizeStringResult(this.stack, this.stoppedEarly);

  /// The rule stack at the end of the line (or at the point tokenization
  /// stopped), to be passed in as the starting stack for the next line.
  final StateStack stack;

  /// Whether tokenization was cut short by the `timeLimit` before reaching
  /// the end of the line.
  final bool stoppedEarly;
}

/// Tokenizes [lineText] from [linePos] to the end of the line, repeatedly
/// matching rules/injections and pushing or popping [stack], writing
/// produced tokens to [lineTokens]. Ported from `vscode-textmate`'s
/// `_tokenizeString`.
///
/// When [checkWhileConditions] is `true`, active `begin`/`while` rules on
/// the stack are first re-checked against this line (see
/// `_checkWhileConditions`) before the main scan loop runs. If [timeLimit]
/// is nonzero and elapsed time exceeds it, tokenization stops early and the
/// returned result has `stoppedEarly: true`.
TokenizeStringResult tokenizeString(
  Grammar grammar,
  OnigString lineText,
  bool isFirstLine,
  int linePos,
  StateStack stack,
  LineTokens lineTokens,
  bool checkWhileConditions,
  int timeLimit,
) {
  final lineLength = lineText.content.length;

  var stop = false;
  var anchorPosition = -1;
  var currentStack = stack;
  var currentLinePos = linePos;
  var currentIsFirstLine = isFirstLine;

  if (checkWhileConditions) {
    final whileCheckResult = _checkWhileConditions(
      grammar,
      lineText,
      currentIsFirstLine,
      currentLinePos,
      currentStack,
      lineTokens,
    );
    currentStack = whileCheckResult.stack;
    currentLinePos = whileCheckResult.linePos;
    currentIsFirstLine = whileCheckResult.isFirstLine;
    anchorPosition = whileCheckResult.anchorPosition;
  }

  final startTime = DateTime.now().millisecondsSinceEpoch;
  while (!stop) {
    if (timeLimit != 0) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      if (elapsed > timeLimit) {
        return TokenizeStringResult(currentStack, true);
      }
    }

    // scanNext, potentially modifying currentLinePos & anchorPosition.
    final r = _matchRuleOrInjections(
      grammar,
      lineText,
      currentIsFirstLine,
      currentLinePos,
      currentStack,
      anchorPosition,
    );

    if (r == null) {
      lineTokens.produce(currentStack, lineLength);
      stop = true;
      break;
    }

    final captureIndices = r.captureIndices;
    final matchedRuleId = r.matchedRuleId;

    final hasAdvanced = captureIndices.isNotEmpty
        ? captureIndices[0].end > currentLinePos
        : false;

    if (matchedRuleId == endRuleId) {
      final poppedRule = currentStack.getRule(grammar) as BeginEndRule;

      lineTokens.produce(currentStack, captureIndices[0].start);
      currentStack = currentStack.withContentNameScopesList(
        currentStack.nameScopesList!,
      );
      _handleCaptures(
        grammar,
        lineText,
        currentIsFirstLine,
        currentStack,
        lineTokens,
        poppedRule.endCaptures,
        captureIndices,
      );
      lineTokens.produce(currentStack, captureIndices[0].end);

      final popped = currentStack;
      currentStack = currentStack.parent!;
      anchorPosition = popped.getAnchorPos();

      if (!hasAdvanced && popped.getEnterPos() == currentLinePos) {
        // Grammar pushed & popped a rule without advancing: assume mistake and
        // continue in this state to avoid an endless loop.
        currentStack = popped;
        lineTokens.produce(currentStack, lineLength);
        stop = true;
        break;
      }
    } else {
      final rule = grammar.getRule(matchedRuleId);

      lineTokens.produce(currentStack, captureIndices[0].start);

      final beforePush = currentStack;
      final scopeName = rule.getName(lineText.content, captureIndices);
      final nameScopesList = currentStack.contentNameScopesList!.pushAttributed(
        scopeName,
        grammar,
      );
      currentStack = currentStack.push(
        matchedRuleId,
        currentLinePos,
        anchorPosition,
        captureIndices[0].end == lineLength,
        null,
        nameScopesList,
        nameScopesList,
      );

      if (rule is BeginEndRule) {
        final pushedRule = rule;
        _handleCaptures(
          grammar,
          lineText,
          currentIsFirstLine,
          currentStack,
          lineTokens,
          pushedRule.beginCaptures,
          captureIndices,
        );
        lineTokens.produce(currentStack, captureIndices[0].end);
        anchorPosition = captureIndices[0].end;

        final contentName = pushedRule.getContentName(
          lineText.content,
          captureIndices,
        );
        final contentNameScopesList = nameScopesList.pushAttributed(
          contentName,
          grammar,
        );
        currentStack = currentStack.withContentNameScopesList(
          contentNameScopesList,
        );

        if (pushedRule.endHasBackReferences) {
          currentStack = currentStack.withEndRule(
            pushedRule.getEndWithResolvedBackReferences(
              lineText.content,
              captureIndices,
            ),
          );
        }

        if (!hasAdvanced && beforePush.hasSameRuleAs(currentStack)) {
          currentStack = currentStack.pop()!;
          lineTokens.produce(currentStack, lineLength);
          stop = true;
          break;
        }
      } else if (rule is BeginWhileRule) {
        final pushedRule = rule;
        _handleCaptures(
          grammar,
          lineText,
          currentIsFirstLine,
          currentStack,
          lineTokens,
          pushedRule.beginCaptures,
          captureIndices,
        );
        lineTokens.produce(currentStack, captureIndices[0].end);
        anchorPosition = captureIndices[0].end;

        final contentName = pushedRule.getContentName(
          lineText.content,
          captureIndices,
        );
        final contentNameScopesList = nameScopesList.pushAttributed(
          contentName,
          grammar,
        );
        currentStack = currentStack.withContentNameScopesList(
          contentNameScopesList,
        );

        if (pushedRule.whileHasBackReferences) {
          currentStack = currentStack.withEndRule(
            pushedRule.getWhileWithResolvedBackReferences(
              lineText.content,
              captureIndices,
            ),
          );
        }

        if (!hasAdvanced && beforePush.hasSameRuleAs(currentStack)) {
          currentStack = currentStack.pop()!;
          lineTokens.produce(currentStack, lineLength);
          stop = true;
          break;
        }
      } else {
        final matchingRule = rule as MatchRule;
        _handleCaptures(
          grammar,
          lineText,
          currentIsFirstLine,
          currentStack,
          lineTokens,
          matchingRule.captures,
          captureIndices,
        );
        lineTokens.produce(currentStack, captureIndices[0].end);

        currentStack = currentStack.pop()!;

        if (!hasAdvanced) {
          currentStack = currentStack.safePop();
          lineTokens.produce(currentStack, lineLength);
          stop = true;
          break;
        }
      }
    }

    if (captureIndices[0].end > currentLinePos) {
      currentLinePos = captureIndices[0].end;
      currentIsFirstLine = false;
    }
  }

  return TokenizeStringResult(currentStack, false);
}

class _WhileCheckResult {
  _WhileCheckResult(
    this.stack,
    this.linePos,
    this.anchorPosition,
    this.isFirstLine,
  );
  final StateStack stack;
  final int linePos;
  final int anchorPosition;
  final bool isFirstLine;
}

_WhileCheckResult _checkWhileConditions(
  Grammar grammar,
  OnigString lineText,
  bool isFirstLine,
  int linePos,
  StateStack stack,
  LineTokens lineTokens,
) {
  var anchorPosition = stack.beginRuleCapturedEOL ? 0 : -1;
  var currentStack = stack;
  var currentLinePos = linePos;
  var currentIsFirstLine = isFirstLine;

  final whileRules = <_WhileStack>[];
  for (StateStack? node = stack; node != null; node = node.pop()) {
    final nodeRule = node.getRule(grammar);
    if (nodeRule is BeginWhileRule) {
      whileRules.add(_WhileStack(node, nodeRule));
    }
  }

  for (var i = whileRules.length - 1; i >= 0; i--) {
    final whileRule = whileRules[i];
    final compiled = whileRule.rule.compileWhileAG(
      grammar,
      whileRule.stack.endRule,
      currentIsFirstLine,
      currentLinePos == anchorPosition,
    );
    final r = compiled.findNextMatch(lineText, currentLinePos);

    if (r != null) {
      final matchedRuleId = r.ruleId;
      if (matchedRuleId != whileRuleId) {
        currentStack = whileRule.stack.pop()!;
        break;
      }
      if (r.captureIndices.isNotEmpty) {
        lineTokens.produce(whileRule.stack, r.captureIndices[0].start);
        _handleCaptures(
          grammar,
          lineText,
          currentIsFirstLine,
          whileRule.stack,
          lineTokens,
          whileRule.rule.whileCaptures,
          r.captureIndices,
        );
        lineTokens.produce(whileRule.stack, r.captureIndices[0].end);
        anchorPosition = r.captureIndices[0].end;
        if (r.captureIndices[0].end > currentLinePos) {
          currentLinePos = r.captureIndices[0].end;
          currentIsFirstLine = false;
        }
      }
    } else {
      currentStack = whileRule.stack.pop()!;
      break;
    }
  }

  return _WhileCheckResult(
    currentStack,
    currentLinePos,
    anchorPosition,
    currentIsFirstLine,
  );
}

class _WhileStack {
  _WhileStack(this.stack, this.rule);
  final StateStack stack;
  final BeginWhileRule rule;
}

class _MatchResult {
  _MatchResult(this.captureIndices, this.matchedRuleId);
  final List<OnigCaptureIndex> captureIndices;
  final RuleId matchedRuleId;
}

class _MatchInjectionsResult {
  _MatchInjectionsResult(
    this.priorityMatch,
    this.captureIndices,
    this.matchedRuleId,
  );
  final bool priorityMatch;
  final List<OnigCaptureIndex> captureIndices;
  final RuleId matchedRuleId;
}

_MatchResult? _matchRuleOrInjections(
  Grammar grammar,
  OnigString lineText,
  bool isFirstLine,
  int linePos,
  StateStack stack,
  int anchorPosition,
) {
  final matchResult = _matchRule(
    grammar,
    lineText,
    isFirstLine,
    linePos,
    stack,
    anchorPosition,
  );

  final injections = grammar.getInjections();
  if (injections.isEmpty) return matchResult;

  final injectionResult = _matchInjections(
    injections,
    grammar,
    lineText,
    isFirstLine,
    linePos,
    stack,
    anchorPosition,
  );
  if (injectionResult == null) return matchResult;

  if (matchResult == null) {
    return _MatchResult(
      injectionResult.captureIndices,
      injectionResult.matchedRuleId,
    );
  }

  final matchResultScore = matchResult.captureIndices[0].start;
  final injectionResultScore = injectionResult.captureIndices[0].start;

  if (injectionResultScore < matchResultScore ||
      (injectionResult.priorityMatch &&
          injectionResultScore == matchResultScore)) {
    return _MatchResult(
      injectionResult.captureIndices,
      injectionResult.matchedRuleId,
    );
  }
  return matchResult;
}

_MatchResult? _matchRule(
  Grammar grammar,
  OnigString lineText,
  bool isFirstLine,
  int linePos,
  StateStack stack,
  int anchorPosition,
) {
  final rule = stack.getRule(grammar);
  final ruleScanner = rule.compileAG(
    grammar,
    stack.endRule,
    isFirstLine,
    linePos == anchorPosition,
  );
  final r = ruleScanner.findNextMatch(lineText, linePos);

  if (r != null) {
    return _MatchResult(r.captureIndices, r.ruleId);
  }
  return null;
}

_MatchInjectionsResult? _matchInjections(
  List<Injection> injections,
  Grammar grammar,
  OnigString lineText,
  bool isFirstLine,
  int linePos,
  StateStack stack,
  int anchorPosition,
) {
  // A sentinel larger than any match position. Uses the max safe integer so
  // the value is exact on the web (dart2js ints are 53-bit doubles); match
  // ratings are line offsets, always far below this.
  var bestMatchRating = 9007199254740991; // 2^53 - 1

  List<OnigCaptureIndex>? bestMatchCaptureIndices;
  RuleId bestMatchRuleId = -1;
  var bestMatchResultPriority = 0;

  final scopes = stack.contentNameScopesList!.getScopeNames();

  for (final injection in injections) {
    if (!injection.matcher(scopes)) continue;
    final rule = grammar.getRule(injection.ruleId);
    final ruleScanner = rule.compileAG(
      grammar,
      null,
      isFirstLine,
      linePos == anchorPosition,
    );
    final matchResult = ruleScanner.findNextMatch(lineText, linePos);
    if (matchResult == null) continue;

    final matchRating = matchResult.captureIndices[0].start;
    if (matchRating >= bestMatchRating) continue;

    bestMatchRating = matchRating;
    bestMatchCaptureIndices = matchResult.captureIndices;
    bestMatchRuleId = matchResult.ruleId;
    bestMatchResultPriority = injection.priority;

    if (bestMatchRating == linePos) break;
  }

  if (bestMatchCaptureIndices != null) {
    return _MatchInjectionsResult(
      bestMatchResultPriority == -1,
      bestMatchCaptureIndices,
      bestMatchRuleId,
    );
  }
  return null;
}

class _LocalStackElement {
  _LocalStackElement(this.scopes, this.endPos);
  final AttributedScopeStack scopes;
  final int endPos;
}

void _handleCaptures(
  Grammar grammar,
  OnigString lineText,
  bool isFirstLine,
  StateStack stack,
  LineTokens lineTokens,
  List<CaptureRule?> captures,
  List<OnigCaptureIndex> captureIndices,
) {
  if (captures.isEmpty) return;

  final lineTextContent = lineText.content;

  final len = captures.length < captureIndices.length
      ? captures.length
      : captureIndices.length;
  final localStack = <_LocalStackElement>[];
  final maxEnd = captureIndices[0].end;

  for (var i = 0; i < len; i++) {
    final captureRule = captures[i];
    if (captureRule == null) continue;

    final captureIndex = captureIndices[i];
    if (captureIndex.length == 0) continue;
    if (captureIndex.start > maxEnd) break;

    while (localStack.isNotEmpty &&
        localStack.last.endPos <= captureIndex.start) {
      lineTokens.produceFromScopes(
        localStack.last.scopes,
        localStack.last.endPos,
      );
      localStack.removeLast();
    }

    if (localStack.isNotEmpty) {
      lineTokens.produceFromScopes(localStack.last.scopes, captureIndex.start);
    } else {
      lineTokens.produce(stack, captureIndex.start);
    }

    if (captureRule.retokenizeCapturedWithRuleId != 0) {
      final scopeName = captureRule.getName(lineTextContent, captureIndices);
      final nameScopesList = stack.contentNameScopesList!.pushAttributed(
        scopeName,
        grammar,
      );
      final contentName = captureRule.getContentName(
        lineTextContent,
        captureIndices,
      );
      final contentNameScopesList = nameScopesList.pushAttributed(
        contentName,
        grammar,
      );

      final stackClone = stack.push(
        captureRule.retokenizeCapturedWithRuleId,
        captureIndex.start,
        -1,
        false,
        null,
        nameScopesList,
        contentNameScopesList,
      );
      final onigSubStr = grammar.createString(
        lineTextContent.substring(0, captureIndex.end),
      );
      tokenizeString(
        grammar,
        onigSubStr,
        isFirstLine && captureIndex.start == 0,
        captureIndex.start,
        stackClone,
        lineTokens,
        false,
        0,
      );
      continue;
    }

    final captureRuleScopeName = captureRule.getName(
      lineTextContent,
      captureIndices,
    );
    if (captureRuleScopeName != null) {
      final base = localStack.isNotEmpty
          ? localStack.last.scopes
          : stack.contentNameScopesList!;
      final captureRuleScopesList = base.pushAttributed(
        captureRuleScopeName,
        grammar,
      );
      localStack.add(
        _LocalStackElement(captureRuleScopesList, captureIndex.end),
      );
    }
  }

  while (localStack.isNotEmpty) {
    lineTokens.produceFromScopes(
      localStack.last.scopes,
      localStack.last.endPos,
    );
    localStack.removeLast();
  }
}
