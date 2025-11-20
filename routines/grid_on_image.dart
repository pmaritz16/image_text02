import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:image_text02/pm_utilities/pm_dartUtils.dart';

import 'package:image_text02/routines/app_common.dart';
import 'package:image_text02/routines/model.dart';
import 'package:image_text02/routines/IEImage_and_GridSquare.dart';

class GridSquareOnImage extends StatefulWidget {
  @override
  _GridSquareOnImageState createState() => _GridSquareOnImageState();
}

class _GridSquareOnImageState extends State<GridSquareOnImage> {
  final PMR p = PMR(className: 'GridSquareOnImage', defaultLevel: 0);
  late double maxHeight;
  late double maxWidth;

  late IEImage ieImage;

  setAttributes(int i, Map action, IEImage ie) {
    setState(() {
      switch (action[kVerb]) {
        case kEnable:
          p.logR('enabling $i');
          ie.enableInput(i, textStyle: action[kData]);
          break;
        case kMove:
          int sourceId = action[kData];
          p.logR('moving $sourceId to $i}');
          ie.copyGridSquare(i, sourceId);
          ie.disableInput(sourceId);
          break;
        case kDisable:
          ie.disableInput(i);
          break;
        case kColor:
          ie.setColor(i, action[kData]);
          break;
        case kFontSizeChange:
          ie.changeFontSize(i, action[kData]);
          break;
        case kFontFamilyChange:
          ie.changeFontFamily(i, action[kData]);
          break;
        case kToggleFontWeight:
          GridSquare g = ie.grids[i];
          g.textStyle = g.textStyle!.copyWith(
              fontWeight: (g.textStyle!.fontWeight == FontWeight.normal)
                  ? FontWeight.bold
                  : FontWeight.normal);
          break;
        default:
          p.logR(
            'Unknown verb: ${action[kVerb]}',
          );
      }
    });
  }

  Widget enableTextField(int i) {
    if (ieImage.grids[i].enabled) {
      return Draggable<Map>(
        child: ieImage.grids[i].child,
        //feedback: pmText(ieImage.grids[i].text, c: kpmYellow),
        //childWhenDragging: pmCircle(color: Colors.grey, opacity: 0.5),
        feedback: pmCircle(color: Colors.yellow, opacity: 0.5),
        data: {kVerb: kMove, kData: i},
      );
    } else
      return Container();
  }

  @override
  Widget build(BuildContext context) {
    p.logR('building GridSquareOnImage', level: 0);
    Model model = Provider.of<Model>(context);
    ieImage = model.currentIEImage!;

    // force current text into text field of active grids
    for (int i = 0; i < ieImage.grids.length; i++)
      if (pmNotNil(ieImage.grids[i].text)) {
        p.logR('text $i: ${ieImage.grids[i].text}');
        ieImage.enableInput(i);
      }

    maxHeight = ieImage.imageEditHeight * ieImage.gridYPercent;
    maxWidth = ieImage.imageEditWidth * ieImage.gridXPercent;
    //
    List<Widget> buildLayouts() {
      List<Widget> layouts = [];
      layouts.add(LayoutId(
        id: 0,
        child: ieImage.imageFL,
      ));
      for (int i = 0; i < ieImage.grids.length; i++) {
        layouts.add(
          LayoutId(
            id: i + 1,
            child: DragTarget<Map>(
              //onAccept: (data) => setAttributes(i, data, ieImage),
              onAcceptWithDetails: (DragTargetDetails details) {
                // Access the dropped data and drop location
                setAttributes(i, details.data, ieImage);
              },
              builder: (context, _, __) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(
                    color: ieImage.grids[i].borderColor,
                    width: ieImage.grids[i].borderWidth,
                  ),
                ),
                child: Center(child: enableTextField(i)),
                height: ieImage.imageEditHeight * ieImage.gridYPercent,
                width: ieImage.imageEditWidth * ieImage.gridXPercent,
              ), // EC
            ),
          ),
        );
      }
      return layouts;
    }

    return Center(
      child: CustomMultiChildLayout(
        delegate: _CustomMultiChildLayoutDelegate(
            imageSize: Size(ieImage.imageEditWidth, ieImage.imageEditHeight),
            maxHeight: maxHeight,
            maxWidth: maxWidth,
            ieImage: ieImage),
        children: buildLayouts(),
      ),
    );
  }
}

class _CustomMultiChildLayoutDelegate extends MultiChildLayoutDelegate {
  // The height and width here are to calculate the position of the child
  final maxHeight;
  final maxWidth;
  final Size? imageSize;
  IEImage? ieImage;

  _CustomMultiChildLayoutDelegate(
      {this.imageSize, this.maxHeight, this.maxWidth, this.ieImage});

  @override
  void performLayout(Size size) {
    p.logR('Performing Layout');

    if (hasChild(0)) {
      layoutChild(
          0,
          BoxConstraints(
              maxWidth: imageSize!.width, maxHeight: imageSize!.height));
      positionChild(0, Offset(0.0, 0.0));
    }

    for (int i = 0; i < ieImage!.grids.length; i++) {
      if (hasChild(i + 1)) {
        layoutChild(
            i + 1, BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight));
        // Center of the box
        double dX = imageSize!.width * ieImage!.grids[i].xPos;
        double dY = imageSize!.height * ieImage!.grids[i].yPos;
        p.logR('positioning grid $i at $dX,$dY');
        positionChild(i + 1, Offset(dX, dY));
      }
    }
  }

  @override
  bool shouldRelayout(_CustomMultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}
