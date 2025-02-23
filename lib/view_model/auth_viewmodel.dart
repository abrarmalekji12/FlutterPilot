import 'package:flutter/foundation.dart';

import '../data/remote/firestore/firebase_bridge.dart';

class FVBUser {
  String email;
  String password;
  String confirmPassword = '';
  String? userId;

  FVBUser({this.email = '', this.password = '', this.userId}) {
    if (email.isEmpty && kDebugMode) {
      if (dbType == DBType.old) {
        email = 'test_fvb1@mailinator.com';
        password = 'password';
      } else if (dbType == DBType.latest1) {
        email = 'abrar_malekji@mailinator.com';
        password = 'password';
      }
    }
  }

  Map<String, dynamic> toJson({bool includePass = false}) => {
        'email': email,
        'userId': userId,
        if (includePass) 'password': password,
      };

  factory FVBUser.fromJson(data) => FVBUser(
        userId: data['userId'],
        email: data['email'] ?? data['username'],
        password: data['password'] ?? '',
      );
}
