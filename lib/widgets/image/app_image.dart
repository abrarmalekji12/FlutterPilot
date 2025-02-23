import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppImage extends StatelessWidget {
  final String assetName;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final BlendMode? blendMode;

  const AppImage(this.assetName,
      {Key? key,
      this.width,
      this.blendMode,
      this.height,
      this.filterQuality = FilterQuality.low,
      this.color,
      this.fit = BoxFit.contain,
      this.alignment = Alignment.center})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (assetName.endsWith('.svg')) {
      return SvgPicture.asset(
        assetName,
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
      );
    }
    return Image.asset(
      assetName,
      color: color,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      filterQuality: filterQuality,
      colorBlendMode: blendMode,
    );
  }
}

class AppImageButton extends StatelessWidget {
  final String assetName;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final VoidCallback? onTap;

  const AppImageButton(
    this.assetName, {
    Key? key,
    this.width,
    this.height,
    this.filterQuality = FilterQuality.low,
    this.color,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: width != null ? BorderRadius.circular(width! / 2) : null,
      child: AppImage(
        assetName,
        width: width,
        height: height,
        filterQuality: filterQuality,
        color: color,
        fit: fit,
        alignment: alignment,
      ),
    );
  }
}
