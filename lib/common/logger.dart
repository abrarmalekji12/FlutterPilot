import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/app_config.dart';

void logger(dynamic message) {
  if (appConfig.loggerEnable) {
    debugPrint(message);
  }
}
