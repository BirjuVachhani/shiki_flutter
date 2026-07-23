// Scope-selector matcher, ported from `vscode-textmate`'s `matcher.ts`.
//
// Parses selectors like `source.js meta.function` or `L:string -comment` into
// predicate functions over a list of scope names, with a priority.

/// A compiled scope-selector predicate: `true` if [input] satisfies the
/// selector expression it was parsed from.
typedef Matcher<T> = bool Function(T input);

/// One alternative of a parsed selector (from [createMatchers]), paired
/// with the priority its `L:`/`R:` prefix (if any) assigns it.
class MatcherWithPriority<T> {
  /// Creates a [MatcherWithPriority] pairing [matcher] with [priority].
  MatcherWithPriority(this.matcher, this.priority);

  /// The compiled predicate for this selector alternative.
  final Matcher<T> matcher;

  /// 0 default, -1 for `L:`, 1 for `R:`.
  final int priority;
}

final RegExp _tokenRegExp = RegExp(r'([LR]:|[\w.:][\w.:\-]*|[,|\-()])');
final RegExp _identifierRegExp = RegExp(r'[\w.:]+');

/// Parses a scope [selector] (e.g. `source.js meta.function`, `L:string
/// -comment`, `a | b`) into one [MatcherWithPriority] per top-level,
/// comma-separated alternative. [matchesName] decides whether a run of
/// space-separated identifiers matches a given `input`, letting callers
/// use this for either raw scope-name lists or arbitrary `T`.
List<MatcherWithPriority<T>> createMatchers<T>(
  String selector,
  bool Function(List<String> names, T input) matchesName,
) {
  final results = <MatcherWithPriority<T>>[];
  final tokenizer = _newTokenizer(selector);
  String? token = tokenizer();

  late final Matcher<T>? Function() parseOperand;
  late final Matcher<T> Function() parseConjunction;
  late final Matcher<T> Function() parseInnerExpression;

  parseOperand = () {
    if (token == '-') {
      token = tokenizer();
      final expressionToNegate = parseOperand();
      return (T input) =>
          expressionToNegate != null && !expressionToNegate(input);
    }
    if (token == '(') {
      token = tokenizer();
      final expressionInParens = parseInnerExpression();
      if (token == ')') {
        token = tokenizer();
      }
      return expressionInParens;
    }
    if (_isIdentifier(token)) {
      final identifiers = <String>[];
      do {
        identifiers.add(token!);
        token = tokenizer();
      } while (_isIdentifier(token));
      return (T input) => matchesName(identifiers, input);
    }
    return null;
  };

  parseConjunction = () {
    final matchers = <Matcher<T>>[];
    var matcher = parseOperand();
    while (matcher != null) {
      matchers.add(matcher);
      matcher = parseOperand();
    }
    return (T input) => matchers.every((m) => m(input));
  };

  parseInnerExpression = () {
    final matchers = <Matcher<T>>[];
    var matcher = parseConjunction();
    while (true) {
      matchers.add(matcher);
      if (token == '|' || token == ',') {
        do {
          token = tokenizer();
        } while (token == '|' || token == ',');
      } else {
        break;
      }
      matcher = parseConjunction();
    }
    return (T input) => matchers.any((m) => m(input));
  };

  while (token != null) {
    var priority = 0;
    if (token!.length == 2 && token![1] == ':') {
      switch (token![0]) {
        case 'R':
          priority = 1;
        case 'L':
          priority = -1;
        default:
          break;
      }
      token = tokenizer();
    }
    final matcher = parseConjunction();
    results.add(MatcherWithPriority(matcher, priority));
    if (token != ',') break;
    token = tokenizer();
  }
  return results;
}

bool _isIdentifier(String? token) {
  return token != null && _identifierRegExp.hasMatch(token);
}

String? Function() _newTokenizer(String input) {
  final matches = _tokenRegExp.allMatches(input).iterator;
  return () {
    if (!matches.moveNext()) return null;
    return matches.current.group(0);
  };
}
