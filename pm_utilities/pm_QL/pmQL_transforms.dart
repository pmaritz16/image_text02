// 2024-04-06

import '../pm_CSV/pm_CSVDatasets.dart';
import '../pm_CSV/pm_CSVStorage.dart';
import '../pm_dartUtils.dart';
import '../pm_constants.dart';
import '../pm_CSV/pm_CSVPrintTable.dart';
import '../pm_CSV/pm_CSVDatasetOps.dart';
import 'pmQL_common.dart';
import 'pmQL_compile_expression.dart';

const kqlATTRIB = 'ATTRIB';
const kqlCOMBINE = 'COMBINE';
const kqlCOPY = 'COPY';
const kqlDROP = 'DROP';
const kqlCOMPUTE = 'COMPUTE';
const kqlGROUP = 'GROUP';
const kqlKEEP = 'KEEP';
const kqlPRINT = 'PRINT';
const kqlREM = 'REM';
const kqlSELECT = 'SELECT';
const kqlSORT = 'SORT';
const kqlWHERE = 'WHERE';
const kqlWRITECSV = 'WRITECSV';
const kqlWRITESET = 'WRITESET';

final Token nullToken = Token(value: '');

class QLTransforms {
  final PMR p = PMR(className: 'Transforms', defaultLevel: 0);
  PMCSVStorage storage;
  Map? cache; // holds mappings of parameters to values
  QLTransforms(this.storage);

  int qlFindColumnIndex(List<PMCSVDSchemaItem> schema, String colName) {
    return pmListFind(schema, colName, xform: (x) => x.colName);
  }

  int qlFindValueIndex(List<List> lines, int colI, var value) {
    for (int r = 0; r < lines.length; r++) {
      if (value == lines[r][colI]) return r;
    }
    return -1;
  }

  qlGetDataSet(name) {
    Map r = storage.getDataSet(name);
    if (r[kpmValue] == null) qlError('unable to find table: $name', nullToken);
    PMCSVDataSet dataSet = r[kpmValue];
    return dataSet;
  }

  String replaceParameters(String s) {
    if (pmNotNil(cache))
      cache!.forEach((k, v) {
        s = s.replaceAll(k, v);
      });
    return s;
  }

  dynamic evaluateExpression(
      {Token? token,
      PMCSVDataSet? dataSet,
      int? rowIndex,
      Operator? parentOperator}) {
    fail(String msg) {
      qlError(
          '$msg\n${token!.dump()}\n${dataSet!.name}, row:$rowIndex', nullToken);
    }

    // evaluate a fully compiled tree

    printEvalTree(token!, '');

    switch (token.type) {
      case kqlString:
      case kqlNumber:
        return token.value;
      case kqlVariable:
        String val = token.value;
        // is the variable a parameter (begins with _)
        if (pmNotNil(val) && val.substring(0, 1) == '_') {
          if (pmNil(cache)) qlError('cache null', nullToken);
          return cache![val];
        }

        // are we doing constants/parameters only?
        if (dataSet == null) return 0;

        // is this a columnar operator?
        if (pmNotNil(parentOperator) && parentOperator!.type == kqlColumnar)
          return token; // do not de-ref the variable, operator will do it

        // its a lookup into the table - find the column
        if (pmNil(rowIndex))
          fail('non-columnar operation not allowed in GROUP-BY');
        int i = qlFindColumnIndex(dataSet.schema, token.value);
        if (i < 0) fail('unknown column name: ${token.value}');
        return dataSet.table[rowIndex!][i];
      case kqlOperator:
        // get the operator descriptor from pmQL_common file
        int i = findOperatorIndex(token.value);
        Operator op = operators[i];
        // build out the list of its arguments
        List values = [];
        switch (op.type) {
          case kqlColumnar:
            // columnar or lookup operator - feed it the dataSet and column name
            values.add(dataSet);
            values.add(token.operands[0].value);
            break;
          case kqlLookup:
            // lookup: dataset name, column, value, column
            Map r = storage.getDataSet(token.operands[0].value);
            if (r[kpmValue] == null)
              fail('unable to find table: ${token.operands[0].value}');
            values.add(r[kpmValue]);
            for (int m = 1; m < 4; m++) values.add(token.operands[m].value);
            break;
          case kqlRow:
            if (pmNil(rowIndex)) fail('requesting rowToString for null row');
            values.add(dataSet!.table[rowIndex!].toString());
            break;
          default:
            // direct operator, evaluate its operands and feed as a list to the op
            for (Token opr in token.operands) {
              if (opr.type == kqlOperator || opr.type == kqlVariable) {
                // recurse if needed
                var result = evaluateExpression(
                    token: opr,
                    dataSet: dataSet,
                    rowIndex: rowIndex,
                    parentOperator: op);
                if (result == null) fail('null result');
                values.add(result);
              } else
                values.add(opr.value);
            }
        }

        // perform the actual operation and return the value
        var finalValue = op.operation(values);
        return finalValue;
      case kqlError:
        break;
      default:
        qlError('Unknown type in evaluate: ${token.value}', nullToken);
    }
  }

  qlCompileAndEvaluate(String expression) {
    qlBuildParameterCache();
    Token exp = compileExpression(expression);
    if (exp.type == kqlError) qlError(exp.value, nullToken);
    return evaluateExpression(token: exp);
  }

  setAttributes(PMCSVDataSet set, String a) {
    if (pmNotNil(a)) {
      List items = a.split(',');
      PMCSVDataSetOps.setAttributes(set, items);
    }
    //p.logR('${set.name} has save:${set.save}, show:${set.show}|',);
  }

  qlExecTransform(List args) {
    try {
      PMCSVDataSet? dataSet;

      checkArgs(int len) {
        if (args.length < len)
          qlError('too few args for transform: $args', nullToken);
        dataSet = qlGetDataSet(args[1]);
      }

      if (pmNil(args)) qlError('qlExec called with nil list', nullToken);

      //p.logR('performing ${args[0]}');
      switch (args[0]) {
        case kqlATTRIB:
          //p.logR('Exec ATTRIB: $args');
          checkArgs(3);
          //dataSet!.setAttributes(args[2]);
          setAttributes(dataSet!, args[2]);
          break;
        case kqlREM:
          //p.logR('Exec REM: $args');
          // remark, skip the step
          break;
        case kqlCOPY:
          //p.logR('Exec COPY: $args');
          checkArgs(3);
          var newSet = storage.copyDataSet(
            dataSet!,
            args[2],
          );
          setAttributes(newSet, args[3]);
          break;
        case kqlCOMBINE:
          //p.logR('Exec COMBINE: $args');
          checkArgs(4);
          PMCSVDataSet dataSet2 = qlGetDataSet(args[2]);
          String schemaString = args[3];
          qlCombine(dataSet!, dataSet2, schemaString);
          break;
        case kqlWHERE:
          //p.logR('Exec WHERE: $args');
          checkArgs(3);
          qlWhere(dataSet!, args[2]);
          break;
        case kqlCOMPUTE:
          //p.logR('Exec COMPUTE: $args');
          checkArgs(4);
          qlCompute(dataSet!, args[2], args[3]);
          break;
        case kqlSELECT:
          //p.logR('Exec SELECT: $args');
          checkArgs(3);
          String s =
              args[2].replaceAll(' ', ''); // remove any leading/trailing spaces
          qlSelect(dataSet!, s.split(','));
          break;
        case kqlDROP:
          //p.logR('Exec DROP: $args');
          checkArgs(3);
          String s = pmStripCommaListSpaces(args[2]);
          qlDrop(dataSet!, s.split(','));
          break;
        case kqlSORT:
          //p.logR('Exec SORT: $args, ${args.length}');
          checkArgs(3);
          qlSort(dataSet!, args[2]);
          break;
        case kqlGROUP:
          //p.logR('Exec GROUP: $args');
          checkArgs(4);
          qlGroupBy(dataSet!, args[2], args[3]);
          break;
        case kqlPRINT:
          //p.logR('Exec PRINT: $args');
          checkArgs(2);
          PMCSVPrintTable.printTable(dataSet!);
          break;
        case kqlKEEP:
          //p.logR('Exec KEEP: $args');
          checkArgs(3);
          int? l;
          try {
            l = int.parse(args[2]);
          } catch (e) {
            qlError('KEEP needs integer param', nullToken);
          }
          while (dataSet!.table.length > l!) dataSet!.table.removeLast();
          break;
        case kqlWRITECSV:
          checkArgs(3);
          storage.writeDataSetAsExcelCSV(dataSet!, args[2]);
          break;
        case kqlWRITESET:
          checkArgs(3);
          qlWriteSet(dataSet!, args);
          break;
        default:
          //p.logR('Exec UNKNOWN: $args');
          qlError('unknown workflow command: $args[0]', nullToken);
      }
    } catch (e) {
      qlError('EXPRESSION ERROR:\n$e\n$args', nullToken);
    }
  }

  qlBuildParameterCache() {
    // build out the parameter cache
    Map r = storage.getDataSet(kpmPARAMETERS);
    cache = {};
    if (r[kpmValue] != null) {
      PMCSVDataSet parameters = r[kpmValue];
      for (List row in parameters.table) {
        cache![row[0]] = row[1];
      }
    }
  }

  qlTransformsListExec() {
    try {
      qlBuildParameterCache();
      for (int i = 0; i < storage.dataSets.length && pmNil(storage.error); i++) {
        PMCSVDataSet set = storage.dataSets[i];
        //p.logR('considering set: ${set.name}, ${set.type}');
        if (set.type != kpmTransforms) continue;
        for (List step in set.table) {
          //p.logR('Transform: $step');
          qlExecTransform(step);
        }
      }
    } catch (e) {
      storage.setError(e.toString());
      //p.logR('caught transform failure: ${e.toString()}',);
      throw 'transform failure: ${e.toString()}';
    }
  }

  qlCombine(PMCSVDataSet dS1, PMCSVDataSet dS2, String colName) {
    List<List> lines1 = dS1.table;
    List<List> lines2 = dS2.table;
    List<PMCSVDSchemaItem> schema1 = dS1.schema;
    List<PMCSVDSchemaItem> schema2 = dS2.schema;

    int si1 = qlFindColumnIndex(schema1, colName);
    int si2 = qlFindColumnIndex(schema2, colName);

    if (si1 < 0)
      qlError('column $colName does not exist in ${dS1.name}', nullToken);
    if (si2 < 0)
      qlError('column $colName does not exist in ${dS2.name}', nullToken);

    // add cols from schema2
    for (int i = 0; i < schema2.length; i++) {
      if (i == si2) continue;
      schema1.add(schema2[i]);
    }

    for (int r1 = 0; r1 < lines1.length; r1++) {
      int r2 = qlFindValueIndex(lines2, si2, lines1[r1][si1]);
      for (int c2 = 0; c2 < schema2.length; c2++) {
        if (c2 == si2) continue;
        lines1[r1].add(r2 >= 0 ? lines2[r2][c2] : null);
      }
    }
  }

  qlWhere(PMCSVDataSet dataSet, String expression) {
    Token exp = compileExpression(expression);
    if (exp.type == kqlError) qlError(exp.value, nullToken);
    List<List> newTable = [];
    List<List> table = dataSet.table;

    for (int i = 0; i < table.length; i++) {
      var result = evaluateExpression(
          token: exp, dataSet: dataSet, rowIndex: i, parentOperator: null);
      if (result != 0) newTable.add(table[i]);
    }

    dataSet.table = newTable;
  }

  qlCompute(PMCSVDataSet dataSet, String expression, String colString) {
    List<PMCSVDSchemaItem> colSchema =
        dataSet.decodeSchema(replaceParameters(colString));
    Token exp = compileExpression(expression);
    if (exp.type == kqlError) qlError(exp.value, nullToken);
    printEvalTree(exp, '');

    List<List> table = dataSet.table;
    List<PMCSVDSchemaItem> schema = dataSet.schema;

    for (int i = 0; i < table.length; i++) {
      var result = evaluateExpression(
          token: exp, dataSet: dataSet, rowIndex: i, parentOperator: null);
      table[i].add(result);
    }
    schema.add(colSchema[0]);
  }

  qlSelect(PMCSVDataSet dataSet, List<String> colNames) {
    if (pmNil(colNames)) qlError('nil list passed to Select', nullToken);
    List<List> table = dataSet.table;
    List<PMCSVDSchemaItem> schema = dataSet.schema;

    // build list of indices for selected columns
    List<int> indices = [];
    for (String cn in colNames) {
      int i = qlFindColumnIndex(schema, cn);
      if (i < 0) qlError('unable to find column name: $cn', nullToken);
      indices.add(i);
    }

    //build new schema
    List<PMCSVDSchemaItem> newSchema = [];
    for (int index in indices) newSchema.add(schema[index]);
    dataSet.schema = newSchema;

    for (int i = 0; i < table.length; i++) {
      List newRow = [];
      for (int index in indices) newRow.add(table[i][index]);
      table[i] = newRow;
    }
  }

  qlDrop(PMCSVDataSet dataSet, List<String> colNames) {
    if (pmNil(colNames)) qlError('nil list passed to Select', nullToken);
    for (String cn in colNames) {
      dataSet.dropColumn(cn);
    }
  }

  qlSort(PMCSVDataSet dataSet, String sortString) {
    dataSet.sortTable(sortString);
  }

  qlWriteSet(PMCSVDataSet dataSet, List args) {
    PMCSVDataSet newSet = PMCSVDataSet(name: dataSet.name, schema: dataSet.schema, schemaString: dataSet.schemaString, table: dataSet.table);
    setAttributes(newSet,args[3]);
    storage.writeDataSet(newSet, args[2]);
  }

  qlGroupBy(PMCSVDataSet dataSet, String colName, String colSummaryString) {
    // general form: GROUP dataset (on) colName.
    // First column of the new table will be colName (See note below if colName is nil).
    // Subsequent columns are given in the columnSummaryString in schemaString format (see PMCSVDataSet)
    // Each schema item has an 'sXXXX' field where XXXX is a columnar expression, if none is
    // given then a "SUM col" is assumed and col must exist.
    //  e.g. (dataSet, 'Name', 'bills|tN2,homes|sCOUNT address|tN0')
    // will create a table of names, a sum total of bills outstanding (SUM assumed), and a COUNT of associated addresses.
    //
    // Note: If colName is nil, then an 'anonymous' group-by is performed, ie. no group-by is performed,
    // and the summary columns are calculated for the whole original table.
    // e.g. (dataSet, '', 'Total PIC|tN1|wM|sSUM PIC,Total Dual|tN1|wM|sSUM Dual')
    // will produce single row table with columns containing Total PIC and Total Dual

    List<List> table = dataSet.table;
    List<PMCSVDSchemaItem> schema = dataSet.schema;
    List<PMCSVDataSet> subDataSets = [];

    List<PMCSVDSchemaItem> newSchema =
        dataSet.decodeSchema(replaceParameters(colSummaryString));

    // fill in defaults from parent schema, if no summarize expression is given
    for (PMCSVDSchemaItem item in newSchema) {
      if (pmNil(item.colSummarize)) {
        int j = qlFindColumnIndex(schema, item.colName);
        if (j < 0) qlError('column not found: ${item.colName}', nullToken);
        if (!(schema[j].colType == kpmtN || schema[j].colType == kpmtI))
          qlError(
              'requesting summary of non-numeric column: ${schema[j].colName}',
              nullToken);
        item.colSummarize = 'SUM ' + item.colName;
      }
    }
    //print('Doing Group By $colSummaryString');
    //for (PMCSVDSchemaItem item in newSchema) print(item.encode());

    if (pmNotNil(colName)) {
      // a real group-by to be performed
      dataSet.sortTable(colName);
      //PMCSVPrintTable.printTable(dataSet);

      // find the column to group by
      int colIndex = qlFindColumnIndex(schema, colName);
      if (colIndex < 0)
        qlError(
            'unable to find column to group-by: $colName in ${dataSet.name}',
            nullToken);

      // now to split dataset into sub-dataSets, according to group-by column

      List<List> tableSubset = [table[0]];
      for (int i = 1; i < table.length; i++) {
        if (table[i - 1][colIndex] != table[i][colIndex]) {
          // there has been a change in the run, so create dataset for previous run
          subDataSets.add(PMCSVDataSet(
              name: table[i - 1][colIndex].toString(),
              schema: dataSet.schema,
              table: tableSubset,
              schemaString: ''));
          // reset for the next subset
          tableSubset = [];
        }
        tableSubset.add(table[i]);
      }
      // was there a run left to be added?
      if (pmNotNil(tableSubset))
        subDataSets.add(PMCSVDataSet(
            name: tableSubset[0][colIndex].toString(),
            schema: dataSet.schema,
            table: tableSubset,
            schemaString: ''));
      newSchema.insert(0, schema[colIndex]);
    } else {
      // an anonymous summary
      subDataSets.add(PMCSVDataSet(
          name: dataSet.name,
          schema: dataSet.schema,
          table: dataSet.table,
          schemaString: ''));

      var item = PMCSVDSchemaItem(dataSet.name);
      item.colVis = kpmvI; // make column invisible
      newSchema.insert(0, item);
    }

    //for (PMCSVDataSet d in subDataSets) PMCSVPrintTable.printTable(d);

    // now build out the table for the final dataset
    List<List> newTable = [];
    for (int i = 0; i < subDataSets.length; i++) {
      // create a new summary row for each subset
      List newRow = [];
      // add name of subset as first item in row
      newRow.add(subDataSets[i].name);
      // now calculate and add each new column
      for (int j = 1; j < newSchema.length; j++) {
        // for each new column
        Token t = compileExpression(newSchema[j].colSummarize);
        if (t.type == kqlError) qlError(t.value, nullToken);
        var result = evaluateExpression(
            token: t, dataSet: subDataSets[i], rowIndex: null);
        newRow.add(result);
      }
      newTable.add(newRow);
    }
    dataSet.schema = newSchema;
    dataSet.table = newTable;
    //PMCSVPrintTable.printTable(dataSet);
  }
}
