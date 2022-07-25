import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'code_processor.dart';
import 'fvb_classes.dart';

class PainterWrapper extends CustomPainter {
  final CodeProcessor processor;
  final canvasClass = FVBModuleClasses.fvbClasses['Canvas']!;
  final sizeClass = FVBModuleClasses.fvbClasses['Size']!;

  PainterWrapper(this.processor);

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.draw
    canvasClass.fvbFunctions['drawPoint']!.dartCall = (arguments) {
      canvas.drawRect(Rect.fromPoints(Offset(0, 0), Offset(100, 100)),
          Paint()..color = Colors.red);
    };

    canvasClass.fvbFunctions['drawRect']!.dartCall = (arguments) {
      final rect = (arguments[0] as FVBInstance?)?.toDart();
      final paint = (arguments[1] as FVBInstance?)?.toDart();
      print('HERE ${(rect as Rect).bottom}');
      if (CodeProcessor.operationType == OperationType.regular) {
        canvas.drawRect(rect, paint);
      }
    };

    processor.functions['paint']?.execute(processor, [
      canvasClass.createInstance(processor, []),
      sizeClass.createInstance(processor, [size.width,size.height])
    ]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return processor.functions['shouldRepaint']
            ?.execute(processor, [oldDelegate]) ??
        true;
  }
}
