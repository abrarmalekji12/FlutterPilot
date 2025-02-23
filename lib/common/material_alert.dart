import 'package:flutter/material.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../ui/navigation/animated_dialog.dart';

class MaterialAlertDialog extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? negativeButtonText;
  final String positiveButtonText;
  final VoidCallback? onPositiveTap;
  final VoidCallback? onNegativeTap;

  const MaterialAlertDialog({
    Key? key,
    this.title,
    this.subtitle,
    this.negativeButtonText,
    required this.positiveButtonText,
    this.onPositiveTap,
    this.onNegativeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(title ?? ''),
      content: subtitle != null ? Text(subtitle!) : null,
      actions: [
        TextButton(
            onPressed: () {
              AnimatedDialog.hide(context).then((value) {
                onPositiveTap?.call();
              });
            },
            child: Text(positiveButtonText)),
        if (negativeButtonText != null)
          TextButton(
              onPressed: () {
                AnimatedDialog.hide(context).then((value) {
                  onNegativeTap?.call();
                });
              },
              child: Text(negativeButtonText!)),
      ],
    );
  }
}

class MaterialDialogButton extends StatelessWidget {
  final double? buttonWidth, buttonHeight;
  final String buttonText;
  final VoidCallback? onPress;

  const MaterialDialogButton(
      {Key? key,
      this.buttonWidth,
      this.buttonHeight,
      required this.onPress,
      required this.buttonText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(10),
        surfaceTintColor: ColorAssets.theme,
      ),
      child: Container(
        alignment: Alignment.center,
        width: buttonWidth,
        height: buttonHeight,
        child: Text(
          buttonText.toUpperCase(),
          style: AppFontStyle.lato(
            14,
            color: ColorAssets.theme,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      onPressed: onPress,
    );
  }
}
