import 'package:flutter/material.dart';

import '../../../../common/responsive/responsive_dimens.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';

class FilledButtonWidget extends StatelessWidget {
  final String? text;
  final VoidCallback? onTap;
  final Color fillColor;
  final Color? textColor;
  final bool enable;
  final double? height;
  final double? width;
  final double? fontSize;
  final EdgeInsets? padding;
  final Widget? child;

  const FilledButtonWidget(
      {Key? key,
      this.text,
      this.onTap,
      this.child,
      this.fillColor = ColorAssets.theme,
      this.enable = true,
      this.textColor,
      this.height,
      this.width,
      this.fontSize,
      this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = AppFontStyle.lato(fontSize ?? res(context, 18.sp, 16.sp),
            color: enable ? (textColor ?? Colors.white) : Colors.white,
            fontWeight: Responsive.isMobile(context) ? FontWeight.w400 : FontWeight.w500)
        .copyWith(height: 0.8);
    return SizedBox(
      width: width,
      height: height ?? 45,
      child: ElevatedButton(
        style: ButtonStyle(
            padding: WidgetStatePropertyAll(padding ?? EdgeInsets.zero),
            enableFeedback: enable,
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              // if(states.contains(WidgetState.pressed)){
              //   return fillColor.withOpacity(0.5);
              // }
              if (states.contains(WidgetState.disabled)) {
                return Theme.of(context).disabledColor;
              }
              return fillColor;
            })),
        onPressed: enable ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(res(context, 10.r, 6.r)),
          ),
          padding: EdgeInsets.only(top: (fontSize ?? res(context, 18.sp, 16.sp)!) / 4),
          alignment: Alignment.center,
          child: child != null
              ? DefaultTextStyle(style: textStyle, child: child!)
              : Text(
                  text ?? '',
                  style: textStyle,
                ),
        ),
      ),
    );
  }
}
