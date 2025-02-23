import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import '../../../common/extension_util.dart';

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final Color color;
  final double width;
  final double height;
  final bool filled;
  final double strokeWidth;
  final double radius;
  final double rotation;

  ImagePainter({
    required this.color,
    required this.width,
    required this.height,
    required this.filled,
    required this.strokeWidth,
    required this.radius,
    required this.rotation,
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        (Path()
              ..addRRect(RRect.fromRectAndRadius(
                  Rect.fromLTWH(0, 0, width, height), Radius.circular(radius))))
            .transform((Matrix4.identity()
                  ..translate(width / 2, height / 2)
                  ..rotateZ(rotation.toRadian)
                  ..translate(-width / 2, -height / 2))
                .storage),
        Paint()
          ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color);
  }

  @override
  bool shouldRepaint(ImagePainter old) =>
      color != old.color ||
      width != old.width ||
      height != old.height ||
      filled != old.filled ||
      strokeWidth != old.strokeWidth ||
      radius != old.radius ||
      rotation != old.rotation ||
      image != old.image;
}
