// 2024-04-03

import '../pm_dartUtils.dart';
import '../pm_constants.dart';

class PMCSVBase {
  static const kpmMaxrowLength = 80;

  static decode(String inputString,
      {bool splitrows = true, sweepLeadingSpaces = true}) {
    // takes contents of a CSV file as a string and
    // returns the fields as List<List<String>>

    int index = 0;
    bool endOfRow;
    bool inDoubleQ;
    List row=[];
    List<List> rows = [];
    List<int> field = [];

    int _getNextChar() {
      int c;
      c = (index < 0 || index >= inputString.length)
          ? -1
          : inputString.codeUnitAt(index++);
      //print('_getNextChar: $c');
      return c;
    }

    int _peekNextChar() {
      int c;
      c = (index < 0 || index >= inputString.length)
          ? -1
          : inputString.codeUnitAt(index);
      //print('_peekNextChar: $c');
      return c;
    }

    _sweep() {
      if (sweepLeadingSpaces)
        while (_peekNextChar() == PMCV.Space) _getNextChar();
    }

    _addToField(code) {
      field.add(code);
    }

    _addField() {
      row.add(String.fromCharCodes(field));
      field = [];
      _sweep();
    }

    _addrow() {
      rows.add(row);
      row = [];
    }

    _readrow() {
      int c;
      inDoubleQ = false;
      endOfRow = false;
      field = [];
      row = [];
      while (!endOfRow) {
        c = _getNextChar();
        switch (c) {
          case PMCV.CR:
            continue;
          case PMCV.LF:
          case -1:
            _addField();
            endOfRow = true;
            break;
          case PMCV.Comma:
            if (inDoubleQ) {
              _addToField(c);
            } else
              _addField();
            break;
          case PMCV.DoubleQ:
            if (inDoubleQ) {
              // accumulating quoted string, find out if this is the end of string
              // or an 'escaped' Double quote
              if (_peekNextChar() != PMCV.DoubleQ) {
                // its the end, just ignore the quote and continue;
                inDoubleQ = false;
                continue;
              } else {
                // it is an escape, add a DoubleQ to the field
                c = _getNextChar();
                _addToField(c);
              }
            } else {
              // start of Double quoted string, ignore and set mode
              inDoubleQ = true;
            }
            break;
          case PMCV.BackSlash:
            // backslash at end of row means ignore end of row
            if (splitrows) {
              int n = _peekNextChar();
              if (n == PMCV.CR || n == PMCV.LF) {
                // step over CR or LF
                c = _getNextChar();
                n = _peekNextChar();
                if (n == PMCV.LF) {
                  // deal with CR,LF
                  c = _getNextChar();
                }
              } else
                _addToField(c);
            } else
              _addToField(c);
            break;
          default:
            _addToField(c);
        }
      }
      _addrow();
    }

    if (pmNotNil(inputString)) {
      _sweep();
      while (_peekNextChar() >= 0) {
        _readrow();
      }
    }
    return rows;
  } // end decodeCSV

  static encode(List rows, {bool splitrows = true}) {
    // takes a List<List<Dynamic>> and
    // returns a string representing encoded rows

    //final PMR p = PMR(className: 'CSVB', defaultLevel: 0);

    _addField(List<int> charCodes, String field) {
      List<int> fchars = [];
      bool doubleQ = false;
      for (int i = 0; i < field.length; i++) {
        int c = field.codeUnitAt(i);
        switch (c) {
          case PMCV.Comma:
            doubleQ = true;
            fchars.add(PMCV.Comma);
            break;
          case PMCV.DoubleQ:
            doubleQ = true;
            // escape the Double quote
            fchars.add(PMCV.DoubleQ);
            fchars.add(PMCV.DoubleQ);
            break;
          default:
            fchars.add(c);
        }
      }
      if (doubleQ) charCodes.add(PMCV.DoubleQ);
      for (int i = 0; i < fchars.length; i++) charCodes.add(fchars[i]);
      if (doubleQ) charCodes.add(PMCV.DoubleQ);
      charCodes.add(PMCV.Comma);
    }

    _addrow(List<int> charCodes, List row) {
      int len = 0;
      for (var field in row) {
        String fs = pmNil(field) ? '' : field.toString();
        if (splitrows) {
          if ((len + fs.length) > kpmMaxrowLength) {
            //p.logR('field $fs, len: $len');
            len = 0;
            charCodes.add(PMCV.BackSlash);
            charCodes.add(PMCV.CR);
            charCodes.add(PMCV.LF);
          } else len = len + fs.length;
        }
        _addField(charCodes, fs);
      }
      charCodes[charCodes.length - 1] = PMCV.CR; // replace trailing comma
      charCodes.add(PMCV.LF);
    }

    List<int> charCodes = [];
    for (List row in rows) {
      _addrow(charCodes, row);
    }
    if (charCodes.length == 0) return '';
    if (charCodes[charCodes.length - 1] == PMCV.LF) charCodes.removeLast();
    String rowsString = String.fromCharCodes(charCodes);
    return rowsString;
  } // end encodeCSV

}
