// 2021-01-11

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'pm_dartUtils.dart';

class PMLocalFile {
  String? dirPath;
  File? file;

  PMR p = PMR(className: 'PMLocalFileStorage', defaultLevel: 0);

  PMLocalFile(PMParsePath localPath) {
    //p.logR('path set to: ${localPath.fullPath}');
    file = File(localPath.fullPath);
  }

  static Future<String> mobilelocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> readAsString() async {
    try {
      String? contents = await file?.readAsString();
      //p.logR('readAsString: $contents');
      return contents!;
    } catch (e) {
      p.logE('readAsString error: $e');
      return '';
    }
  }

  Future<bool> writeAsString(String value) async {
    try {
      await file!.writeAsString(value);
      //p.logR('writeAsString: $value');
      // Write the file
      return true;
    } catch (e) {
      p.logE('writeAsString error: $e');
      return false;
    }
  }

  Future<bool> rename(String fullPath) async {
    try {
      //p.logR('file renaming: $fullPath');
      await file!.rename(fullPath);
      //p.logR('file renamed');
      return true;
    } catch (e) {
      p.logE('rename error: $e');
      return false;
    }
  }

  Future<bool> exists() async {
    return await file!.exists();
  }

  delete({recursive=false}) async {
    await file!.delete(recursive: recursive);
  }

}
