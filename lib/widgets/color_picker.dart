import 'package:flutter/material.dart';

import '../constant/color_assets.dart';
import '../ui/parameter_ui.dart';

class ColorPicker extends StatelessWidget {
  final Color? color;
  final ValueChanged<Color> onChange;

  const ColorPicker({Key? key, required this.color, required this.onChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ColorAssets.grey,
          )),
      child: ColorButton(
          color: color ?? Colors.black,
          decoration: BoxDecoration(
              color: color ?? Colors.black, shape: BoxShape.circle),
          onColorChanged: (value) {
            onChange.call(value);
          }),
    );
  }
}
