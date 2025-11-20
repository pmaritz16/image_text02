// 2024-11-12

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:image_text02/pm_utilities/pm_dartUtils.dart';
import 'package:image_text02/pm_utilities/pm_constants.dart';

import 'package:image_text02/routines/model.dart';
import 'package:image_text02/routines/grid_on_image.dart';
import 'package:image_text02/routines/app_common.dart';
import 'package:image_text02/routines/rename_and_move_screen.dart';
import 'package:image_text02/routines/IEImage_and_GridSquare.dart';
//import 'package:image_text02/routines/preview_image_screen.dart';

class EditImageScreen extends StatefulWidget {
  const EditImageScreen({Key? key}) : super(key: key);

  @override
  State<EditImageScreen> createState() => _EditImageScreenState();
}

class _EditImageScreenState extends State<EditImageScreen> {
  final PMR p = PMR(className: 'EditImage', defaultLevel: 0);
  late IEImage ieImage;

  late List<Widget> colorChoices;

  List<Widget> buildFontColorList() {
    List<Widget> colorItems = [];
    for (int i = 0; i < apFontColors.length; i++) {
      callBack() {
        setState(() {
          ieImage.currentFontApColorItem = i;
        });
      }

      colorItems.add(Draggable(
          data: {kVerb: kColor, kData: apFontColors[i].color},
          child: pmCircle(color: apFontColors[i].color, onTap: callBack),
          feedback: pmCircle(color: apFontColors[i].color, onTap: callBack)));
    }
    return colorItems;
  }

  toggleFW() {
    setState(() {
      ieImage.currentFontWeight =
          (ieImage.currentFontWeight == FontWeight.normal)
              ? FontWeight.bold
              : FontWeight.normal;
    });
  }

  Widget buildFontWeightToggle() {
    return Draggable(
        data: {kVerb: kToggleFontWeight},
        child: pmCircle(
            borderColor: Colors.black,
            color: (ieImage.currentFontWeight == FontWeight.normal)
                ? Colors.lightBlueAccent
                : Colors.deepOrangeAccent,
            width: 35,
            height: 35,
            child: Center(
              child: Text(
                'B',
                style: TextStyle(
                    fontSize: 25, fontWeight: ieImage.currentFontWeight),
              ),
            ),
            onTap: toggleFW),
        feedback: pmCircle(color: Colors.grey, child: Text('B')));
  }

  setCurrentFontItem(value) {
    setState(() {
      ieImage.setCurrentFontItem(value);
    });
  }

  changeFontSize(Map action) {
    if (action[kVerb] == kFontSizeChange) {
      setState(() {
        ieImage.currentFontSize += action[kData];
        p.logR('font size now: ${ieImage.currentFontSize}');
      });
    }
  }

  showRenameResizeTag() {
    pmShowTopSheet(context: context, child: RenameAndMoveOptions());
  }

  Widget textWidget(String t, double size) {
    double w = size * 3;
    return pmRectangle(
      width: w,
      height: size + 4,
      borderRadius: 8,
      color: Colors.lightBlueAccent,
      child: Text(t, style: TextStyle(fontSize: size)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Model model = Provider.of<Model>(context);
    ieImage = model.currentIEImage!;
    p.logR('Building Edit Image');
    colorChoices = buildFontColorList();

    return Scaffold(
      body: pmColumn(
        mAlign: kpmStart,
        [
          pmRow(
            mAlign: kpmStart,
            [
              //** The Image and GRID
              Container(
                width: ieImage.imageEditWidth,
                height: ieImage.imageEditHeight,
                child: Center(
                  child: GridSquareOnImage(),
                ),
              ),
              SizedBox(width: 25),
              pmColumn(xAlign: kpmStart, [
                pmRow(mAlign: kpmStart, [
                  //** Color Circles
                  pmRectangle(
                    width: 180,
                    height: 50,
                    child: pmRow(colorChoices),
                    color: Colors.blueGrey.shade300,
                  ),
                ]),
                pmSpacerV(),
                pmRow([
                  //** Font Increase/Decrease
                  Draggable<Map>(
                    data: {kVerb: kFontSizeChange, kData: -10.0},
                    child: textWidget('A--', 16),
                    feedback: Text('A--', style: TextStyle(fontSize: 16)),
                  ),
                  pmSpacerH(),
                  Draggable<Map>(
                    data: {kVerb: kFontSizeChange, kData: -4.0},
                    child: textWidget('A-', 20),
                    feedback: Text('A-', style: TextStyle(fontSize: 20)),
                  ),
                  pmSpacerH(),
                  Draggable<Map>(
                    data: {kVerb: kFontSizeChange, kData: 4.0},
                    child: textWidget('A+', 24),
                    feedback: Text('A+', style: TextStyle(fontSize: 24)),
                  ),
                  pmSpacerH(),
                  Draggable<Map>(
                    data: {kVerb: kFontSizeChange, kData: 10.0},
                    child: textWidget('A++', 28),
                    feedback: Text('A++', style: TextStyle(fontSize: 48)),
                  ),
                  pmSpacerH(),
                  //** Current Font Weight
                  buildFontWeightToggle(),
                ]),
                pmSpacerV(),
                pmRow([
                  //** Current Font
                  Draggable<Map>(
                    data: {
                      kVerb: kFontFamilyChange,
                      kData: ieImage.currentFontName
                    },
                    child: pmRectangle(
                        child: ieImage.currentFontItem,
                        width: 100,
                        height: 40,
                        color: Colors.white38),
                    feedback: pmRectangle(
                        child: ieImage.currentFontItem,
                        width: 100,
                        height: 40,
                        color: Colors.grey),
                  ),
                  pmSpacerH(),
                  //** Font Picker
                  SizedBox(
                    child: PMDropDownButton(
                      action: setCurrentFontItem,
                      itemList: pmBuildDropDownMenuList(apFontFamilyItems),
                    ),
                  )
                ]),
                pmSpacerV(),
                pmRow([
                  //** Current Font Size
                  DragTarget<Map>(
                    //onAccept: changeFontSize,
                    onAcceptWithDetails: (DragTargetDetails details) {
                      // Access the dropped data and drop location
                      changeFontSize(details.data);
                    },
                    builder: (context, _, __) =>
                        pmText('font size ${ieImage.currentFontSize}'),
                  ),
                ]),
                pmSpacerV(h: 30),
                //** The TEXT Icon
                pmRow([
                  pmRectangle(
                    height: 50,
                    width: 50,
                    color: Colors.blueGrey,
                    child: Draggable<Map>(
                      data: {kVerb: kEnable, kData: ieImage.currentTextStyle()},
                      child: Icon(Icons.text_fields,
                          size: 40,
                          color:
                              apFontColors[ieImage.currentFontApColorItem].color),
                      feedback: Icon(Icons.text_fields,
                          size: 40,
                          color:
                              apFontColors[ieImage.currentFontApColorItem].color),
                      childWhenDragging:
                          Icon(Icons.text_fields, size: 40, color: Colors.grey),
                    ),
                  ),
                  pmSpacerH(),
                  //**  The ERASE Icon
                  Draggable<Map>(
                    data: {kVerb: kDisable},
                    child: Icon(Icons.delete, size: 40, color: Colors.black),
                    feedback: Icon(Icons.delete, size: 40, color: Colors.black),
                    childWhenDragging:
                        Icon(Icons.delete, size: 40, color: Colors.grey),
                  ),
                ]),
                //** Preview Button
                pmSpacerV(h: 40),
                pmButton(
                  backgroundColor: kpmColorDarkBlue,
                  child: pmText('Preview', c: kpmWhite),
                  width: 120.0,
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, kPreviewImage);
                  },
                ),
                pmSpacerV(h: 40.0),
                pmBack(() {
                  Navigator.pushReplacementNamed(context, kDisplayImage);
                }),
              ]),
            ],
          ),
          //** Original Image Data
          pmRow(mAlign: kpmStart, [
            pmText('${model.currentIndex + 1}/${model.fileItems.length}:' +
                ' ${ieImage.imagePathAndBaseName}, ${ieImage.originalWidth}x${ieImage.originalHeight}, size ${ieImage.originalSize}KB'),
          ]),
        ],
      ),
    );
  }
}
