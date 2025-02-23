import 'package:flutter/material.dart';

import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        backgroundColor: ColorAssets.theme,
        alignment: Alignment.center,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: AppFontStyle.lato(
          16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
