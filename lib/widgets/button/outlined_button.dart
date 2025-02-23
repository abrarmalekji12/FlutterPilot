import 'package:flutter/material.dart';

import '../../../../common/responsive/responsive_dimens.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../injector.dart';

class OutlinedButtonWidget extends StatelessWidget {
  final String? text;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool enable;
  final double? height;
  final double? width;
  final double? fontSize;
  final Color? background;
  final Color? borderColor;
  final Widget? child;
  final EdgeInsets? padding;

  const OutlinedButtonWidget(
      {Key? key,
      this.text,
      this.child,
      this.padding,
      this.onTap,
      this.textColor,
      this.enable = true,
      this.height,
      this.width,
      this.fontSize,
      this.background,
      this.borderColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: enable ? onTap : null,
        borderRadius: BorderRadius.circular(res(context, 10.r, 6.r)),
        child: Container(
          width: width,
          padding: (padding ?? EdgeInsets.symmetric(horizontal: 16.w))
              .copyWith(top: (fontSize ?? res(context, 18.sp, 16.sp)!) / 4),
          height: height ?? 45,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: borderColor ?? ColorAssets.border),
              color: background),
          alignment: Alignment.center,
          child: child != null
              ? DefaultTextStyle(
                  style: AppFontStyle.lato(
                          fontSize ?? res(context, 18.sp, 16.sp),
                          color: textColor ?? theme.text1Color,
                          fontWeight: Responsive.isMobile(context)
                              ? FontWeight.w400
                              : FontWeight.w500)
                      .copyWith(height: 0.8),
                  child: child!,
                )
              : Text(
                  text!,
                  style: AppFontStyle.lato(
                          fontSize ?? res(context, 18.sp, 16.sp),
                          color: textColor ?? theme.text1Color,
                          fontWeight: Responsive.isMobile(context)
                              ? FontWeight.w400
                              : FontWeight.w500)
                      .copyWith(height: 0.8),
                ),
        ));
  }
}
