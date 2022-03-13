import 'package:flutter/material.dart';

import '../constant/app_colors.dart';
import '../constant/font_style.dart';

class MaterialAlertDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? negativeButtonText;
  final String positiveButtonText;
  final VoidCallback? onPositiveTap;
  final VoidCallback? onNegativeTap;

  const MaterialAlertDialog({
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
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
              kElevationToShadow[1]
          ),
            width: 350,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, top: 24, bottom: 12, right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: AppFontStyle.roboto(18,color: Colors.black)
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(
                        height: 24,
                      ),
                      if(subtitle!=null) ...[
                        Padding(
                          padding: const EdgeInsets.only(right:40),
                          child: Text(
                            subtitle!,
                            style: AppFontStyle.roboto(14, color: const Color(0xff666666))
                                .copyWith(fontWeight: FontWeight.normal),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if(negativeButtonText!=null) ... [
                              MaterialDialogButton(
                                buttonHeight: 30,
                                buttonWidth: 100,
                                buttonText: negativeButtonText!,
                                onPress: () {
                                  onNegativeTap?.call();
                                  Navigator.of(context).pop();
                                },
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                            ],
                            MaterialDialogButton(
                              buttonHeight: 30,
                              buttonWidth: 100,
                              buttonText: positiveButtonText,
                              onPress: () {
                                onPositiveTap?.call();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  right: 17,
                  top: 17,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                )
              ],
            )),
      ),
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
    final buttonStyle = AppFontStyle.roboto( 14, color: AppColors.theme,).copyWith(fontWeight: FontWeight.w700);
    return InkWell(
      hoverColor: AppColors.theme.withOpacity(0.1),
      splashColor:AppColors.theme.withOpacity(0.3) ,
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