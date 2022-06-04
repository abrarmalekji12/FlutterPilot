import 'package:flutter/material.dart';
import '../constant/font_style.dart';

import 'logger.dart';

class AppTextField extends StatelessWidget {
  late final TextEditingController textFieldController;
  static String changedValue = '';
  late final FocusNode focusNode;
  final void Function(String)? onChange;

  AppTextField(
      {Key? key,
      String? value,
      this.onChange,
      TextEditingController? controller,
      FocusNode? node})
      : super(key: key) {
    if (controller != null) {
      textFieldController = controller;
    } else if (value != null) {
      textFieldController =
          TextEditingController.fromValue(TextEditingValue(text: value));
      changedValue = value;
    }
    if (node != null) {
      focusNode = node;
    } else {
      focusNode = FocusNode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) {
        changedValue = value;
        onChange?.call(value);
      },
      focusNode: focusNode..requestFocus(),
      autofocus: true,
      controller: textFieldController,
      style: AppFontStyle.roboto(15, fontWeight: FontWeight.normal),
      onSubmitted: (data) {
        logger('SUBMITTED');
      },
      onEditingComplete: () {
        logger('EDITING COMP');
      },
      decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          enabled: true,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Colors.blueAccent, width: 1.5))),
    );
  }
}
