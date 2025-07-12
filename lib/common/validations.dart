import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/constants/processor_constant.dart';
import 'package:get/get.dart';

import '../injector.dart';

final RegExp _alphaNumericNoStartDigitRegex = RegExp(r'^(?!^\d)[a-zA-Z0-9]+$');

class Validations {
  static String? Function(String?) nonEmpty(String name) {
    return (value) {
      if (value?.isEmpty ?? true) {
        return 'Please enter __name__'.replaceAll('__name__', name);
      }
      return null;
    };
  }

  static FormFieldValidator commonNameValidator() => (value) {
        if (value.isEmpty) {
          return 'Please enter valid name.';
        }
        if (value.length <= 3) {
          return 'Name should be more than 3 characters.';
        }

        if (value.length > 25) {
          return 'Name should be less than 25 characters.';
        }
        if (value is String &&
            (value[0].codeUnits.first >= zeroCodeUnit) &&
            (value[0].codeUnits.first <= nineCodeUnit)) {
          return 'First character cann\'t be a digit.';
        }

        if (!_alphaNumericNoStartDigitRegex.hasMatch(value)) {
          return 'Name should only contain alphanumeric values';
        }

        if (collection.project?.screens
                .firstWhereOrNull((e) => e.name == value) !=
            null) {
          return 'This is one of the screen name, try different';
        }

        if (collection.project?.name == value) {
          return 'This name is project name, please try different name';
        }
        if (collection.project?.customComponents
                .firstWhereOrNull((e) => e.name == value) !=
            null) {
          return 'This is one of the custom-widget name, try different';
        }
        return null;
      };

  static FormFieldValidator projectNameValidator() => (value) {
        if (value.isEmpty) {
          return 'Please enter valid name.';
        }
        if (value.length <= 3) {
          return 'Name should be more than 3 characters.';
        }

        if (value.length > 25) {
          return 'Name should be less than 25 characters.';
        }
        if (value is String &&
            (value[0].codeUnits.first >= zeroCodeUnit) &&
            (value[0].codeUnits.first <= nineCodeUnit)) {
          return 'First character cann\'t be a digit.';
        }


        if (collection.project?.name == value) {
          return 'This name is project name, please try different name';
        }
        return null;
      };
}
