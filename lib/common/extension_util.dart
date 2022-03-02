import '../constant/string_constant.dart';

extension StringEmailValidation on String {
  bool isValidEmail() {
    return StringEmptyValidation(this).hasValidData() &&
        RegExp(wEmailRegex).hasMatch(this);
  }

  bool isValidPassword() {
    return StringEmptyValidation(this).hasValidData() &&
        trim().length >= minPasswordLength;
  }
}

extension ListEmptyValidation on List<dynamic> {
  bool hasData() {
    return isNotEmpty;
  }
}

extension StringEmptyValidation on String {
  bool hasValidData() {
    return trim().isNotEmpty;
  }
}
