import 'package:flutter/foundation.dart';

class AuthViewModel {
  String userName = '';
  String password = '';
  String confirmPassword = '';

  AuthViewModel() {
    if (kDebugMode) {
      userName = 'abrarmalekji1234@gmail.com';
      password = 'password';
    }
  }
}
