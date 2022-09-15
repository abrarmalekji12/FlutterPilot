import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../constant/app_colors.dart';


class CustomShimmer extends StatelessWidget {
  final Widget child;
  final bool enable;

  const CustomShimmer({Key? key, required this.child, this.enable = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: child),
      enabled: enable,
      baseColor: AppColors.shimmerColor,
      highlightColor: Colors.white,
    );
  }
}
