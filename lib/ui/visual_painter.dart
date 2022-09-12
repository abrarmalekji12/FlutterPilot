import 'package:flutter/material.dart';

import '../constant/app_colors.dart';
import 'visual_model.dart';

class BoundaryPainter extends CustomPainter {
  final Paint myPaint = Paint();
  final Paint paintOuter = Paint();
  final Paint fillPaint = Paint();
  final List<Boundary> boundaries;
  final List<Boundary> hoverBoundaries;

  final Rect? errorBoundary;

  BoundaryPainter(
      {required this.boundaries,
      required this.hoverBoundaries,
      this.errorBoundary}) {
    myPaint.color = Colors.blueAccent;
    myPaint.strokeWidth = 2;
    myPaint.style = PaintingStyle.stroke;
    paintOuter.color = AppColors.black.withOpacity(0.4);
    paintOuter.strokeWidth = 0.5;
    paintOuter.style = PaintingStyle.stroke;
    fillPaint.color = AppColors.white.withOpacity(0.7);
    fillPaint.style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    myPaint.color = Colors.blueAccent.withOpacity(0.6);


    for (final boundary in hoverBoundaries) {
      if (!boundaries.contains(boundary)) {
        drawSelection(canvas, Colors.yellow.shade700, size, boundary);
      }
    }
    for (final boundary in boundaries) {
      drawSelection(canvas, Colors.blueAccent, size, boundary);
    }
    if (errorBoundary != null) {
      myPaint.color = Colors.red;
      canvas.drawRect(errorBoundary!, myPaint);
    }
  }

  void drawSelection(Canvas canvas, Color color, Size size, Boundary boundary) {
    myPaint.color=color;
    canvas.drawRect(boundary.rect, myPaint);
    canvas.drawLine(
        Offset(0, boundary.rect.top), boundary.rect.topLeft, paintOuter);
    canvas.drawLine(
        Offset(boundary.rect.left, 0), boundary.rect.topLeft, paintOuter);
    canvas.drawLine(
        Offset(boundary.rect.right, 0), boundary.rect.topRight, paintOuter);
    canvas.drawLine(
        Offset(0, boundary.rect.bottom), boundary.rect.bottomLeft, paintOuter);
    canvas.drawLine(Offset(boundary.rect.left, size.height),
        boundary.rect.bottomLeft, paintOuter);
    canvas.drawLine(Offset(boundary.rect.right, size.height),
        boundary.rect.bottomRight, paintOuter);
    canvas.drawLine(Offset(size.width, boundary.rect.top),
        boundary.rect.topRight, paintOuter);
    canvas.drawLine(Offset(size.width, boundary.rect.bottom),
        boundary.rect.bottomRight, paintOuter);
    final span = TextSpan(
      children: [
        TextSpan(
            text: boundary.name,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            )),
        TextSpan(
          text:
              '   ${boundary.rect.width.toStringAsFixed(2)} x ${boundary.rect.height.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.darkGrey.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    fillPaint.color = color;
    canvas.drawRect(
        Rect.fromPoints(Offset(boundary.rect.left, boundary.rect.top - 20),
            Offset(boundary.rect.left + painter.width, boundary.rect.top)),
        fillPaint);

    painter.paint(canvas, boundary.rect.topLeft.translate(0, -20));
  }

  @override
  bool shouldRepaint(covariant BoundaryPainter oldDelegate) {
    return oldDelegate.boundaries != boundaries ||
        oldDelegate.errorBoundary != errorBoundary;
  }
}
