import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as DI;
import 'package:flutter/services.dart';

import 'package:image_text02/pm_utilities/pm_dartUtils.dart';
import 'package:image_text02/pm_utilities/pm_constants.dart';

import 'package:image_text02/routines/app_common.dart';


// this routine is spawned as a separate isolate by Model

Future<void> readAndMakeThumb(SendPort port) async {
  final PMR p = PMR(className: 'readAndMakeThumb', defaultLevel: 0);

  makeThumbUIImage(String fileName) {
    //
    sendResult(bytes, width, height, size) {
      Map thumb = {kpmFileName: fileName,
        kpmWidth: width,
        kpmHeight: height,
        kpmSize: size,
        kpmData: bytes};
      // and send it back
      p.logR('sending back thumb for $fileName');
      port.send(thumb);
    }

    //
    try {
      Uint8List diBytes = File(fileName).readAsBytesSync();
      DI.Image? imageDI = DI.decodeImage(diBytes);

      int width = imageDI!.width;
      int height = imageDI.height;
      int tWidth = 0;
      int tHeight = 0;
      if (width > height) {
        tWidth = kThumbWidth;
        tHeight = (kThumbWidth * height / width).floor();
      } else {
        tHeight = kThumbHeight;
        tWidth = (kThumbHeight * width / height).floor();
      }

      var thumbnailDI = DI.copyResize(imageDI, width: tWidth, height: tHeight);
      var data = DI.encodeJpg(thumbnailDI);
      var bytes = Uint8List.fromList(data);
      sendResult(bytes, width, height, diBytes.length);
    }
    catch (error) {
      sendResult(null, 0, 0, 0);
    }
  }

  //
  p.logR('Spawned isolate started.');

  // first pass back port to send commands to
  final commandPort = ReceivePort();
  port.send(commandPort.sendPort);

  // Wait for file names to come in.
  await for (final fileName in commandPort) {
    if (fileName is String) {
      p.logR('Got request for $fileName');
      makeThumbUIImage(fileName);
    } else if (fileName == null) {
      break;
    }
  }

  p.logR('Spawned isolate finished.');
  Isolate.exit();
}
