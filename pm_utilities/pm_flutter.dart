// revision: 2025-03-03, with NewDropdown, ScreenSize fixed, pmTextWidth added
// Null Safe
// General purpose routines for Flutter use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'pm_constants.dart';
import 'pm_dartUtils.dart';

//-------------------- GLOBAL CONSTANTS -------------------------------

// pmText constants

const kpmXXS = 'XXS';
const kpmXS = 'XS';
const kpmS = 'S';
const kpmM = 'M';
const kpmL = 'L';
const kpmXL = 'XL';
const kpmXXL = 'XXL';
const kFontInc = 4.0;
const kpmBaseFontSize = 14.0;
const kpmFontSizeTable = {
  kpmXXS: kpmBaseFontSize - kFontInc,
  kpmXS: kpmBaseFontSize,
  kpmS: kpmBaseFontSize + kFontInc,
  kpmM: kpmBaseFontSize + (kFontInc * 2),
  kpmL: kpmBaseFontSize + (kFontInc * 3),
  kpmXL: kpmBaseFontSize + (kFontInc * 4),
  kpmXXL: kpmBaseFontSize + (kFontInc * 5),
};
const kpmSFontSize = kpmBaseFontSize + kFontInc;
const kpmDefaultTextStyle =
    TextStyle(fontSize: kpmBaseFontSize + (kFontInc * 2));
const kDefaultDropdownTextStyle =
    TextStyle(fontSize: kpmBaseFontSize, color: Colors.black);

const kpmBlack = 'black';
const kpmBlue = 'blue';
const kpmGrey = 'gray';
const kpmRed = 'red';
const kpmGreen = 'green';
const kpmYellow = 'yellow';
const kpmWhite = 'white';
const kpmColorTable = {
  kpmBlack: Colors.black,
  kpmBlue: Colors.blue,
  kpmGrey: Colors.grey,
  kpmRed: Colors.red,
  kpmGreen: Colors.green,
  kpmYellow: Colors.yellow,
  kpmWhite: Colors.white
};
const kpmLineThrough = 'lineThrough';
const kpmUnderline = 'underline';
const kpmBold = 'bold';

// pmSpacer constants
const kpmVerticalDefault = 10.0;
const kpmHorizontalDefault = 10.0;

// button constants

const double kpmSmallRoundButtonSize = 16;
const double kpmMediumRoundButtonSize = 28;
const double kpmLargeRoundButtonSize = 45;
const kDefaultButtonColor = Colors.blueGrey;
const kpmDefaultBackgroundColor =
    Color(0xFFE3F2FD); // very light blue, blue[50]
const kpmErrorColor = Color(0XFFFFCDD2);
const kpmColorBack = Color(0xffed8a82);
const kpmColorSave = Colors.red;
const kpmColorCloud = Color(0x886603fc);
final kpmColorGrey0 = Color(0xFFede8e7);
const kpmColorGrey1 = Color(0xffd3d3d3);
const kpmColorGrey2 = Color(0xffaaaaaa);
const kpmColorAmber = Color(0XFFFFD54F);
const kpmColorLighterBlue = Color(0xFF84BEE8);
const kpmColorLightBlue = Color(0XFF29B6F6);
const kpmColorLightGreen = Color(0XFFA5D6A7);
const kpmColorLightPurple = Color(0XFFCE93D8);
const kpmColorDarkBlue = Color(0XFF0D47A1);
const kpmColorLightCyan = Color(0XFF80DEEA);
const kpmColorDarkCyan = Color(0XFF0097A7);
const kpmColorRose = Color(0Xfff5c4ba);

// Text decorations

const kpmTextStyleDefault = TextStyle(
  fontSize: 14.0,
  color: Colors.black,
);

const kpmInputDecoration = InputDecoration(
  hintText: 'enter a value',
  hintStyle: TextStyle(color: Colors.blue),
  filled: true,
  fillColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(16.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(16.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(16.0)),
  ),
);

const kpmInputDecorationSmall = InputDecoration(border: OutlineInputBorder());

//-------------------- WIDGETS ------------------------------

Widget pmAdd(Function() action, {Color? color, String? message, double? size}) {
  // returns 'add' button
  return PMRoundIconButton(
      size: size,
      message: message,
      icon: Icons.add,
      color: (color == null) ? kpmColorGrey1 : color,
      onPressed: action);
}

Widget pmBack(Function() action,
    {Color? color, String? message, double? size}) {
  // returns 'back' button
  return PMRoundIconButton(
      size: size,
      message: (message == null) ? 'go back' : message,
      icon: Icons.arrow_back,
      color: (color == null) ? kpmColorGrey1 : color,
      onPressed: action);
}

Widget pmSave(Function() action,
    {Color? color, String? message, double? size}) {
  // returns 'back' button
  return PMRoundIconButton(
      size: size,
      message: (message == null) ? 'save' : message,
      icon: Icons.save_rounded,
      color: (color == null) ? kpmColorGrey1 : color,
      onPressed: action);
}

Widget pmDelete(Function() action,
    {Color? color, String? message, double? size}) {
  // returns 'back' button
  return PMRoundIconButton(
      size: size,
      message: (message == null) ? 'delete' : message,
      icon: Icons.delete,
      color: (color == null) ? kpmColorGrey1 : color,
      onPressed: action);
}

Widget pmBoxAndDebit(Widget child, PMScreenSize screen, {double? h, w}) {
  return SizedBox(
    child: child,
    width: (w != null) ? screen.debitW(w) : null,
    height: (h != null) ? screen.debitH(h) : null,
  );
}

Widget pmButton(
    {required Widget child,
    Function()? onPressed,
    width = 100.0,
    Color backgroundColor = kpmDefaultBackgroundColor}) {
  return Container(
    width: width,
    child: OutlinedButton(
      child: child,
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
      ),
    ),
  );
}

List<DropdownMenuItem<dynamic>> pmBuildDropDownMenuList(list,
    {Function(dynamic)? xFormToText}) {
  // builds the menu list of items for a drop down,
  // takes as input a list of items, and an optional function
  // to transform the list items to strings

  if (pmNil(list)) return [];

  List<DropdownMenuItem<dynamic>> menuList = [];
  for (var item in list) {
    DropdownMenuItem<dynamic> d = DropdownMenuItem(
        value: item, child: (xFormToText != null) ? xFormToText(item) : item);
    menuList.add(d);
  }
  return menuList;
}

class PMDropDownButton extends StatelessWidget {
  // wraps flutter dropdown button, adding in
  // optional size and text style
  final Function action;
  final List<DropdownMenuItem<dynamic>> itemList;
  final TextStyle style;
  final double size;

  PMDropDownButton(
      {required this.action,
      required this.itemList,
      this.size = kpmMediumRoundButtonSize,
      this.style = kDefaultDropdownTextStyle});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<dynamic>(
      //value: null,
      icon: Icon(Icons.arrow_drop_down_circle),
      iconSize: size,
      elevation: 16,
      style: style,
      onChanged: (dynamic newValue) {
        action(newValue);
      },
      items: itemList,
    );
  }
}

Widget pmCenteredRow(Widget item) {
  return pmRow([
    SizedBox(),
    item,
    SizedBox(),
  ], mAlign: kpmCenter);
}

class PMCheckBox extends StatefulWidget {
  final Function change;
  final bool checked;

  PMCheckBox({required this.change, this.checked = false});

  @override
  State<PMCheckBox> createState() => _PMCheckBoxState();
}

class _PMCheckBoxState extends State<PMCheckBox> {
  bool? isChecked;

  @override
  void initState() {
    isChecked = widget.checked;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Color getColor(Set<WidgetState> states) {
      const Set<WidgetState> interactiveStates = <WidgetState>{
        WidgetState.pressed,
        WidgetState.hovered,
        WidgetState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue;
      }
      return Colors.red;
    }

    return Checkbox(
      checkColor: Colors.white,
      fillColor: WidgetStateProperty.resolveWith(getColor),
      value: isChecked,
      onChanged: (bool? value) {
        setState(() {
          isChecked = value!;
          widget.change(value);
        });
      },
    );
  }
}

pmCircle<Widget>(
    {child,
    Color color = Colors.black,
    borderColor,
    borderRadius,
    double height = 25.0,
    double width = 25.0,
    double opacity = 1.0,
    Function()? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      child: Center(child: child),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 50),
        shape: BoxShape.circle,
        border: (borderColor == null)
            ? null
            : Border.all(
                color: borderColor,
              ),
        borderRadius: (borderRadius == null)
            ? null
            : BorderRadius.all(Radius.circular(20)),
      ),
      height: height,
      width: width,
    ),
  );
}

Widget pmColumn(List<Widget> items, {xAlign, mAlign}) {
  // wraps flutter column for simpler syntax
  var alignX = CrossAxisAlignment.center;
  switch (xAlign) {
    case kpmStart:
      alignX = CrossAxisAlignment.start;
      break;
    case kpmEnd:
      alignX = CrossAxisAlignment.end;
      break;
    case kpmCenter:
      alignX = CrossAxisAlignment.center;
      break;
    default:
  }
  var alignM = MainAxisAlignment.start;
  switch (mAlign) {
    case kpmStart:
      alignM = MainAxisAlignment.start;
      break;
    case kpmEnd:
      alignM = MainAxisAlignment.end;
      break;
    case kpmCenter:
      alignM = MainAxisAlignment.center;
      break;
    default:
  }
  return Column(
    children: items,
    crossAxisAlignment: alignX,
    mainAxisAlignment: alignM,
  );
}

class PMFlashing extends StatefulWidget {
  // flashes a widget on and off
  final Widget child;

  PMFlashing({required this.child});

  @override
  _PMFlashingState createState() => _PMFlashingState();
}

class _PMFlashingState extends State<PMFlashing>
    with SingleTickerProviderStateMixin {
  var _animationController;

  @override
  void initState() {
    _animationController =
        new AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationController.repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child:
          widget.child, // widget.child refers to parameter fed into root class
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

Widget pmGenericHold(Map args, BuildContext context) {
  if (args[kpmRouteSaveFunction] != null)
    args[kpmRouteSaveFunction](context, args[kpmRoute]);
  if (args[kpmHoldingCheckFunction] != null)
    scheduleMicrotask(() {
      args[kpmHoldingCheckFunction](context);
    });
  Widget spinner = (args[kpmSpinner] != null)
      ? args[kpmSpinner]
      : SpinKitFadingCircle(
          itemBuilder: (BuildContext context, int index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            );
          },
        );

  //p.logF('building GenericHold');
  return Scaffold(
    backgroundColor: Colors.blue[900],
    body: Center(
      child: pmColumn(
        [
          if (pmNotNil(args[kpmMessage]))
            pmText(args[kpmMessage], c: kpmRed, s: kpmXL, d: [kpmBold]),
          SizedBox(height: 50),
          spinner,
        ],
        xAlign: kpmCenter,
        mAlign: kpmCenter,
      ),
    ),
  );
}

class PMGenericHoldScreen extends StatelessWidget {
  const PMGenericHoldScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late var args;
    args = ModalRoute.of(context)!.settings.arguments;
    return pmGenericHold(args, context);
  }
}

class PMGPScreen extends StatefulWidget {
  const PMGPScreen({super.key});

  @override
  State<PMGPScreen> createState() => _PMGPScreenState();
}

class _PMGPScreenState extends State<PMGPScreen> {
  @override
  Widget build(BuildContext context) {
    late var args;
    args = ModalRoute.of(context)!.settings.arguments;
    return PMGenericProgress(args);
  }
}

class PMGenericProgressScreen extends StatefulWidget {
  const PMGenericProgressScreen({super.key});

  @override
  State<PMGenericProgressScreen> createState() =>
      _PMGenericProgressScreenState();
}

class _PMGenericProgressScreenState extends State<PMGenericProgressScreen> {
  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments;
    return PMGenericProgress(args);
  }
}

class PMGenericProgress extends StatefulWidget {
  final args;

  const PMGenericProgress(this.args);

  @override
  State<PMGenericProgress> createState() => _PMGenericProgressState();
}

class _PMGenericProgressState extends State<PMGenericProgress> {
  final PMR p = PMR(className: 'PMProgressScreen', defaultLevel: 0);
  bool? firstBuild;

  @override
  void initState() {
    firstBuild = true;
    super.initState();
  }

  double progress = 0.0;

  progressCallback(double value) {
    setState(() {
      progress = value;
    });
  }

  callHolding(BuildContext context, args) {
    if (firstBuild!) {
      setState(() {
        firstBuild = false;
      });
      if (args[kpmHoldingCheckFunction] != null)
        args[kpmHoldingCheckFunction](context, progressCallback);
      // above function should do its thing,
      // and then replace the screen when done by doing a pushReplacementRoute.
      // progress Callback should be called to update progress
      //p.logF('Holding Check called');
    }
  }

  @override
  Widget build(BuildContext context) {
    //p.logF('PROGRESS SCREEN INVOKED');
    Map args = widget.args;
    callHolding(context, args);

    //p.logF('Returning Scaffold');
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: pmColumn(
          [
            if (pmNotNil(args[kpmMessage]))
              pmText(args[kpmMessage], c: kpmRed, s: kpmXL, d: [kpmBold]),
            SizedBox(height: 50),
            CircularPercentIndicator(
              percent: progress,
              radius: 120.0,
              lineWidth: 30.0,
              progressColor: Colors.green,
              backgroundColor: Colors.white,
              center:
                  pmText('${(progress * 100).floor()}%', c: kpmWhite, s: kpmL),
            )
          ],
          mAlign: kpmCenter,
          xAlign: kpmCenter,
        ),
      ),
    );
  }
}

/*
class PMIconLabel extends StatelessWidget {
  // provides an icon with a label
  PMIconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          icon,
          size: 80.0,
        ),
        pmSpacerV(),
        pmText(label, s: kpmM),
      ],
    );
  }
} // end IconContent
*/

List<List<String>> pmListKVPairs(Map map) {
  List<List<String>> kvPairs = [];
  List keys = map.keys.toList();
  for (var key in keys) {
    kvPairs.add([key.toString(), map[key].toString()]);
  }
  return kvPairs;
}

class PMMajorButton extends StatelessWidget {
  // provides a large button that contains a child and responds with
  // an action, everything optional
  final Color buttonColor;
  final Function() buttonAction;
  final Widget? buttonChild;
  final double height;
  final double width;

  PMMajorButton(
      {this.buttonColor = Colors.orange,
      required this.buttonAction,
      this.buttonChild,
      this.height = 40,
      this.width = 150});

  final double minWidth = 50;

  @override
  Widget build(BuildContext context) {
    double boxWidth = width < minWidth ? minWidth : width;
    return SizedBox(
      width: boxWidth,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Material(
          elevation: 5.0,
          color: buttonColor,
          borderRadius: BorderRadius.circular(30.0),
          child: MaterialButton(
              onPressed: buttonAction,
              minWidth: minWidth,
              height: height,
              child: buttonChild),
        ),
      ),
    );
  }
} // end MajorButton

pmNavigatorPush(BuildContext context, Widget newWidget) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return newWidget;
      },
    ),
  );
}

Widget pmRectangle(
    {Widget? child,
    Color color = Colors.white,
    Color borderColor = Colors.black,
    double opacity = 1.0,
    double width = 100.0,
    double height = 100.0,
    Border? border,
    double? borderRadius,
    Function()? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      child: child,
      alignment: Alignment(0.0, 0.0),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.rectangle,
        borderRadius: borderRadius == null
            ? null
            : BorderRadius.all(Radius.circular(borderRadius)),
        border: border == null
            ? Border.all(
                color: borderColor,
              )
            : border,
      ),
      height: height,
      width: width,
    ),
  );
}

class PMRoundIconButton extends StatelessWidget {
  // defaults for size and color
  final IconData icon;
  final Function() onPressed;
  final double? size;
  final Color color;
  final String? message;

  PMRoundIconButton(
      {required this.icon,
      required this.onPressed,
      this.message,
      this.size,
      this.color = kpmColorGrey1});

  @override
  Widget build(BuildContext context) {
    String? m = message == null ? '' : message;
    double sz = (size == null) ? kpmMediumRoundButtonSize : size!;
    return Tooltip(
        message: m,
        child: RawMaterialButton(
          elevation: 0.0,
          child: Icon(icon, size: size),
          onPressed: onPressed,
          constraints: BoxConstraints.tightFor(
            width: sz + 10,
            height: sz + 10,
          ),
          shape: CircleBorder(),
          fillColor: color,
        ));
  }
}

class PMRoundIconButtonLabelled extends StatelessWidget {
  // defaults for size and color
  final IconData icon;
  final Function() onPressed;
  final double? size;
  final Color color;
  final String? message;
  final Widget label;

  PMRoundIconButtonLabelled(
      {required this.icon,
      required this.onPressed,
      required this.label,
      this.message,
      this.size,
      this.color = kpmColorGrey1});

  @override
  Widget build(BuildContext context) {
    return pmColumn([
      label,
      PMRoundIconButton(
          icon: icon,
          onPressed: onPressed,
          size: size,
          color: color,
          message: message)
    ]);
  }
}

Widget pmRow(List<Widget> items, {xAlign, mAlign}) {
  // wraps flutter column for simpler syntax
  var alignX = CrossAxisAlignment.center;
  switch (xAlign) {
    case kpmStart:
      alignX = CrossAxisAlignment.start;
      break;
    case kpmEnd:
      alignX = CrossAxisAlignment.end;
      break;
    case kpmCenter:
      alignX = CrossAxisAlignment.center;
      break;
    default:
  }
  var alignM = MainAxisAlignment.center;
  switch (mAlign) {
    case kpmStart:
      alignM = MainAxisAlignment.start;
      break;
    case kpmEnd:
      alignM = MainAxisAlignment.end;
      break;
    case kpmCenter:
      alignM = MainAxisAlignment.center;
      break;
    default:
  }
  return Row(
    children: items,
    crossAxisAlignment: alignX,
    mainAxisAlignment: alignM,
  );
} // end pmRow


class PMScreenSize {
  late double width, height;
  late double heightSafe;
  late double remainingH, remainingW;

  PMScreenSize(BuildContext context, {width, height}) {
    // Full screen width and height
    if (width == null) width = MediaQuery.of(context).size.width;
    if (height == null) {
      height = MediaQuery.of(context).size.height;
      var padding = MediaQuery.of(context).padding;
      this.heightSafe = height! - padding.top - padding.bottom;
    } else
      heightSafe = height!;
    this.width = width!;
    this.height = height!;

    remainingH = heightSafe;
    remainingW = width!;
  }

  double debitH(double d) {
    remainingH = remainingH - d;
    return d;
  }

  double debitW(double d) {
    remainingW = remainingW - d;
    return d;
  }
}


/*
class PMSizedCard extends StatelessWidget {
  // rectangular display with optional child and action,
  // height, width, color required
  final Color cardColor;
  final double cardHeight;
  final double cardWidth;
  final Function()? cardAction;
  final Widget? cardChild;

  PMSizedCard({
    required this.cardColor,
    required this.cardHeight,
    required this.cardWidth,
    this.cardAction,
    this.cardChild,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: cardAction,
      child: Container(
        child: cardChild,
        height: cardHeight,
        width: cardWidth,
        margin: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
} // end Sized Card
*/

Future pmShowTopSheet(
    {required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    Color? color}) {
  // displays a child in a sheet that fills the top of the screen
  // use Navigator.pop to release
  PMR p = PMR(className: 'TopSheet', defaultLevel: 0);
  p.logR('Top Sheet invoked');
  return showGeneralDialog(
      //useRootNavigator: false,
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation animation,
          Animation secondaryAnimation) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: Container(
                decoration: BoxDecoration(
                  color: color == null ? Colors.grey : color,
                  borderRadius: BorderRadius.circular(
                      20.0), // Set the radius for the corners
                ),
                width:
                    (width == null) ? MediaQuery.of(context).size.width : width,
                height: (height == null)
                    ? MediaQuery.of(context).size.height - 50
                    : height,
                child: child),
          ),
        );
      });
} // end ShowTopSheet

pmShowError(BuildContext context, String msg, {fatal = false}) {
  // displays an error message and then goes away when OK pressed if not fatal
  pmShowTopSheet(
    context: context,
    color: Colors.red,
    width: 600,
    height: 110,
    child: pmColumn(
      [
        pmText(msg, s: kpmXL),
        pmSpacerV(),
        if (!fatal)
          pmBack(() {
            Navigator.pop(context);
          }),
      ],
    ),
  );
}

pmShowAlert(BuildContext context, Widget child, {title = ''}) {
  // shows dialogue box that goes away when OK pressed
  // set up the button

  Widget okButton = OutlinedButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: pmText(title),
    content: child,
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

pmShowDialogue(BuildContext context, Widget child) {
  // shows dialogue box that goes away when OK pressed
  // set up the button

  exit() {
    Navigator.pop(context);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return pmColumn([
        child,
        pmSpacerV(),
        pmBack(exit, color: Colors.white),
      ]);
    },
  );
}

Widget pmSpacerV({double h = kpmVerticalDefault}) {
  return SizedBox(height: h);
}

Widget pmSpacerH({double w = kpmHorizontalDefault}) {
  return SizedBox(width: w);
}

class PMSpinner extends StatelessWidget {
  // provides a circle that flips over and over
  final String? msg;
  final Color color;
  final double size;

  PMSpinner({this.msg, this.color = Colors.red, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        pmText(msg == null ? 'Please Wait' : msg, c: kpmBlack, s: kpmXL),
        SizedBox(height: 50),
        SpinKitRotatingCircle(
          color: color,
          size: size,
        )
      ],
    );
  }
}

pmWaitFor(
    {required BuildContext context,
    required Widget child,
    required Function waitFor}) {
  // provides a child widget which will go away when waitFor completes, see below
  start() {
    // the waitFor function that is passed in as a parameter must
    // execute a Navigator.of(context).pop() call to release the dialogue
    waitFor(context);
    return child;
  }

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return start();
    },
  );
}

//________________________________________________________________________

// TEXT Functions

Widget pmText(text, {String s = kpmM, String c = kpmBlack, List<String>? d}) {
  // s = size, c = color, d = decoration List
  // wraps TEXT for easier use, see constant definitions above for
  // optional size, color, directive constants

  //final PMR p = PMR(className: 'pmText', defaultLevel: 1);

  double? fontSize;
  var color;
  var weight = FontWeight.normal;
  var style = FontStyle.normal;
  var decoration = TextDecoration.none;

  if (pmNotNil(s)) fontSize = kpmFontSizeTable[s];
  if (fontSize == null) fontSize = kpmFontSizeTable[kpmM];

  if (pmNotNil(c)) color = kpmColorTable[c];
  if (color == null) color = kpmColorTable[kpmBlack];

  if (d != null)
    for (String direct in d)
      switch (direct) {
        case kpmLineThrough:
          decoration = TextDecoration.lineThrough;
          break;
        case kpmUnderline:
          decoration = TextDecoration.underline;
          break;
        case kpmBold:
          weight = FontWeight.bold;
      }

  return Text(
    text.toString(),
    style: TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      fontStyle: style,
      decoration: decoration,
    ),
  );
}

double pmTextWidth(text, {String s = kpmM, String c = kpmBlack, List<String>? d}) {
  // s = size, c = color, d = decoration List
  // wraps TEXT for easier use, see constant definitions above for
  // optional size, color, directive constants

  //final PMR p = PMR(className: 'pmText', defaultLevel: 1);

  double? fontSize;
  var color;
  var weight = FontWeight.normal;
  var style = FontStyle.normal;
  var decoration = TextDecoration.none;

  if (pmNotNil(s)) fontSize = kpmFontSizeTable[s];
  if (fontSize == null) fontSize = kpmFontSizeTable[kpmM];

  if (pmNotNil(c)) color = kpmColorTable[c];
  if (color == null) color = kpmColorTable[kpmBlack];

  if (d != null)
    for (String direct in d)
      switch (direct) {
        case kpmLineThrough:
          decoration = TextDecoration.lineThrough;
          break;
        case kpmUnderline:
          decoration = TextDecoration.underline;
          break;
        case kpmBold:
          weight = FontWeight.bold;
      }

  final TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: text.toString(),
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        decoration: decoration,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  //textPainter.layout(maxWidth: maxWidth); // Layout the text with a maximum width
  textPainter.layout();
  return textPainter.width;
}

Widget pmMultiLineText(List textItems,
    {String s = '', String c = '', List<String>? d}) {
  List<Widget> pmTexts = [];
  for (String t in textItems) pmTexts.add(pmText(t, s: s, c: c, d: d));
  return pmColumn(pmTexts);
}

class PMTextInput extends StatelessWidget {
  final Function(String)? callback;
  final InputDecoration? decoration;
  final String? initialText;
  final String? hintText;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Color? fillColor;
  final Widget? label;
  final TextAlign textAlign;

  PMTextInput({
    this.callback,
    this.decoration,
    this.textStyle,
    this.initialText,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.multiline,
    this.width,
    this.height,
    this.obscureText = false,
    this.maxLines,
    this.fillColor,
    this.label,
    this.textAlign = TextAlign.left,
  });

  final PMR p = PMR(className: 'PMTextInput', defaultLevel: 0);

  @override
  Widget build(BuildContext context) {
    //if (pmNotNil(initialText)) p.logR('building TextInput with: $initialText');
    InputDecoration? inputDec =
        decoration == null ? kpmInputDecoration : decoration;
    if (hintText != null) inputDec = inputDec?.copyWith(hintText: hintText);
    if (fillColor != null)
      inputDec = inputDec?.copyWith(fillColor: fillColor, filled: true);

    return pmRow([
      if (label != null) label!,
      SizedBox(
        width: width == null ? 200.0 : width,
        height: height == null ? 40 : height,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: TextFormField(
              controller: controller,
              initialValue: initialText,
              style: textStyle == null ? kpmDefaultTextStyle : textStyle,
              decoration: inputDec,
              keyboardType: keyboardType,
              onChanged: callback,
              obscureText: obscureText,
              textAlign: textAlign,
              maxLines: obscureText ? 1 : maxLines),
        ),
      ),
    ]);
  }
}

class PMTextInputWithReset {
  Function callback;
  late TextEditingController localController;
  final InputDecoration? decoration;
  final String? initialText;
  final String? hintText;
  final TextStyle? textStyle;
  final double? width;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Color? fillColor;
  final Widget? label;
  late Widget textInput;
  String value = '';
  Function()? resetFunction;

  PMTextInputWithReset(this.callback,
      {this.decoration,
      this.textStyle,
      this.initialText,
      this.hintText,
      this.keyboardType = TextInputType.multiline,
      this.width,
      this.obscureText = false,
      this.maxLines,
      this.fillColor,
      this.label,
      this.resetFunction}) {
    localController = TextEditingController();
    localController.addListener(() {
      value = localController.text;
      //p.logF('cText: $value');
      callback(value);
    });
    textInput = pmRow([
      PMTextInput(
          controller: localController,
          label: label,
          decoration: decoration,
          textStyle: textStyle,
          initialText: initialText,
          hintText: hintText,
          keyboardType: keyboardType,
          width: width,
          obscureText: obscureText,
          maxLines: maxLines),
      if (resetFunction != null)
        PMRoundIconButton(
            message: 'reset text field',
            size: 15,
            icon: Icons.arrow_left,
            color: Colors.lightBlue,
            onPressed: () {
              clear();
              resetFunction!();
            }),
    ]);
  }

  clear() {
    reset('');
  }

  reset(String s) {
    //p.logF('resetting controller: "$s"');
    int pos = 0;
    if (pmNil(s)) {
      localController.clear();
    } else {
      localController.text = s;
      pos = s.length;
    }
    localController.selection =
        TextSelection.fromPosition(TextPosition(offset: pos));
  }

  String currentValue() {
    return localController.text;
  }
}

class PMTextInputButton extends StatelessWidget {
  // Text Input Field with "done" button
  final Function(String) callback;
  final InputDecoration? decoration;
  final String? initialText;
  final String? hintText;
  final TextStyle? textStyle;
  final double width;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLines;
  final double buttonSize;
  final Color buttonColor;
  final IconData icon;
  final Widget? label;

  PMTextInputButton({
    this.label,
    required this.callback,
    this.decoration,
    this.textStyle,
    this.initialText = '',
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.multiline,
    this.width = 200,
    this.obscureText = false,
    this.maxLines,
    this.buttonSize = kpmMediumRoundButtonSize,
    this.buttonColor = Colors.orange,
    this.icon = Icons.check_box,
  });

  @override
  Widget build(BuildContext context) {
    String lastVal = '';

    setText(String text) {
      lastVal = text;
    }

    passText() {
      callback(lastVal);
    }

    return pmRow(
      [
        PMTextInput(
            label: label,
            callback: setText,
            decoration: decoration,
            textStyle: textStyle,
            initialText: initialText,
            hintText: hintText,
            controller: controller,
            keyboardType: keyboardType,
            width: width,
            obscureText: obscureText,
            maxLines: maxLines),
        PMRoundIconButton(
          icon: icon,
          color: buttonColor,
          size: buttonSize,
          onPressed: passText,
        ),
      ],
    );
  }
}

class PMTextInputWithDropdown extends StatefulWidget {
// this widget presents a text field and a dropdown menu. Text can be selected either from
// the drop down, or by directly entering it into the text field (for new text).
// Optional functions are passed in in a map:
// possible values are kpmDropdownCallback, kpmTextCheck, kpmTextCallback, kpmXFormToS
  final List<DropdownMenuItem<dynamic>>
      itemList; // required! The menu items (must be separately built)
  final Map functions; // required, will hold the three optional functions
  final String? hintText; // text
  final InputDecoration? decoration; // to apply to text field
  final TextStyle? textStyle;
  final String? initialTextVal;
  final String? label; // optional label
  final double? width;
  final double? height;

  PMTextInputWithDropdown(
      {required this.itemList,
      required this.functions,
      this.decoration,
      this.textStyle,
      this.hintText = '',
      this.initialTextVal = '',
      this.label = '',
      this.width,
      this.height});

  @override
  _PMTextInputWithDropdownState createState() =>
      _PMTextInputWithDropdownState();
}

class _PMTextInputWithDropdownState extends State<PMTextInputWithDropdown> {
  var textController;

  var p = PMR(className: "PMTextInputWithDropdown", defaultLevel: 0);

  var result;
  String? lastDropDownText;
  String? lastTextText;
  bool dropDown = false;
  var buildContext;

  textCallback() {
    String text = textController.text;

    // was the callback the result of the dropdown menu? If so, ignore it.
    if (text != lastDropDownText) {
      // do we have a function to check the new text?
      if (widget.functions[kpmTextCheck] == null) {
        result = text;
      } else
      // yes, check it
      if (widget.functions[kpmTextCheck](text, buildContext)) {
        // OK
        result = text;
        lastTextText = text;
      }
      // not OK, restore it to last valid value
      else
        textController.text = lastTextText;
    }
  }

  dropdownCallback(value) {
    setState(() {
      lastDropDownText = (widget.functions[kpmXFormToS] != null
          ? widget.functions[kpmXFormToS]!(value)
          : value);
      textController = TextEditingController.fromValue(
        TextEditingValue(text: lastDropDownText!),
      );
      textController.addListener(textCallback);
      result = value;
      dropDown = true;
      if (widget.functions[kpmDropdownCallback] != null)
        widget.functions[kpmDropdownCallback](result);
    });
  }

  showCallback() {
    if (widget.functions[kpmTextCallback] != null)
      widget.functions[kpmTextCallback](result);
  }

  @override
  Widget build(BuildContext context) {
    p.logR('building with $dropDown : ${widget.initialTextVal}');

    setState(() {
      buildContext = context;
      if (dropDown)
        dropDown = false;
      else {
        textController = TextEditingController.fromValue(
            widget.initialTextVal == null
                ? null
                : TextEditingValue(text: widget.initialTextVal!));
        textController.addListener(textCallback);
      }
    });

    double height =
        (widget.height == null) ? kpmMediumRoundButtonSize : widget.height!;
    double width = ((widget.width == null) ? 200 : widget.width!) + height + 25;

    return Container(
        width: width,
        child: pmRow(
          [
            if (pmNotNil(widget.label))
              pmText(widget.label, s: kpmM, c: kpmBlack),
            PMTextInput(
              controller: textController,
              textStyle: widget.textStyle,
              decoration: widget.decoration,
              hintText: widget.hintText,
              width: widget.width,
              height: height,
            ),
            PMDropDownButton(
              itemList: widget.itemList,
              action: dropdownCallback,
              size: height,
            ),
            if (widget.functions[kpmTextCallback] != null)
              PMRoundIconButton(
                icon: Icons.add,
                size: height,
                onPressed: showCallback,
              ),
          ],
          mAlign: kpmStart,
        ));
  }
}

// __________________________________________________________________________
// new dropdowns

class PMNewDropdownMenu extends StatelessWidget {
  final List items;
  final Function action;

  PMNewDropdownMenu({required this.items, required this.action});

  @override
  Widget build(BuildContext context) {
    List<String> menu = [];

    for (var item in items) {
      menu.add(item.toString());
    }

    Widget makeRow(index) {
      invokeAction() {
        //p.logF('index $index tapped');
        action(index);
        Navigator.pop(context);
      }

      return ListTile(
        title: pmText(menu[index], s: kpmS),
        onTap: invokeAction,
      );
    }

    return ListView.builder(
      itemCount: menu.length,
      itemBuilder: (context, index) {
        return makeRow(index);
      },
    );
  }
}

Widget pmNewDropDown({
  required BuildContext context,
  required List items,
  required Function action,
  IconData? iconData,
  double? width,
  double? height,
  String? label,
  Color? color,
}) {
  showMenu() {
    pmShowTopSheet(
      context: context,
      height: (height == null) ? 400 : height,
      width: (width == null) ? 300 : width,
      color: color == null ? Colors.lightBlueAccent : color,
      child: PMNewDropdownMenu(items: items, action: action),
    );
  }

  return pmRow(
    [
      if (label != null) pmText(label, s: kpmM),
      PMRoundIconButton(
        icon: iconData == null ? Icons.arrow_drop_down : iconData,
        size: 30,
        onPressed: showMenu,
      ),
    ],
  );
}

class PMNewTextInputWithDropdown extends StatefulWidget {
// this widget presents a text field and a dropdown menu. Text can be selected either from
// the drop down, or by directly entering it into the text field (for new text).
// Optional functions are passed in in a map:
// possible values are kpmDropdownCallback, kpmTextCheck, kpmTextCallback, kpmXFormToS
  final List itemList; // required! But can be any type that can .toString()
  final Map functions; // required, will hold the three optional functions
  final String? hintText; // text
  final InputDecoration? decoration; // to apply to text field
  final TextStyle? textStyle;
  final String? initialTextVal;
  final String? label; // optional label
  final double? width;
  final double? height;
  final Color? color;

  PMNewTextInputWithDropdown(
      {required this.itemList,
      required this.functions,
      this.decoration,
      this.textStyle,
      this.hintText = '',
      this.initialTextVal = '',
      this.label = '',
      this.width,
      this.height,
      this.color});

  @override
  _PMNewTextInputWithDropdownState createState() =>
      _PMNewTextInputWithDropdownState();
}

class _PMNewTextInputWithDropdownState
    extends State<PMNewTextInputWithDropdown> {
  var textController;

  var p = PMR(className: "PMNewTextInputWithDropdown", defaultLevel: 0);

  var result;
  String? lastDropDownText;
  String? lastTextText;
  bool dropDown = false;
  var buildContext;

  textCallback() {
    String text = textController.text;

    // was the callback the result of the dropdown menu? If so, ignore it.
    if (text != lastDropDownText) {
      // do we have a function to check the new text?
      if (widget.functions[kpmTextCheck] == null) {
        result = text;
      } else
      // yes, check it
      if (widget.functions[kpmTextCheck](text, buildContext)) {
        // OK
        result = text;
        lastTextText = text;
      }
      // not OK, restore it to last valid value
      else
        textController.text = lastTextText;
    }
  }

  dropdownCallback(index) {
    String value = widget.itemList[index];
    setState(() {
      lastDropDownText = (widget.functions[kpmXFormToS] != null
          ? widget.functions[kpmXFormToS]!(value)
          : value);
      textController = TextEditingController.fromValue(
        TextEditingValue(text: lastDropDownText!),
      );
      textController.addListener(textCallback);
      result = value;
      dropDown = true;
      if (widget.functions[kpmDropdownCallback] != null)
        widget.functions[kpmDropdownCallback](result);
    });
  }

  showCallback() {
    if (widget.functions[kpmTextCallback] != null)
      widget.functions[kpmTextCallback](result);
  }

  @override
  Widget build(BuildContext context) {
    p.logR('building with $dropDown : ${widget.initialTextVal}');

    setState(() {
      buildContext = context;
      if (dropDown)
        dropDown = false;
      else {
        textController = TextEditingController.fromValue(
            widget.initialTextVal == null
                ? null
                : TextEditingValue(text: widget.initialTextVal!));
        textController.addListener(textCallback);
      }
    });

    double height =
        (widget.height == null) ? kpmMediumRoundButtonSize : widget.height!;
    double width = ((widget.width == null) ? 200 : widget.width!) + 70;

    return pmRow(
      [
        if (pmNotNil(widget.label)) pmText(widget.label, s: kpmM, c: kpmBlack),
        if (pmNotNil(widget.label)) pmSpacerH(w: 5),
        PMTextInput(
          controller: textController,
          textStyle: widget.textStyle,
          decoration: widget.decoration,
          hintText: widget.hintText,
          width: widget.width,
          height: height,
        ),
        pmNewDropDown(
          context: context,
          items: widget.itemList,
          action: dropdownCallback,
          width: width,
          color: widget.color,
        ),
        if (widget.functions[kpmTextCallback] != null)
          PMRoundIconButton(
            icon: Icons.add,
            size: height,
            onPressed: showCallback,
          ),
      ],
      mAlign: kpmStart,
    );
  }
}
