import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final void Function(String) onChange;
  final String? hint;
  final TextEditingController? controller;
  const CustomTextField({Key? key, required this.onChange, this.hint,this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChange,
      controller: controller,
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
