import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/ui/visual_model.dart';

class BoundaryPainter extends CustomPainter {
  final List<Boundary> boundaries;
  final Paint myPaint = Paint();

  BoundaryPainter(this.boundaries) {
    myPaint.color = Colors.blueAccent;
    myPaint.strokeWidth=2;
    myPaint.style=PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final boundary in boundaries) {
      canvas.drawRect(boundary.rect, myPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundaryPainter oldDelegate) {
    return oldDelegate.boundaries != boundaries;
  }
}
