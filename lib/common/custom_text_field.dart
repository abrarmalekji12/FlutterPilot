import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final void Function(String) onChange;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool enabled;
  const CustomTextField(
      {Key? key,
      required this.onChange,
      this.hint,
      this.enabled = true,
      this.controller,
      this.validator,
      this.focusNode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: TextFormField(
          enabled: enabled,
          onChanged: onChange,
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.grey, width: 1.5),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.grey, width: 1.5),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
        ),
      ),
    );
  }
}
