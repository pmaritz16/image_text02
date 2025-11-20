import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:image_text02/pm_utilities/pm_dartUtils.dart';
import 'package:image_text02/pm_utilities/pm_constants.dart';

import 'package:image_text02/routines/model.dart';
import 'package:image_text02/routines/app_common.dart';
import 'package:image_text02/routines/rename_and_move_screen.dart';

import 'dart:io';

class DisplayImageScreen extends StatefulWidget {
  const DisplayImageScreen({Key? key}) : super(key: key);

  @override
  State<DisplayImageScreen> createState() => _DisplayImageScreenState();
}

class _DisplayImageScreenState extends State<DisplayImageScreen> {
  final PMR p = PMR(className: 'DisplayImage', defaultLevel: 0);
  late Model model;

  double widthAllocation = 150;
  bool moveFlag = false;

  groupDelete() {
    model.stopSlideShow();
    model.groupDelete(model.currentNameForFilter());
    Navigator.pushReplacementNamed(context, kListFiles);
  }

  groupCopy() {
    model.stopSlideShow();
    model.groupCopy(model.currentNameForFilter(), 0);
    Navigator.pushReplacementNamed(context, kListFiles);
  }

  groupMove() {
    model.stopSlideShow();
    model.groupMove(model.currentNameForFilter());
    Navigator.pushReplacementNamed(context, kListFiles);
  }

  Widget returnToListing() {
    return PMRoundIconButton(
        message: 'grid view',
        color: kpmColorLightPurple,
        icon: Icons.grid_on,
        onPressed: () {
          model.stopSlideShow();
          Navigator.pushReplacementNamed(context, kListFiles);
        });
  }

  setWidthAllocation() {
    widthAllocation = moveFlag ? 305 : 150;
  }

  showRenameResizeTag() {
    model.stopSlideShow();
    pmShowTopSheet(context: context, child: RenameAndMoveOptions());
  }

  showEditImage() {
    model.stopSlideShow();
    model.setAndInvokeEditImage(context);
  }

  toggleMoveFlag() {
    setState(() {
      moveFlag = !moveFlag;
    });
  }

  @override
  Widget build(BuildContext context) {
    model = Provider.of<Model>(context);

    int screenWidth = MediaQuery.of(context).size.width.floor();
    int screenHeight = MediaQuery.of(context).size.height.floor();

    setWidthAllocation();

    if (model.clearImageCache) {
      imageCache.clear();
      imageCache.clearLiveImages();
      model.clearImageCache = false;
    }

    if (model.slideShowInterval > 0) {
      int secs = model.slideShowInterval;
      model.slideShowInterval = 0; // prevent spurious Futures being created
      Future.delayed(
        Duration(seconds: secs),
        () {
          if (model.slideShowInterval >= 0) {
            model.slideShowInterval = model.requestedInterval;
            model.jumpToOffset(1);
          }
        },
      );
    }

    FileItem fi = model.fileItems[model.currentIndex];
    return Scaffold(
      body: pmColumn(
        mAlign: kpmCenter,
        [
          pmRow(
            mAlign: kpmStart,
            [
              //** The Image and  GRID
              Container(
                width: screenWidth - widthAllocation,
                height: screenHeight - 25,
                child: FittedBox(
                  child: Image.file(
                    key: UniqueKey(),
                    File(fi.fullPath),
                  ),
                ),
              ),
              SizedBox(width: 25),
              pmColumn(xAlign: kpmStart, [
                pmRow([
                  PMRoundIconButton(
                      size: 35,
                      message: 'move group',
                      icon: MdiIcons.contentSaveMove,
                      color: Colors.orange,
                      onPressed: groupCopy),
                  pmSpacerH(),
                  PMRoundIconButton(
                      size: 35,
                      message: 'copy group',
                      icon: MdiIcons.contentSaveMove,
                      color: Colors.greenAccent,
                      onPressed: groupCopy),
                ]),
                PMRoundIconButton(
                    size: 35,
                    message: 'delete group',
                    icon: MdiIcons.fileDocumentRemove,
                    color: Colors.redAccent,
                    onPressed: groupDelete),
                pmSpacerV(),
                PMRoundIconButton(
                    message: 'show/hide tags',
                    icon: MdiIcons.playlistPlay,
                    color: Colors.greenAccent,
                    onPressed: toggleMoveFlag),
                if (moveFlag) apMakeMoveTargetsRow(model, model.setMoveTargets),
                pmSpacerV(),
                PMRoundIconButton(
                    message: 'flag for deletion',
                    icon: Icons.delete,
                    onPressed: () {
                      model.flagForDeletion(model.currentIndex);
                    },
                    color: fi.toBeDeleted ? Colors.red : Colors.blueAccent),
                PMRoundIconButton(
                  message: 'show rename/resize/tag screen',
                  color: kpmColorAmber,
                  icon: MdiIcons.cog,
                  onPressed: showRenameResizeTag,
                ),
                pmSpacerV(),
                PMRoundIconButton(
                    message: 'annotate image',
                    color: kpmColorAmber,
                    icon: Icons.edit_note,
                    onPressed: showEditImage),
                pmSpacerV(),
                pmRow([
                  PMRoundIconButton(
                      message: 'slide show',
                      icon: Icons.crisis_alert,
                      size: kpmMediumRoundButtonSize,
                      color: model.slideShowInterval < 0
                          ? Colors.yellow
                          : Colors.red,
                      onPressed: () {
                        if (model.slideShowInterval < 0)
                          model.startSlideShow();
                        else
                          model.stopSlideShow();
                        p.logR(
                          'interval: ${model.requestedInterval}, ${model.slideShowInterval}',
                        );
                      }),
                  pmColumn([
                    PMRoundIconButton(
                      icon: Icons.add,
                      color: Colors.grey,
                      size: kpmSmallRoundButtonSize,
                      onPressed: model.increaseInterval,
                    ),
                    pmText(model.requestedInterval.toString(), s: kpmXS),
                    PMRoundIconButton(
                      icon: Icons.minimize,
                      color: Colors.grey,
                      size: kpmSmallRoundButtonSize,
                      onPressed: model.decreaseInterval,
                    ),
                  ]),
                ]),
                pmSpacerV(),
                returnToListing(),
                pmSpacerV(),
                apGroupJump(model),
                pmRow([
                  if (model.currentIndex == 0) pmSpacerH(w: 48.0),
                  if (model.currentIndex > 0)
                    PMRoundIconButton(
                        icon: Icons.arrow_circle_left,
                        color: kpmColorLightBlue,
                        onPressed: () {
                          model.jumpToOffset(-1);
                        }),
                  if (model.currentIndex < model.fileItems.length - 1)
                    PMRoundIconButton(
                        icon: Icons.arrow_circle_right,
                        color: kpmColorLightGreen,
                        onPressed: () {
                          model.jumpToOffset(1);
                        }),
                ]),
              ]),
            ],
          ),
          //** Original Image Data
          pmRow(mAlign: kpmCenter, [
            apTextShrink(
              '${fi.fullPath} (${model.currentIndex + 1}/${model.fileItems.length})',
            ),
            pmSpacerH(),
            if (fi.width > 0)
              apTextShrink(
                  '(${fi.width}x${fi.height}, ${double.parse((fi.size / (1024 * 1024)).toStringAsFixed(2))}MB)',
                  c: kpmGrey),
          ]),
        ],
      ),
    );
  }
}
