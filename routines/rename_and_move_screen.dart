import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:image_text02/pm_utilities/pm_dartUtils.dart';
import 'package:image_text02/pm_utilities/pm_constants.dart';

import 'package:image_text02/routines/model.dart';
import 'package:image_text02/routines/app_common.dart';

class RenameAndMoveOptions extends StatefulWidget {
  const RenameAndMoveOptions({Key? key}) : super(key: key);

  @override
  State<RenameAndMoveOptions> createState() => _RenameAndMoveOptionsState();
}

class _RenameAndMoveOptionsState extends State<RenameAndMoveOptions> {
  final PMR p = PMR(className: 'SetNameChoices', defaultLevel: 0);
  late Model model;
  late PMTextInputWithReset getNewPath;
  late PMTextInputWithReset getNewMoniker;
  late PMTextInputWithReset getFilter;
  String newPath = '';
  String newMoniker = '';
  String localFilter = '';
  final rectWidth = 900.0;
  final subWidth = 230.0;
  final rectHeight = 65.0;

  addNewChoice() {
    setState(() {
      if (pmNil(newPath))
        pmShowError(context, 'newPath is nil');
      else {
        model.addMoveFileItem(newPath, newMoniker);
      }
      newMoniker = '';
      newPath = '';
      getNewMoniker.reset('');
      getNewPath.reset('');
    });
  }

  groupCopy(int j) {
    model.groupCopy(localFilter, j);
    Navigator.pop(context);
  }

  filterDelete() {
    model.groupDelete(localFilter);
    Navigator.pop(context);
  }

  Widget makeMoveRow(int i) {
    deleteI() {
      model.moveDirectories.removeAt(i);
      model.notify();
    }

    return pmRow([
      pmRectangle(
        width: rectHeight,
        height: 30,
        borderRadius: 7.0,
        color: kMoveTargetsColor,
        child: pmText(model.moveDirectories[i].moniker),
      ),
      pmSpacerH(w: 5.0),
      pmRectangle(
        width: 400,
        height: 30,
        borderRadius: 7.0,
        color: kMoveTargetsColor,
        child: pmText(model.moveDirectories[i].newPath, s: kpmXS),
      ),
      pmSpacerH(w: 5.0),
      pmDelete(deleteI),
    ]);
  }

  newName(String nbn) {
    model.setNewBaseName(nbn);
  }

  newBase(String nbn) {
    p.logR('New base: $nbn, ${pmInteger(nbn)}', level: 1);
    if (pmInteger(nbn))
      model.setNewBaseNumber(int.parse(nbn));
    else
      pmShowDialogue(context, pmText('must be integer'));
  }

  rename() {
    model.rename();
    Navigator.pop(context);
  }

  resize(double factor) {
    resizeHold(BuildContext context, Function(double) progressCallback) async {
      p.logR('resizing to $factor');
      await model.resize(factor, progressCallback);
      Navigator.pushReplacementNamed(context, kListFiles);
    }

    Navigator.pushReplacementNamed(context, kGenericProgress, arguments: {
      kpmMessage: 'Resizing Files',
      kpmHoldingCheckFunction: resizeHold
    });
  }

  resize75() {
    resize(0.75);
  }

  resize50() {
    resize(0.5);
  }

  resize25() {
    resize(0.25);
  }

  setLocalFilter(String s) {
    setState(() {
      localFilter = s;
    });
  }

  setMoniker(String s) {
    if (s.length <= 4)
      setState(() {
        newMoniker = s;
      });
  }

  setNewPath(String s) {
    setState(() {
      newPath = s;
    });
  }

  @override
  void initState() {
    super.initState();
    getNewPath = PMTextInputWithReset(
      setNewPath,
      hintText: 'directory?',
    );
    getNewMoniker = PMTextInputWithReset(
      setMoniker,
      hintText: 'moniker?',
    );
    getFilter = PMTextInputWithReset(
      setLocalFilter,
      width: 300,
      textStyle: TextStyle(fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    model = Provider.of<Model>(context);
    if (pmNil(localFilter)) getFilter.reset(model.currentNameForFilter());

    return Scaffold(
      body: Center(
        child: pmColumn(mAlign: kpmCenter, xAlign: kpmCenter, [
          pmRow([
            pmRectangle(
              height: rectHeight,
              width: subWidth,
              child: pmRow([
                if (model.numToBeDeleted > 0)
                  PMFlashing(
                    child: PMRoundIconButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onPressed: model.deleteImages),
                  ),
                pmSpacerH(),
                if (model.numToBeMoved > 0)
                  PMFlashing(
                    child: PMRoundIconButton(
                        icon: MdiIcons.folderMove,
                        message: 'move flagged files',
                        color: Colors.red,
                        onPressed: model.moveFiles),
                  ),
                if (model.numToBeMoved > 0)
                  PMFlashing(
                    child: PMRoundIconButton(
                        icon: MdiIcons.folderMove,
                        message: 'copy flagged files',
                        color: Colors.orange,
                        onPressed: model.copyFiles),
                  ),
                pmSpacerH(w: 20),
                pmCircle(
                    color: Colors.blue,
                    width: 20,
                    height: 20,
                    child: pmText('25', c: kpmWhite, s: kpmXS),
                    onTap: resize25),
                pmCircle(
                    color: Colors.blue,
                    width: 30,
                    height: 30,
                    child: pmText('50', c: kpmWhite, s: kpmS),
                    onTap: resize50),
                pmCircle(
                    color: Colors.blue,
                    width: 40,
                    height: 40,
                    child: pmText('75', c: kpmWhite, s: kpmM),
                    onTap: resize75),
                pmSpacerH(),
              ]),
            ),
            pmSpacerH(),
            pmRectangle(
                width: rectWidth-subWidth,
                height: rectHeight,
                child: pmRow([
                  getFilter.textInput,
                  pmSpacerH(),
                  PMRoundIconButton(
                      icon: MdiIcons.deleteSweep,
                      message: 'filter delete',
                      color: Colors.blueGrey,
                      onPressed: filterDelete),
                ])),
          ]),
          pmSpacerV(),
          pmRectangle(
            width: rectWidth,
            height: rectHeight,
            child: pmRow([
              pmText('Rename?'),
              pmSpacerH(w: 5),
              PMTextInput(
                callback: newName,
                hintText: 'new name',
              ),
              pmSpacerH(),
              pmText('PXL names?', s: kpmXS),
              pmSpacerH(w: 5),
              Checkbox(
                  value: model.pxlNames,
                  onChanged: (bool? value) {
                    model.pxlToggle(value);
                  }),
              pmSpacerH(),
              PMTextInput(
                callback: newBase,
                hintText: 'start count',
              ),
              pmSpacerH(),
              if (pmNotNil(model.newBaseFileName))
                PMRoundIconButton(
                    color: Color(0XFFFFD54F),
                    icon: Icons.refresh,
                    onPressed: rename),
            ]),
          ),
          pmSpacerV(),
          pmRectangle(
            width: rectWidth,
            height: 400,
            child: pmColumn(mAlign: kpmCenter, xAlign: kpmCenter, [
              if (model.moveDirectories.length < 7)
                pmRow([
                  pmText('Add Move Path?'),
                  pmSpacerH(w: 5),
                  getNewPath.textInput,
                  pmSpacerH(w: 25),
                  getNewMoniker.textInput,
                  pmSpacerH(),
                  pmAdd(addNewChoice),
                ]),
              pmSpacerV(),
              if (model.moveDirectories.length > 0)
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: model.moveDirectories.length,
                    itemBuilder: (context, index) {
                      return makeMoveRow(index);
                    },
                  ),
                ),
            ]),
          ),
          pmSpacerV(),
          pmBack(() {
            Navigator.pop(context);
          }),
        ]),
      ),
    );
  }
}
