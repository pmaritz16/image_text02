// 2023-02-18

import 'package:flutter/material.dart';
//import '../pm_CSV/pm_CSVDatasets.dart';
import '../pm_flutter.dart';
import '../pm_dartUtils.dart';
import '../pm_constants.dart';
import 'dart:io';
import '../pm_CSV/pm_CSVStorage.dart';

double textInputdWidth = Platform.isWindows ? 500 : 265;

class PMCSVStorageAdmin extends StatefulWidget {
  final PMCSVStorage storage;


  PMCSVStorageAdmin({required this.storage});

  @override
  _PMCSVStorageAdminState createState() => _PMCSVStorageAdminState();
}

class _PMCSVStorageAdminState extends State<PMCSVStorageAdmin> {
  final PMR p = PMR(className: 'CSV Admin', defaultLevel: 0);

  String statusMessage = '';
  late Map storeParams;

  @override
  Widget build(BuildContext context) {
    PMCSVStorage storage = widget.storage;

    /*for (PMCSVDataSet d in storage.dataSets)
      //p.logR(d.stringifyDataSet(), level: 0);*/

    updateStatus(msg) {
        //p.logF(msg);
        setState(() {
          statusMessage = msg;
        });

    }

    performOp(Function op) async {
      updateStatus(kpmPending);
      if (await op())
        updateStatus(kpmSuccess);
      else
        updateStatus(kpmFailure);
    }

    sendTextExpress() async {
      await performOp(storage.pushDataSetsExpress);
    }

    getTextExpress() async {
      await performOp(storage.pullDataSetsExpress);
      //p.logF('got datasets from server');
    }

    readFromFile() async {
      await performOp(storage.readDataSetsLocal);
    }

    writeToFile() async {
      await performOp(storage.writeDataSetsLocal);
    }

    storeParams = {
      kpmWindowsPath: storage.windowsPath,
      kpmAndroidPath: storage.androidPath,
      kpmExpressURL: storage.expressURL,
    };

    Widget showStatus() {
      if (statusMessage == kpmSuccess)
        return pmText(statusMessage,
            s: kpmL,
            c: (statusMessage == kpmFailure) ? kpmRed : kpmGreen,
            d: [kpmBold]);
      return PMFlashing(
        child: pmText(statusMessage,
            s: kpmL,
            c: (statusMessage == kpmFailure) ? kpmRed : kpmGrey,
            d: [kpmBold]),
      );
    }

    //p.logF('building Storage Admin');
    return Material(
      child: Container(
        child: pmColumn([
          if (pmNotNil(storage.userName))
            pmText("User set to: ${storage.userName}"),
          pmSpacerV(),
          pmRow([
            PMMajorButton(
                buttonColor: Colors.blue,
                buttonChild: pmMultiLineText(['Express', 'PUSH'],
                    s: kpmXS, d: [kpmBold], c: kpmWhite),
                buttonAction: sendTextExpress,
                width: 120,
                height: 20),
            pmSpacerH(),
            PMMajorButton(
              buttonColor: Colors.lightBlue,
              buttonChild:
                  pmMultiLineText(['Express', 'PULL'], s: kpmXS, d: [kpmBold]),
              buttonAction: getTextExpress,
              width: 120,
            ),
          ]),
          pmRow([
            PMMajorButton(
              buttonColor: Colors.green,
              buttonChild: pmMultiLineText(['Local', 'WRITE'],
                  s: kpmXS, d: [kpmBold], c: kpmWhite),
              buttonAction: writeToFile,
              width: 120,
            ),
            pmSpacerH(),
            PMMajorButton(
              buttonColor: Colors.greenAccent,
              buttonChild:
                  pmMultiLineText(['Local', 'READ'], s: kpmXS, d: [kpmBold]),
              buttonAction: readFromFile,
              width: 120,
            ),
          ]),
          PMTextInput(
            width: textInputdWidth,
            height: 110.0,
            label: pmText('Windows', c: kpmBlue),
            initialText: storeParams[kpmWindowsPath],
            maxLines: 4,
            callback: (value) {
              storeParams[kpmWindowsPath] = value;
            },
          ),
          PMTextInput(
            width: textInputdWidth,
            height: 80,
            label: pmText('Android', c: kpmBlue),
            initialText: storeParams[kpmAndroidPath],
            callback: (value) {
              storeParams[kpmAndroidPath] = value;
            },
          ),
          PMTextInput(
            width: textInputdWidth,
            height: 80,
            label: pmText('Express', c: kpmBlue),
            initialText: storeParams[kpmExpressURL],
            callback: (value) {
              storeParams[kpmExpressURL] = value;
            },
          ),
          if (pmNotNil(statusMessage)) pmSpacerV(),
          if (pmNotNil(statusMessage)) showStatus(),
          pmSpacerV(),
          pmRow([
            PMRoundIconButton(
                icon: Icons.arrow_back,
                onPressed: () {
                  //p.logF('going back to Primary');
                  Navigator.pop(context);
                }),
            pmSpacerH(),
            PMRoundIconButton(
                icon: Icons.add,
                color: Colors.blue,
                onPressed: () {
                  storage.initialize(storeParams);
                  setState(() {
                    statusMessage = kpmInitialized;
                  });
                })
          ])
        ]),
      ),
    );
  }
}
