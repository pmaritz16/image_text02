// 2025-03-01

import 'package:flutter/material.dart';
import '../pm_constants.dart';
import 'pm_CSVDisplayTable.dart';

//import '../pm_constants.dart';
import '../pm_flutter.dart';
import '../pm_dartUtils.dart';
import '../pm_CSV/pm_CSVDatasets.dart';

class PMEditRecord extends StatefulWidget {
  final List recordIn; // the record to be created or edited
  final List<PMCSVDSchemaItem> schema; // schema of the record
  final Function
      commit; // function to be called to commit the record from whence it came
  final Function defaultValue; // function to evaluate default value expressions
  final Function
      autoFill; // function called to domain dependent auto-fill fields
  final Function
      semanticCheck; // checks fields of correct types for acceptable values
  final double height;

  PMEditRecord(
      {required this.recordIn,
      required this.schema,
      required this.commit,
      required this.autoFill,
      required this.semanticCheck,
      required this.defaultValue,
      this.height = 600.0});

  @override
  _PMEditRecordState createState() => _PMEditRecordState();
}

class _PMEditRecordState extends State<PMEditRecord> {
  final PMR p = PMR(className: 'EditRecord', defaultLevel: 0);
  late List record;
  late List errors;
  late List editFields;

  Color fieldColor(int i) {
    return pmNil(errors[i]) ? kpmDefaultBackgroundColor : kpmErrorColor;
  }

  copyRecord() {
    // make a copy of the record passed in, filling with nils if needed
    record = [];
    errors = pmListInit(widget.schema.length, '');
    for (int i = 0; i < widget.schema.length; i++) {
      if (pmNil(widget.recordIn) || i >= widget.recordIn.length) {
        record.add('');
        continue;
      }
      record.add(widget.recordIn[i]);
    }
  }

  checkAndCommit() {
    bool clean = true;
    setState(() {
      PMCSVDataSet.convertRowToType(record, widget.schema, errors);
      clean = PMCSVDataSet.noErrors(errors);
      if (clean) {
        widget.semanticCheck(record, errors);
        clean = PMCSVDataSet.noErrors(errors);
      }
    });
    if (clean) {
      widget.commit(record);
      Navigator.pop(context);
    } else {
      editFields = buildFieldList('field checks');
    }
  }

  List<Widget> buildFieldList(String msg) {
    List<Widget> fields = [];
    List schema = widget.schema;
    // parameter msg can be used to track who called the routine
    //dumpSchema(schema);

    //p.logR('building Fields with:\n$record\n$errors');

    for (int i = 0; i < schema.length; i++) {
      setRecordI(value) {
        setState(() {
          record[i] = value;
          //p.logR('set: $i, ${record[i]}');
        });
      }

      if (pmNotNil(schema[i].colDefault) && pmNil(record[i])) {
        // initialize field from default value expression
        var dExp = schema[i].colDefault;
        var dVal = widget.defaultValue(dExp);
        record[i] = dVal.toString();
      }

      if (schema[i].colEdit == kpmeF || schema[i].colVis == kpmvI)
        continue; // column not editable or invisible

      double width = kpmWidthMappings[schema[i].colWidth] + 100.0;
      int maxLines = (schema[i].colWidth == kpmwXXL) ? 2 : 1;

      if (pmNil(schema[i].colDropDown)) {
        // i.e. its a normal entry field

        TextEditingController textController = TextEditingController.fromValue(
            pmNil(record[i])
                ? null
                : TextEditingValue(text: record[i].toString()));
        textController.addListener(() {
          setRecordI(textController.text);
        });

        //p.logR('name: ${schema[i].colName}, ${schema[i].colWidth}, = $kpmwXL, wid: $width, max: $maxLines', level: 1);
        PMTextInput textInput = PMTextInput(
          width: width,
          maxLines: maxLines,
          controller: textController,
          keyboardType:
              (schema[i].colType == kpmtI || schema[i].colType == kpmtN)
                  ? TextInputType.number
                  : TextInputType.text,
          fillColor: fieldColor(i),
        );
        fields.add(
          pmRow(
            [
              pmText(schema[i].colName),
              pmSpacerH(),
              textInput,
              pmSpacerH(),
              pmText(errors[i]),
            ],
            mAlign: kpmEnd,
          ),
        );
      } else {
        // its a dropdown menu
        fields.add(
          pmRow(
            [
              PMNewTextInputWithDropdown(
                itemList: schema[i].colDropDown,
                functions: {kpmDropdownCallback: setRecordI},
                width: width,
                height: 50.0,
                label: schema[i].colName,
                initialTextVal: record[i],
                color: kpmColorLightBlue,
              ),
              pmSpacerH(),
              pmText(errors[i]),
            ],
            mAlign: kpmEnd,
          ),
        );
      }
      fields.add(pmSpacerV(h: 5.0));
    }

    return fields;
  }

  @override
  void initState() {
    copyRecord();
    super.initState();
    editFields = buildFieldList('init state');
  }

  @override
  Widget build(BuildContext context) {
    p.logF('building EditRecord, height: ${widget.height}');

    return Material(
      child: Container(
        color: kpmColorLighterBlue,
        alignment: Alignment.center,
        child: pmColumn([
          pmRow([
            pmBack(() {
              Navigator.pop(context);
            }),
            pmSpacerH(),
            PMRoundIconButton(
                icon: Icons.check,
                onPressed: () {
                  setState(() {
                    widget.autoFill(record);
                    errors = pmListInit(widget.schema.length, '');
                    editFields = buildFieldList('autoFill');
                  });
                }),
            pmSpacerH(),
            pmAdd(() {
              checkAndCommit();
            }),
          ]),
          pmSpacerV(),
          Container(
            height: widget.height - 60.0,
            child: ListView.builder(
              itemCount: editFields.length,
              itemBuilder: (context, index) {
                return editFields[index];
              },
            ),
          ),
        ]),
      ),
    );
  }
}
