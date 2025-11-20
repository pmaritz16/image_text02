// 2024-11-09

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:image_text02/pm_utilities/pm_constants.dart';
import 'package:image_text02/pm_utilities/pm_dartUtils.dart';

import 'package:image_text02/routines/model.dart';
import 'package:image_text02/routines/app_common.dart';
import 'package:image_text02/routines/rename_and_move_screen.dart';

class ListFilesScreen extends StatefulWidget {
  const ListFilesScreen({Key? key}) : super(key: key);

  @override
  State<ListFilesScreen> createState() => _ListFilesScreenState();
}

class _ListFilesScreenState extends State<ListFilesScreen> {
  String jumpIndex = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<Model>(
      builder: (context, model, child) {
        final PMR p = PMR(className: 'ListFilesScreen', defaultLevel: 0);

        //--------------- helpers ------------------------------

        List<Widget> pageRows = [];

        init() {
          if (model.initialize()) {
            if (model.fileItems.length == 0 && model.directories.length == 0) {
              pmShowDialogue(context,pmText('${model.currentDirPath} Empty'));
              return;
            }
          } else {
            //p.logR('pmDir error', level: 1);
            pmShowDialogue(context, pmText('unable to list: ${model.currentDirPath}'));
            return;
          }
        }

        setDirName(s) {
          //if (pmSubstring(s, start: s.length - 1, len: 1) == '\\')
          // s = pmSubstring(s, start: 0, len: s.length - 1);
          model.currentDirPath = s;
        }

        PMTextInputWithReset getDirPath = PMTextInputWithReset(
          setDirName,
          width: 300.0,
          textStyle: TextStyle(fontSize: 18),
        );

        Function()? clearFilterString;

        clearFilter() {
          clearFilterString!();
        }

        PMTextInputWithReset getFilterString = PMTextInputWithReset(
          model.setFilter,
          width: 100.0,
          hintText: 'filter',
          textStyle: TextStyle(fontSize: 11),
          resetFunction: clearFilter,
        );

        clearFilterString = () {
          model.setFilter('');
          getFilterString.clear();
        };


        Widget directoryEntry(int i) {
          drillDown() {
            setDirName(
                pmJoinPathToName(model.currentDirPath, model.directories[i]));
            init();
          }

          //p.logR('adding dir: $i, ${model.directories[i]}', level: 1);
          return pmRectangle(
            child: apTextShrink(model.directories[i]),
            height: 40,
            width: 150,
            borderRadius: 5.0,
            color: kDirectoryColor,
            onTap: drillDown,
          );
        }

        Widget directoryEntries() {
          List<Widget> entryRow = [];
          List<Widget> entryRows = [];
          int count = 0;
          for (int i = 0; i < model.directories.length; i++) {
            entryRow.add(directoryEntry(i));
            entryRow.add(pmSpacerH(w: 5.0));
            count++;
            if (count > 6) {
              count = 0;
              entryRows.add(pmRow(entryRow));
              entryRow = [];
            }
          }
          if (count > 0) entryRows.add(pmRow(entryRow));
          return ListView.builder(
              itemCount: entryRows.length,
              itemBuilder: (context, index) {
                return entryRows[index];
              });
        }


        goUpDirectory() {
          PMParsePath pp = PMParsePath(model.currentDirPath);
          //p.logF('go Up, curDir: "${model.currentDirPath}" pl len: ${pp.pathList.length}, pathTo: "${pp.pathTo}"');
          if (pmNil(pp.pathTo)) return;
          clearFilterString!();
          setDirName(pp.pathTo);
          p.logR(
              'going up: "${model.currentDirPath}", filter: "${model.filterString}"');
          init();
        }

        jumpTo() {
          int? j = int.tryParse(jumpIndex);
          if (j != null)
            model.jumpToAbsolute(j - 1);
          else {
            model.jumpToFilter(jumpIndex);
          }
        }

        Widget makeFileItem(int i) {
          FileItem fi = model.fileItems[i];

          displayImage() {
            model.setAndInvokeDisplayImage(context, i);
          }

          //p.logR('row ${fi.name}, ${fi.isolateRequestStatus}', level: 0);
          return pmRectangle(
            height: kCellHeight,
            width: kCellWidth,
            color:
                i == model.currentIndex ? Colors.lightBlueAccent : Colors.white,
            child: pmColumn([
              pmRow(mAlign: kpmCenter, [
                pmRectangle(
                  onTap: displayImage,
                  child: (fi.thumbnail != null)
                      ? fi.thumbnail
                      : pmText('null', s: kpmXS),
                  width: kThumbWidth + 2,
                  height: kThumbHeight + 2,
                ),
                PMRoundIconButton(
                    icon: Icons.delete,
                    size: 10.0,
                    onPressed: () {
                      model.flagForDeletion(i);
                    },
                    color: fi.toBeDeleted ? Colors.red : Colors.grey),
              ]),
              Expanded(
                  child: pmText('${i + 1}. ${fi.name}',
                      s: kpmXXS,
                      c: i == model.currentIndex ? kpmBlack : kpmGrey)),
            ]),
          ); // end rectangle
        }

        setJump(String s) {
          setState(() {
            jumpIndex = s;
          });
        }

        // ----------- code run on build --------------------------


        getDirPath.reset(model.currentDirPath);
        getFilterString.reset(model.filterString);
        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;

        p.logR(
            'Building: filter: "${model.filterString}", value: "${getFilterString.currentValue()}".');

        if (model.fileItems.length > 0) {
          // calculate grid dimensions

          model.setPageStartEnd(); // i.e. check limits
          model.initiateThumbs();

          // now start to populate the grid

          int numCols = (screenWidth / kCellWidth).floor();
          pageRows = [];
          List<Widget> itemRow = [];
          int j = 0;
          for (int i = model.start; i < model.end; i++) {
            itemRow.add(makeFileItem(i));
            j++;
            if (j >= numCols) {
              j = 0;
              pageRows.add(pmRow(itemRow, mAlign: kpmStart));
              itemRow = [];
            }
          }
          if (itemRow.length > 0)
            pageRows.add(pmRow(itemRow, mAlign: kpmStart));
        }

        //----------------- display the actual page --------------------

        return Scaffold(
          body: pmColumn(
            [
              pmRow(
                [
                  // header row
                  pmText('($kAppRevision)', c: kpmBlue, s: kpmXXS),
                  pmSpacerH(),
                  PMRoundIconButton(
                      message: 'go to parent directory',
                      icon: MdiIcons.arrowTopLeftThick,
                      color: kpmColorGrey1,
                      onPressed: goUpDirectory),
                  pmSpacerH(),
                  pmText('Dir?'),
                  pmSpacerH(w: 5),
                  getDirPath.textInput,
                  pmSpacerH(),
                  PMRoundIconButton(
                      message: 'list images/directories',
                      color: kpmColorLightPurple,
                      icon: Icons.format_align_justify_outlined,
                      onPressed: init),
                  if (model.fileItems.length > 0 && model.thumbsActive > 0)
                    // show flashing icon if thumbs are being made
                    PMFlashing(
                      child: Icon(
                        Icons.thumb_up,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                  pmSpacerH(),
                  getFilterString.textInput,

                  // rest of info once directory listed
                  pmSpacerH(),
                  if (model.fileItems.length > 0)
                    PMTextInput(
                      callback: setJump,
                      hintText: 'jump',
                      textStyle: TextStyle(fontSize: 11),
                      width: 75,
                      decoration: kpmInputDecorationSmall,
                    ),
                  if (model.fileItems.length > 0)
                    PMRoundIconButton(
                        icon: MdiIcons.kangaroo,
                        color: Colors.brown,
                        onPressed: jumpTo),

                  PMRoundIconButton(
                    message: 'show rename/resize/tag screen',
                    color: kpmColorAmber,
                    icon: MdiIcons.cog,
                    onPressed: () {
                      pmShowTopSheet(
                          context: context, child: RenameAndMoveOptions());
                    },
                  ),
                  apGroupJump(model),
                  if (model.start > 0) pmSpacerH(),
                  if (model.start > 0)
                    PMRoundIconButton(
                        color: kpmColorLightBlue,
                        icon: Icons.arrow_circle_up,
                        onPressed: model.pageUp),
                  if (model.end < model.fileItems.length) pmSpacerH(),
                  if (model.end < model.fileItems.length)
                    PMRoundIconButton(
                        color: kpmColorLightGreen,
                        icon: Icons.arrow_circle_down,
                        onPressed: model.pageDown),
                ],
              ),
              // start of table
              if (model.directories.length > 0) pmSpacerV(),
              //pmText('${model.directories.length} DIRS', s: kpmXL),
              if (model.directories.length > 0)
                SizedBox(
                  height: screenHeight - 110,
                  child: directoryEntries(),
                ),
              pmSpacerV(),
              //pmText('${model.files.length} FILES', s: kpmXL),
              if (model.fileItems.length > 0 && model.directories.length == 0)
                pmColumn([
                  SizedBox(
                    height: screenHeight -
                        (model.directories.length > 0 ? 110 : 160),
                    child: ListView.builder(
                      itemCount: pageRows.length,
                      itemBuilder: (context, index) {
                        return pageRows[index];
                      },
                    ),
                  ),
                  pmSpacerV(h: 20),
                  pmText(
                      '${model.start + 1}-${model.end} of ${model.fileItems.length} files',
                      s: kpmS),
                ]),
            ], // end of major column
          ),
        );
      },
    );
  }
}
