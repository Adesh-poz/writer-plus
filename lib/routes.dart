import 'package:flutter/widgets.dart';

import 'package:writer_plus/screens/app_info_page.dart';
import 'package:writer_plus/screens/home_page.dart';
import 'package:writer_plus/screens/text_editor.dart';

/// Defines all the named routes used throughout the project
Map<String, Widget Function(BuildContext)> routes = <String, WidgetBuilder>{
  '/home': (context) => const WriterPlusHomePage(),
  '/editor': (context) => const TextEditor(),
  '/info': (context) => const AppInfoPage(),
};
