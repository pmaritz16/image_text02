import 'package:flutter/material.dart';
import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:image_text02/routines/model.dart';

const kAppRevision = '2025-11-19';

List<String> kMoveTargets = [
  'c1',
  'c2',
  'c3',
  'c4',
  'c5',
  'c6'
];

const kInitialPageSize = 35;
const kItemsPerRow = 6;
const kImageEditSize = 800.0; // the width used for on screen edit-annotation
const kNumXGridSquares = 4; // X axis division for above
const kNumYGridSquares = 5; // Y axis
const kThumbWidth = 100; // thumbnail size
const kThumbHeight = 75;
const kCellHeight = 110.0; // for main image/thumb listing grid
const kCellWidth = 200.0;
const kDefaultPMFontSize = 14.0;
const kDefaultInterval = 2; // side show
const kStartingDirectory = 't:\\';

// page routes
const kPreviewImage = '/PreviewImage';
const kEditImage = '/EditImage';
const kDisplayImage = '/DisplayImage';
const kSaveImage = '/SaveImage';
const kListFiles = '/ListFiles';
const kGenericHold = '/GenericHold';
const kGenericProgress = '/GenericProgress';

// constants for map field names
const kVerb = 'verb';
const kEnable = 'enable';
const kDisable = 'disable';
const kMove = 'move';
const kData = 'data';
const kColor = 'color';
const kFontSizeChange = 'change font size';
const kFontFamilyChange = 'change font family';
const kToggleFontWeight = 'Toggle Font Weight';

const kGridSquareBorderColor = Colors.grey;
const kGridSquareBorderColorSelected = Colors.white;
const kDirectoryColor = Color(0XFFFFF9C4);

// color picker constructs for annotations
class ApColorItem {
  late String name;
  late Color color;
  late Widget child;

  ApColorItem(this.name, this.color) {
    child = pmCircle(color: color, width: 10, height: 10);
  }
}

final List apFontColors = [
  ApColorItem('black', Colors.black),
  ApColorItem('grey', Colors.grey),
  ApColorItem('white', Colors.white),
  ApColorItem('red', Colors.red),
  ApColorItem('yellow', Colors.yellow),
  ApColorItem('blue', Colors.blue),
  ApColorItem('green', Colors.green)
];

final List apFontFamilyItems = [
  Text('Merriweather', style: TextStyle(fontFamily: 'Merriweather')),
  Text('DancingScript', style: TextStyle(fontFamily: 'DancingScript')),
  Text('Roboto', style: TextStyle(fontFamily: 'Roboto')),
];

const kMoveTargetsColor = kpmColorLightCyan;

Widget apMakeMoveTargetsRow(Model model, Function action) {
  List<Widget> items = [];

  for (int j = 0; j < model.moveDirectories.length; j++) {
    setMoveTargetsIJ() {
      //model.setMoveTargets(ix, j);
      action(j);
    }

    Color bc = kMoveTargetsColor;
    String tc = kpmBlack;
    if (model.fileItems[model.currentIndex].moveIndex == j) {
      bc = kpmColorDarkCyan;
      tc = kpmWhite;
    }

    items.add(
      pmRectangle(
          width: 40,
          height: 27,
          child: pmText(model.moveDirectories[j].moniker, s: kpmXS, c: tc),
          onTap: setMoveTargetsIJ,
          borderRadius: 5.0,
          color: bc),
    );
    items.add(pmSpacerH(w: 5.0));
  }
  return pmRow(items);
}

Widget apTextShrink(String s, {String c = ''}) {
  return s.length < 30 ? pmText(s, s: kpmXS, c: c) : pmText(s, s: kpmXXS, c: c);
}

Widget apGroupJump(Model model) {
  return pmRow([
    if (model.start == 0) pmSpacerH(w: 48.0),
    if (model.start > 0)
      PMRoundIconButton(
          message: 'go back a group',
          color: Colors.pinkAccent,
          icon: MdiIcons.arrowUpBoldBox,
          onPressed: model.jumpBackToPrev),
    if (model.end < model.fileItems.length)
      PMRoundIconButton(
          message: 'go forward a group',
          color: Colors.purple,
          icon: MdiIcons.arrowDownBoldBox,
          onPressed: model.jumpDownToNext),
  ]);
}
