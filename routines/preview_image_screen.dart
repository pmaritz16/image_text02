import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as UI;
import 'package:image/image.dart' as DI;
import 'dart:io';

import 'package:image_text02/pm_utilities/pm_constants.dart';
import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:image_text02/pm_utilities/pm_dartUtils.dart';

import 'package:image_text02/routines/model.dart';
import 'package:image_text02/routines/painting.dart';
import 'package:image_text02/routines/app_common.dart';
import 'package:image_text02/routines/IEImage_and_GridSquare.dart';

class PreviewImageScreen extends StatefulWidget {
  const PreviewImageScreen({Key? key}) : super(key: key);

  @override
  State<PreviewImageScreen> createState() => _PreviewImageScreenState();
}

class _PreviewImageScreenState extends State<PreviewImageScreen> {
  @override
  Widget build(BuildContext context) {
    final PMR p = PMR(className: 'PreviewImageScreen', defaultLevel: 0);
    Model model = Provider.of<Model>(context);
    final IEImage ieImage = model.currentIEImage!;

    exitPreview() {
      Navigator.pushReplacementNamed(context, kEditImage);
    }

    doSave() {

      saveImageHold(context) async {
        exitSave() {
          model.reInitializeImage(context);
          Navigator.pushReplacementNamed(context, kDisplayImage);
        }

        // save canvas as
        p.logR('saveImage called');

        Future<bool> saveSizedImage(imageUI, double width, double height,
            {bool? savePNG, bool? saveJPG}) async {
          // set up ImagePainter to draw annotations on the image
          UI.PictureRecorder recorder = UI.PictureRecorder();
          Canvas canvas = Canvas(recorder);
          var size = Size(width, height);

          var painter = ImagePainter(ieImage, imageUI);
          // and Paint!!!
          painter.paint(canvas, size);

          // now get a copy of the canvas in dart:ui image format
          UI.Picture picture = recorder.endRecording();
          var imageForEditUI =
              await picture.toImage(size.width.floor(), size.height.floor());
          // and convert to bytes in PNG format, alas dart:ui does not support '.jpg' format
          var bytesPNG =
              await imageForEditUI.toByteData(format: UI.ImageByteFormat.png);
          var bytesPNGList = bytesPNG?.buffer.asUint8List();
          if (pmTrue(savePNG)) ieImage.savePNG(ieImage.imagePathAndBaseName, bytesPNGList);
          if (pmTrue(saveJPG)) {
            final imageJPG = DI.decodeImage(bytesPNGList!)!;
            ieImage.saveJPG(ieImage.imagePathAndBaseName, imageJPG);
          }
          return true;
        }

        // save a PNG & JPG copy at Edit size
        // await saveSizedImage(ieImage.imageForEditUI, ieImage.imageEditWidth, ieImage.imageEditHeight, '-normal');

        orgImageCallBack(image) async {
          await saveSizedImage(image, ieImage.originalWidth.toDouble(),
              ieImage.originalHeight.toDouble(),
              saveJPG: true);
          exitSave();
        }

        // now prepare to apply edits to the original and save copies
        File originalFile = File(ieImage.imagePathAndBaseName + '.jpg');
        var orgBytes = originalFile.readAsBytesSync();
        UI.decodeImageFromList(orgBytes, orgImageCallBack);
      }

      Navigator.pushReplacementNamed(context, kGenericHold,
          arguments: {kpmMessage: 'Saving File', kpmHoldingCheckFunction: saveImageHold});
    }

    return Row(
      children: [
        Container(
          width: ieImage.imageEditWidth,
          height: ieImage.imageEditHeight,
          child: CustomPaint(
            child: Container(),
            painter: ImagePainter(ieImage, ieImage.imageForEditUI),
          ),
        ),
        SizedBox(width: 25),
        pmBack(exitPreview),
        SizedBox(width: 25),
        pmSave(doSave),
      ],
    );
  }
}
