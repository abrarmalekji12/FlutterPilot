import 'package:flutter/material.dart';
import '../constant/app_colors.dart';
import '../screen_model.dart';
import 'preview_ui.dart';

class ConnectionPainter extends CustomPainter {
  final List<Line> list;
  final myPaint = Paint();
  final ScreenConfig _screenConfig;
  ConnectionPainter(this.list, this._screenConfig);
  @override
  void paint(Canvas canvas, Size size) {
    myPaint.color = Colors.black;
    myPaint.strokeWidth = 2;
    for (final Line line in list) {
      final offset1 = getPosition(line.key1);
      final offset2 = getPosition(line.key2);
      myPaint.color = Colors.grey;
      canvas.drawLine(offset1, offset2, myPaint);
      myPaint.color = Colors.grey.withOpacity(0.3);
      canvas.drawCircle(offset1, 20, myPaint);
      myPaint.color = Colors.grey.withOpacity(0.5);
      canvas.drawCircle(offset1, 10, myPaint);
      myPaint.color = AppColors.theme.withOpacity(0.1);
      canvas.drawCircle(offset2, 50, myPaint);

      myPaint.color = AppColors.theme.withOpacity(0.3);
      canvas.drawCircle(offset2, 25, myPaint);

      myPaint.color = AppColors.theme.withOpacity(0.5);
      canvas.drawCircle(offset2, 10, myPaint);
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return true;
  }

  Offset getPosition(final GlobalObjectKey globalKey) {
    final RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero,
        ancestor: (const GlobalObjectKey('STACK')
            .currentContext!
            .findRenderObject()));
    return Offset(offset.dx + renderBox.size.width / 2,
        offset.dy + renderBox.size.height / 2);
  }
}
