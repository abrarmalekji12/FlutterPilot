import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/ui/visual_model.dart';

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
      TextPainter textPainter = TextPainter();
      textPainter.text = TextSpan(
          text: boundary.name,
          style: AppFontStyle.roboto(
            15,
            color: AppColors.theme,
            fontWeight: FontWeight.bold,
          ));
      textPainter.textDirection = TextDirection.ltr;
      textPainter.layout();
      textPainter.paint(canvas, boundary.rect.topLeft.translate(0, -20));

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
