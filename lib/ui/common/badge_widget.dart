import 'package:flutter/material.dart';

import '../../constant/app_colors.dart';

class BadgeWidget extends StatelessWidget {
  final ValueNotifier<bool> error;
  final Widget child;

  const BadgeWidget({Key? key, required this.error, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: child),
        ValueListenableBuilder(
          valueListenable: error,
          builder: (BuildContext context, bool value, Widget? child) {
            return value
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: AppColors.red, shape: BoxShape.circle),
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
