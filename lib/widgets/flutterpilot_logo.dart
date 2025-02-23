import 'package:flutter/material.dart';

import '../common/extension_util.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../constant/image_asset.dart';
import '../injector.dart';

class FlutterPilotLogo extends StatelessWidget {
  const FlutterPilotLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: ColorAssets.theme,
            radius: 24,
            child: Image.asset(
              Images.logo,
              color: Colors.white,
              width: 40,
              height: 40,
            ),
          ),
          20.wBox,
          Text(
            'FlutterPilot',
            style: AppFontStyle.lato(
              28,
              fontWeight: FontWeight.w900,
              color: theme.text1Color,
            ),
          )
        ],
      ),
    );
  }
}

class FlutterPilotMediumLogo extends StatelessWidget {
  const FlutterPilotMediumLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: ColorAssets.theme,
          radius: 24,
          child: Image.asset(
            Images.logo,
            color: Colors.white,
            width: 40,
            height: 40,
          ),
        ),
        10.wBox,
        Text(
          'FlutterPilot',
          style: AppFontStyle.lato(
            22,
            fontWeight: FontWeight.w900,
            color: theme.text1Color,
          ),
        )
      ],
    );
  }
}
