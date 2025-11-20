// 2024-04-20

import '../pm_dartUtils.dart';
import '../pm_constants.dart';

final PMR p = PMR(className: 'CSV DataSets', defaultLevel: 0);

/* Group of Classes that manage the creation of table datasets that are persisted in CSV format.
 The general format of a dataset when encoded as CSV is:
  <SetSep>, name<metaSep>value, type<metaSep>value, sort<metaSep>value, time<metaSep>value, schema<metaSep>"item<schemaSep>value,item<schemaSep>value,..."
  [data row]
  [data row]
    ...

    See below for <SetSep>, <metaSep>, <schemaSep>
 */

// Separators
const kpmCSVDataSetSeparator = '<<<|||>>>';
const kpmMetadataSeparator = ':';
const kmpSchemaSeparator = '|';
// 'w' widths
const kpmwXS = 'wXS';
const kpmwS = 'wS';
const kpmwM = 'wM';
const kpmwL = 'wL';
const kpmwXL = 'wXL';
const kpmwXXL = 'wXXL';
const kpmwXXXL = 'wXXXL';
// 't' types
const kpmtS = 'tS'; // string
const kpmtI = 'tI'; // int
const kpmtN =
    'tN'; // tNn = decimal, where n is optional, indicates number of decimal places
const kpmtB = 'tB'; // boolean
const kpmtD = 'tD'; // date in YYYY/MM/DD format
// 'e' field edit controls
const kpmeF = 'eF'; // not user editable
const kpmeN = 'eN'; // may not be null
//const kpmeB = 'eB'; // field may be left blank
const kpmeD = 'eD'; // discard row if blank
// 'v' visibility controls
const kpmvI = 'vI'; // column is invisible
const kpmvF = 'vF'; // column is fixed wrt horizontal scroll
// And:
// 's': summary controls are indicated by 'sXXX' where XXX = SUM, AVG, ...
// 'i': initial Value - ixxxx where xxxx is the default value for the field

//-----------------------------------------------------------------------

class PMCSVDSchemaItem {
  String colName = '';
  String colType = kpmtS; // default type String
  int colDigits = -1;
  String colWidth = kpmwS; // default width
  String colEdit = '';
  String colVis = '';
  String colDefault = '';
  String colSummarize = '';
  List colDropDown = [];

  PMCSVDSchemaItem(nameIn) {
    colName = nameIn;
  }

  encode() {
    return 'colName: $colName, colType: $colType, colDigits: $colDigits, colWidth: $colWidth,' +
        '\ncolEdit $colEdit, colVis: $colVis, ' +
        'colDefault: $colDefault, colSummarize: $colSummarize, colDropDown: $colDropDown';
  }
}

dumpSchemaItem(List schema, int i) {
  p.logE('Item $i: ' + schema[i].encode());
}

dumpSchema(List schema) {
  for (int i = 0; i < schema.length; i++) dumpSchemaItem(schema, i);
}

//-----------------------------------------------------------------------

class PMCSVDataSet {
  List<List> table;
  String name;
  String schemaString;
  List<PMCSVDSchemaItem> schema;
  String timeStamp = '';
  late Function autoFill;
  late Function semanticCheck;

  // attributes
  String sort;
  String show;
  String save;
  String type;

  PMCSVDataSet({
    required this.name,
    required this.schema,
    required this.schemaString,
    required this.table,
    this.type = '',
    this.sort = '',
    this.show = '',
    this.save = '',
  }) {
    if (pmNil(schema)) {
      schema = (pmNil(schemaString)) ? [] : decodeSchema(schemaString);
    } else {
      schemaString = (pmNil(schema)) ? '' : encodeSchema();
    }
    if (pmNil(table)) table = [];
    // initialize to do-nothing functions
    autoFill = (var x) {};
    semanticCheck = (var x, y) {};
  }

  int findColumnIndex(String colName) {
    return pmListFind(schema, colName, xform: (x) => x.colName);
  }

  double computeColumnAverage(String colName) {
    int i = findColumnIndex(colName);
    if (i < 0) throw 'AVG: unable to find column $colName';
    if (table.length == 0) return 0;

    double total = 0;
    int count = 0;
    for (List row in table) {
      //p.logR('row[i] ${row[i]}, ${pmType(row[i])}');
      if (pmNil(row[i])) continue;
      if (!pmIsNumber(row[i])) continue;
      total = total + row[i];
      count++;
    }
    double avg = (total / count);
    return avg;
  }

  computeColumnMinMax(String colName) {
    int i = findColumnIndex(colName);
    if (i < 0) throw 'MIN,MAX: unable to find column $colName';
    if (table.length == 0) return 0;

    var min;
    var max;
    for (List row in table) {
      if (pmNil(row[i])) continue;
      if (!pmIsNumber(row[i])) continue;
      if (min == null) if (row[i] != 0) min = row[i];
      if (max == null) max = row[i];
      if (row[i] < min) min = row[i];
      if (row[i] > max) max = row[i];
    }
    return {kpmMin: min, kpmMax: max};
  }

  double computeColumnSum(String colName) {
    int i = findColumnIndex(colName);
    if (i < 0) throw 'SUM: unable to find column $colName';

    var sum = 0.0;
    for (List row in table) {
      if (pmNil(row[i])) continue;
      if (!pmIsNumber(row[i])) continue;
      sum = sum + row[i];
    }
    return sum;
  }

  int computeColumnCount(String colName) {
    int i = findColumnIndex(colName);
    if (i < 0) throw 'COUNT: unable to find column $colName';

    int count = 0;
    for (List row in table) {
      if (pmNotNil(row[i])) count++;
    }
    return count;
  }

  static bool noErrors(List errors) {
    for (String e in errors) if (pmNotNil(e)) return false;
    return true;
  }

  static bool convertRowToType(
      List row, List<PMCSVDSchemaItem> schema, List errors) {
    for (int i = 0; i < schema.length; i++) errors[i] = '';

    for (int i = 0; i < schema.length; i++) {
      try {
        dynamic convertNumber(Function action, String s) {
          try {
            return (pmIsBlank(s)) ? action('0') : action(s);
          } catch (e) {
            throw 'non-numeric: $s';
          }
        }

        if (i >= row.length) row.add('');

        if (pmNil(row[i])) {
          // field is blank
          if (schema[i].colEdit == kpmeD) {
            // row will be discarded
            row = [];
            return false;
          }
          if (schema[i].colEdit == kpmeN)
            throw 'field may not blank'; // field may not be blank
          if (row[i] == null) row[i] = '';
          // continue;
        }

        //if (schema[i].colEdit == kpmeN && pmNil(row[i])) throw 'empty';

        String rType = row[i].runtimeType.toString();
        switch (schema[i].colType.substring(0, 2)) {
          case kpmtS:
            if (rType != 'String')
              row[i] = row[i].toString();
            else
              row[i].trim();
            break;
          case kpmtI:
            if (rType != 'int')
              row[i] = convertNumber(int.parse, row[i].toString());
            break;
          case kpmtN:
            if (rType != 'double') {
              // deal with $nnn,nnn.nn
              String s = row[i].toString().replaceAll('\$', '');
              s = s.replaceAll(',', '');
              row[i] = convertNumber(double.parse, s);
            }
            break;
          case kpmtB:
            if (rType != 'int') if (row[i].toString().toUpperCase() ==
                    'FALSE' ||
                row[i].toString() == '0')
              row[i] = 0;
            else
              row[i] = 1;
            break;
          case kpmtD:
            if (rType != 'String') row[i] = row[i].toString();
            if (!pmCheckDate(row[i])) throw 'YYYY/MM/DD expected';
            break;
        }
      } catch (e) {
        errors[i] = '${schema[i].colName}: ${e.toString()}';
        return false;
      }
    }
    return true;
  }

  String convertTypes() {
    List errors = pmListInit(schema.length, '');
    int i = -1;

    for (i = 0; i < table.length; i++) {
      bool success = convertRowToType(table[i], schema, errors);
      if (!success)
        table.removeAt(
            i); // fatal error or row will be removed on indicated blank field, type "kpmeD"
      if (!noErrors(errors)) {
        return 'convert types, fatal error: ${name}, line $i, $errors';
      }
    }
    return '';
  }

  List<PMCSVDSchemaItem> decodeSchema(String sIn) {
    List<PMCSVDSchemaItem> schema = [];
    List sp = sIn.split(',');
    for (String p1 in sp) {
      List q1 = p1.split(kmpSchemaSeparator);
      var item = PMCSVDSchemaItem(q1[0]);
      for (int i = 1; i < q1.length; i++) {
        switch (q1[i].substring(0, 1)) {
          case 'w':
            item.colWidth = q1[i];
            break;
          case 't':
            String n = q1[i];
            if (n.substring(0, 2) == kpmtN) {
              try {
                // its a number, does it have precision?
                if (n.length > 2) {
                  String pr = n.substring(2, n.length); // get the digits
                  item.colDigits = int.parse(pr);
                }
              } catch (e) {
                // ignore non-numeric digit specifier
                //p.logR('non-numeric tNx: $n');
              }
            }
            item.colType = n.substring(0, 2);
            break;
          case 'e':
            item.colEdit = q1[i];
            break;
          case 's':
            item.colSummarize =
                q1[i].substring(1, q1[i].length); // strip leading 's'
            break;
          case 'd':
            item.colDropDown.add(q1[i].substring(1)); // strip leading 'd'
            break;
          case 'i':
            item.colDefault = q1[i].substring(1, q1[i].length); // ixxxx
            break;
          case 'v':
            item.colVis = q1[i];
            break;
          default:
        }
      }
      schema.add(item);
    }

    return schema;
  }

  dropColumn(String name) {
    int index = findColumnIndex(name);
    if (index < 0) return;
    schema.removeAt(index);
    for (int i = 0; i < table.length; i++) table[i].removeAt(index);
  }

  String encodeSchema() {
    //p.logR('encoding schema:\n${stringifyDataSet()}');
    String ss = '';
    for (PMCSVDSchemaItem item in schema) {
      String cols = item.colName;
      if (pmNotNil(item.colType)) {
        String digits = item.colDigits >= 0 ? item.colDigits.toString() : '';
        cols = cols + kmpSchemaSeparator + item.colType + digits;
      }
      if (pmNotNil(item.colEdit))
        cols = cols + kmpSchemaSeparator + item.colEdit;
      if (pmNotNil(item.colVis)) cols = cols + kmpSchemaSeparator + item.colVis;
      if (pmNotNil(item.colWidth))
        cols = cols + kmpSchemaSeparator + item.colWidth;
      if (pmNotNil(item.colSummarize))
        cols = cols + kmpSchemaSeparator + 's' + item.colSummarize;
      if (pmNotNil(item.colDefault))
        cols = cols + kmpSchemaSeparator + 'i' + item.colDefault;
      if (pmNotNil(item.colDropDown)) {
        for (String d in item.colDropDown) {
          cols = cols + kmpSchemaSeparator + 'd' + d;
        }
      }
      ss = ss + cols + ',';
    }
    return ss.substring(0, ss.length - 1); // strip last comma
  }

  /*static int findColumnIndex(List schema, String name) {
    int index = pmListFind(schema, name, xform: (x) => x.colName);
    return index;
  }*/

  int findRow(value, colI, {test}) {
    int i;
    for (i = 0; i < table.length; i++) {
      bool equals = (test == null)
          ? (table[i][colI] == value)
          : test(value, table[i][colI]);
      if (equals) break;
    }
    return (i < table.length) ? i : -1;
  }

  String stringifyDataSet() {
    String s = '';
    String sum =
        'Data Set: $name, type $type, sort: $sort, show: $show,table length: ${pmLength(table)}, schema length: ${pmLength(schema)}';
    s = pmAddLine(s, sum);
    s = pmAddLine(s, 'schemaString: $schemaString');
    if (table.length > 0)
      s = pmAddLine(s, 'row 0: len ${table[0].length}, ${table[0]}');
    return s;
  }

  moveRow(bool direction, int index) {
    swap(i, iP1) {
      var row = table[i];
      table[i] = table[iP1];
      table[iP1] = row;
    }

    if (direction) {
      // move down the list
      int indexP1 = index + 1;
      if (indexP1 >= table.length) return;
      swap(index, indexP1);
    } else {
      int indexP1 = index - 1;
      if (indexP1 < 0) return;
      swap(index, indexP1);
    }
    setTimeStamp();
  }

  modifyRow(String operation, int index, List row) {
    // used to add, insert, delete, replace a row]
    //p.logR('Modify row: $operation on $index: $row');
    if (operation == kpmDelete) {
      table.removeAt(index);
    } else {
      switch (operation) {
        case kpmAdd:
          table.add(row);
          break;
        case kpmReplace:
          table[index] = row;
          break;
        case kpmInsert:
          table.insert(index, row);
          break;
        default:
      }
    }
    setTimeStamp();
  }

  setTimeStamp() {
    timeStamp = pmDateTimeString(DateTime.now());
  }

  /*
  setAttributes(String input) {
    if (pmNil(input)) return;
    List l = input.split(',');
    for (int i = 0; i < l.length; i++) {
      if (pmNil(l[i])) continue;
      List lI = l[i].split(':');
      if (lI.length != 2) throw 'Setting Malformed Attribute: ${l[i]}';
      if (pmNil(lI[0]) || pmNil(lI[1])) throw 'Setting Malformed Attribute: ${l[i]}';
      switch (lI[0]) {
        case kpmShow:
          show = lI[1];
          break;
        case kpmType:
          type = lI[1];
          break;
        case kpmSave:
          save = lI[1];
          break;
        case kpmSort:
          sort = lI[1];
          break;
        default:
          throw 'Setting Unknown Attribute: ${l[i]}';
      }
    }
  }

   */

  sortTable(String sortString) {
    if (pmNil(sortString)) return;
    //if (pmNil(sort)) sort = sortString; // if no sort previously specified (sort not copied on COPY dataset)

    // sort string is of form column|direction|column|direction...
    List s = sortString.split(kmpSchemaSeparator);

    try {
      // define a comparison function
      int sortFn(l1, l2) {
        for (int i = 0; i < s.length; i = i + 2) {
          int colI = findColumnIndex(s[i]);
          if (colI < 0) throw 'col ${s[i]} not found';
          bool sortDirection = true;
          if ((i + 1) < s.length) if (s[i + 1].toUpperCase() == kpmDOWN)
            sortDirection = false;

          var l10 = l1[colI];
          var l20 = l2[colI];
          int cVal = 0;
          if (l10 is String || l20 is String) {
            cVal = sortDirection
                ? l10.compareTo(l20.toString())
                : l20.compareTo(l10.toString());
          } else {
            if (l10 != l20)
              cVal = sortDirection
                  ? ((l10 < l20) ? -1 : 1)
                  : ((l10 < l20) ? 1 : -1);
          }
          if (cVal != 0) return cVal;
        }
        return 0;
      }

      table.sort(sortFn);
    } catch (e) {
      p.logE('sort failure $e');
    }
  }

  sortDataSet() {
    if (pmNotNil(sort) && pmNotNil(schema)) {
      sortTable(sort);
    }
  }
} // end class DataSet

//-----------------------------------------------------------------------

