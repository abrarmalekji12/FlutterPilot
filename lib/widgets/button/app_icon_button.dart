import 'package:flutter/material.dart';

import '../../constant/color_assets.dart';
import '../image/app_image.dart';

class AppIconButton extends StatelessWidget {
  final String? asset;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foreground;
  final VoidCallback? onTap;
  final double? size;
  final bool round;
  final Color? borderColor;
  final double? imageSize;
  final bool elevated;
  final bool enable;

  const AppIconButton(
      {Key? key,
      this.imageSize,
      this.enable = true,
      this.borderColor,
      this.elevated = false,
      this.round = false,
      this.backgroundColor,
      this.onTap,
      this.asset,
      this.icon,
      this.foreground,
      this.size})
      : assert(
            (asset == null || icon == null) && (asset != null || icon != null)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? ColorAssets.green;
    return SizedBox(
      width: size ?? 44,
      height: size ?? 44,
      child: ElevatedButton(
        // borderRadius: BorderRadius.circular(6.r),
        onPressed: enable ? onTap : null,
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: WidgetStateProperty.resolveWith(
            (states) => !round
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: states.contains(WidgetState.focused)
                        ? const BorderSide(color: ColorAssets.green)
                        : (borderColor != null
                            ? BorderSide(color: borderColor!, width: 1.5)
                            : BorderSide.none))
                : CircleBorder(
                    side: states.contains(WidgetState.focused)
                        ? const BorderSide(color: ColorAssets.green)
                        : (borderColor != null
                            ? BorderSide(color: borderColor!, width: 1.5)
                            : BorderSide.none),
                  ),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => !states.contains(WidgetState.hovered)
                ? color.withOpacity(0.9)
                : color,
          ),
          elevation: WidgetStateProperty.resolveWith(
            (states) => elevated
                ? (states.contains(WidgetState.hovered) ? 2 : 1)
                : (states.contains(WidgetState.hovered) ? 1 : 0),
          ),
        ),
        child: asset != null
            ? AppImage(
                asset!,
                width: imageSize ?? (size != null ? size! / 1.8 : 20),
                fit: BoxFit.fitWidth,
                color: foreground ?? Colors.white,
              )
            : Icon(
                icon,
                size: imageSize ?? (size != null ? size! / 1.8 : 20),
                color: foreground ?? Colors.white,
              ),
      ),
    );
  }
}
