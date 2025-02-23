import 'package:flutter/material.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../injector.dart';

class AppButton extends StatefulWidget {
  AppButton(
      {this.title = '',
      this.onPressed,
      this.style,
      this.isEnabled = true,
      Color? enabledColor,
      this.textAlign,
      this.height = 45.0,
      this.fontSize = 14,
      this.width,
      this.border = 0,
      Key? key})
      : super(key: key) {
    if (enabledColor != null) {
      this.enabledColor = enabledColor;
    } else {
      this.enabledColor = ColorAssets.theme;
    }
  }

  late final Color enabledColor;
  final VoidCallback? onPressed;
  final String? title;
  final double height;
  final double? width;
  final double border;
  final double fontSize;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool isEnabled;

  @override
  _AppButtonState createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  _AppButtonState();

  TextStyle style = AppFontStyle.lato(15);

  @override
  void initState() {
    super.initState();
    if (widget.style == null) {
      style = AppFontStyle.lato(widget.fontSize,
          color: Colors.white, fontWeight: FontWeight.w600);
    } else {
      style = widget.style!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        onPressed: widget.isEnabled ? widget.onPressed : null,
        child: Container(
          alignment: Alignment.center,
          height: widget.height,
          width: widget.width,
          child: Text(
            widget.title ?? '',
            style: style,
            textAlign: widget.textAlign,
          ),
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              return widget.isEnabled
                  ? widget.enabledColor
                  : const Color(0xffc4c4c4);
            },
          ),
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    this.icon,
    this.asset,
    this.background,
    required this.onPressed,
    this.margin = 8,
    this.elevation,
    this.size = 16,
    this.iconColor,
    Key? key,
  }) : super(key: key);
  final IconData? icon;
  final String? asset;
  final Color? background, iconColor;
  final void Function() onPressed;
  final double margin;
  final double size;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(margin),
          shape: const CircleBorder(),
          backgroundColor: background ?? theme.background1,
          minimumSize: Size.zero,
          elevation: elevation),
      onPressed: onPressed,
      child: asset != null
          ? Image.asset(
              asset!,
              width: size,
              height: size,
              color: iconColor ?? theme.iconColor1,
            )
          : Icon(
              icon,
              color: iconColor ?? theme.iconColor1,
              size: size,
            ),
    );
  }
}
