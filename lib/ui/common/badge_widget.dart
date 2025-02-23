import 'package:flutter/material.dart';

import '../../constant/color_assets.dart';

class BadgeWidget extends StatelessWidget {
  final ValueNotifier<bool> error;
  final Widget child;

  const BadgeWidget({Key? key, required this.error, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(child: child),
        ValueListenableBuilder(
          valueListenable: error,
          builder: (BuildContext context, bool value, Widget? child) {
            return value
                ? Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: ColorAssets.red, shape: BoxShape.circle),
                      ),
                    ),
                  )
                : const Offstage();
          },
        )
      ],
    );
  }
}
