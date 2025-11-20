//2025-02-27

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pm_CSV/pm_CSVDatasets.dart';
import '../pm_flutter.dart';
import '../pm_constants.dart';
import '../pm_CSV/pm_CSVStorage.dart';
import '../pm_dartUtils.dart';
import '../pm_CSVFlutter/pm_CSVDisplayTable.dart';
import '../pm_CSVFlutter/pm_CSVEditRecord.dart';

// displays a table of a dataSet in a new page, parameters are passed in on the Navigator call:
// args = {kpmName: name-of-dataSet, kpmTrigger: optional function to be called when state of table changes

class PMTableInPage extends StatelessWidget {
  final PMR p = PMR(className: 'TableInPage', defaultLevel: 0);

  @override
  Widget build(BuildContext context) {
    PMScreenSize screen = PMScreenSize(context);
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final storage = Provider.of<PMCSVStorage>(context);

    double sheetWidth = 0.0;
    double sheetHeight = 0.0;

    var result = storage.getDataSet(args[kpmName]);
    if (result[kpmValue] == null)
      return pmShowError(
          context, fatal: true, 'cannot find dataSet: ${args[kpmName]}');
    PMCSVDataSet dataSet = result[kpmValue];

    for (PMCSVDSchemaItem item in dataSet.schema) {
      sheetHeight += 50.0;
      double w =
          kpmWidthMappings[item.colWidth] + pmTextWidth(item.colName) + 130;
      if (w > sheetWidth) sheetWidth = w;
    }

    if (sheetHeight > screen.height) sheetHeight = screen.height;
    p.logF(
        'height: $sheetHeight, width: $sheetWidth, screenHeight: ${screen.height}');

    addRecord(List record) {
      storage.modifyRow(kpmAdd, dataSet, -1, record, trigger: args[kpmTrigger]);
    }

    showEditTopSheet(List record, Function commit) {
      pmShowTopSheet(
          context: context,
          width: sheetWidth,
          height: sheetHeight,
          color: kpmColorLightBlue,
          child: PMEditRecord(
            recordIn: record,
            schema: dataSet.schema,
            commit: commit,
            autoFill: dataSet.autoFill,
            semanticCheck: dataSet.semanticCheck,
            defaultValue: storage.transforms!.qlCompileAndEvaluate,
            height: sheetHeight,
          ));
    }

    editRecord(int index) {
      replaceRecord(List record) {
        storage.modifyRow(kpmReplace, dataSet, index, record,
            trigger: args[kpmTrigger]);
      }

      showEditTopSheet(dataSet.table[index], replaceRecord);
    }

    insertRecord(int index) {
      insertRecord(List record) {
        storage.modifyRow(kpmInsert, dataSet, index, record,
            trigger: args[kpmTrigger]);
      }

      showEditTopSheet([], insertRecord);
    }

    deleteRecord(int index) {
      storage.modifyRow(kpmDelete, dataSet, index, [],
          trigger: args[kpmTrigger]);
    }

    moveRowDown(index) {
      storage.moveRow(true, dataSet, index);
    }

    moveRowUp(index) {
      storage.moveRow(false, dataSet, index);
    }

    List actions = [
      {kpmName: 'delete', kpmAction: deleteRecord},
      {kpmName: 'edit', kpmAction: editRecord},
      {kpmName: 'insert', kpmAction: insertRecord},
      {kpmName: 'up', kpmAction: moveRowUp},
      {kpmName: 'down', kpmAction: moveRowDown},
    ];

    //p.logR(dataSet.stringifyDataSet());

    return Material(
      child: SafeArea(
        child: Container(
          alignment: Alignment.center,
          child: pmColumn([
            Container(
              height: screen.debitH(50),
              child: pmRow(
                [
                  pmBack(() {
                    Navigator.pop(context);
                  }),
                  pmSpacerH(w: 30),
                  if (dataSet.show == kpmEdit)
                    PMRoundIconButton(
                      icon: Icons.add,
                      onPressed: () {
                        showEditTopSheet([], addRecord);
                      },
                    ),
                ],
                xAlign: kpmCenter,
              ),
            ),
            PMDisplayTable(
              dataSet: dataSet,
              actions: dataSet.show == kpmEdit ? actions : [],
              screen: screen,
            ),
          ]),
        ),
      ),
    );
  }
}
