import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'code_processor.dart';
import 'fvb_classes.dart';


class PainterWrapper extends CustomPainter{
  final CodeProcessor processor;
  final canvasClass=FVBModuleClasses.fvbClasses['Canvas']!;
  final sizeClass= FVBModuleClasses.fvbClasses['Size']!;

  PainterWrapper(this.processor);
  @override
  void paint(Canvas canvas, Size size) {
    // canvas.draw
  canvasClass.fvbFunctions['drawPoint']!.dartCall=
        (arguments){
      canvas.drawRect(Rect.fromPoints(Offset(0,0), Offset(100,100)), Paint()..color=Colors.red);
    };

  canvasClass.fvbFunctions['drawRect']!.dartCall=
      (arguments){
    canvas.drawRect((arguments[0] as FVBInstance?)?.toDart(), (arguments[1] as FVBInstance?)?.toDart());
  };
    processor.functions['paint']?.execute(processor, [canvasClass.createInstance(processor, []),sizeClass.createInstance(processor, [])..variables['width']!.value=size.width..variables['height']!.value=size.height]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return  processor.functions['shouldRepaint']?.execute(processor, [oldDelegate])??true;
  }

}