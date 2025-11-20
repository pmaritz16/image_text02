import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:image_text02/pm_utilities/pm_flutter.dart';
import 'package:image_text02/pm_utilities/pm_dartUtils.dart';

import 'package:image_text02/routines/model.dart';
import 'package:image_text02/routines/preview_image_screen.dart';
import 'package:image_text02/routines/edit_image_screen.dart';
import 'package:image_text02/routines/display_image_screen.dart';
import 'package:image_text02/routines/list_files_screen.dart';
import 'package:image_text02/routines/app_common.dart';

void main() {
  runApp(Root());
}

class Root extends StatefulWidget {
  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  final PMR p = PMR(className: 'ROOT', defaultLevel: 0);

  @override
  Widget build(BuildContext context) {
    p.logR('Building Root');
    return ChangeNotifierProvider(
      create: (context) => Model(), // Model instance must go closest to root
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => ListFilesScreen(),
          kEditImage: (context) => EditImageScreen(),
          kDisplayImage: (context) => DisplayImageScreen(),
          kPreviewImage: (context) => PreviewImageScreen(),
          kGenericHold: (context) => PMGenericHoldScreen(),
          kGenericProgress: (context) => PMGenericProgressScreen(),
          kListFiles: (context) => ListFilesScreen(),
        },
      ),
    );
  }
}
