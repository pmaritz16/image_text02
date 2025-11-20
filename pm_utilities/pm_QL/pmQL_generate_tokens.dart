// 2020-02-15

import '../pm_dartUtils.dart';
import '../pm_constants.dart';
import './pmQL_common.dart';

throwError(int index, String m) {
  throw 'Parse Error at $index, $m';
}

List<Token> pmExtractPrimitiveTokens(String inputString) {
  // pull out tokens: name, string, number, character
  // collapse double character operators: ==, !=, etc
  int index = 0;
  int char;
  List<Token> tokens = [];

  int getNextChar() {
    int c;
    c = (index < 0 || index >= inputString.length)
        ? -1
        : inputString.codeUnitAt(index++);
    //print('getNextChar: $c');
    return c;
  }

  int peekNextChar() {
    int c;
    c = (index < 0 || index >= inputString.length)
        ? -1
        : inputString.codeUnitAt(index);
    //print('peekNextChar: $c');
    return c;
  }

  isAlpha(int a) {
    return ((a >= PMCV.A && a <= PMCV.Z) || (a >= PMCV.a && a <= PMCV.z) || a == PMCV.Underscore);
  }

  isNumeric(int n) {
    return (n == PMCV.Period) || (n >= PMCV.Zero && n <= PMCV.Nine);
  }

  isName(int a) {
    if (isAlpha(a) || isNumeric(a)) return true;
    return (a == PMCV.Underscore);
  }

  gatherName(int c, int index) {
    String s = String.fromCharCode(c);
    while (isName(peekNextChar())) {
      s = s + String.fromCharCode(getNextChar());
    }
    tokens.add(Token(
        type: kqlVariable,
        value: s,
        index: index - 1,
        inputString: inputString));
  }

  gatherNumber(int c, int index) {
    String n = String.fromCharCode(c);
    while (isNumeric(peekNextChar())) {
      n = n + String.fromCharCode(getNextChar());
    }
    double value = double.parse(n);
    tokens.add(Token(
        type: kqlNumber,
        value: value,
        index: index - 1,
        inputString: inputString));
  }

  gatherString(int index) {
    // gather string, allowing for double quotes ''
    int c;
    String s = '';
    do {
      c = getNextChar();
      if (c < 0) break; // end of input
      if (c == PMCV.SingleQ) {
        int d = peekNextChar();
        if (d != PMCV.SingleQ)
          break; // end of string
        else {
          // escaped sQ, add one sQ
          c = getNextChar(); // step over it
          s = s + String.fromCharCode(c); // add one dQ
        }
      } else
        s = s + String.fromCharCode(c);
    } while (true);
    if (c < 0) throwError(index, 'Unterminated String');
    tokens.add(Token(type: kqlString, value: s, index: index - 1));
  }

  gatherCharacter(int c, {int d = -1}) {
    int i = index - 1;
    String value = String.fromCharCode(c);
    if (d >= 0) {
      value = value + String.fromCharCode(d);
      i--;
    }
    tokens.add(Token(
        type: kqlCharacter, value: value, index: i, inputString: inputString));
  }

  if (pmNil(inputString)) return tokens;
  while (peekNextChar() >= 0) {
    char = getNextChar();
    if (char == PMCV.Space) continue;
    if (isAlpha(char)) {
      gatherName(char, index);
      continue;
    }
    if (isNumeric(char)) {
      gatherNumber(char, index);
      continue;
    }
    if (char == PMCV.SingleQ) {
      gatherString(index);
      continue;
    }
    gatherCharacter(char);
  }

  return tokens;
}

List<Token> classifyTokens(List<Token> tokens) {
  // find reserved words, deal with negation

  if (pmNil(tokens)) return [];

  // first identify all reserved words, substitute for FALSE/TRUE, eliminate comma's
  int k = 0;
  while (k < tokens.length) {
    Token t = tokens[k];
    if (t.value == ',') {
      tokens.removeAt(k);
      continue;
    }
    if (t.type == kqlVariable && (kqlReservedWords[t.value] != null)) {
      if (t.value == 'FALSE') {
        t.value = 0.0;
        t.type = kqlNumber;
        continue;
      }
      if (t.value == 'TRUE') {
        t.value = 1.0;
        t.type = kqlNumber;
        continue;
      }
      t.type = kqlReserved;
    }
    k++;
  }

  // now collapse double character operators and distinguish - from --
  for (int i = 0; i < tokens.length; i++) {
    // collapse double character operators, e.g. ==
    if (tokens[i].type != kqlCharacter) continue;
    int f = pmListFind(doubleCharOperators, tokens[i].value,
        xform: (item) => item[0]);
    if (f >= 0) {
      if (i + 1 == tokens.length) continue;
      if (tokens[i + 1].type == kqlCharacter &&
          tokens[i + 1].value == doubleCharOperators[f][1]) {
        tokens[i].value = doubleCharOperators[f][2];
        tokens.removeAt(i + 1);
      }
      continue;
    }
    // now distinguish between minus '-', and negation '--'
    if (tokens[i].value == '-') {
      if (i == 0) {
        tokens[i].value = '--';
        continue;
      }
      if (tokens[i - 1].type == kqlNumber || tokens[i - 1].type == kqlVariable)
        continue;
      tokens[i].value = '--';
    }
  }

  // now identify operators
  for (Token t in tokens) {
    if (t.type == kqlCharacter || t.type == kqlVariable) {
      if (pmListFind(operators, t.value, xform: (var x) => x.symbol) >= 0)
        t.type = kqlOperator;
      else if (t.type == kqlCharacter) t.type = kqlString;
    }
  }
  return tokens;
}

List<Token> generateTokens(String inputString) {
  // go from an input string to a list of tokens
  List<Token> tokens = pmExtractPrimitiveTokens(inputString);
  tokens = classifyTokens(tokens);
  return tokens;
}
