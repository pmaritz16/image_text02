// 2024-04-06

import '../pm_dartUtils.dart';
import '../pm_CSV/pm_CSVDatasets.dart';
import '../pm_constants.dart';


class PMCSVDataSetOps {


  static List join(List<PMCSVDataSet> sets) {
    // join a list of datasets into one CSV file, using
    // separator string in first position of a row, encoding
    // according to header type - see pmCSVESplit for format.
    // Input is a list of Maps
    List newRows = [];
    for (PMCSVDataSet set in sets) {
      List header = [kpmCSVDataSetSeparator];

      addItem(String label, String value) {
        if (pmNotNil(value)) {
          header.add(label + kpmMetadataSeparator + value);
        }
      }

      // create the set header row
      addItem(kpmName, set.name);
      addItem(kpmType, set.type);
      addItem(kpmSort, set.sort);
      addItem(kpmSave, set.save);
      addItem(kpmShow, set.show);
      addItem(kpmTimeStamp, set.timeStamp);
      if (pmNotNil(set.schema)) addItem(kpmSchema, set.encodeSchema());
      newRows.add(header);

      // now add the table rows
      for (List row in set.table)
        newRows.add(row);
    }
    return newRows;
  }

  static setAttributes(PMCSVDataSet currentSet, List row) {
    for (int i = 0; i < row.length; i++) {
      List fields = row[i].split(kpmMetadataSeparator);
      setValue() {
        if (fields.length == 1) return '';
        return fields[1].trim();
      }

      switch (fields[0].trim()) {
        case kpmCSVDataSetSeparator:
          break;
        case kpmShow:
          currentSet.show = setValue();
          break;
        case kpmName:
          currentSet.name = setValue();
          break;
        case kpmSort:
          currentSet.sort = setValue();
          break;
        case kpmSave:
          currentSet.save = setValue();
          break;
        case kpmSchema:
          currentSet.schemaString = setValue();
          if (pmNotNil(currentSet.schemaString)) {
            currentSet.schema = currentSet.decodeSchema(currentSet.schemaString);
            currentSet.convertTypes();
          }
          break;
        case kpmType:
          currentSet.type = setValue();
          break;
        case kpmTimeStamp:
          currentSet.timeStamp = setValue();
          break;
        default:
          throw 'unknown attribute of ${currentSet.name}: $fields';
      }
    }
  } // end setAttributes

  static List<PMCSVDataSet> split(rows) {
    // Splits out a CSV file into its subsets, according to separator
    // string in first position of a row, followed by subset name and type.
    // Each subset must start with a row starting with a kqlSeparator.
    // converts types according to schema.

    //final PMR p = PMR(className: 'CSV DataSetOps', defaultLevel: 0);
    List<PMCSVDataSet> dataSets = [];
    var currentSet;

    for (List row in rows) {
      if (row.length == 0) continue;

      if (row[0] != kpmCSVDataSetSeparator) {
        if (currentSet == null) {
          // no header row given
          currentSet =
              PMCSVDataSet(name: '', schemaString: '', table: [], schema: []);
          dataSets.add(currentSet);
        }
        currentSet.table.add(row);
        continue; // to end of loop
      }

      // control only arrives here at start of set
      currentSet =
          PMCSVDataSet(name: '', schemaString: '', table: [], schema: []);
      dataSets.add(currentSet);

      //p.logF('set attrib: ${currentSet.name}, $row');
      PMCSVDataSetOps.setAttributes(currentSet, row);
    }
    return dataSets;
  }
}