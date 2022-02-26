import 'package:flutter/material.dart';

import '../screen_model.dart';

class EmulationView extends StatelessWidget {
  final Widget widget;
  final ScreenConfig screenConfig;

  const EmulationView(
      {Key? key, required this.widget, required this.screenConfig})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Transform.scale(
        scale: screenConfig.scale,
        child: SizedBox(
          width: constraints.maxWidth* (2-screenConfig.scale),
          height: constraints.maxWidth * (2-screenConfig.scale),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: screenConfig.width,
              height: screenConfig.height,
              child: widget,
            ),
          ),
        ),
      );
    });
  }
}
