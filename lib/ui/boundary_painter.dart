import 'dart:math';

import 'package:flutter/material.dart';

import '../common/analyzer/render_models.dart';
import '../common/converter/string_operation.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import 'visual_model.dart';

final Paint myPaint = Paint();
final Paint cornerPaint = Paint();
final Paint radiusPaint = Paint();
final Paint paintOuter = Paint();
final Paint fillPaint = Paint();
const radiusOffset = Offset(15, 15);
final Paint distanceLinePainter = Paint()
  ..color = Colors.grey
  ..strokeJoin = StrokeJoin.round;

class BoundaryPainter extends CustomPainter {
  final BuildContext context;
  final List<Boundary> boundaries;
  final List<Boundary> hoverBoundaries;
  final List<Boundary> errorBoundaries;
  final double scale;

  BoundaryPainter({
    required this.boundaries,
    required this.errorBoundaries,
    required this.hoverBoundaries,
    required this.scale,
    required this.context,
  }) {
    myPaint.color = ColorAssets.theme;
    myPaint.strokeWidth = 1;
    myPaint.style = PaintingStyle.stroke;

    cornerPaint.color = ColorAssets.theme;
    cornerPaint.strokeWidth = 1;
    cornerPaint.style = PaintingStyle.fill;

    radiusPaint.color = ColorAssets.theme;
    radiusPaint.strokeWidth = 1;
    radiusPaint.style = PaintingStyle.stroke;
    paintOuter.color = ColorAssets.black.withOpacity(0.1);
    paintOuter.strokeWidth = 0.5;
    distanceLinePainter.strokeWidth = 1 * scale;
    paintOuter.style = PaintingStyle.stroke;
    fillPaint.color = ColorAssets.white.withOpacity(0.7);
    fillPaint.style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    myPaint.color = ColorAssets.theme.withOpacity(0.6);

    myPaint.strokeWidth = scale * 1;
    paintOuter.strokeWidth = scale * 1;
    for (final boundary in hoverBoundaries) {
      if (!boundaries.contains(boundary)) {
        drawSelection(context, canvas, ColorAssets.darkerGrey, size, boundary);
      }
    }
    for (final boundary in boundaries) {
      if (boundary.comp is CRenderModel ||
          (boundary.comp is CLeafRenderModel &&
              (boundary.comp as CLeafRenderModel).fixedSize != null)) {
        final size = (boundary.comp is CRenderModel)
            ? (boundary.comp as CRenderModel).size
            : (boundary.comp as CLeafRenderModel).fixedSize!;
        final rect = boundary.rect;
        drawSelection(
            context,
            canvas,
            ColorAssets.theme,
            size,
            Boundary(
                Rect.fromLTWH(
                    rect.left,
                    rect.top,
                    rect.width,

                    /// TODO: Update this logic => size.width.isFinite ? size.width : rect.width,
                    rect.height

                    /// size.height.isFinite ? size.height : rect.height
                    ),
                boundary.comp,
                errorMessage: boundary.errorMessage,
                onTap: boundary.onTap),
            selection: true);
      } else {
        drawSelection(context, canvas, ColorAssets.theme, size, boundary);
      }
    }
    double centerXPoint(Rect rect1, Rect rect2) {
      final left = max(rect1.left, rect2.left);
      final right = min(rect1.right, rect2.right);
      return (left + right) / 2;
    }

    double centerYPoint(Rect rect1, Rect rect2) {
      final top = max(rect1.top, rect2.top);
      final bottom = min(rect1.bottom, rect2.bottom);
      return (top + bottom) / 2;
    }

    for (int i = 0; i < hoverBoundaries.length; i++) {
      for (int j = 0; j < boundaries.length; j++) {
        final hrect = hoverBoundaries[i].rect;
        final brect = boundaries[j].rect;
        if (hrect.top < brect.top && hrect.bottom < brect.top) {
          final p1 = Offset(centerXPoint(hrect, brect), hrect.bottom);
          drawDistanceLine(canvas, p1, brect.top - p1.dy, false);
        } else if (hrect.top > brect.top && brect.bottom < hrect.top) {
          final p1 = Offset(centerXPoint(hrect, brect), hrect.top);
          drawDistanceLine(canvas, p1, brect.bottom - p1.dy, false);
        }
        if (hrect.left < brect.left && hrect.right < brect.left) {
          final p1 = Offset(hrect.right, centerYPoint(hrect, brect));
          drawDistanceLine(canvas, p1, brect.left - p1.dx, true);
        } else if (hrect.left > brect.left && brect.right < hrect.left) {
          final p1 = Offset(hrect.left, centerYPoint(hrect, brect));
          drawDistanceLine(canvas, p1, brect.right - p1.dx, true);
        }
      }
    }
    for (final boundary in errorBoundaries) {
      drawSelection(context, canvas, Colors.red, size, boundary);
    }
  }

  void drawDottedLine(
      Canvas canvas, Offset point1, Offset point2, Paint paint) {
    final step = 4 * scale;
    final diff = (point2 - point1);
    final gap = diff.distance;
    for (double i = 0; i < gap; i += 2 * step) {
      canvas.drawLine(point1 + ((diff * i) / gap),
          point1 + ((diff * (i + step)) / gap), paint);
    }
  }

  void drawDistanceLine(
      Canvas canvas, Offset point1, double end, bool horizontal) {
    final endOffset =
        horizontal ? point1.translate(end, 0) : point1.translate(0, end);
    drawDottedLine(canvas, point1, endOffset, distanceLinePainter);
    final TextPainter painter = TextPainter(
      text: TextSpan(
          text:
              '${horizontal ? (endOffset.dx - point1.dx).abs().toStringAsFixed(2) : (endOffset.dy - point1.dy).abs().toStringAsFixed(2)}',
          style: AppFontStyle.lato(8 * scale, color: Colors.white)),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    final point = point1 +
        ((endOffset - point1) / 2) +
        Offset(horizontal ? 0 : 10, horizontal ? 10 : 0);
    drawText(
      painter,
      canvas,
      point.dx - (horizontal ? painter.width / 2 : 0),
      point.dy - (!horizontal ? painter.height / 2 : 0),
      Colors.grey,
    );
  }

  void drawSelection(BuildContext context, Canvas canvas, Color color,
      Size size, Boundary boundary,
      {bool selection = false}) {
    myPaint.color = color;
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
      text:
          '${boundary.errorMessage ?? StringOperation.toNormalCase(boundary.comp.name)} (${boundary.rect.width.toStringAsFixed(2)} x ${boundary.rect.height.toStringAsFixed(2)})',
      style: TextStyle(
        fontSize: 10 * scale,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout(maxWidth: 300);
    fillPaint.color = color;
    painter.layout();
    // canvas.drawRect(
    //     Rect.fromPoints(Offset(boundary.rect.left, boundary.rect.top - painter.height),
    //         Offset(boundary.rect.left + painter.width, boundary.rect.top)),
    //     fillPaint);
    drawText(
      painter,
      canvas,
      boundary.rect.center.dx,
      boundary.rect.bottom,
      color,
    );

    if (boundary.comp is Resizable && selection) {
      final radius = 3.0 * scale;
      canvas.drawCircle(boundary.rect.topLeft, radius, cornerPaint);
      canvas.drawCircle(boundary.rect.bottomLeft, radius, cornerPaint);
      canvas.drawCircle(boundary.rect.bottomRight, radius, cornerPaint);
      canvas.drawCircle(boundary.rect.topRight, radius, cornerPaint);
      // if((boundary.comp as Resizable).canUpdateRadius){
      //   canvas.drawCircle( boundary.rect.topLeft+radiusOffset, radius, radiusPaint);
      //   canvas.drawCircle( boundary.rect.bottomLeft+Offset(radiusOffset.dx, -radiusOffset.dy), radius, radiusPaint);
      //   canvas.drawCircle( boundary.rect.topRight+Offset(-radiusOffset.dx, radiusOffset.dy), radius, radiusPaint);
      //   canvas.drawCircle( boundary.rect.bottomRight+Offset(-radiusOffset.dx, -radiusOffset.dy), radius, radiusPaint);
      // }
    }
  }

  void drawText(
      TextPainter painter, Canvas canvas, double x, double y, Color color) {
    final gap = 8 * scale;
    final padding = 4 * scale;
    final w = painter.width + 2 * padding;
    final h = painter.height + 2 * padding;
    final l = x - (w / 2);
    final t = y + gap;
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(l, t, w, h), Radius.circular(4 * scale));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = ColorAssets.colorD0D5EF
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 0.5),
    );
    canvas.drawRRect(rrect, fillPaint..color = color);
    painter.paint(canvas, Offset(l + padding, y + gap + padding));
  }

  @override
  bool shouldRepaint(covariant BoundaryPainter oldDelegate) {
    return oldDelegate.boundaries != boundaries ||
        oldDelegate.hoverBoundaries != hoverBoundaries ||
        oldDelegate.errorBoundaries != errorBoundaries;
  }
}
