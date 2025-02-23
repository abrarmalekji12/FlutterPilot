import 'package:flutter/material.dart';

import '../../common/extension_util.dart';
import '../../constant/font_style.dart';
import '../../injector.dart';

class EmptyTextIconWidget extends StatelessWidget {
  final String text;
  final IconData icon;

  const EmptyTextIconWidget(
      {super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 35,
              color: theme.text4Color,
            ),
            15.hBox,
            Text(
              text,
              style: AppFontStyle.lato(14,
                  color: theme.text4Color, fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
