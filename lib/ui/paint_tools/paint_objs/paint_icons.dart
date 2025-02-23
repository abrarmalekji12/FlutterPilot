import 'dart:math';

import 'package:flutter/material.dart';

class RectIconPainter extends CustomPainter {
  final Color color;

  RectIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 10.0;
    canvas.drawRect(
        Rect.fromLTWH(padding, padding, size.width - 2 * padding,
            size.height - 2 * padding),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircleIconPainter extends CustomPainter {
  final Color color;

  CircleIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 10.0;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        (size.width / 2) - padding,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TriangleIconPainter extends CustomPainter {
  final Color color;

  TriangleIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * 0.5;
    final path = Path()
      ..moveTo((side / 2), 0)
      ..lineTo(side, side)
      ..lineTo(0, side)
      ..close();
    canvas.drawPath(
        path.shift(Offset(
            (size.width - side) / 2, (size.height - (side * sqrt(3) / 2)) / 2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
