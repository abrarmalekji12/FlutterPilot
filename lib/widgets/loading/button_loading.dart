import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../../constant/color_assets.dart';

class ButtonLoadingWidget extends StatelessWidget {
  const ButtonLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: ColorAssets.colorD0D5EF,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      height: 45,
      padding: const EdgeInsets.symmetric(vertical: 5),
      alignment: Alignment.center,
      child: const LoadingIndicator(
        indicatorType: Indicator.ballPulseSync,
        colors: [
          ColorAssets.theme,
        ],
      ),
    );
  }
}
