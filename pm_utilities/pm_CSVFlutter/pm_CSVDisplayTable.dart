// 2025-02-27

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pm_CSV/pm_CSVStorage.dart';
import '../pm_flutter.dart';
import '../pm_constants.dart';
import '../pm_dartUtils.dart';
import '../pm_CSV/pm_CSVDatasets.dart';
import 'dart:io';

const kpmDefaultTableColor = Color(0xffbaedf7);
const kpmDefaultWidth = kpmwS;
final Map kpmWidthMappings = {
  kpmwXS: 30.0,
  kpmwS: 50.0,
  kpmwM: 65.0,
  kpmwL: 90.0,
  kpmwXL: 105.0,
  kpmwXXL: Platform.isWindows ? 360.0 : 125.0,
  kpmwXXXL: Platform.isWindows ? 540.0 : 125.0,
};
//define display page size
final vPageRows = 20;
final hPageCols = Platform.isWindows ? 10 : 6;

class PMDisplayTable extends StatefulWidget {
  final PMCSVDataSet dataSet; // dataSet holding the table to be displayed
  final List
      actions; // a list of type {name: , action: } offered in drop-down for each row
  final bool headers; // show column headers or not
  final Color color; // background color of the container
  final showName; // show the table name or not
  final PMScreenSize? screen;

  PMDisplayTable(
      {required this.dataSet,
      required this.actions,
      this.screen,
      this.color = kpmDefaultTableColor,
      this.showName = true,
      this.headers = true});

  @override
  _PMDisplayTableState createState() => _PMDisplayTableState();
}

class _PMDisplayTableState extends State<PMDisplayTable> {
  final PMR p = PMR(className: 'PMDisplayTable', defaultLevel: 0);

  late List<int>
      dIndices; // this list will hold the dIndices of rows to display
  late List colHeaders;
  late List colWidths;
  late List colDigits;
  late List colTypes;
  late List colEdit;
  bool error = false;
  late ScrollController controller;
  late Widget headerRow;
  late List<Widget> page;
  late List<int> hIndices; // list of columns in current page
  late int currentStartRow;
  late int currentEndRow;
  late int currentStartCol;
  late int lastCol;
  late List<PMCSVDSchemaItem> schema;
  late List table;
  late PMCSVStorage storage;
  PMScreenSize? screen;

  setupSchema() {
    colHeaders = [];
    colWidths = [];
    colTypes = [];
    colDigits = [];
    colEdit = [];
    dIndices = [];
    hIndices = [];

    // build out separate list of attributes for each schema item
    // for ease of access
    //dumpSchema(schema);
    for (int i = 0; i < schema.length; i++) {
      PMCSVDSchemaItem item = schema[i];
      colHeaders.add(item.colName);
      colWidths.add(pmNotNil(item.colWidth) ? item.colWidth : kpmDefaultWidth);
      colDigits.add(item.colDigits);
      colTypes.add(item.colType);
      colEdit.add(item.colEdit);
      if (item.colVis == kpmvI) continue; // column is invisible
      dIndices.add(i);
    }
    //for(int i=0;i<colWidths.length;i++) {
    //   //p.logR('item $i: width: ${colWidths[i]}', level: 1);
    //}
  }

  setPage() {
    // set the display page to where current row and column have been set
    page = [];

    // set the rows to display
    int newRow = currentStartRow;
    if (newRow > table.length - vPageRows) newRow = table.length - vPageRows;
    if (newRow < 0) newRow = 0;
    currentStartRow = newRow;
    currentEndRow = currentStartRow + vPageRows;
    if (currentEndRow > table.length) currentEndRow = table.length;

    // set the columns to display according to screen size
    hIndices = [];
    double colWidth = 0.0;
    // first add fixed columns
    for (int i = 0; i < schema.length; i++)
      if (schema[i].colVis == kpmvF) {
        colWidth = colWidth + kpmWidthMappings[colWidths[i]];
        hIndices.add(i);
      }
    for (int i = currentStartCol; i < schema.length; i++) {
      if (schema[i].colVis == kpmvF) continue; // fixed already in list
      if (schema[i].colVis == kpmvI) continue; // invisible
      colWidth = colWidth + kpmWidthMappings[colWidths[i]];
      //p.logR('$i: $colWidth, $hPageWidth', level: 1);
      if (colWidth > screen!.remainingW - kpmWidthMappings[kpmwS] - 15.0) break;
      hIndices.add(i);
      lastCol = i;
    }

    for (int i = currentStartRow; i < currentEndRow; i++)
      page.add(rowBuilder(table[i], i));
    headerRow = SizedBox(
      height: screen!.debitH(35),
      child: rowBuilder(colHeaders, null, bold: true),
    );
  }

  pageRight() {
    setState(() {
      // find first no-fixed column to right
      int i = currentStartCol + 1;
      while (i < schema.length && schema[i].colVis == kpmvF) i++;
      if (i < schema.length) currentStartCol = i;
      setPage();
    });
  }

  pageLeft() {
    setState(() {
      // find first no-fixed column to left
      int i = currentStartCol - 1;
      while (i >= 0 && schema[i].colVis == kpmvF) i--;
      if (i >= 0) currentStartCol = i;
      setPage();
    });
  }

  pageHardLeft() {
    setState(() {
      currentStartCol = 0;
      setPage();
    });
  }

  pageHardRight() {
    pageHardLeft();
    while (lastCol < schema.length - 1) {
      pageRight();
    }
  }

  pageDown() {
    setState(() {
      currentStartRow = currentStartRow + vPageRows;
      setPage();
    });
  }

  pageUp() {
    setState(() {
      currentStartRow = currentStartRow - vPageRows;
      setPage();
    });
  }

  jumpTo(int newRow) {
    setState(() {
      currentStartRow = newRow;
      setPage();
    });
  }

  Widget rowBuilder(row, index, {bold = false}) {
    // build out a row of pmText's from contents of 'row', sizing according
    // to colWidths

    List<Widget> rowItems = [];
    double colW = 0.0;
    //p.logR('row builder: $row, display Indices: $dIndices');
    for (int j = 0; j < dIndices.length; j++) {
      int i = dIndices[j];
      // first check to see if this column is to be displayed in current page
      if (i >= row.length) continue;
      if (pmListFind(hIndices, i) < 0) continue;
      //p.logR('adding column: $i from $dIndices');

      colW = colW + kpmWidthMappings[colWidths[i]];

      String entry;
      if (row[i] is double && colDigits[i] >= 0)
        entry = row[i].toStringAsFixed(colDigits[i]);
      else
        entry = pmTS(row[i]);

      //if (index == 5) //p.logR('row $index, col $i: width ${colWidths[i]}, ${kpmWidthMappings[colWidths[i]]} ', level: 1);

      rowItems.add(Container(
          //margin: const EdgeInsets.all(15.0),
          //padding: const EdgeInsets.all(3.0),
          alignment: Alignment(0, 0),
          width: kpmWidthMappings[colWidths[i]],
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            color: Colors.white,
          ),
          child: bold
              ? pmText(entry, s: kpmXS, c: kpmBlack, d: [kpmBold])
              : pmText(entry, s: kpmXS)));
    }
    //p.logR('col width: $colW', level:0);

    // now add a menu for actions on the row
    if (pmNotNil(widget.actions) && (index != null)) {
      var popUp = PopupMenuButton<int>(
        itemBuilder: (context) {
          List<PopupMenuItem<int>> items = [];
          for (int i = 0; i < widget.actions.length; i++) {
            items.add(PopupMenuItem<int>(
              value: i,
              child: Text(widget.actions[i][kpmName]),
            ));
          }
          return items;
        },
        onSelected: (value) {
          widget.actions[value]
              [kpmAction](index); // call the action with arg index
        },
        icon: Icon(Icons.list),
      );
      // build a pop-up menu showing possible actions on the row
      rowItems.add(popUp);
    } else
      rowItems.add(pmSpacerH(w: 40));
    return pmColumn([
      pmSpacerV(h: 5.0),
      ConstrainedBox(
        constraints: new BoxConstraints(
          maxHeight: 30.0,
        ),
        child: pmRow(rowItems, mAlign: kpmCenter),
      )
    ]);
  }

  scrollListener() {
    //p.logR('pos: ${controller.currentStartRow}');
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      setState(() {
        //p.logR('reached bottom');
        pageDown();
      });
    }
    if (controller.offset <= controller.position.minScrollExtent &&
        !controller.position.outOfRange) {
      setState(() {
        //p.logR('reached top');
        pageUp();
      });
    }
  }

  @override
  void initState() {
    //p.logR('Initializing display for ${widget.dataSet.name}');
    controller = ScrollController();
    controller.addListener(scrollListener);
    currentStartRow = 0;
    currentStartCol = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    storage = Provider.of<PMCSVStorage>(context);
    screen = (widget.screen == null)
        ? PMScreenSize(context)
        : PMScreenSize(context,
            width: widget.screen!.remainingW,
            height: widget.screen!.remainingH);
    //p.logR('screen: ${screen.width}, ${screen.height}, ${screen.heightSafe}', level: 1);

    if (pmNil(widget.dataSet.schema))
      return Container(
        child: pmText('TABLE ERROR (dataset or schema nil)'),
      );

    schema = widget.dataSet.schema;
    table = widget.dataSet.table;
    setupSchema();
    setPage();

    //p.logF('building table display: ${widget.dataSet.name}, length: ${table.length}, height: $height');

    return Container(
      alignment: Alignment.center,
      height: screen!.remainingH,
      width: screen!.remainingW,
      color: widget.color,
      child: pmColumn(
        [
          if (widget.showName && pmNotNil(widget.dataSet.name))
            Container(
              height: screen!.debitH(30),
              child: pmRow([
                pmText(widget.dataSet.name),
                pmSpacerH(w: 5),
                if (pmNotNil(widget.dataSet.timeStamp))
                  pmText('(${widget.dataSet.timeStamp})', s: kpmXXS),
              ]),
            ),
          Container(
            height: screen!.debitH(50),
            child: pmRow([
              PMRoundIconButton(
                  icon: Icons.switch_right,
                  onPressed: pageHardLeft,
                  color: kpmColorGrey2),
              PMRoundIconButton(
                  icon: Icons.arrow_left,
                  onPressed: pageLeft,
                  color: kpmColorGrey2),
              PMRoundIconButton(
                icon: Icons.vertical_align_top,
                onPressed: () {
                  jumpTo(0);
                },
                color: kpmColorGrey1,
              ),
              PMRoundIconButton(
                  icon: Icons.arrow_upward,
                  onPressed: pageUp,
                  color: kpmColorGrey1),
              PMRoundIconButton(
                  icon: Icons.arrow_downward,
                  onPressed: pageDown,
                  color: kpmColorGrey1),
              PMRoundIconButton(
                icon: Icons.vertical_align_bottom,
                onPressed: () {
                  jumpTo(table.length);
                },
                color: kpmColorGrey1,
              ),
              PMRoundIconButton(
                  icon: Icons.arrow_right,
                  onPressed: pageRight,
                  color: kpmColorGrey2),
              PMRoundIconButton(
                  icon: Icons.switch_left,
                  onPressed: pageHardRight,
                  color: kpmColorGrey2),
            ]),
          ),
          if (widget.headers) headerRow,
          Container(
            height: screen!.remainingH - 40,
            child: ListView.builder(
              controller: controller,
              itemCount: page.length,
              itemBuilder: (context, index) {
                return page[index];
              },
            ),
          ),
        ],
      ),
    );
  }
}
