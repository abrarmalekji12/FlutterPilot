import 'package:flutter/cupertino.dart';

import '../app_config.dart';

void logger(dynamic message) {
  if (appConfig.loggerEnable) {
    debugPrint(message);
  }
}
