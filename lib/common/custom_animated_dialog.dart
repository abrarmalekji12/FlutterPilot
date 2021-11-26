import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAnimatedDialog {
  static Future<void> show(BuildContext context, Widget widget, GlobalKey sourceKey,
      {bool closeOnOutsideClick = true,void Function()? onDismiss}) async {
    final initialPosition = getPosition(sourceKey);
    final initialPositionDifference = Offset(
        initialPosition.dx - (Get.width / 2),
        initialPosition.dy - (Get.height / 2));
    const lastPosition = Offset(0, 0);

    await Get.dialog(GestureDetector(
      onTap: () {
        if (closeOnOutsideClick) {
          onDismiss?.call();
          Get.back();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.decelerate,
                duration: const Duration(milliseconds: 400),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: interpolate(
                        initialPositionDifference, lastPosition, value * value),
                    // offset: Offset(0,0),
                    child: Transform.scale(
                      scale: (value * 0.8 / 1) + 0.2,
                      child: widget,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }

  static Offset interpolate(Offset offset1, Offset offset2, double progress) {
    return Offset(offset1.dx + (progress * (offset2.dx - offset1.dx)),
        offset1.dy + progress * (offset2.dy - offset1.dy));
  }

  static Offset getPosition(GlobalKey globalKey) {
    RenderBox renderBox =
    globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;

    Offset position = renderBox.localToGlobal(Offset.zero);
    return Offset(position.dx + renderBox.size.width / 2,
        position.dy + renderBox.size.height / 2);
  }

  static void hide() {
    Get.back();
  }
}
