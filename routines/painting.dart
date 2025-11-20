import 'package:flutter/material.dart';
import 'dart:ui' as UI;

import 'package:image_text02/pm_utilities/pm_dartUtils.dart';

import 'package:image_text02/routines/IEImage_and_GridSquare.dart';

class ImagePainter extends CustomPainter {
  IEImage ieImage;
  UI.Image imageUI; // image to be painted on in dart:ui format

  ImagePainter(this.ieImage, this.imageUI);

  final PMR p = PMR(className: 'ImagePainter', defaultLevel: 0);

  @override
  void paint(Canvas canvas, Size size) {
    TextPainter textPainter(
        String s, TextStyle style, double maxWidth, TextAlign align) {
      final span = TextSpan(text: s, style: style);
      final tp = TextPainter(
          text: span, textAlign: align, textDirection: TextDirection.ltr);
      tp.layout(minWidth: 0, maxWidth: maxWidth);
      return tp;
    }

    Size drawText(Canvas canvas, Offset position, String text, TextStyle style,
        double maxWidth) {
      final tp = textPainter(text, style, maxWidth, TextAlign.center);
      final pos = position +
          Offset(size.width * ieImage.gridXPercent * 0.2,
              size.height * ieImage.gridYPercent * 0.2);
      tp.paint(canvas, pos);
      return tp.size;
    }

    canvas.drawImage(imageUI, Offset(0.0, 0.0), Paint());

    final maxWidth = size.width / ieImage.numXGridSquares;

    for (GridSquare grid in ieImage.grids)
      if (pmNotNil(grid.text)) {
        double xPos = grid.xPos * size.width;
        double yPos = grid.yPos * size.height;
        p.logR('drawing text ${grid.text} at $xPos,$yPos');
        double? fs = grid.textStyle!.fontSize! * size.width / ieImage.imageEditWidth;
        drawText(canvas, Offset(xPos, yPos), grid.text,
            grid.textStyle!.copyWith(fontSize: fs), maxWidth);
      }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}
