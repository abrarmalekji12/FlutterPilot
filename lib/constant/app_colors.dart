import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  static bool _isOperator = true;

  static const Color grey = Color(0xffd3d3d3);

  static const theme = Colors.blueAccent;
  static set operator(bool isOperator) {
    _isOperator = isOperator;
  }

  static const Color msgColor = Color(0xffF2F2F2);
  static const Color background = Color(0xFF74AAD8);
  // static const Color theme = Color(0xFFFB7A43);
  static const black = Color(0xff000000);
  static const white = Color(0xffffffff);

  static const Color DADADA = Color(0xFFDADADA);

  static const Color shimmerColor = Color(0xFFF2F2F2);
  // red color
  static const Color red = Color(0xFFF44336);

  //green color
  static const Color green = Color(0xFF4CAF50);

  //light grey
  static const Color lightGrey = Color(0xFFF2F2F2);
  //separator color
  static const Color separator = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF040E2F);

  // dark grey
  static const Color darkGrey2 = Color(0xFF0A0A0A);
}
