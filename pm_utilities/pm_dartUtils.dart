// 2025-03-01
// Null Safe

import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'dart:math';

import 'pm_constants.dart';

//import 'package:meta/meta.dart';

const kpmFlutterMode = true; // set to true for use in AndroidStudio/Flutter
const kpmReportingLevel = 0; // use to turn logging on/off, see PMLog below

final PMR p = PMR(className: 'Dart Utils', defaultLevel: 0);

pmAddLine(String r, String s) {
  return r + '\n' + s;
}

bool pmDateGreater(a, b) {
  return a.compareTo(b) > 0;
}

String pmDateString(DateTime d, {String sep = '/'}) {
  String year = d.year.toString();
  String month = pmPadNum(d.month, 2);
  String day = pmPadNum(d.day, 2);
  return '$year$sep$month$sep$day';
}

String pmDateTimeString(DateTime d, {String sep = '/'}) {
  return '${pmDateString(d, sep: sep)} ${pmTimeString(d, seconds: true)}';
}

List pmDeepListCopy(List l) {
  List n = [];
  for (int i = 0; i < l.length; i++) {
    String type = l[i].runtimeType.toString();
    print(type);
    n.add(type.substring(0, type.length < 4 ? type.length : 4) == 'List'
        ? pmDeepListCopy(l[i])
        : l[i]);
  }
  return n;
}

void pmDeleteEntry(String name) {
  // recursively deletes a directory or file
  var ff = new File(name);
  if (ff.existsSync()) {
    ff.deleteSync();
  } else {
    var dd = new Directory(name);
    if (dd.existsSync()) {
      dd.deleteSync(recursive: true);
    }
  }
}

bool pmEntryExists(name) {
  // test whether a directory entry exists (file or Dir)
  var ff = new File(name);
  if (ff.existsSync()) {
    return true;
  } else {
    var dd = new Directory(name);
    if (dd.existsSync()) {
      return true;
    }
  }
  return false;
}

DateTime pmDirLastMod(FileSystemEntity dir) {
  var stats = dir.statSync();
  return stats.modified;
}

bool pmIsBlank(String s) {
  if (pmNil(s)) return true;
  return RegExp(r'^\s+$').hasMatch(s);
}

pmIsNumber(var arg) {
  return (arg is int || arg is double);
}

bool pmIsStringNumber(String s, {decimal = false}) {
  for (int i = 0; i < s.length; i++) {
    switch (s.substring(i, i + 1)) {
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        break;
      case '.':
        if (!decimal) return false;
        break;
      default:
        return false;
    }
  }
  return true;
}

pmLength(var item) {
  if (item == null) return null;
  return item.length;
}


class PMLinkedNode {
  final nodeValue;
  PMLinkedNode? leftNode;
  PMLinkedNode? rightNode;

  PMLinkedNode({required this.nodeValue});

  PMLinkedNode? get left => leftNode;

  set left(PMLinkedNode? l) {
    leftNode = l;
  }

  PMLinkedNode? get right => rightNode;

  set right(PMLinkedNode? l) {
    rightNode = l;
  }

  get value => nodeValue;

  PMLinkedNode? delete({Function? cb}) {
    // delete the node and always return first link in the chain,
    // avoids losing the reference to the chain
    if (leftNode != null) leftNode!.right = rightNode;
    if (rightNode != null) rightNode!.left = leftNode;
    if (cb != null) cb(value);
    if (leftNode == null)
      return rightNode; // this was first link, right will be new first link
    else {
      return _skipToStart();
    }
  }

  PMLinkedNode? deleteChain({Function? cb}) {
    PMLinkedNode? node = _skipToStart();
    while (node != null) {
      node = node.delete(cb: cb);
    }
    return null;
  }

  append(PMLinkedNode newNode, {Function? cb}) {
    PMLinkedNode? node = _skipToEnd();
    node!.rightNode = newNode;
    newNode.left = node;
    if (cb != null) cb(newNode.value);
  }

  PMLinkedNode? _skipToStart() {
    PMLinkedNode? node = this;
    while (node!.left != null) node = node.left;
    return node;
  }

  PMLinkedNode? _skipToEnd() {
    PMLinkedNode? node = this;
    while (node!.right != null) node = node.right;
    return node;
  }

  find(findValue) {
    PMLinkedNode? node = _skipToStart();
    while (node != null && node.value != findValue) {
      node = node.right;
    }
    return node;
  }

  insertAfter(PMLinkedNode node) {
    node.right = rightNode;
    node.left = this;
    if (rightNode != null) rightNode!.left = node;
    rightNode = node;
  }

  String stringifyChain() {
    PMLinkedNode? node = _skipToStart();
    String s = '|';
    while (node != null) {
      s = s + '${node.value},';
      node = node.right;
    }
    return s = s + '|';
  }
}


List<Map>? pmListDir(String inPath, {forceToUpperCase = true}) {
  // List out contents of a Directory of pathL inPath
  // returning a sorted, ascending
  // List of maps of form:
  // {kpmEntry: FileSystemEntity,
  // kpmParsePath: PMParsePath,
  // kpmDir: bool,
  // kpmFileName: name}
  // returns null if error

  comp(a, b) {
    String an = a[kpmFileName];
    String bn = b[kpmFileName];
    if (forceToUpperCase) {
      an = an.toUpperCase();
      bn = bn.toUpperCase();
    }
    return an.compareTo(bn);
  }

  List<Map>? dl;
  var myDir = Directory(inPath);
  if (myDir.existsSync()) {
    try {
      dl = [];
      List<FileSystemEntity> contents = myDir.listSync();
      for (var c in contents) {
        PMParsePath pp = PMParsePath(c.path);
        Map m = {
          kpmEntry: c,
          kpmDir: (c is Directory) ? true : false,
          kpmParsePath: pp,
          kpmFileName: pp.fileName,
        };
        dl.add(m);
      }
      dl.sort(comp);
    } catch (err) {}
  }
  return dl;
}

List pmListsCopy(List<List> lists) {
  // concatenates a list of lists, producing one new list
  if (pmNil(lists)) return [];
  List newList = [];
  for (List ll in lists) if (pmNotNil(ll)) for (var l in ll) newList.add(l);
  return newList;
}

int pmListFind(List list, var value, {Function xform = pmNoop}) {
  if (pmNil(list)) return -1;
  // find an item in a list, the optional xform function first transforms list items to the same type of "value".
  for (int i = 0; i < list.length; i++) {
    if (value == xform(list[i])) {
      return i;
    }
  }
  return -1;
}

List pmListInit(int len, var value) {
  List l = [];
  for (int i = 0; i < len; i++) l.add(value);
  return l;
}

bool pmNil(var arg) {
  // returns true if argument is null or "empty"
  if (arg == null) return true;
  if (arg is String || arg is List) return (arg.length == 0);
  if (arg is int) return false;
  if (arg is double) return false;
  if (arg is Map || arg is Set || arg is Queue) return arg.isEmpty;
  return false;
}

pmNoop(x) => x;

bool pmNotNil(var arg) {
  return !pmNil(arg);
}

pmCheckDate(String d) {
  bool checkSeg(String s, int l) {
    return !(s.length == l && pmDigits(s));
  }

  List dl = d.split('/');
  if (dl.length != 3) return false;
  if (checkSeg(dl[0], 4)) return false;
  if (checkSeg(dl[1], 2)) return false;
  if (checkSeg(dl[2], 2)) return false;
  return true;
}

String pmSetDate(String dr) {
  // fill out YYYY/MM/DD date with defaults

  var ds = pmDateString(DateTime.now()); // returns today's date in YYYY/MM/DD
  if (pmNil(dr)) {
    return ds;
  }

  List<String> dsl = ds.split('/');
  List<String> drl = dr.split('/');
  for (String seg in drl) if (!pmDigits(seg)) return dr;
  switch (drl.length) {
    case 1:
      dsl[2] = drl[0];
      break;
    case 2:
      dsl[1] = drl[0];
      dsl[2] = drl[1];
      break;
    case 3:
      dsl = drl;
      break;
    default:
      return dr;
  }
  if (dsl[1].length == 1) dsl[1] = '0' + dsl[1];
  if (dsl[2].length == 1) dsl[2] = '0' + dsl[2];
  if (dsl[0].length < 4) return dr;

  return dsl[0] + '/' + dsl[1] + '/' + dsl[2];
}

bool pmDigits(String s) {
  if (pmNil(s)) return false;
  if (s.substring(0, 1) == '-') return false;
  return pmInteger(s);
}

bool pmInteger(String? s) {
  if (s == null) return false;
  int? i = int.tryParse(s);
  return (i != null);
}

bool pmNumber(String? s) {
  if (s == null) return false;
  double? d = double.tryParse(s);
  return (d != null);
}

double? pmToDouble(String s) {
  if (pmNil(s)) return null;
  return double.tryParse(s);
}

String pmPadNum(int n, int nChars) {
  String s = n.toString();
  while (s.length < nChars) s = '0' + s;
  return s;
}

class PMParsePath {
  bool windows = true;
  String fullPath = '';
  String rootName = '';
  String parentName = '';
  String pathTo = '';
  String fileName = '';
  String base = '';
  String ext = '';
  List pathList = [];
  late String separator;
  late String altSeparator;

  static String join(String path, name) {
    return pmJoinPathToName(path, name);
  }

  PMParsePath(String p) {
    String fn;

    if (Platform.isWindows) {
      windows = true;
      separator = kpmWindowsSeparator;
      altSeparator = kpmDefaultSeparator;
      //print('Platform is Windows: $separator');
    } else {
      windows = false;
      altSeparator = kpmWindowsSeparator;
      separator = kpmDefaultSeparator;
      //print('Platform is Not Windows: $separator');
    }

    String pmBase(String n) {
      List l1 = n.split('.');
      if (l1.length == 1) return n;
      int l = l1.last.length;
      return n.substring(0, n.length - l - 1);
    }

    String pmExt(String n) {
      List l1 = n.split('.');
      if (l1.length == 1) return '';
      int l = l1.last.length;
      return n.substring(n.length - l, n.length);
    }

    if (pmNil(p)) return; // nothing to do

    fullPath = p.replaceAll(
        altSeparator, separator); // set correct separator everywhere
    List lp = fullPath.split(separator);
    //print('full path: $fullPath. separator $separator, list: $lp');
    if (pmNil(lp[0])) lp.removeAt(0); // occurs in '/xxx...'
    if (pmNil(lp[lp.length - 1]))
      lp.removeAt(lp.length - 1); // occurs in '.../xxx/'
    if (lp.length == 0) return;
    if (lp.length == 1)
      fn = lp[0];
    else
      fn = lp.last;

    fileName = fn;
    base = pmBase(fn);
    ext = pmExt(fn);

    if (lp.length > 1) {
      lp.removeLast();

      // recreate the path to the file
      String pp = separator;
      if (windows) {
        // deal with windows leading drive letter
        if (RegExp('^[a-z,A-Z]:').hasMatch(lp[0])) pp = '';
      }
      for (int i = 0; i < lp.length; i++) pp = pp + lp[i] + separator;
      pathTo = pp;

      if (lp.length > 0) {
        // set root name to first directory in the list
        if (windows && RegExp('^[a-z,A-Z]:').hasMatch(lp[0])) {
          // the windows drive letter is not considered root or parent
          if (lp.length > 1) {
            rootName = lp[1];
            parentName = lp[lp.length - 1];
          }
        } else {
          rootName = lp[0];
          parentName = lp[lp.length - 1];
        }
        // preserve the path list
        pathList = lp;
      }
    } // end constructor
  }

  stringify() {
    return '\npmParsePath: windows=$windows' +
        '\nfullPath: $fullPath' +
        '\npathTo: $pathTo' +
        '\npathList: $pathList' +
        '\nfileName: $fileName' +
        '\nbase: $base' +
        '\next: $ext' +
        '\nrootName: $rootName' +
        '\nparentName: $parentName';
  }
}

String pmJoinPathToName(String path, String name) {
  if (pmNil(path)) return name;
  int len = path.length;
  String separator = Platform.isWindows ? '\\' : '/';
  if (path.substring(len - 1, len) == separator) return path + name;
  return path + separator + name;
}

class PMLog {
  // write log messages to the console.
  // messages can be:
  // - printed to the console, or
  // - accumulated in a log and then dumped,
  // or both.
  // Messages are only logged if their "level" is higher than the
  // global reporting level constant - see top of this file.
  // This allows only messages of a sufficient level to be seen.

  // used to make messages stand out
  static const kAsterix = '***********';
  static const kSpaces = '           ';
  static const kInternalError = '!! APP ERROR !! ';

  static List logList = [];
  static bool logToList = false;
  static bool logToConsole = true;

  static listOnOff(bool onOff) {
    logToList = onOff;
  }

  static consoleOnOff(bool onOff) {
    logToConsole = onOff;
  }

  static dumpLog() {
    print(kAsterix + ' LOG ' + kAsterix);
    for (int i = 0; i < logList.length; i++) {
      print('${logList[i]}');
    }
  }

  static purgeLog() {
    logList = [];
  }

  static aPrint() {
    if (kpmFlutterMode) print(kSpaces + kAsterix + kAsterix);
  }

  static sPrint(m) {
    if (kpmFlutterMode) {
      DateTime time = DateTime.now();
      String ms = '${time.minute}:${time.second} $m';
      if (logToConsole) print(kSpaces + ms);
      if (logToList) logList.add(ms);
    } else {
      if (logToConsole) print(m);
      if (logToList) logList.add(m);
    }
  }

  static mPrint(String m) {
    aPrint();
    sPrint(m);
    //aPrint();
  }

  // log the string
  static void r(var m1, {String m = '', int level = 0}) {
    if (level > kpmReportingLevel && m1 != null) {
      mPrint('$m ${m1.toString()}');
    }
  }

  // log the JSON rendition of an object
  static void j(var obj, {String m = '', int level = 0, error}) {
    // logging Json representation of object state
    if (level > kpmReportingLevel || error != null) {
      aPrint();
      if (error != null) mPrint('APP ERROR: ' + error.toString());
      if (pmNotNil(m)) mPrint(m);
      JsonEncoder encoder = JsonEncoder.withIndent('  ');
      List indentList = encoder.convert(obj).split('\n');
      for (String line in indentList) sPrint(line);
    }
  }

  static void o(var obj,
      {Function xForm = pmNoop, String m = '', int level = 0, error}) {
    // logging Json representation of object state
    if (level > kpmReportingLevel) {
      aPrint();
      if (pmNotNil(m)) mPrint(m);
      if (obj is List || obj is Set)
        obj.forEach((v) => sPrint(xForm(v)));
      else if (obj is Map)
        obj.forEach((k, v) => sPrint('key $k: ${xForm(v)}'));
      else
        e('unknown type fed to PMLog.o: ${obj.runtimeType}');
    }
  }

  // log an app error
  static void e(m, {error}) {
    String ms = kInternalError + m;
    mPrint('$ms ${(error == null) ? '' : (' | ' + error.toString())}');
  }

  // log and throw an app error
  static void E(m, {error}) {
    // logging AND throwing an error
    String ms = kInternalError + m;
    mPrint('$ms ${(error == null) ? '' : (' | ' + error.toString())}');
    throw 'SERIOUS APP ERROR';
  }
}

List pmMatchRegX(String target, Iterable exps) {
  // takes in a list of RegX's, and returns a list of all matches and their
  // indices where found in the string
  List lm = [];
  for (var exp in exps) {
    Iterable<Match> matches = exp.allMatches(target);
    if (matches.length > 0) {
      for (Match m in matches) {
        var match = m.group(0);
        var pos = m.end - pmLength(match);
        var rm = {'indexOf': pos, 'match': match};
        //print("Match: ${target}, ${rm['position']}, ${rm['matched']}");
        lm.add(rm);
      }
    }
  }
  return lm;
}

int pmMatchX(String target, RegExp regx) {
  List lm = pmMatchRegX(target, [regx]);
  if (lm.length == 0) return -1;
  return lm[0]['indexOf'];
}

class PMR {
  // proxy to PMLog that adds in class name and
  // sets reporting level for the calling class instance
  String className;
  int defaultLevel;
  bool addClassToken;

  PMR(
      {required this.className,
      this.defaultLevel = 0,
      this.addClassToken = true});

  String _addClassToken(m, token) {
    if (addClassToken)
      return className +
          (token != null ? ' from: $token, ' : '') +
          (m != null ? '| $m ' : '');
    else
      return m;
  }

  int _setLevel(level) {
    return level == null ? defaultLevel : level;
  }

  logR(m1, {String m = '', level, token}) =>
      PMLog.r(_addClassToken(m1 + m, token), level: _setLevel(level));

  logF(m1, {String m = '', level, token}) =>
      PMLog.r(_addClassToken(m1 + (pmNotNil(m) ? ' | ' + m : ''), token),
          level: defaultLevel + 1);

  logJ(obj, {String m = '', level, token}) =>
      PMLog.j(obj, m: _addClassToken(m, token), level: _setLevel(level));

  logE(m, {error, token}) => PMLog.e(_addClassToken(m, token), error: error);

  logEJ(obj, {m, error, token}) =>
      PMLog.j(obj, m: _addClassToken(m, token), error: error);

  logO(obj,
          {String m = '',
          Function xForm = pmNoop,
          int level = 0,
          String token = ''}) =>
      PMLog.o(obj,
          m: _addClassToken(m, token), xForm: xForm, level: _setLevel(level));

  on() {
    defaultLevel = 3;
  }

  off() {
    defaultLevel = 0;
  }
}

int pmRandom(int min, max) {
  final random = Random();
  return min + random.nextInt(max - min + 1);
}

bool pmSC(first, second) {
  // compare two strings, fail if first arg is null
  if (first == null) return false;
  return (first == second);
}

pmTrue(bool? x) {
  if (pmNil(x)) return false;
  return x;
}

String pmTS(value) {
  if (value == null) return '';
  return value.toString();
}

pmSortedListFind(List list, var value, {Function xform = pmNoop}) {
  // find an item in a list, sorted in ascending order, via a binary search
  // the optional xform function first transforms list items.

  findBetween(int start, int end) {
    if (end < start || start > end) return null;
    double md = (end - start) / 2; // find midpoint
    int m = start + md.truncate();
    var vm = xform(list[m]);
    if (value == vm) return m; // found item
    if (value.compareTo(vm) < 0)
      return findBetween(start, m - 1);
    else
      return findBetween(m + 1, end);
  }

  return findBetween(0, list.length - 1);
}

String pmStripCommaListSpaces(String s) {
  // strip leading,trailing spaces from comma separated list
  RegExp r1 = RegExp(r'^\s*');
  RegExp r2 = RegExp(r'\s*$');
  RegExp r3 = RegExp(r'\s*,\s*');
  s = s.replaceAll(r1, '');
  s = s.replaceAll(r2, '');
  s = s.replaceAll(r3, ',');
  return s;
}

String pmSubstring(s, {int start = 0, int len = 1}) {
  // provides javascript-like Substring function
  int end;

  if (len < 0) len = s.length;
  if (start < 0) start = 0;
  end = start + len;
  if (end > s.length) end = s.length;

  return s.substring(start, end);
}

bool pmTestRegX(String target, Iterable exps) {
  // tests a string against a list of regX's
  var ll = pmMatchRegX(target, exps);
  return (ll.length > 0);
}

String pmTimeString(DateTime d, {bool seconds = false}) {
  String hours = pmPadNum(d.hour, 2);
  String mins = pmPadNum(d.minute, 2);
  String secs = pmPadNum(d.second, 2);
  if (seconds)
    return '${hours}h${mins}m$secs';
  else
    return '${hours}h$mins';
}

String pmTimeNow() => DateTime.now().toString();

pmType(arg) {
  if (arg is String) return 'String';
  if (arg is int) return 'int';
  if (arg is double) return 'double';
  if (arg is bool) return 'bool';
  if (arg is Map) return 'Map';
  if (arg is List) return 'List';

  return 'Other';
}
