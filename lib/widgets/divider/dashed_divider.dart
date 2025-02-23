import 'package:flutter/material.dart';

class DashedLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Axis direction;
  final double dash;
  final double gap;

  const DashedLine(
      {Key? key,
      required this.width,
      required this.height,
      required this.color,
      required this.direction,
      this.gap = 2,
      this.dash = 2})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: DashedLinePainter(direction, color, dash, gap),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Axis axis;
  final Color color;
  final double dash;
  final double gap;

  DashedLinePainter(this.axis, this.color, this.dash, this.gap);

  @override
  void paint(Canvas canvas, Size size) {
    final filledPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final limit = size.height;
    for (double i = 0; i < limit; i += gap + dash) {
      if (axis == Axis.horizontal) {
        canvas.drawRect(Rect.fromLTWH(i, 0, dash, size.height), filledPaint);
      } else {
        canvas.drawRect(Rect.fromLTWH(0, i, size.width, dash), filledPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

const dashedLineDotDartCode = '''
import 'package:flutter/material.dart';

class DashedLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Axis direction;
  final double dash;
  final double gap;

  const DashedLine(
      {Key? key, required this.width, required this.height, required this.color, required this.direction, this.gap = 2,this.dash = 2})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: DashedLinePainter(direction, color, dash,gap),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Axis axis;
  final Color color;
  final double dash;
  final double gap;

  DashedLinePainter(this.axis, this.color, this.dash, this.gap);

  @override
  void paint(Canvas canvas, Size size) {
    final filledPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final limit = size.height;
    for (double i = 0; i < limit; i += gap+dash) {
      if(axis==Axis.horizontal) {
        canvas.drawRect(Rect.fromLTWH(i, 0, dash, size.height), filledPaint);
      }
      else{
        canvas.drawRect(Rect.fromLTWH(0, i,  size.width,dash), filledPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

''';
