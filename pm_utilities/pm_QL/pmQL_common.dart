//2021-07-30

import '../pm_dartUtils.dart';
import '../pm_constants.dart';
import 'dart:math';

const kqlString = 'String';
const kqlNumber = 'Number';
const kqlVariable = 'Variable';
const kqlCharacter = 'Character';
const kqlReserved = 'Reserved';
const kqlSeparator = 'Separator';
const kqlOperator = 'Operator';
const kqlExpression = 'Expression';
const kqlError = 'Error';
const kqlColumnar = 'columnar';
const kqlLookup = 'lookup';
const kqlRow = 'row';

const kqlReservedWords = {'FALSE': true, 'TRUE': true};

var random = Random(DateTime.now().millisecondsSinceEpoch);

// operators with two char symbols
List doubleCharOperators = [
  ['=', '=', '=='],
  ['!', '=', '!='],
  ['<', '=', '<='],
  ['>', '=', '>='],
  ['|', '|', '||'],
  ['&', '&', '&&'],
];

final PMR p = PMR(className: 'Common', defaultLevel: 0);


class Operator {
  final String symbol;
  final int left; // number of operands to left of operator symbol
  final int right; // number to the right
  final Function
      operation; // function to perform op - takes a List of argument values from left to right
  String type;

  Operator({
    this.symbol = '',
    this.left = 0,
    this.right = 0,
    this.operation = pmNoop,
    this.type = '',
  });
}

// operators in order of precedence for binding
List<Operator> operators = [
  Operator(
      symbol: '--',
      left: 0,
      right: 1,
      operation: (list) => numeric(list, (list) => (-list[0]))),
  Operator(
      symbol: 'AVG',
      left: 0,
      right: 1,
      type: kqlColumnar,
      operation: (list) {
        return list[0].computeColumnAverage(list[1]);
      }),
  Operator(
      symbol: 'MIN',
      left: 0,
      right: 1,
      type: kqlColumnar,
      operation: (list) {
        return list[0].computeColumnMinMax(list[1])[kpmMin];
      }),
  Operator(
      symbol: 'MAX',
      left: 0,
      right: 1,
      type: kqlColumnar,
      operation: (list) {
        return list[0].computeColumnMinMax(list[1])[kpmMax];
      }),
  Operator(
      symbol: 'SUM',
      left: 0,
      right: 1,
      type: kqlColumnar,
      operation: (list) {
        var result = list[0].computeColumnSum(list[1]);
        return result;
      }),
  Operator(
      symbol: 'COUNT',
      left: 0,
      right: 1,
      type: kqlColumnar,
      operation: (list) {
        return list[0].computeColumnCount(list[1]);
      }),
  Operator(symbol: 'COUNTER', left: 0, right: 0, operation: seqNum),
  Operator(
      symbol: 'TOSTRING',
      left: 0,
      right: 1,
      operation: (list) => list[0].toString()),
  Operator(
      symbol: 'ROWSTR',
      left: 0,
      right: 0,
      type: kqlRow,
      operation: (list) => list[0].substring(1, list[0].length - 1)),
  Operator(symbol: 'SUBSTR', left: 1, right: 2, operation: substr),
  Operator(
      symbol: 'CONCAT',
      left: 1,
      right: 1,
      operation: (list) => list[0].toString() + list[1].toString()),
  Operator(
      symbol: 'REGEXP',
      left: 1,
      right: 1,
      operation: regexp),
  Operator(
      symbol: 'EPOCHINMS',
      left: 0,
      right: 0,
      operation: (list) => DateTime.now().millisecondsSinceEpoch),
  Operator(
      symbol: 'EPOCHINDAYS', left: 0, right: 1, operation: daysSinceEpoch),
  Operator(
      symbol: 'DATENOW',
      left: 0,
      right: 0,
      operation: (list) => pmDateString(DateTime.now())),
  Operator(
      symbol: 'TIMENOW',
      left: 0,
      right: 0,
      operation: (list) => pmTimeString(DateTime.now())),
  Operator(
      symbol: 'TRUNC',
      left: 0,
      right: 1,
      operation: (list) => numeric(list, (list) => list[0].truncate())),
  Operator(
      symbol: 'ROUND',
      left: 0,
      right: 2,
      operation: (list) => numeric(list, roundNum)),
  Operator(
      symbol: 'RANDOM',
      left: 0,
      right: 0,
      operation: (list) => random.nextDouble()),
  Operator(
      symbol: '?', left: 1, right: 2, operation: (list) => list[0] != 0 ? list[1] : list[2]),
  Operator(
      symbol: '^',
      left: 1,
      right: 1,
      operation: (list) => numeric(list, (list) => pow(list[0], list[1]))),
  Operator(
      symbol: '*',
      left: 1,
      right: 1,
      operation: (list) => numeric(list, (list) => (list[0] * list[1]))),
  Operator(
      symbol: '/',
      left: 1,
      right: 1,
      operation: (list) => numeric(list, (list) => (list[0] / list[1]))),
  Operator(
      symbol: '%',
      left: 1,
      right: 1,
      operation: (list) => numeric(list, (list) => (list[0] % list[1]))),
  Operator(
      symbol: '-',
      left: 1,
      right: 1,
      operation: (list) => numeric(list, (list) => (list[0] - list[1]))),
  Operator(symbol: '+', left: 1, right: 1, operation: plus),
  Operator(
      symbol: '!',
      left: 0,
      right: 1,
      operation: (list) => numeric(list, (list) => (list[0] == 0 ? 1 : 0))),
  Operator(symbol: '<', left: 1, right: 1, operation: slt),
  Operator(symbol: '>', left: 1, right: 1, operation: sgt),
  Operator(symbol: '<=', left: 1, right: 1, operation: sle),
  Operator(symbol: '>=', left: 1, right: 1, operation: sge),
  Operator(symbol: '==', left: 1, right: 1, operation: (list) => (list[0] == list[1] ? 1 : 0)),
  Operator(symbol: '!=', left: 1, right: 1, operation: (list) => (list[0] != list[1] ? 1 : 0)),
  Operator(
      symbol: '&&',
      left: 1,
      right: 1,
      operation: (list) {
        return numeric(list, (list) => (list[0] != 0 && list[1] != 0) ? 1 : 0);
      }),
  Operator(
      symbol: '||',
      left: 1,
      right: 1,
      operation: (list) {
        return numeric(list, (list) => (list[0] != 0 || list[1] != 0) ? 1 : 0);
      }),
];

numeric(list, op) {
  for (var l in list) {
    if (!(l is int || l is double)) {
      qlError('NON-NUMERIC OPERAND: $l', Token());
    }
  }
  return op(list);
}

class Token {
  String type;
  var value;
  final int index;
  final String inputString;
  List<Token> operands = [];

  Token({this.value, this.type = '', this.index = 0, this.inputString = ''});

  String dump({String m = ''}) {
    //String oprs = '';
    //for (Token opr in operands) oprs = oprs + 'o: ${opr.type} ${opr.value}, ';
    return 'token $m : t:$type v:$value';
  }
}

dumpTokenList(List<Token> tokens, {m}) {
  print('Token List $m length ${tokens.length}');
  for (Token t in tokens) print(t.dump());
}

qlError(var msg, Token token) {
  String errorMsg = 'PMQL ERROR: ${msg.toString()}';
  if (pmNotNil(token)) {
    if (pmNotNil(token.inputString)) {
      p.logE(errorMsg);
      errorMsg = errorMsg + '\ninput: ${token.inputString}';
      p.logE(token.inputString);
      String spacer = '';
      for (int i = 0; i < token.index; i++) spacer = spacer + ' ';
      p.logE('$spacer^');
    }
  }
  throw msg.toString();
}

roundNum(List l) {
  String y = l[0].toStringAsFixed(l[1].round());
  return double.parse(y);
}

int truncNum(List l) {
  return l[0].truncate();
}

int seqCount=0;
int seqNum(List list) {
  return seqCount++;
}

numStr(List l) {
  l[0] = l[0].round(l[2]);



}

regexp(List list) {
  int r = RegExp(list[1].toString()).hasMatch(list[0].toString()) ? 1 : 0;
  //p.logR('REGEXP: ${list[0]}\n${list[1]}\n$r', level: 1);
  return r;
}

substr(List l) {
  if ((l[1] is double) && (l[2] is double))
    return pmSubstring(l[0].toString(), start: l[1].truncate(), len: l[2].truncate());
  qlError('NON-NUMERIC OPERAND', Token());
}

plus(List l) {
  if (l[0] is String || l[1] is String) return l[0].toString() + l[1].toString();
  return l[0] + l[1];
}

sle(List l) {
  if (l[0] is String || l[1] is String)
    return l[0].toString().compareTo(l[1].toString()) <= 0 ? 1 : 0;
  return l[0] <= l[1] ? 1 : 0;
}

slt(List l) {
  if (l[0] is String || l[1] is String)
    return l[0].toString().compareTo(l[1].toString()) < 0 ? 1 : 0;
  return l[0] < l[1] ? 1 : 0;
}

sge(List l) {
  if (l[0] is String || l[1] is String)
    return l[0].toString().compareTo(l[1].toString()) >= 0 ? 1 : 0;
  return l[0] >= l[1] ? 1 : 0;
}

sgt(List l) {
  if (l[0] is String || l[1] is String)
    return l[0].toString().compareTo(l[1].toString()) > 0 ? 1 : 0;
  return l[0] > l[1] ? 1 : 0;
}

daysSinceEpoch(List l) {
  if (pmCheckDate(l[0])) {
    var d1 = DateTime.parse(l[0].replaceAll('/', '-'));
    var d3 = d1.difference(DateTime.parse('1970-01-01'));
    return d3.inDays;
  }
  else return 0;
}


int findOperatorIndex(String symbol) {
  for (int i = 0; i < operators.length; i++) {
    if (operators[i].symbol == symbol) return i;
  }
  return -1;
}
