import 'package:flutter/material.dart';
import '../constant/app_colors.dart';
import 'visual_model.dart';

class BoundaryPainter extends CustomPainter {
  final Paint myPaint = Paint();
  final List<Boundary> boundaries;
  final Rect? errorBoundary;

  BoundaryPainter({required this.boundaries, this.errorBoundary}) {
    myPaint.color = Colors.blueAccent;
    myPaint.strokeWidth = 2;
    myPaint.style = PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    myPaint.color = Colors.blueAccent;
    for (final boundary in boundaries) {
      canvas.drawRect(boundary.rect, myPaint);
      final span = TextSpan(
          text: boundary.name,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.theme,
            fontWeight: FontWeight.bold,
          ));
      TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout()
        ..paint(canvas, boundary.rect.topLeft.translate(0, -20));
    }

    if (errorBoundary != null) {
      myPaint.color = Colors.red;
      canvas.drawRect(errorBoundary!, myPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundaryPainter oldDelegate) {
    return oldDelegate.boundaries != boundaries ||
        oldDelegate.errorBoundary != errorBoundary;
  }
}
