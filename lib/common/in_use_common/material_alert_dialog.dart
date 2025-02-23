import 'package:flutter/material.dart';

import '../../constant/font_style.dart';

class MaterialSimpleAlertDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? negativeButtonText;
  final String positiveButtonText;
  final VoidCallback? onPositiveTap;
  final VoidCallback? onNegativeTap;

  const MaterialSimpleAlertDialog({
    Key? key,
    required this.title,
    this.subtitle,
    this.negativeButtonText,
    required this.positiveButtonText,
    this.onPositiveTap,
    this.onNegativeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(title),
      content: subtitle != null ? Text(subtitle!) : null,
      actions: [
        TextButton(onPressed: onPositiveTap, child: Text(positiveButtonText)),
        if (negativeButtonText != null)
          TextButton(
              onPressed: onNegativeTap, child: Text(negativeButtonText!)),
      ],
    );
  }
}

class MaterialDialogButton extends StatelessWidget {
  final double buttonWidth, buttonHeight;
  final String buttonText;
  final VoidCallback? onPress;

  const MaterialDialogButton(
      {Key? key,
      required this.buttonWidth,
      required this.buttonHeight,
      required this.onPress,
      required this.buttonText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = AppFontStyle.lato(
      14,
      color: Theme.of(context).primaryColor,
    ).copyWith(fontWeight: FontWeight.w700);
    return InkWell(
      hoverColor: Theme.of(context).primaryColor.withOpacity(0.1),
      splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.all(5),
        alignment: Alignment.center,
        width: buttonWidth,
        height: buttonHeight,
        child: Text(
          buttonText.toUpperCase(),
          style: buttonStyle,
        ),
      ),
      onTap: onPress,
    );
  }
}
