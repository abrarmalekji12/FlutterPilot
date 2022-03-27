import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final void Function(String) onChange;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  const CustomTextField(
      {Key? key, required this.onChange, this.hint, this.controller, this.validator, this.focusNode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChange,
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.all(5),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
      ),
    );
  }
}
