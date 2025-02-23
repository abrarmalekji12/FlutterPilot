import 'package:flutter/material.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';

class EmptyTextWidget extends StatelessWidget {
  final String text;

  const EmptyTextWidget({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          text,
          style: AppFontStyle.lato(
            14,
            color: ColorAssets.color72788AGrey,
          ),
        ),
      ),
    );
  }
}
