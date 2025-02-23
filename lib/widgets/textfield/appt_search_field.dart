import 'package:flutter/material.dart';

import '../../common/extension_util.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../constant/image_asset.dart';
import '../image/app_image.dart';

class AppSearchField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? image;
  final FocusNode? focusNode;
  final Color? iconColor;
  final bool autoFocus;
  final VoidCallback? onEditingComplete;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  const AppSearchField(
      {Key? key,
      required this.hint,
      this.textInputAction,
      this.textCapitalization = TextCapitalization.none,
      this.controller,
      this.onTap,
      this.onChanged,
      this.focusNode,
      this.image,
      this.iconColor,
      this.autoFocus = false,
      this.onEditingComplete,
      this.suffix})
      : super(key: key);

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final ValueNotifier<String> notifier = ValueNotifier('');
  late TextEditingController controller;

  @override
  void initState() {
    controller = widget.controller ?? TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (String value) {
        notifier.value = value;
        widget.onChanged?.call(value);
      },
      focusNode: widget.focusNode,
      keyboardType: TextInputType.text,
      readOnly: false,
      onEditingComplete: widget.onEditingComplete,
      autofocus: widget.autoFocus,
      onTap: widget.onTap,
      textCapitalization: widget.textCapitalization,
      style: AppFontStyle.lato(
        16.sp,
        fontWeight: FontWeight.w400,
      ),
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 0,
        ),
        hintText: widget.hint,
        hintStyle: AppFontStyle.lato(
          16.sp,
          color: ColorAssets.border,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: ColorAssets.border,
            width: 1,
          ),
          gapPadding: 0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: ColorAssets.border,
            width: 1,
          ),
          gapPadding: 0,
        ),
        focusColor: ColorAssets.theme,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: ColorAssets.border,
            width: 1,
          ),
          gapPadding: 0,
        ),
        prefixIconConstraints: BoxConstraints.tight(Size.square(40.w)),
        prefixIcon: SizedBox(
          width: 30.w,
          height: 30.w,
          child: Align(
            child: AppImage(
              widget.image ?? Images.search,
              width: 18,
              color: widget.iconColor ?? ColorAssets.border,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        iconColor: Colors.white,
        suffixIconColor: ColorAssets.border,
        suffixIconConstraints: BoxConstraints.tight(const Size.square(30)),
        suffixIcon: ValueListenableBuilder<String>(
            valueListenable: notifier,
            builder: (context, value, _) {
              if (value.isEmpty) {
                return const Offstage();
              }
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                canRequestFocus: false,
                autofocus: false,
                onTap: () {
                  if (controller.text.isNotEmpty) {
                    controller.clear();
                    widget.onChanged?.call('');
                  }
                },
                child: const Icon(
                  Icons.cancel_outlined,
                  size: 18,
                ),
              );
            }),
        enabled: true,
      ),
      obscureText: false,
    );
  }
}
