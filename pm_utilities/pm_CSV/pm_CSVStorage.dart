// 2025-02-25

// package to handle storage over local file system and via an Express Server to a remote file system

import 'package:flutter/material.dart';
import 'dart:io';
import '../pm_local_file.dart';
import '../pm_dartUtils.dart';
import '../pm_ajax.dart';
import '../pm_CSV/pm_CSVBase.dart';
import '../pm_CSV/pm_CSVDatasets.dart';
import '../pm_CSV/pm_CSVDatasetOps.dart';
import '../pm_constants.dart';
import '../pm_QL/pmQL_transforms.dart';

const kpmWindowsPath = 'windowsPath';
const kpmAndroidPath = 'androidPath';
const kpmExpressURL = 'expressURL';
const kpmAppTrigger = 'appTrigger';
//const kpmHeightReserve = 'heightReserve';

class PMCSVStorage extends ChangeNotifier {
  List<PMCSVDataSet> dataSets = [];
  Function? trigger;
  String error = '';
  PMLocalFile? localFile;
  PMAjax? expressServer;
  String userName = '';
  String userPassword = '';
  PMParsePath? localParse, windowsParse;
  bool dirty = false;
  //double heightReserved = 0; // used to reserve space on table displays
  String windowsPath = '';
  String androidPath = '';
  String expressURL = '';
  QLTransforms? transforms;

  final PMR p = PMR(className: 'CSV Storage', defaultLevel: 0);

  initialize(params) {
    //p.logR('storage initializing');
    trigger = params[kpmAppTrigger];
    windowsPath = params[kpmWindowsPath];
    androidPath = params[kpmAndroidPath];
    expressURL = params[kpmExpressURL];
    windowsParse = pmNil(windowsPath) ? null : PMParsePath(windowsPath);
    var androidParse = pmNil(androidPath) ? null : PMParsePath(androidPath);
    localParse = Platform.isWindows ? windowsParse : androidParse;
    localFile = PMLocalFile(localParse!);
    expressServer = pmNil(expressURL) ? null : PMAjax(expressURL);
    //heightReserved = 200.0;
    error = '';
    dirty = false;
  }

  // -------------- helper functions --------------

  notify() {
    notifyListeners();
  }

  Map getDataSet(String name) {
    int i = pmListFind(dataSets, name, xform: (x) => x.name);
    return i < 0 ? {} : {kpmValue: dataSets[i]};
  }

  removeDataSet(String name) {
    int i = pmListFind(dataSets, name, xform: (x) => x.name);
    if (i < 0) return;
    dataSets.removeAt(i);
  }

  PMCSVDataSet copyDataSet(PMCSVDataSet dataSet, String newName) {
    int i = pmListFind(dataSets, newName, xform: (x) => x.name);
    if (i >= 0) dataSets.removeAt(i);

    List<List> newTable = [];
    List<List> table = dataSet.table;
    for (int i = 0; i < table.length; i++) {
      newTable.add(List.from(table[i]));
    }

    PMCSVDataSet newSet = PMCSVDataSet(
        name: newName,
        schema: List<PMCSVDSchemaItem>.from(dataSet.schema),
        table: newTable,
        type: dataSet.type,
        sort: '',
        show: dataSet.show,
        schemaString: '');
    dataSets.add(newSet);
    return newSet;
  }

  moveRow(bool direction, PMCSVDataSet dataSet, int index) {
    setDirty();
    dataSet.moveRow(direction, index);
    notify();
  }

  modifyRow(String operation, PMCSVDataSet dataSet, int index, List row,
      {Function? trigger}) {
    // used to add, delete, replace a row]
    dataSet.modifyRow(operation, index, row);
    setDirty();
    if (trigger != null) trigger(); // the re-execution of transforms
    sortAndNotify();
  }

  setCredentials(String name, String password) {
    userName = name;
    userPassword = password;
  }

  setCredentialsFromDataSet() {
    if (pmNotNil(userName)) return;
    Map r = getDataSet(kpmCredentials);
    if (r[kpmValue] == null) return;
    PMCSVDataSet credentials = r[kpmValue];
    List table = credentials.table;
    if (table.length == 0) return;
    if (table[0].length < 2) return;
    userName = table[0][0];
    userPassword = table[0][1];
  }

  setError(String msg) {
    // if there is already an error, add msg on new line
    if (pmNil(msg)) error = '';
    else error = pmNil(error) ? msg : error + '\n' + msg;
    //p.logR('storage error set:$error',);
    notify();
  }

  setDirty() {
    dirty = true;
    notify();
  }

  // -------------- encoding and decoding of datasets --------------

  decodeDataSets(String csv, {Function? trigger}) {
    //p.logR('decoding datasets');
    List rows = PMCSVBase.decode(csv);
    //p.logR('Decoded ${rows.length} from CSV file');
    dataSets = PMCSVDataSetOps.split(rows);
    /*for (PMCSVDataSet set in dataSets) {
      //p.logR('decoded: ${set.name}, rows: ${set.table.length}');
      //PMCSVPrintTable.printTable(set);
    }*/
    setCredentialsFromDataSet();
    if (trigger != null) {
      trigger();
    }
    sortAndNotify();
  }

  String encodeDataSet(PMCSVDataSet dataSet) {
    List<PMCSVDataSet> sets = [dataSet];
    List rows = PMCSVDataSetOps.join(sets);
    String encoded = PMCSVBase.encode(rows);
    return encoded;
  }

  addDataSet(
    String name,
    List<List> table, {
    String? show,
    String? save,
    String? hide,
    String? type,
    String? schemaString,
  }) {
    if (pmNil(schemaString)) {
      schemaString = '';
    }

    dataSets.add(
      PMCSVDataSet(
        name: name,
        show: (show == null) ? '' : show,
        save: (save == null) ? '' : save,
        type: (type == null) ? '' : type,
        table: table,
        schemaString: schemaString!,
        schema: [],
      ),
    );
  }

  String encodeDataSets() {
    if (pmNil(dataSets)) return '';

    // make sure that the latest credentials are written out
    if (pmNotNil(userName)) {
      Map r = getDataSet(kpmCredentials);
      if (r[kpmValue] != null) {
        // update them
        PMCSVDataSet credentials = r[kpmValue];
        credentials.table = [
          [userName, userPassword]
        ];
      } else {
        // add a credentials dataset
        addDataSet(
          kpmCredentials,
          [
            [userName, userPassword]
          ],
          show: kpmHide,
          save: kpmSave,
        );
      }
    }

    List<PMCSVDataSet> sets = [];
    for (PMCSVDataSet set in dataSets) {
      if (set.save == kpmSave) {
        sets.add(set);
      }
    }
    List rows = PMCSVDataSetOps.join(sets);
    String encoded = PMCSVBase.encode(rows);
    return encoded;
  }

  sortAndNotify({String? m}) {
    for (PMCSVDataSet d in dataSets) {
      d.sortDataSet();
    }
    notify();
    // pass word up the chain of a change
  }

  String stringifyDataSets() {
    String s = 'Datasets:\n';
    int n = 0;
    for (PMCSVDataSet d in dataSets) {
      String ds = d.stringifyDataSet();
      s = s + ds + '\n';
      n++;
    }
    return s + '\n$n sets';
  }

  // -------------- deal with cloud and local store --------------

  Future readDataSetsLocal() async {
    //p.logF('local read called');
    if (localFile == null) return false;
    error = '';
    String contents = await localFile!.readAsString();
    if (pmNil(contents)) {
      String readError = 'local read is nil, windows:$windowsPath | android: $androidPath';
      p.logE(readError);
      error = readError;
      return false;
    }
    //p.logR('Local read success: ${contents.length}');
    decodeDataSets(contents, trigger: trigger);
    //p.logR('Datasets after local read:\n ${stringifyDataSets()}');
    return true;
  }

  Future writeDataSetsLocal({String? backupExt}) async {
    if (localFile == null) return false;
    error = '';
    //p.logR('local write');
    if (backupExt != null) {
      if (await localFile!.exists()) {
        // make a backup with the specified '.ext'
        String backupPath =
            PMParsePath.join(localParse!.pathTo, localParse!.base + backupExt);
        await localFile!.rename(backupPath);
      }
    }
    if (await localFile!.writeAsString(encodeDataSets())) {
      dirty = false;
      notify();
      return true;
    }
    return false;
  }

  Future writeDataSetAsExcelCSV(PMCSVDataSet dataSet, String fileName) async {
    try {
      error = '';
      File outputFile = File(fileName);
      List row0 = [];
      for (PMCSVDSchemaItem item in dataSet.schema) {
        row0.add(item.colName);
      }
      List newTable = [row0];
      for (List row in dataSet.table) {
        newTable.add(row);
      }
      String output = PMCSVBase.encode(newTable);
      await outputFile.writeAsString(output);
      return true;
    } catch (e) {
      error = e.toString();
      p.logE('failure to write as ExcelCSV: $fileName | $error');
      return false;
    }
  }

  Future writeDataSet(PMCSVDataSet dataSet, String fileName) async {
    try {
      error = '';
      File outputFile = File(fileName);
      String output = encodeDataSet(dataSet);
      await outputFile.writeAsString(output);
      return true;
    } catch (e) {
      error = e.toString();
      p.logE('failure to write DataSet: $fileName | $error');
      return false;
    }
  }

  Future pushDataSetsExpress() async {
    int loadSize = 4096;
    String data = encodeDataSets();
    bool result = true;

    if (expressServer == null) return false;

    //p.logR('express pushing, len: ${data.length}');
    sendData(load, path) async {
      //p.logR('sending load, len: ${load.length}, path: $path|');
      var result = await expressServer!.post(verb: 'push', params: [
        [kpmPath, path],
        [kpmData, load]
      ]);
      if (result[kpmStatus] != kpmOK) {
        //p.logR('express push failed: ${result[kpmPayload]}');
        return false;
      }
      return true;
    }

    // chunk the data up
    while (result && data.length >= loadSize) {
      String load = data.substring(0, loadSize);
      data = data.substring(loadSize, data.length);
      result = await sendData(load, '');
    }
    if (result) result = await sendData(data, windowsParse!.fullPath);
    return result;
  }

  Future pullDataSetsExpress() async {
    if (expressServer == null) return false;
    error = '';
    Map result = await expressServer!.post(verb: 'pull', params: [
      [kpmPath, windowsParse!.fullPath],
    ]);
    if (result[kpmStatus] != kpmOK) {
      //p.logR('express pull failed: ${result[kpmPayload]}');
      return false;
    }
    setDirty();
    decodeDataSets(result[kpmPayload], trigger: trigger);
    return true;
  }
}
