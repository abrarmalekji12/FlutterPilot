import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  static bool _isOperator = true;

  static const Color grey=Color(0xffd3d3d3);

  static const theme=Colors.blueAccent;
  static set operator(bool isOperator) {
    _isOperator = isOperator;
  }

  static const Color msgColor = Color(0xffF2F2F2);
  static const Color background = Color(0xFF74AAD8);
  // static const Color theme = Color(0xFFFB7A43);
  static const black=Color(0xff000000);
  static const white=Color(0xffffffff);

  static const Color DADADA = Color(0xFFDADADA);
}
