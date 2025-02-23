import 'package:flutter/material.dart';

import '../constant/color_assets.dart';

class CommonCircularLoading extends StatelessWidget {
  final double? size;
  const CommonCircularLoading({Key? key, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      child: SizedBox(
        width: size ?? 35,
        height: size ?? 35,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(ColorAssets.theme),
        ),
      ),
    );
  }
}
