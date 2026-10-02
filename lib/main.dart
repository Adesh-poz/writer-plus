import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:writer_plus/constants/constants.dart';
import 'package:writer_plus/routes.dart';

/// ----------------------------------------------------------------------------
/// Writer Plus
/// Version: 1.0.0
///
/// Author: Adesh (POZ)
/// Created: September 2026
/// ----------------------------------------------------------------------------

void main() {
  runApp(const WriterPlusApp());
}

class WriterPlusApp extends StatelessWidget {
  const WriterPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Writer Plus',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: .fromSeed(
          seedColor: Constants.primaryColor,
          primary: Constants.primaryColor,
          brightness: Brightness.dark,
        ),
        textTheme: Constants.textTheme,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      initialRoute: '/home',
      routes: routes,
    );
  }
}
