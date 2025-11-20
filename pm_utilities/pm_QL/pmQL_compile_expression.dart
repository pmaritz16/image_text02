// 2021-07-30

import 'pmQL_generate_tokens.dart';
import 'pmQL_common.dart';
import '../pm_dartUtils.dart';

final PMR p = PMR(className: 'CompileExpression', defaultLevel: 0);

printExpressionList(List<Token> tree, String indent, {level}) {
  const base = '...';
  for (Token t in tree) {
    //p.logR('$indent${t.dump()}', level: level);
    if (t.type == kqlExpression)
      printExpressionList(t.value, base + indent);
    else {
      for (Token opr in t.operands) printExpressionList([opr], base + indent);
    }
  }
}

printEvalTree(Token t, String indent, {m = '', level}) {
  const base = '...';
  //p.logR('$indent$m${t.dump()}', level: level);
  for (Token opr in t.operands) {
    printEvalTree(opr, base + indent, m: 'opr ');
  }
}

List<Token> replaceSubExpressions(List<Token> tokensIn,
    {bool inParens = false}) {
  // first replace all subexpressions with expression tokens
  List<Token> tokens = [];
  Token t = Token();

  while (tokensIn.length > 0) {
    t = tokensIn[0];
    if (t.value == '(') {
      tokensIn.removeAt(0);
      List<Token> subExp = replaceSubExpressions(tokensIn, inParens: true);
      tokens.add(Token(type: kqlExpression, value: subExp));
      continue;
    }
    if (t.value == ')') {
      if (inParens) {
        tokensIn.removeAt(0);
        inParens = false;
      } else
        qlError('unmatched )', t);
      break;
    }
    tokens.add(t);
    tokensIn.removeAt(0);
  }

  if (inParens) qlError('Missing )', t);
  return tokens;
}

bool validOperandType(Token token) {
  switch (token.type) {
    case kqlExpression:
    case kqlNumber:
    case kqlString:
    case kqlVariable:
    case kqlOperator:
      return true;
    default:
      {
        print('invalid operand: ${token.type}');
        return false;
      }
  }
}

Token assignOperands(List<Token> tokensIn) {

  //p.logR('assignOperands entry');
  printExpressionList(tokensIn, '');


  if (tokensIn.length == 1) {
    // if it is just a single variable, return that
    if (tokensIn[0].type == kqlVariable)
      return tokensIn[0];
    // if it is from an expression in ()'s, dereference it
    if (tokensIn[0].type == kqlExpression) {
      return assignOperands(tokensIn[0].value);
    }
  }

  // otherwise look for an operator in order of precedence
  int opi = 0;
  int ts = 0;
  while (tokensIn.length >= 1 && opi < operators.length) {
    Operator op = operators[opi];
    //p.logR('found ${op.symbol}');

    // scan remaining portion of the token list
    int i = ts;
    while (i < tokensIn.length) {
      if (tokensIn[i].type == kqlOperator && op.symbol == tokensIn[i].value)
        break;
      i++;
    }

    // found an instance of the operator??
    if (i >= tokensIn.length) {
      // not found
      ts = 0; // reset to start of tokenList
      opi++; // and go onto the next operator

    } else {
      // operator was found at i

      Token t = tokensIn[i]; // remember it
      tokensIn.removeAt(i); // excise it
      int k = i - op.left; // where do left operands start?
      if (k < 0) qlError('missing left operand: ${t.value}', t);
      int m = op.right + op.left; // how many total operands?
      //p.logR('initial m= $m, k=$k');
      while (m > 0) {
        //p.logR('m= $m, k=$k');
        m--;
        if (k >= tokensIn.length) qlError('missing right operand: ${t.value}', t);
        if (!validOperandType(tokensIn[k])) qlError('invalid operand type', t);
        t.operands.add(tokensIn[k]);
        tokensIn.removeAt(k); // excise the operands out
      }

      // reinsert the operator token, now with its operands
      tokensIn.insert(k, t);

      // move start point of search to next token, and look for more op instances
      ts = k + 1;
    }
  }

  // at the end of all this, there should be a single operator left
  if (tokensIn.length > 1) {
    String ms = '';
    for (int m=0;m<tokensIn.length;m++) ms = ms + tokensIn[m].value + ',';
    qlError('unmatched operators/operands: $ms', tokensIn[tokensIn.length - 1]);
  }

 // now walk the tree, looking for expressions that need to have operands assigned
  assign(Token t) {
    for (int i = 0; i < t.operands.length; i++) {
      Token opr = t.operands[i];
      if (opr.type == kqlExpression)
        t.operands[i] = assignOperands(opr.value);
      else
        assign(opr);
    }
  }

  Token t = tokensIn[0];
  assign(t);

  return t;
}

Token compileExpression (String input) {
  try {
    // generate a list of tokens
    List<Token> tokens = generateTokens(input);

    // form into a tree of expressions, each a list of tokens
    List<Token> parseTree = replaceSubExpressions(tokens);

    // now bind operands to operators, yielding a tree ready for evaluation
    Token evalTree = assignOperands(parseTree);
    return evalTree;
  } catch (e) {
    p.logE('COMPILE ERROR: ${e.toString()}');
    return Token(type: kqlError, value: e.toString());
  }
}
