import 'dart:math';

import 'package:flutter/material.dart';

import '../../../common/extension_util.dart';

class CirclePainter extends CustomPainter {
  final Color color;
  final double width;
  final double height;
  final bool filled;
  final double strokeWidth;
  final double angle;
  final bool semi;

  CirclePainter({
    this.semi = false,
    required this.color,
    required this.filled,
    required this.strokeWidth,
    required this.width,
    required this.height,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        (Path()
              ..addArc(Rect.fromLTWH(0, 0, width, height * (semi ? 2 : 1)), 0,
                  semi ? -pi : 2 * pi)
              ..close())
            .transform((Matrix4.identity()
                  ..translate(width / 2, height / 2)
                  ..rotateZ(angle.toRadian)
                  ..translate(-width / 2, -height / 2))
                .storage),
        Paint()
          ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color);
  }

  @override
  bool shouldRepaint(CirclePainter old) =>
      color != old.color ||
      filled != old.filled ||
      strokeWidth != old.strokeWidth ||
      width != old.width ||
      height != old.height ||
      angle != old.angle;
}
