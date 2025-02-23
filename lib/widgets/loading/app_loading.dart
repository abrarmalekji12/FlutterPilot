import 'package:flutter/material.dart';

import '../../constant/color_assets.dart';
import '../../injector.dart';

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: theme.background3,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: ColorAssets.theme,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
