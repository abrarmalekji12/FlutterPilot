import 'package:flutter/material.dart';

import '../../common/extension_util.dart';
import '../../constant/font_style.dart';

class AppActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final double? fontSize;

  const AppActionButton({
    Key? key,
    this.padding,
    this.fontSize,
    required this.text,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: backgroundColor,
        alignment: Alignment.center,
        minimumSize: Size.zero,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: fontSize != null ? fontSize! * 1.2 : 18,
            color: Colors.white,
          ),
          10.wBox,
          Text(
            text,
            style: AppFontStyle.lato(
              fontSize ?? 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
