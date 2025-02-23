import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/extension_util.dart';
import '../../common/responsive/responsive_dimens.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../injector.dart';

class AppTextField extends StatefulWidget {
  final String? hintText;
  final TextEditingController? controller;
  final bool? obscureText;
  final bool isEditView;
  final TextInputType? textInputType;

  //final AppTheme appTheme;
  final GestureTapCallback? onTap;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization? textCapitalization;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final int? maxLength;
  final int? maxLines;
  final String? Function(String)? validator;
  final ValueChanged<String>? onChanged;
  final Function? onFieldSubmit;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final double? prefixGap;
  final Size? prefixIconSize;
  final Color fillColor;
  final Color? borderColor;
  final double borderWidth;
  final double? borderRadiusTop;
  final double? borderRadiusBottom;
  final void Function()? onEditingComplete;
  final bool autofocus;
  final String? title;
  final bool required;
  final bool alwaysShowLabel;
  final double? fontSize;
  final double? radius;
  final double? height;
  final Color? labelColor;
  final Color? fontColor;
  final String? name;
  final String? prefixText;
  final InputDecoration? decoration;
  final bool readOnly;
  final String? initialValue;
  final double? verticalPadding;
  final bool expands;
  final List<String>? autofillHints;
  final FontWeight? fontWeight;
  final Color? hintColor;
  final bool removePadding;

  const AppTextField({
    //required this.appTheme,
    Key? key,
    this.prefixGap,
    this.verticalPadding,
    this.fontWeight,
    this.removePadding = false,
    this.expands = false,
    this.readOnly = false,
    this.fontSize,
    this.fontColor,
    this.required = false,
    this.hintText,
    this.labelColor,
    this.alwaysShowLabel = false,
    this.autofocus = false,
    this.prefixIcon,
    this.isEditView = false,
    this.borderWidth = 1,
    this.borderRadiusTop,
    this.borderRadiusBottom,
    this.controller,
    this.obscureText = false,
    this.textInputType,
    this.borderColor,
    this.onTap,
    this.enabled = true,
    this.inputFormatters,
    this.textCapitalization,
    this.textInputAction,
    this.focusNode,
    this.nextFocusNode,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.suffixIcon,
    this.onFieldSubmit,
    this.onEditingComplete,
    this.fillColor = Colors.white,
    this.onChanged,
    this.title,
    this.radius,
    this.height,
    this.name,
    this.prefixText,
    this.decoration,
    this.initialValue,
    this.autofillHints,
    this.prefixIconSize,
    this.hintColor,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
  static Map<String, dynamic> controllers = {};

  static control(String name) => controllers[name];
}

class _AppTextFieldState extends State<AppTextField> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.name != null && widget.controller == null) {
      AppTextField.controllers[widget.name!] = controller;
    }
  }

  @override
  void dispose() {
    if (widget.name != null) {
      AppTextField.controllers.remove(widget.name);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultRadius = res(context, 10.r, 5.r, 10.r);
    final InputBorder inputBorder = widget.isEditView
        ? OutlineInputBorder(
            borderRadius: BorderRadius.only(
                topLeft: widget.radius?.radius ??
                    Radius.circular(widget.borderRadiusTop ?? defaultRadius),
                topRight: widget.radius?.radius ??
                    Radius.circular(widget.borderRadiusTop ?? defaultRadius),
                bottomLeft: widget.radius?.radius ??
                    Radius.circular(widget.borderRadiusBottom ?? defaultRadius),
                bottomRight: widget.radius?.radius ??
                    Radius.circular(
                        widget.borderRadiusBottom ?? defaultRadius)),
            borderSide: BorderSide(
                color: widget.borderColor ?? ColorAssets.colorD0D5EF,
                width: widget.borderWidth),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.only(
              topLeft: widget.radius?.radius ??
                  Radius.circular(widget.borderRadiusTop ?? defaultRadius),
              topRight: widget.radius?.radius ??
                  Radius.circular(widget.borderRadiusTop ?? defaultRadius),
              bottomLeft: widget.radius?.radius ??
                  Radius.circular(widget.borderRadiusBottom ?? defaultRadius),
              bottomRight: widget.radius?.radius ??
                  Radius.circular(widget.borderRadiusBottom ?? defaultRadius),
            ),
            borderSide: BorderSide(
                color: widget.borderColor ?? ColorAssets.colorD0D5EF,
                width: widget.borderWidth),
          );
    final fontSize = widget.fontSize ?? res(context, 18.sp, 14.sp, 18.sp)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null &&
            (!Responsive.isMobile(context) || widget.alwaysShowLabel)) ...[
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: widget.title!,
                style: AppFontStyle.lato(widget.fontSize ?? 18.sp,
                    color: widget.labelColor ?? ColorAssets.color333333,
                    fontWeight: FontWeight.w400),
              ),
              if (widget.required)
                TextSpan(
                    text: ' *',
                    style: AppFontStyle.lato(widget.fontSize ?? 18.sp,
                        color: ColorAssets.darkPink,
                        fontWeight: FontWeight.w400))
            ]),
          ),
          10.hBox
        ],
        Expanded(
          flex: widget.expands ? 1 : 0,
          child: TextFormField(
            key: widget.initialValue != null
                ? ValueKey(widget.initialValue)
                : null,
            textAlignVertical: widget.expands
                ? TextAlignVertical.top
                : TextAlignVertical.center,
            enabled: widget.enabled,
            controller: widget.initialValue == null
                ? (widget.controller ?? controller)
                : null,
            cursorColor: Colors.grey,
            autofocus: widget.autofocus,
            initialValue: widget.initialValue,
            obscureText: widget.obscureText ?? false,
            readOnly: widget.readOnly,
            keyboardType: widget.textInputType ?? TextInputType.text,
            autofillHints: widget.autofillHints,
            style: widget.isEditView
                ? AppFontStyle.lato(fontSize,
                    color: widget.fontColor ?? ColorAssets.color222222,
                    fontWeight: widget.fontWeight ?? FontWeight.normal)
                : widget.enabled
                    ? AppFontStyle.lato(fontSize,
                        color: widget.fontColor ?? ColorAssets.color222222,
                        fontWeight: widget.fontWeight ?? FontWeight.normal)
                    : AppFontStyle.lato(
                        fontSize,
                        color: widget.fontColor ?? ColorAssets.color222222,
                        fontWeight: widget.fontWeight ?? FontWeight.normal,
                      ),
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters ?? [],
            textInputAction: Responsive.isDesktop(context) && !isLandscapeTab
                ? ((widget.maxLines ?? 0) <= 1
                    ? (widget.textInputAction ?? TextInputAction.next)
                    : TextInputAction.none)
                : (widget.textInputAction ?? TextInputAction.next),
            textCapitalization:
                widget.textCapitalization ?? TextCapitalization.none,
            validator: (value) {
              if (widget.validator != null) {
                return widget.validator!(value!);
              }
              return null;
            },
            onEditingComplete: widget.onEditingComplete,
            onFieldSubmitted: (value) {
              // if (widget.nextFocusNode != null&&widget.maxLines) {
              //   FocusScope.of(context).requestFocus(widget.nextFocusNode);
              // }
              if (widget.onFieldSubmit != null) {
                widget.onFieldSubmit!();
              }
            },
            onChanged: (value) {
              if (widget.onChanged != null) {
                return widget.onChanged!(value);
              }
              return;
            },
            focusNode: widget.focusNode,
            maxLength: widget.maxLength,
            maxLines: widget.expands ? null : widget.maxLines,
            expands: widget.expands,
            decoration: widget.decoration ??
                InputDecoration(
                  prefix: widget.prefixIcon != null || widget.prefixText != null
                      ? (widget.prefixGap != null
                          ? SizedBox(
                              width: widget.prefixGap!,
                            )
                          : null)
                      : SizedBox(
                          width: 15.w,
                        ),
                  prefixIcon: widget.prefixIcon,
                  prefixText: widget.prefixText,
                  prefixStyle:
                      AppFontStyle.lato(fontSize, fontWeight: FontWeight.w500),
                  prefixIconConstraints: BoxConstraints.tight(
                    widget.prefixIconSize ?? Size(20.w, 20.w),
                  ),
                  contentPadding: widget.removePadding
                      ? null
                      : (widget.height != null) && ((widget.maxLines ?? 0) <= 1)
                          ? EdgeInsets.symmetric(
                              vertical: widget.verticalPadding ??
                                  (widget.height! / 2) - (fontSize / 2),
                            )
                          : ((widget.maxLines ?? 0) > 1 || widget.expands
                              ? EdgeInsets.symmetric(
                                  vertical: widget.verticalPadding ?? 15)
                              : EdgeInsets.zero),
                  border: inputBorder,
                  hoverColor: Colors.transparent,
                  focusedBorder: inputBorder,
                  enabledBorder: inputBorder,
                  errorBorder: inputBorder,
                  disabledBorder: inputBorder,
                  filled: true,
                  isDense: widget.height != null ? true : false,
                  fillColor: Colors.white,
                  //widget.fillColor,
                  counterText: widget.maxLength != null ? '' : null,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: widget.suffixIcon,
                  ),
                  hintText: widget.hintText,
                  hintStyle: AppFontStyle.lato(
                    widget.fontSize ?? res(context, 18.sp, 14.sp, 18.sp),
                    color: widget.hintColor ??
                        ColorAssets.color222222.withOpacity(.5),
                    fontWeight: FontWeight.w400,
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minHeight: 20, minWidth: 20),
                  errorStyle: AppFontStyle.lato(
                      widget.fontSize != null
                          ? widget.fontSize! - 2
                          : res(context, 15.sp, 13.sp, 14.sp),
                      color: Colors.red),
                ),
          ),
        ),
      ],
    );
  }
}
