import 'package:flutter/material.dart';

import 'code_processor.dart';
import 'fvb_classes.dart';

class PainterWrapper extends CustomPainter {
  final CodeProcessor processor;
  final canvasClass = FVBModuleClasses.fvbClasses['Canvas']!;
  final sizeClass = FVBModuleClasses.fvbClasses['Size']!;

  PainterWrapper(this.processor);

  @override
  void paint(Canvas canvas, Size size) {
    processor.functions['paint']?.execute(processor, null, [
      canvasClass.createInstance(processor, [canvas]),
      sizeClass.createInstance(processor, [size.width, size.height])
    ]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return processor.functions['shouldRepaint']
            ?.execute(processor, null, [oldDelegate]) ??
        true;
  }
}
