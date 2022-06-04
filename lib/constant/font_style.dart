import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: avoid_classes_with_only_static_members
class AppFontStyle {
  static TextStyle roboto(double fontSize,
      {Color color = Colors.black, FontWeight fontWeight = FontWeight.normal}) {
    return GoogleFonts.roboto(
      textStyle: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
