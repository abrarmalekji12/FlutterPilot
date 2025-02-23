import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../injector.dart';

// ignore: avoid_classes_with_only_static_members
class AppFontStyle {
  static TextStyle titleStyle() =>
      lato(16, color: theme.text1Color, fontWeight: FontWeight.w700);
  static TextStyle subtitleStyle() =>
      lato(14, color: theme.text1Color, fontWeight: FontWeight.w700);

  static TextStyle headerStyle() =>
      lato(20, fontWeight: FontWeight.w900, color: theme.text1Color);

  static TextStyle lato(double fontSize,
      {Color? color, FontWeight fontWeight = FontWeight.w900}) {
    return GoogleFonts.lato(
      textStyle: TextStyle(
        color: color ?? theme.text1Color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
