import 'package:flutter/material.dart';

import '../../common/extension_util.dart';
import '../../constant/color_assets.dart';

class OverlayLoadingComponent extends StatelessWidget {
  final Widget child;
  final bool loading;
  final double radius;
  final double? size;
  final Color? background;

  const OverlayLoadingComponent(
      {Key? key,
      required this.child,
      this.loading = false,
      required this.radius,
      this.size,
      this.background})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Visibility(
          visible: loading,
          child: Positioned.fill(
            child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 500),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, _) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: radius.borderRadius,
                      color:
                          (background ?? Colors.white).withOpacity(0.8 * value),
                      border: Border.all(color: ColorAssets.border, width: 0.3),
                    ),
                    alignment: Alignment.center,
                    child: Center(
                      child: SizedBox(
                        height: size ?? 30,
                        width: size ?? 30,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(ColorAssets.theme),
                        ),
                      ),
                    ),
                  );
                }),
          ),
        )
      ],
    );
  }
}
