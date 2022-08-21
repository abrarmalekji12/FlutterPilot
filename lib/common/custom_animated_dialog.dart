import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDialog {
  static Future<void> show(BuildContext context, Widget widget,
      {bool closeOnOutsideClick = true, void Function()? onDismiss}) async {
    // final initialPosition = getPosition(sourceKey);
    // final initialPositionDifference = Offset(
    //     initialPosition.dx - (Get.width / 2),
    //     initialPosition.dy - (Get.height / 2));
    // const lastPosition = Offset(0, 0);
    await showDialog(
        context: context,
        builder: (context) => GestureDetector(
              onTap: () {
                if (closeOnOutsideClick) {
                  onDismiss?.call();
                  Navigator.pop(context);
                }
              },
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: widget,
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

  static void hide(BuildContext context) {
    Navigator.pop(context);
  }
}
