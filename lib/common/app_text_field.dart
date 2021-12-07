import 'package:flutter/material.dart';
import 'package:flutter_builder/constant/font_style.dart';

class AppTextField extends StatelessWidget {
  late final TextEditingController textFieldController;
  static String changedValue='';
  final void Function(String)? onChange;

  AppTextField({Key? key, String? value, this.onChange, TextEditingController? controller}) : super(key: key) {
    if(controller!=null){
      textFieldController=controller;
    }
    else if (value != null) {
      textFieldController = TextEditingController.fromValue(TextEditingValue(text: value));
      changedValue=value;
    }

  }


  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) {
        changedValue=value;
        onChange?.call(value);
      },
      focusNode: FocusNode()..requestFocus(),
      controller: textFieldController,
      style: AppFontStyle.roboto(14,fontWeight: FontWeight.w500),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10,vertical: 0),
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
