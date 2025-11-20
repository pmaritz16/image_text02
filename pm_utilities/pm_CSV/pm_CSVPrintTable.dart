// 2021-01-21

import 'pm_CSVDatasets.dart';
//import '../pm_dartUtils.dart';

class PMCSVPrintTable {
  static printTable(PMCSVDataSet dataSet) {
    //final PMR p = PMR(className: 'Print Table', defaultLevel: 1, addClassToken: false);
    List<PMCSVDSchemaItem> schema = dataSet.schema;

    pad(entry, width) {
      String s = entry.toString();
      int size = 0;
      switch (width) {
        case kpmwXS:
          size = 3;
          break;
        case kpmwS:
          size = 6;
          break;
        case kpmwM:
          size = 9;
          break;
        case kpmwL:
          size = 15;
          break;
        case kpmwXL:
          size = 25;
          break;
        default:
          size = 6;
      }
      while (s.length < size) s = ' ' + s;
      return s;
    }

    String formrow(row) {
      String s = '|';
      for (int i = 0; i < row.length; i++) {
        if (i >= schema.length) break;
        if (schema[i].colVis == kpmvI) continue; // invisible column
        var item;
        if (row[i] is double) {
          int digits = (schema[i].colDigits >= 0) ? schema[i].colDigits : 1;
          item = row[i].toStringAsFixed(digits);
        }
        else item = row[i];
        s = s + pad(item, schema[i].colWidth) + '|';
      }
      return s;
    }

    //p.logR('\nTABLE: ${dataSet.name}, length: ${dataSet.table.length}');
    List colNames = [];
    for (PMCSVDSchemaItem item in schema) colNames.add(item.colName);
    String nameString = formrow(colNames);
    //p.logR(nameString);
    String x = '';
    for (int i = 0; i < nameString.length; i++) x = x + '-';
    //p.logR(x);
    //for (List l in dataSet.table) {
      //p.logR(formrow(l));
    //}
  }
}
