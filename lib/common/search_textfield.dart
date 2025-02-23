import 'package:flutter/material.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../constant/string_constant.dart';
import '../injector.dart';

class SearchTextField extends StatelessWidget {
  final FocusNode focusNode;
  final String hint;
  final String text;
  final TextEditingController controller;
  final void Function()? onSubmitted;
  final Color focusColor;

  const SearchTextField(
      {required this.onTextChange,
      required this.focusNode,
      required this.hint,
      required this.controller,
      required this.focusColor,
      this.onSubmitted,
      this.text = '',
      Key? key})
      : super(key: key);

  final Function(String) onTextChange;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        focusNode: focusNode,
        //textInputAction: TextInputAction.newline,
        maxLines: 1,
        onChanged: onTextChange,
        autofocus: false,
        onSubmitted: (data) {
          onSubmitted?.call();
        },
        style: AppFontStyle.lato(15,
            color: theme.text1Color, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
            focusColor: Colors.white,
            hoverColor: Colors.white,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(10.0),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: ColorAssets.theme, width: 2),
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
            //fillColor: readonly ? Colors.white : Colors.white,
            //errorStyle: TextStyle( color: Theme.of(context).backgroundColor, fontSize: 20),
            filled: true,
            hintText: hint,
            hintStyle: AppFontStyle.lato(
              15,
              color: const Color(0xffC4C4C4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: focusColor, width: 1.5),
              borderRadius: const BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: focusColor, width: 1.5),
              borderRadius: const BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
            suffixIcon: Transform.scale(
              scale: 0.45,
              child: Image.asset(
                Collections.SEARCH_ICON,
                width: 15,
                height: 15,
                fit: BoxFit.fitWidth,
              ),
            )
            // suffixIcon: IconButton(
            //   icon: const Icon(
            //     Icons.clear_rounded,
            //     size: 20,
            //     color: Colors.black,
            //   ),
            //   onPressed: () {
            //     _searchController.clear();
            //     var currentFocus = FocusScope.of(context);
            //     if (currentFocus.canRequestFocus) {
            //       FocusScope.of(context).requestFocus(FocusNode());
            //     }
            //   },
            // ),
            ),
      ),
    );
  }
}
