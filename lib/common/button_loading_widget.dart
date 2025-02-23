import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../constant/color_assets.dart';

class ButtonLoadingWidget extends StatelessWidget {
  final Color? color;
  const ButtonLoadingWidget({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 40,
          height: 20,
          child: LoadingIndicator(
            indicatorType: Indicator.ballPulse,
            colors: [color ?? ColorAssets.theme],
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: ColorAssets.lightGrey,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
//SizedBox(
//           width: 30,
//           height: 30,
//           child: CircularProgressIndicator(
//             strokeWidth: 3,
//             valueColor: AlwaysStoppedAnimation(ColorAssets.purpleColor),
//             color: ColorAssets.purpleColor,
//             backgroundColor: Colors.white,
//           ),
//         )
}
