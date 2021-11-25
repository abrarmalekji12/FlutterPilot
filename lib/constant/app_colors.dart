import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  static bool _isOperator = true;
  static set operator(bool isOperator) {
    _isOperator = isOperator;
  }

  static const Color msgColor = Color(0xffF2F2F2);
  static const Color white = Colors.white;
  static const Color background = Color(0xFF74AAD8);
  // static const Color theme = Color(0xFFFB7A43);
  static Color get theme => _isOperator ? operatorTheme : customerTheme;
  static const Color titleTextFieldFocusColor = Color(0xff10A648);
  static Color get lightTheme => _isOperator
      ? operatorTheme.withOpacity(0.5)
      : customerTheme.withOpacity(0.5);
  static const Color errorColor = Color(0xffD5435A);
  static const Color customerTheme = Color(0xFFD5435A);
  static const Color operatorTheme = Color(0xff10A648);
  static const Color ffFF945E = Color(0xFFFF945E);
  static const Color ffB8B8B8 = Color(0xFFB8B8B8);
  static const Color ff333333 = Color(0xFF333333);
  static const Color ff808080 = Color(0xFF808080);
  static const Color ff514F4F = Color(0xFF514F4F);
  static const Color ff509bfb = Color(0xFF509bfb);
  static const Color yellowPending = Color(0xFFFFC632);
  static const Color green = Color(0xff079548);

  static const Color DADADA = Color(0xFFDADADA);
}
