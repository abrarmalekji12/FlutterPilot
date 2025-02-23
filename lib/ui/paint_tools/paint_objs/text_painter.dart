import 'package:flutter/material.dart';

import '../../../common/extension_util.dart';

class FVBTextPainter extends CustomPainter {
  final Color color;
  final bool filled;
  final double width;
  final double height;
  final double radius;
  final double rotation;
  final String text;
  final String fontFamily;
  final double fontSize;
  final Color fontColor;
  final TextAlign textAlign;
  final bool bold, italic;

  FVBTextPainter({
    required this.color,
    required this.width,
    required this.height,
    required this.radius,
    required this.text,
    required this.rotation,
    required this.fontFamily,
    required this.fontSize,
    required this.textAlign,
    required this.filled,
    required this.fontColor,
    required this.bold,
    required this.italic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: fontColor,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    painter.layout(
      maxWidth: width,
    );
    final pivot = painter.size.center(Offset.zero);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(rotation.toRadian);
    canvas.translate(-pivot.dx, -pivot.dy);
    if (filled) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, width, height), Radius.circular(radius)),
          Paint()
            ..style = PaintingStyle.fill
            ..color = color);
    }
    painter.paint(canvas, getOffset(size, painter.size));

    canvas.restore();
  }

  Offset getOffset(Size size, Size textSize) {
    switch (textAlign) {
      case TextAlign.start:
      case TextAlign.left:
        return Offset.zero;
      case TextAlign.right:
      case TextAlign.end:
        return Offset(size.width - textSize.width, 0);
      case TextAlign.center:
      case TextAlign.justify:
        return Offset((size.width - textSize.width) / 2, 0);
    }
  }

  @override
  bool shouldRepaint(FVBTextPainter old) =>
      color != old.color ||
      width != old.width ||
      height != old.height ||
      radius != old.radius ||
      text != old.text ||
      rotation != old.rotation ||
      fontFamily != old.fontFamily ||
      fontSize != old.fontSize ||
      textAlign != old.textAlign ||
      filled != old.filled ||
      fontColor != old.fontColor ||
      bold != old.bold ||
      italic != old.italic;
}
