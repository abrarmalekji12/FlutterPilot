import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'common_methods.dart';

class Sensitive {
  static run(String title, void Function() process,
      {void Function()? fallback}) {
    try {
      process.call();
    } catch (e) {
      if (e is Exception) {
        print('EXCEPTION :: $title :: ${e.toString()}');
      } else {
        print('ERROR :: $title :: ${e.toString()}');
      }
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        showToast('ERROR NOTICED :: $title ::${e.toString()}');
      });
      fallback?.call();
    }
  }
}
