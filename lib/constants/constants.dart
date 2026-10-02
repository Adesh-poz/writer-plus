import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class Constants {
  /// Primary Color of the App
  static const Color primaryColor = Color(0xFF4cc9f0);

  /// Text Styles

  // Heading TS
  static TextStyle headingTS = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  // Body TS
  static TextStyle bodyTS = GoogleFonts.roboto(
    fontSize: 13,
    fontWeight: FontWeight.w300,
  );

  /// App-wide TextTheme built using headingTS and bodyTS
  static TextTheme textTheme = TextTheme(
    displayLarge: headingTS.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: headingTS.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: headingTS.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
    headlineLarge: headingTS.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: headingTS.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: headingTS.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: headingTS.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
    titleMedium: headingTS.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
    titleSmall: headingTS.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: bodyTS.copyWith(fontSize: 15),
    bodyMedium: bodyTS.copyWith(fontSize: 13),
    bodySmall: bodyTS.copyWith(fontSize: 11),
    labelLarge: headingTS.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: bodyTS.copyWith(fontSize: 12),
    labelSmall: bodyTS.copyWith(fontSize: 10),
  );
}
