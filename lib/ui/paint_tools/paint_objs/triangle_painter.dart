import 'package:flutter/material.dart';

import '../../../common/extension_util.dart';

class TrianglePainter extends CustomPainter {
  final Color color;
  final double width;
  final double height;
  final bool filled;
  final double strokeWidth;
  final double angle;

  TrianglePainter({
    required this.color,
    required this.width,
    required this.height,
    required this.filled,
    required this.strokeWidth,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    final path = Path()
      ..moveTo((side / 2), 0)
      ..lineTo(side, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        path.transform((Matrix4.identity()
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
  bool shouldRepaint(TrianglePainter old) =>
      color != old.color ||
      width != old.width ||
      height != old.height ||
      filled != old.filled ||
      strokeWidth != old.strokeWidth ||
      angle != old.angle;
}
