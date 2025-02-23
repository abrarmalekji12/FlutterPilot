import 'package:flutter/material.dart';
import 'responsive/responsive_dimens.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import 'extension_util.dart';

class PasswordBox extends StatefulWidget {
  final void Function(String) onChanged;
  final String text;
  final String? Function(String)? validator;
  final TextEditingController controller;

  const PasswordBox(
      {Key? key,
      required this.onChanged,
      this.text = 'Password',
      required this.controller,
      this.validator})
      : super(key: key);

  @override
  State<PasswordBox> createState() => _PasswordBoxState();
}

class _PasswordBoxState extends State<PasswordBox> {
  bool showPassword = true;

  @override
  Widget build(BuildContext context) {
    final fontSize = res(context, 18.sp, 14.sp, 18.sp);

    return TextFormField(
      controller: widget.controller,
      obscureText: showPassword,
      validator: (value) {
        return value!.length < 5
            ? 'Invalid password'
            : (widget.validator?.call(value));
      },
      onChanged: widget.onChanged,
      style: AppFontStyle.lato(
        fontSize,
        color: ColorAssets.darkGrey,
        fontWeight: FontWeight.w400,
      ),
      readOnly: false,
      textInputAction: TextInputAction.next,
      autofillHints: [AutofillHints.password],
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 5,
        ),
        labelText: widget.text,
        labelStyle: AppFontStyle.lato(
          fontSize,
          color: const Color(0xffababa9),
          fontWeight: FontWeight.w500,
        ),
        helperStyle: AppFontStyle.lato(
          13,
          color: Colors.black,
        ),
        hintStyle: AppFontStyle.lato(
          13,
          color: Colors.black,
        ),
        errorStyle: AppFontStyle.lato(
          13,
          color: Colors.red,
        ),
        border: InputBorder.none,
        iconColor: Colors.white,
        prefixStyle: AppFontStyle.lato(
          13,
          color: Colors.black,
        ),
        suffixStyle: AppFontStyle.lato(
          13,
          color: Colors.black,
        ),
        suffixIconConstraints:
            const BoxConstraints(minHeight: 24, minWidth: 24),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 15),
          child: InkWell(
            canRequestFocus: false,
            focusNode: FocusNode()..canRequestFocus = false,
            autofocus: false,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            onTap: () {
              showPassword = !showPassword;
              setState(() {});
            },
            child: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              size: 22,
              color: const Color(0XFFBDBCC2),
            ),
          ),
        ),
        fillColor: ColorAssets.lightYellow,
      ),
    );
  }
}
