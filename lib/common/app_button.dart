
import 'package:flutter/material.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:flutter_builder/constant/font_style.dart';

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
      this.enabledColor = AppColors.theme;
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
  _AppButtonState createState() => _AppButtonState(fontSize);
}

class _AppButtonState extends State<AppButton> {
  double _fontSize;

  _AppButtonState(this._fontSize);

  TextStyle style = AppFontStyle.roboto(15);

  @override
  void initState() {
    super.initState();
    if (widget.style == null) {
      style = AppFontStyle.roboto(widget.fontSize,
          color: Colors.white, fontWeight: FontWeight.w600);
    } else {
      style = widget.style!;
    }
    _fontSize = style.fontSize ?? 15;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ElevatedButton(
        onPressed: widget.isEnabled ? widget.onPressed : null,
        child: Text(
          widget.title ?? '',
          style: style,
          textAlign: widget.textAlign,
        ),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
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
  const AppIconButton(
      {required this.icon,
        required this.background,
        required this.onPress,
        this.margin = 10,
        this.size = 19,
        this.iconColor = Colors.white,
        Key? key})
      : super(key: key);
  final IconData icon;
  final Color background, iconColor;
  final void Function() onPress;
  final double margin;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(shape: BoxShape.circle, color: background),
        child: Icon(
          icon,
          color: iconColor,
          size: size,
        ),
      ),
    );
  }
}
