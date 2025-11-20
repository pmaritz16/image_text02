import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as UI;
import 'package:image/image.dart' as DI;
import 'package:flutter/services.dart';

import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:image_text02/pm_utilities/pm_dartUtils.dart';

import 'package:image_text02/routines/app_common.dart';

class GridSquare {
  String text = '';
  late double xPos, yPos;
  double borderWidth = 1.0;
  Color borderColor = kGridSquareBorderColor;
  TextStyle? textStyle;
  late Widget child;
  bool enabled = false;

  GridSquare(this.xPos, this.yPos) {
    child = Container();
  }
} // end GridSquare

class IEImage {
  final PMR p = PMR(className: 'IEImage', defaultLevel: 0);

  final String imagePathAndFullName;
  late String fullFileName;
  late String imagePathAndBaseName;

  IEImage(this.imagePathAndFullName) {
    PMParsePath par = PMParsePath(imagePathAndFullName);
    fullFileName = par.fileName;
    imagePathAndBaseName = pmJoinPathToName(par.pathTo, par.base);
    //p.logF('create IEImage: $imagePathAndFullName, $imagePathAndBaseName ');
  }

  late double imageEditWidth; // the width used for on screen edit-annotation
  final numXGridSquares = kNumXGridSquares;
  final numYGridSquares = kNumYGridSquares;
  late List<GridSquare> grids;
  late UI.Image imageForEditUI; // resized to imageEditWidth and as dart:ui type
  late Image imageFL; // image type defined by Flutter
  late double imageEditHeight;
  late int originalWidth;
  late int originalHeight;
  late int originalSize;
  late double gridXPercent; // size of the grids in % of width
  late double gridYPercent; // ditto height
  late Text currentFontItem;
  late String currentFontName;
  late FontWeight currentFontWeight;
  late double currentFontSize;
  late int currentFontApColorItem;

  initialize(Function callback) async {
    //
    decodeEditImageCallBack(image) {
      //p.logR('base image loaded');
      imageForEditUI = image;
      callback(); // and release to the callback provided
    }

    //p.logF('Initializing Image: $imagePathAndBaseName');
    imageCache.clear();
    File originalFile = File(imagePathAndFullName);
    originalSize = (originalFile.lengthSync() / 1024).floor();

    currentFontApColorItem = 0;
    setCurrentFontItem(apFontFamilyItems[0]);
    currentFontName = apFontFamilyItems[0].data;
    currentFontWeight = FontWeight.normal;
    currentFontSize = kDefaultPMFontSize;

    // initialize the text grids
    gridXPercent = 1.0 / numXGridSquares;
    gridYPercent = 1.0 / numYGridSquares;
    grids = [];
    for (int i = 0; i < numXGridSquares; i++)
      for (int j = 0; j < numYGridSquares; j++)
        grids.add(GridSquare(gridXPercent * i, gridYPercent * j));

    // get a dart:ui image for painting
    // to resize, first need to use dar:image library which has its own image type

    var diBytes = originalFile.readAsBytesSync();
    DI.Image? imageDI = DI.decodeImage(diBytes);
    originalWidth = imageDI!.width;
    originalHeight = imageDI.height;
    if (originalWidth > originalHeight) {
      imageEditWidth = kImageEditSize;
      imageEditHeight = (originalHeight * (imageEditWidth / originalWidth));
    } else {
      imageEditHeight = kImageEditSize - 150.0;
      imageEditWidth = (originalWidth * (imageEditHeight / originalHeight));
    }
    var editImageDI = DI.copyResize(imageDI,
        width: imageEditWidth.floor(), height: imageEditHeight.floor());

    imageFL = Image.file(originalFile,
        width: imageEditWidth, height: imageEditHeight);

    // now finally, get resized JPG image back into dart:ui format
    //must be done last as callback will release the holding screen!
    var data = DI.encodeJpg(editImageDI);
    var bytes = Uint8List.fromList(data);
    UI.decodeImageFromList(bytes, decodeEditImageCallBack);
  } // end initialize

  changeFontSize(int i, double increment) {
    if (!grids[i].enabled) return;
    TextStyle oldStyle = grids[i].textStyle!;
    double newSize = oldStyle.fontSize! + increment;
    grids[i].textStyle = oldStyle.copyWith(fontSize: newSize);
  }

  changeFontFamily(int i, String name) {
    if (!grids[i].enabled) return;
    TextStyle oldStyle = grids[i].textStyle!;
    grids[i].textStyle = oldStyle.copyWith(fontFamily: name);
  }

  copyGridSquare(int i, source) {
    grids[i].text = grids[source].text;
    grids[i].textStyle = grids[source].textStyle;
    enableInput(i);
    //notifyListeners();
  }

  TextStyle currentTextStyle() {
    p.logR('current font: $currentFontName');
    return TextStyle(
        fontFamily: currentFontName,
        fontWeight: currentFontWeight,
        fontSize: currentFontSize,
        color: apFontColors[currentFontApColorItem].color);
  }

  disableInput(int i) {
    grids[i].enabled = false;
    grids[i].borderColor = kGridSquareBorderColor;
    grids[i].child = Container();
    grids[i].text = '';
    //notifyListeners();
  }

  enableInput(int i, {TextStyle? textStyle}) {
    callback(String s) {
      grids[i].text = s;
    }

    p.logR('setting attributes $i');
    if (textStyle != null) grids[i].textStyle = textStyle;
    grids[i].enabled = true;
    grids[i].borderColor = kGridSquareBorderColorSelected;
    grids[i].child = PMTextInput(
      callback: callback,
      decoration: kpmInputDecorationSmall,
      initialText: grids[i].text,
      textStyle: grids[i].textStyle!,
      width: imageEditWidth * gridXPercent * 0.9,
      height: imageEditHeight * gridYPercent * 0.9,
      maxLines: 3,
    );
  }

  saveJPG(String name, image) {
    String newName = name + '.jpg';
    pmDeleteEntry(newName);
    File(newName).writeAsBytesSync(DI.encodeJpg(image));
  }

  savePNG(String name, bytesPNGList) {
    String newName = name + '.png';
    pmDeleteEntry(newName);
    File(newName).writeAsBytesSync(bytesPNGList);
  }

  setColor(int i, Color color) {
    if (!grids[i].enabled) return;
    grids[i].textStyle = grids[i].textStyle!.copyWith(color: color);
  }

  setCurrentFontItem(value) {
    currentFontItem = value;
    currentFontName = value.style.fontFamily;
  }
} // end IEImage
