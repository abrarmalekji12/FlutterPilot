import 'package:flutter/material.dart';

import '../screen_model.dart';

class EmulationView extends StatelessWidget {
  final Widget widget;
  final ScreenConfig screenConfig;

  const EmulationView({
    Key? key,
    required this.widget,
    required this.screenConfig,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return InteractiveViewer(
        clipBehavior: Clip.none,
        child: SizedBox(
          width: double.infinity,
          child: FittedBox(
            child: SizedBox(
                width: screenConfig.width * (2 - screenConfig.scale),
                height: screenConfig.height * (2 - screenConfig.scale),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(width: 1, color: Colors.grey.shade600)),
                    width: screenConfig.width,
                    height: screenConfig.height,
                    child: widget,
                  ),
                )),
          ),
        ),
      );
    });
  }
}

class SubEmulationView extends StatelessWidget {
  final Widget widget;
  final ScreenConfig screenConfig;

  const SubEmulationView({
    Key? key,
    required this.widget,
    required this.screenConfig,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(3, 3),
            blurRadius: 24)
      ]),
      width: screenConfig.width,
      height: screenConfig.height,
      child: Focus(
        descendantsAreFocusable: false,
        canRequestFocus: false,
        child: widget,
      ),
    );
  }
}
