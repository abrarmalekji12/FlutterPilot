import 'package:flutter/foundation.dart';

class AuthViewModel {
  String userName = '';
  String password = '';
  String confirmPassword = '';
  int? userId;

  AuthViewModel() {
    if (kDebugMode) {
      userName = 'abrarmalekji12@gmail.com';
      password = 'password';
    }
  }
}
