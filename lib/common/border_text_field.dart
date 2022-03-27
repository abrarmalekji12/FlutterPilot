import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

class BorderTextField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmitted;
  final FocusNode? focusNode;
  const BorderTextField({Key? key,required this.controller,required this.onSubmitted,this.focusNode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode?..requestFocus(),
      controller: controller,
      onEditingComplete: (){
        onSubmitted.call(controller.text);
      },
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10,vertical: 0),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.theme, width: 1.5),
          borderRadius: BorderRadius.all(
            Radius.circular(8.0),
          ),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide:
            BorderSide(color: Colors.grey, width: 1.5)),

        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.theme, width: 1.5),
          borderRadius: BorderRadius.all(
            Radius.circular(8.0),
          ),
        ),
      ),
    );
  }
}
