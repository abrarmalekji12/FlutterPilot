import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:provider/provider.dart';

import '../../bloc/paint_obj/paint_obj_bloc.dart';
import '../../bloc/state_management/state_management_bloc.dart';
import '../../code_operations.dart';
import '../../common/app_switch.dart';
import '../../common/extension_util.dart';
import '../../components/component_impl.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/local_model.dart';
import '../../models/other_model.dart';
import '../../runtime_provider.dart';
import '../boundary_widget.dart';
import '../fvb_code_editor.dart';
import '../home/editing_view.dart';
import '../parameter_ui.dart';
import 'paint_objs/circle_painter.dart';
import 'paint_objs/image_painter.dart';
import 'paint_objs/rect_painter.dart';
import 'paint_objs/text_painter.dart';
import 'paint_objs/triangle_painter.dart';

abstract class PaintParameter<T> {
  final String name;
  final bool nullable;
  T? value;
  String code = '';

  PaintParameter(this.name, this.nullable, this.value) {
    code = LocalModel.valueToCode(value);
  }

  String get dartCode;

  Map<String, dynamic> toJson() {
    dynamic v;

    if (T == Color) {
      v = (value as Color).value;
    } else {
      v = value;
    }
    return {
      'name': name,
      'value': v,
      'code': code,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    value = getValue(json);
    code = json['code'];
  }

  T? getValue(json) {
    if (json['value'] == null) {
      return null;
    }
    if (T == double) {
      return double.tryParse(json['value']!.toString()) as T;
    }
    if (T == int) {
      return int.tryParse(json['value']!.toString()) as T;
    }

    return (T == Color ? Color(json['value']) : json['value']) as T;
  }

  void setCode(String c, Processor processor) {
    this.code = c;
    final v = processor
        .process(CodeOperations.trim(code)!, config: const ProcessorConfig())
        .value;
    if (T == double && v is int) {
      value = v.toDouble() as T;
    } else {
      if (v == null) {
        if (T == int) {
          value = 0 as T;
        } else if (T == double) {
          value = 0.0 as T;
        } else if (T == String) {
          value = '' as T;
        } else if (T == Color) {
          value = ColorAssets.black as T;
        }
      } else {
        value = v;
      }
    }
  }
}

class DoubleParameter extends PaintParameter<double> {
  DoubleParameter(super.name, super.nullable, super.value);

  @override
  String get dartCode => switch (name) {
        'left' ||
        'right' ||
        'width' =>
          '${(value! / selectedConfig!.width).toStringAsFixed(2)}.w',
        'top' ||
        'bottom' ||
        'height' =>
          '${(value! / selectedConfig!.height).toStringAsFixed(2)}.h',
        _ => value?.toStringAsFixed(2) ?? ''
      };
}

class StringParameter extends PaintParameter<String> {
  StringParameter(super.name, super.nullable, super.value);

  @override
  String get dartCode => '"${value ?? ''}"';
}

class ImageParameter extends PaintParameter<FVBImage> {
  ImageParameter(super.name, super.nullable, super.value);

  @override
  String get dartCode => throw UnimplementedError();
}

class ColorParameter extends PaintParameter<Color> {
  ColorParameter(super.name, super.nullable, super.value);

  @override
  String get dartCode => value != null
      ? 'Color(0x${value?.value.toRadixString(16)})'
      : 'Colors.transparent';
}

class BoolParameter extends PaintParameter<bool> {
  BoolParameter(super.name, super.nullable, super.value);

  @override
  String get dartCode => '$value';
}

class EnumParameter<T> extends PaintParameter<Enum> {
  final List<Enum> list;

  EnumParameter(super.name, super.nullable, super.value, this.list);

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value?.index,
      'code': code,
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    value = (json['value'] != null ? list[json['value']] : null);
    code = json['code'];
  }

  @override
  String get dartCode => value?.toString() ?? '';
}

abstract class FVBPaintObj {
  final String name;
  String id = DateTime.now().millisecondsSinceEpoch.toString();
  final List<PaintParameter> parameters;

  FVBPaintObj(
    this.name,
    this.parameters,
  );

  CustomPainter get painter;

  Size get size;

  double get rotation;

  Rect get boundary;

  String get dartCode;

  void onResize(Size size);

  void onMove(Offset offset);

  void onRotate(double angle);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parameters': parameters.map((e) => e.toJson()).toList(growable: false)
      };

  factory FVBPaintObj.fromJson(Map<String, dynamic> map) {
    final FVBPaintObj obj;
    switch (map['name']) {
      case 'Rect':
        obj = RectObj();
        break;
      case 'Circle':
        obj = CircleObj();
        break;
      case 'SemiCircle':
        obj = SemiCircleObj();
        break;
      case 'Triangle':
        obj = TriangleObj();
        break;
      case 'Text':
        obj = TextObj();
        break;
      default:
        throw Exception('Unknown obj ${map['name']}');
    }
    obj.id = map['id'];
    final params = List.of(map['parameters']);
    obj.parameters.asMap().entries.forEach((element) {
      if (params.length > element.key) {
        element.value.fromJson(params[element.key]);
      }
    });
    return obj;
  }

  FVBPaintObj get clone {
    return FVBPaintObj.fromJson(toJson());
  }
}

abstract class DefinedShapeObj extends FVBPaintObj {
  DefinedShapeObj(String name, List<PaintParameter> parameters)
      : super(name, [
          ColorParameter('color', false, ColorAssets.black),
          BoolParameter('fill', false, false),
          DoubleParameter('stroke-width', false, 2),
          DoubleParameter('left', false, 10),
          DoubleParameter('top', false, 10),
          DoubleParameter('width', false, 50),
          DoubleParameter('height', false, 50),
          DoubleParameter('rotation', false, 0),
          ...parameters
        ]);

  String get transformCode => parameters[7].value > 0
      ? '''
   .transform((Matrix4.identity()
    ..translate( ${parameters[5].dartCode}/2,  ${parameters[6].dartCode}/2)
    ..rotateZ(${parameters[7].dartCode}.toRadian)
    ..translate(-${parameters[5].dartCode}/2, -${parameters[6].dartCode}/2)).storage)
  '''
      : '';

  @override
  Size get size => Size(parameters[5].value, parameters[6].value);

  @override
  void onResize(Size size) {
    parameters[5].value += size.width;
    parameters[6].value += size.height;
  }

  @override
  double get rotation => parameters[7].value;

  @override
  Rect get boundary => Rect.fromLTWH(parameters[3].value, parameters[4].value,
      parameters[5].value, parameters[6].value);

  @override
  void onMove(Offset offset) {
    parameters[3].value += offset.dx;
    parameters[4].value += offset.dy;
  }

  @override
  void onRotate(double angle) {
    parameters[7].value = angle;
  }
}

// class MyTestPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     List<dynamic> parameters;
//     Paint paint;
//     paint = Paint();
//     paint.color = ${
//       parameters[0].dartCode
//     };
//     paint.style = ${
//       parameters[1].value == true ? 'PaintingStyle.fill' : 'PaintingStyle.stroke'
//     };
//     paint.strokeWidth = ${
//       parameters[2].dartCode
//     };
//     canvas.drawPath(
//         Path()
//           ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(
//             ${parameters[3].dartCode}, ${parameters[4].dartCode}, ${parameters[4].dartCode}, $
//             {parameters[4].dartCode},),))
//               .transform((Matrix4.identity()
//             ..translate(width / 2, height / 2)
//             ..rotateZ(rotation.toRadian)
//             ..translate(-width / 2, -height / 2)).storage)
//         , paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
//
// }

class RectObj extends DefinedShapeObj {
  RectObj()
      : super('Rect', [
          DoubleParameter('border-radius', false, null),
        ]);

  @override
  CustomPainter get painter => RectPainter(
      color: parameters[0].value,
      filled: parameters[1].value,
      strokeWidth: parameters[2].value,
      width: parameters[5].value,
      height: parameters[6].value,
      rotation: parameters[7].value,
      radius: parameters[8].value ?? 0);

  @override
  String get dartCode => '''
    paint=Paint();
    paint.color=${parameters[0].dartCode};
    paint.style=${parameters[1].value == true ? 'PaintingStyle.fill' : 'PaintingStyle.stroke'};
    paint.strokeWidth=${parameters[2].dartCode};
    canvas.drawPath(
       ( Path()
          ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(${parameters[3].dartCode},${parameters[4].dartCode},${parameters[5].dartCode},${parameters[6].dartCode},),Radius.circular(${parameters[8].dartCode}),),))
      ${transformCode}
        , paint);
  ''';
}

class ImageObj extends DefinedShapeObj {
  ImageObj()
      : super('Image', [
          DoubleParameter('border-radius', false, null),
          ImageParameter('image', false, null),
        ]);

  @override
  CustomPainter get painter => ImagePainter(
      color: parameters[0].value,
      filled: parameters[1].value,
      strokeWidth: parameters[2].value,
      width: parameters[5].value,
      height: parameters[6].value,
      rotation: parameters[7].value,
      radius: parameters[8].value ?? 0,
      image: parameters[9].value);

  /// TODO: Yet to Implement
  @override
  String get dartCode => '';
}

class TextObj extends DefinedShapeObj {
  TextObj()
      : super('Text', [
          DoubleParameter('background-radius', false, 10),
          StringParameter('text', false, 'text'),
          DoubleParameter('font-size', false, 18),
          StringParameter('font-family', false, 'arial'),
          ColorParameter('font-color', false, ColorAssets.black),
          EnumParameter<TextAlign>(
              'text-align', false, TextAlign.start, TextAlign.values),
          BoolParameter('bold', false, false),
          BoolParameter('italic', false, false),
        ]);

  @override
  CustomPainter get painter => FVBTextPainter(
        color: parameters[0].value,
        filled: parameters[1].value,
        width: parameters[5].value,
        height: parameters[6].value,
        rotation: parameters[7].value,
        radius: parameters[8].value,
        text: parameters[9].value,
        fontSize: parameters[10].value,
        fontFamily: parameters[11].value,
        fontColor: parameters[12].value,
        textAlign: parameters[13].value,
        bold: parameters[14].value,
        italic: parameters[15].value,
      );

  @override
  String get dartCode => '''
   canvas.save();
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: ${parameters[9].dartCode},
        style: TextStyle(
            color: ${parameters[12].dartCode},
            fontSize: ${parameters[10].dartCode},
            fontWeight: ${parameters[14].dartCode} ? FontWeight.bold : FontWeight.normal,
            fontStyle: ${parameters[15].dartCode} ? FontStyle.italic : FontStyle.normal),
      ),
      textAlign: ${parameters[13].dartCode},
      textDirection: TextDirection.ltr,
    );
    painter.layout(
      maxWidth: ${parameters[5].dartCode},
    );
    final pivot = painter.size.center(Offset.zero);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(${parameters[7].dartCode}.toRadian);
    canvas.translate(-pivot.dx, -pivot.dy);
    if (${parameters[1].dartCode}) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(${parameters[3].dartCode}, ${parameters[4].dartCode},${parameters[5].dartCode},${parameters[6].dartCode},),Radius.circular(${parameters[8].dartCode}), Paint()
            ..style = PaintingStyle.fill
            ..color = ${parameters[0].dartCode});
    }
    painter.paint(canvas, getOffset(size, painter.size));
    canvas.restore();
  ''';
}

class CircleObj extends DefinedShapeObj {
  CircleObj() : super('Circle', []);

  @override
  Size get size => Size(parameters[5].value * 2, parameters[5].value * 2);

  @override
  CustomPainter get painter => CirclePainter(
        color: parameters[0].value,
        filled: parameters[1].value,
        strokeWidth: parameters[2].value,
        width: parameters[5].value,
        height: parameters[6].value,
        angle: parameters[7].value,
      );

  @override
  String get dartCode => '''
   canvas.drawPath(
        (Path()
              ..addArc(Rect.fromLTWH(${parameters[3].dartCode}, ${parameters[4].dartCode}, ${parameters[5].dartCode}, ${parameters[6].dartCode}), 0, 2 * pi)
              ..close()),
        Paint()
          ..style = ${parameters[1].dartCode}?PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = ${parameters[2].dartCode}
          ..color = ${parameters[0].dartCode});
  ''';
}

class SemiCircleObj extends DefinedShapeObj {
  SemiCircleObj() : super('SemiCircle', []) {
    parameters[5].value = 100.0;
  }

  @override
  Size get size => Size(parameters[5].value, parameters[6].value);

  @override
  CustomPainter get painter => CirclePainter(
      color: parameters[0].value,
      filled: parameters[1].value,
      strokeWidth: parameters[2].value,
      width: parameters[5].value,
      height: parameters[6].value,
      angle: parameters[7].value,
      semi: true);

  @override
  String get dartCode => '''
   canvas.drawPath(
        (Path()
              ..addArc(Rect.fromLTWH(0, 0,${parameters[5].dartCode}, ${parameters[6].dartCode} * 2), 0,
                  -pi)
              ..close())
            $transformCode,
        Paint()
          ..style = ${parameters[1].dartCode} ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = ${parameters[2].dartCode}
          ..color = ${parameters[0].dartCode});
  ''';
}

class TriangleObj extends DefinedShapeObj {
  TriangleObj() : super('Triangle', []);

  @override
  Size get size => Size(parameters[5].value, parameters[6].value);

  @override
  CustomPainter get painter => TrianglePainter(
        color: parameters[0].value,
        filled: parameters[1].value,
        strokeWidth: parameters[2].value,
        width: parameters[5].value,
        height: parameters[6].value,
        angle: parameters[7].value,
      );

  @override
  String get dartCode => '''
    canvas.drawPath(
        (Path()
      ..moveTo((${parameters[5].dartCode} / 2), 0)
      ..lineTo(${parameters[5].dartCode}, ${parameters[6].dartCode})
      ..lineTo(0, ${parameters[6].dartCode})
      ..close()).shift(Offset(${parameters[3].dartCode},${parameters[4].dartCode}))$transformCode,
        Paint()
          ..style = ${parameters[1].dartCode} ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = ${parameters[2].dartCode}
          ..color = ${parameters[0].dartCode});
  ''';
}

abstract class FVBPaintTool {
  final String name;
  final String image;

  FVBPaintTool(this.name, this.image);

  FVBPaintObj get obj;
}

class RectTool extends FVBPaintTool {
  RectTool() : super('Rect', 'rect.png');

  @override
  FVBPaintObj get obj => RectObj();
}

class CircleTool extends FVBPaintTool {
  CircleTool() : super('Oval', 'circle.png');

  FVBPaintObj get obj => CircleObj();
}

class SemiCircleTool extends FVBPaintTool {
  SemiCircleTool() : super('Semi-Circle', 'semicircle.png');

  FVBPaintObj get obj => SemiCircleObj();
}

class TriangleTool extends FVBPaintTool {
  TriangleTool() : super('Triangle', 'triangle.png');

  FVBPaintObj get obj => TriangleObj();
}

class TextTool extends FVBPaintTool {
  TextTool() : super('Text', 'text.png');

  @override
  FVBPaintObj get obj => TextObj();
}

final List<FVBPaintTool> objects = [
  RectTool(),
  CircleTool(),
  SemiCircleTool(),
  TriangleTool(),
  TextTool(),
];
const resizePaintBarSize = 10.0;
const resizePaintHalfSize = resizePaintBarSize / 2;

class PaintViewWidget extends StatefulWidget {
  final FVBPainter paint;
  final ScaleNotifier scaleNotifier;

  const PaintViewWidget(
      {Key? key, required this.paint, required this.scaleNotifier})
      : super(key: key);

  @override
  State<PaintViewWidget> createState() => _PaintViewWidgetState();
}

class _PaintViewWidgetState extends State<PaintViewWidget> {
  late PaintObjBloc _paintObjBloc;
  int lastTapped = 0;

  @override
  void initState() {
    _paintObjBloc = context.read<PaintObjBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final boundary = (widget.paint as Component).boundary!;
    final factor = widget.scaleNotifier.scaleValue;

    return ChangeNotifierProvider<PainterNotifier>(
      create: (context) => PainterNotifier(widget.paint),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              height: 30 * factor,
              child: Card(
                elevation: 4,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemBuilder: (context, i) => PaintObjIconWidget(
                    paintObj: objects[i],
                    paintTools: widget.paint,
                    factor: factor,
                  ),
                  itemCount: objects.length,
                  scrollDirection: Axis.horizontal,
                ),
              )),
          SizedBox(
            height: 5 * factor,
          ),
          Consumer<PainterNotifier>(
            builder: (BuildContext context, value, Widget? child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final obj in widget.paint.paintObjects)
                    BlocBuilder<PaintObjBloc, PaintObjState>(
                        buildWhen: (state1, state2) =>
                            state2 is PaintObjSelectionUpdatedState ||
                            (state2 is PaintObjUpdateState &&
                                state2.obj == obj),
                        builder: (context, state) {
                          final rect = obj.boundary;
                          final boundary =
                              Rect.fromLTWH(0, 0, rect.width, rect.height);
                          final selected = _paintObjBloc.paintObj == obj;
                          return Positioned(
                            left: rect.left - (selected ? 4 : 0),
                            top: rect.top - (selected ? 28 : 0),
                            child: selected
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RotationIcon(
                                        obj: obj,
                                        paintTools: widget.paint,
                                      ),
                                      SizedBox(
                                        width: rect.width + 8,
                                        height: rect.height + 8,
                                        child: Stack(
                                          children: [
                                            DottedBorder(
                                                borderType: BorderType.RRect,
                                                radius:
                                                    const Radius.circular(4),
                                                dashPattern: [4, 4],
                                                strokeCap: StrokeCap.round,
                                                strokeWidth: 1,
                                                padding:
                                                    const EdgeInsets.all(4),
                                                color: Colors.black,
                                                child: Container()),
                                            _buildMovable(boundary, rect, obj,
                                                widget.paint)
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : SizedBox(
                                    width: rect.width + resizePaintHalfSize,
                                    height: rect.height + resizePaintHalfSize,
                                    child: _buildMovable(
                                        boundary, rect, obj, widget.paint),
                                  ),
                          );
                        }),
                  Container(
                    width: boundary.width,
                    height: boundary.height,
                    child: GestureDetector(
                      onTapDown: (details) {
                        lastTapped = DateTime.now().millisecondsSinceEpoch;
                      },
                      onTapUp: (details) {
                        if (DateTime.now().millisecondsSinceEpoch - lastTapped <
                            500) {
                          final position = details.localPosition;
                          double? minArea;
                          FVBPaintObj? obj;
                          for (final bound in widget.paint.paintObjects) {
                            final b = bound.boundary;
                            if (b.contains(position) &&
                                (minArea == null || minArea > b.area)) {
                              minArea = b.area;
                              obj = bound;
                            }
                          }
                          if (obj != null) {
                            widget.paint.paintObjects.remove(obj);
                            widget.paint.paintObjects.add(obj);
                          }
                          _paintObjBloc.add(UpdatePaintObjSelectionEvent(obj));
                        }
                        lastTapped = -1;
                      },
                    ),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  _buildMovable(boundary, rect, obj, FVBPainter paint) => Stack(
        children: [
          if (obj == _paintObjBloc.paintObj) ...[
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: MovablePaintCursor(
                width: boundary.width,
                height: boundary.height,
                obj: obj,
              ),
            ),
            Positioned(
              left: boundary.left,
              top: boundary.top,
              child: ResizablePaintCursor(
                axis: ResizeAxis.horizontal,
                upper: true,
                width: boundary.width,
                height: boundary.height,
                object: obj,
              ),
            ),
            Positioned(
              left: boundary.right,
              top: boundary.top,
              child: ResizablePaintCursor(
                axis: ResizeAxis.horizontal,
                upper: false,
                width: boundary.width,
                height: boundary.height,
                object: obj,
              ),
            ),
            Positioned(
              left: boundary.left,
              top: boundary.top,
              child: ResizablePaintCursor(
                axis: ResizeAxis.vertical,
                upper: true,
                width: boundary.width,
                height: boundary.height,
                object: obj,
              ),
            ),
            Positioned(
              left: boundary.left,
              top: boundary.bottom,
              child: ResizablePaintCursor(
                axis: ResizeAxis.vertical,
                upper: false,
                width: boundary.width,
                height: boundary.height,
                object: obj,
              ),
            ),

            /// Inclined
            Positioned(
              left: boundary.left,
              top: boundary.bottom,
              child: ResizablePaintCursor(
                axis: ResizeAxis.bottomLeftToTopRight,
                upper: false,
                width: resizePaintBarSize,
                height: resizePaintBarSize,
                object: obj,
              ),
            ),
            Positioned(
              left: boundary.right,
              top: boundary.bottom,
              child: ResizablePaintCursor(
                axis: ResizeAxis.bottomRightToTopLeft,
                upper: false,
                width: resizePaintBarSize,
                height: resizePaintBarSize,
                object: obj,
              ),
            ),
            Positioned(
              left: boundary.left,
              top: boundary.top,
              child: ResizablePaintCursor(
                axis: ResizeAxis.topLeftToBottomRight,
                upper: true,
                width: resizePaintBarSize,
                height: resizePaintBarSize,
                object: obj,
              ),
            ),
            Positioned(
              left: boundary.right,
              top: boundary.top,
              child: ResizablePaintCursor(
                axis: ResizeAxis.topRightToBottomLeft,
                upper: true,
                width: resizePaintBarSize,
                height: resizePaintBarSize,
                object: obj,
              ),
            ),
          ]
        ],
      );
}

class RotationIcon extends StatefulWidget {
  final FVBPaintObj obj;
  final FVBPainter paintTools;

  const RotationIcon({
    Key? key,
    required this.obj,
    required this.paintTools,
  }) : super(key: key);

  @override
  State<RotationIcon> createState() => _RotationIconState();
}

class _RotationIconState extends State<RotationIcon> {
  @override
  Widget build(BuildContext context) {
    final center = widget.obj.boundary.center;
    return Listener(
      onPointerMove: (down) {
        final posi = (down.position) -
            (GlobalObjectKey(widget.paintTools)
                    .currentContext!
                    .findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero);
        final theta =
            atan2((posi.dy - center.dy), (posi.dx - center.dx)) + pi / 2;
        widget.obj.onRotate((theta * 180 / pi).ceilToDouble());
        context
            .read<PaintObjBloc>()
            .add(UpdatePaintObjEvent(widget.obj, refreshField: false));
      },
      onPointerUp: (_) {
        context
            .read<PaintObjBloc>()
            .add(UpdatePaintObjEvent(widget.obj, save: true));
      },
      child: const Icon(
        Icons.rotate_right,
        size: 24,
      ),
    );
  }
}

class MovablePaintCursor extends StatefulWidget {
  final double width;
  final double height;
  final FVBPaintObj obj;

  const MovablePaintCursor(
      {Key? key, required this.width, required this.obj, required this.height})
      : super(key: key);

  @override
  State<MovablePaintCursor> createState() => _MovablePaintCursorState();
}

class _MovablePaintCursorState extends State<MovablePaintCursor> {
  late PaintObjBloc paintObjBloc;

  @override
  void initState() {
    super.initState();
    paintObjBloc = context.read<PaintObjBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        widget.obj.onMove
            .call(Offset(event.localDelta.dx, event.localDelta.dy));
        paintObjBloc.add(UpdatePaintObjEvent(widget.obj, refreshField: false));
      },
      onPointerUp: (_) {
        paintObjBloc.add(UpdatePaintObjEvent(widget.obj, save: true));
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: AbsorbPointer(
          child: Container(width: widget.width, height: widget.height),
        ),
      ),
    );
  }
}

class PaintParameterSection extends StatelessWidget {
  final FVBPaintObj obj;
  final Processor processor;

  const PaintParameterSection(
      {Key? key, required this.processor, required this.obj})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Card(
        child: ListView.builder(
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            if (obj.parameters[index] is DoubleParameter) {
              return FieldInputParameterWidget<double>(
                parameter: obj.parameters[index] as DoubleParameter,
                processor: processor,
                obj: obj,
              );
            } else if (obj.parameters[index] is BoolParameter) {
              return FieldInputParameterWidget<bool>(
                parameter: obj.parameters[index] as BoolParameter,
                processor: processor,
                obj: obj,
              );
            } else if (obj.parameters[index] is ColorParameter) {
              return ColorParameterWidget(
                parameter: obj.parameters[index] as ColorParameter,
                processor: processor,
                obj: obj,
              );
            } else if (obj.parameters[index] is StringParameter) {
              return FieldInputParameterWidget<String>(
                parameter: obj.parameters[index] as StringParameter,
                processor: processor,
                obj: obj,
              );
            } else if (obj.parameters[index] is EnumParameter) {
              return EnumParameterWidget(
                parameter: obj.parameters[index] as EnumParameter,
                processor: processor,
                obj: obj,
              );
            }
            return const Offstage();
          },
          itemCount: obj.parameters.length,
        ),
      ),
    );
  }
}

class FieldInputParameterWidget<T> extends StatefulWidget {
  final PaintParameter<T> parameter;
  final Processor processor;
  final FVBPaintObj obj;

  const FieldInputParameterWidget(
      {Key? key,
      required this.parameter,
      required this.processor,
      required this.obj})
      : super(key: key);

  @override
  State<FieldInputParameterWidget<T>> createState() =>
      _FieldInputParameterWidgetState<T>();
}

class _FieldInputParameterWidgetState<T>
    extends State<FieldInputParameterWidget<T>> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaintObjBloc, PaintObjState>(
      listener: (context, state) {
        if (state is PaintObjUpdateState && state.refreshField) {
          if (T == double) {
            _controller.text =
                ((widget.parameter.value ?? 0.0) as double).toStringAsFixed(2);
          } else {
            _controller.text = widget.parameter.code;
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(
              widget.parameter.name,
              style: AppFontStyle.lato(15,
                  color: Colors.black, fontWeight: FontWeight.w600),
            ),
            const SizedBox(
              width: 10,
            ),
            if (T == bool) ...[
              BlocBuilder<PaintObjBloc, PaintObjState>(
                builder: (context, state) {
                  return AppSwitch(
                      value: (widget.parameter.value as bool?) ?? false,
                      onToggle: (value) {
                        widget.parameter.value = value as T;
                        context
                            .read<PaintObjBloc>()
                            .add(UpdatePaintObjEvent(widget.obj, save: true));
                      });
                },
              ),
              const SizedBox(
                width: 10,
              ),
            ],
            Expanded(
                child: FVBCodeEditor(
                    code: widget.parameter.code,
                    onCodeChange: (value, ref) {
                      widget.parameter.setCode(value, widget.processor);
                      context.read<PaintObjBloc>().add(UpdatePaintObjEvent(
                          widget.obj,
                          refreshField: false,
                          save: true));
                    },
                    controller: _controller,
                    onErrorUpdate: (message, v) {
                      final selectionCubit = context.read<SelectionCubit>();
                      selectionCubit.updateError(
                        selectionCubit.selected.intendedSelection,
                        message,
                        AnalysisErrorType.parameter,
                        paintParameter: widget.parameter,
                      );
                    },
                    config: FVBEditorConfig(
                        shrink: true, multiline: false, smallBottomBar: true),
                    processor: widget.processor))
          ],
        ),
      ),
    );
  }
}

class ColorParameterWidget extends StatefulWidget {
  final ColorParameter parameter;
  final Processor processor;
  final FVBPaintObj obj;

  const ColorParameterWidget(
      {Key? key,
      required this.parameter,
      required this.processor,
      required this.obj})
      : super(key: key);

  @override
  _ColorParameterWidgetState createState() => _ColorParameterWidgetState();
}

class _ColorParameterWidgetState extends State<ColorParameterWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaintObjBloc, PaintObjState>(
      buildWhen: (state1, state2) => state2 is PaintObjUpdateState,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          height: 35,
          child: Row(
            children: [
              Text(
                widget.parameter.name,
                style: AppFontStyle.lato(15,
                    color: Colors.black, fontWeight: FontWeight.w600),
              ),
              const SizedBox(
                width: 10,
              ),
              ColorButton(
                  color: widget.parameter.value ?? Colors.black,
                  decoration: BoxDecoration(
                      border: Border.all(),
                      color: widget.parameter.value ?? Colors.black,
                      shape: BoxShape.circle),
                  onColorChanged: (value) {
                    widget.parameter.value = value;
                    context.read<PaintObjBloc>().add(UpdatePaintObjEvent(
                        widget.obj,
                        refreshField: false,
                        save: true));
                  })
            ],
          ),
        );
      },
    );
  }
}

class EnumParameterWidget extends StatefulWidget {
  final EnumParameter parameter;
  final Processor processor;
  final FVBPaintObj obj;

  const EnumParameterWidget(
      {Key? key,
      required this.parameter,
      required this.processor,
      required this.obj})
      : super(key: key);

  @override
  State<EnumParameterWidget> createState() => _EnumParameterWidgetState();
}

class _EnumParameterWidgetState extends State<EnumParameterWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaintObjBloc, PaintObjState>(
      buildWhen: (state1, state2) => state2 is PaintObjUpdateState,
      builder: (context, state) {
        return Container(
          height: 45,
          child: DropdownButtonHideUnderline(
            child: Row(
              children: [
                const SizedBox(
                  width: 8,
                ),
                Text(
                  widget.parameter.name,
                  style: AppFontStyle.lato(15,
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                    child: DropdownButton<Enum>(
                  style: AppFontStyle.lato(14),
                  alignment: Alignment.center,
                  borderRadius: BorderRadius.circular(8),
                  value: widget.parameter.value,
                  items: widget.parameter.list
                      .map(
                        (e) => DropdownMenuItem<Enum>(
                          value: e,
                          child: Text(
                            e.name,
                            style: AppFontStyle.lato(14),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    widget.parameter.value = value;
                    context
                        .read<PaintObjBloc>()
                        .add(UpdatePaintObjEvent(widget.obj, save: true));
                  },
                ))
              ],
            ),
          ),
        );
      },
    );
  }
}

class ResizablePaintCursor extends StatelessWidget {
  final ResizeAxis axis;
  final double width;
  final double height;
  final bool upper;
  final FVBPaintObj object;

  const ResizablePaintCursor(
      {Key? key,
      required this.axis,
      required this.width,
      required this.height,
      required this.upper,
      required this.object})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        if (axis == ResizeAxis.horizontal) {
          final update = event.localDelta.dx * (upper ? -1 : 1);
          object.onResize.call(Size(update, 0));
          if (upper) {
            object.onMove(Offset(-update, 0));
          }
        } else if (axis == ResizeAxis.vertical) {
          final update = event.localDelta.dy * (upper ? -1 : 1);
          object.onResize.call(Size(0, update));
          if (upper) {
            object.onMove(Offset(0, -update));
          }
        } else if (axis == ResizeAxis.bottomLeftToTopRight) {
          object.onResize.call(Size(event.localDelta.dy, event.localDelta.dy));
          object.onMove(Offset(-event.localDelta.dy, 0));
        } else if (axis == ResizeAxis.bottomRightToTopLeft) {
          object.onResize.call(Size(event.localDelta.dy, event.localDelta.dy));
        } else if (axis == ResizeAxis.topLeftToBottomRight) {
          object.onResize
              .call(Size(-event.localDelta.dy, -event.localDelta.dy));
          object.onMove(Offset(event.localDelta.dy, event.localDelta.dy));
        } else if (axis == ResizeAxis.topRightToBottomLeft) {
          object.onResize
              .call(Size(-event.localDelta.dy, -event.localDelta.dy));
          object.onMove(Offset(0, event.localDelta.dy));
        }

        context
            .read<PaintObjBloc>()
            .add(UpdatePaintObjEvent(object, refreshField: false));
      },
      onPointerUp: (_) {
        context
            .read<PaintObjBloc>()
            .add(UpdatePaintObjEvent(object, save: true));
      },
      child: MouseRegion(
        cursor: cursor,
        child: AbsorbPointer(
          child: Container(
            width: axis == ResizeAxis.vertical
                ? max(width, 20)
                : resizePaintBarSize,
            height: axis == ResizeAxis.vertical
                ? resizePaintBarSize
                : max(height, 20),
          ),
        ),
      ),
    );
  }

  MouseCursor get cursor {
    if (axis == ResizeAxis.vertical) {
      return SystemMouseCursors.resizeUpDown;
    } else if (axis == ResizeAxis.horizontal) {
      return SystemMouseCursors.resizeLeftRight;
    } else if (axis == ResizeAxis.bottomLeftToTopRight) {
      return SystemMouseCursors.resizeUpRightDownLeft;
    } else if (axis == ResizeAxis.topRightToBottomLeft) {
      return SystemMouseCursors.resizeUpRightDownLeft;
    } else {
      return SystemMouseCursors.resizeUpLeftDownRight;
    }
  }
}

class PaintObjIconWidget extends StatelessWidget {
  final FVBPaintTool paintObj;
  final FVBPainter paintTools;
  final double factor;

  const PaintObjIconWidget(
      {Key? key,
      required this.paintObj,
      required this.paintTools,
      required this.factor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () {
          final obj = paintObj.obj;
          context.read<PainterNotifier>().addObject(obj);
          context.read<StateManagementBloc>().add(StateManagementUpdateEvent(
              (paintTools as Component), RuntimeMode.edit));
          context.read<PaintObjBloc>().add(UpdatePaintObjSelectionEvent(obj));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.teal,
          ),
          margin: EdgeInsets.all(factor * 3),
          padding: EdgeInsets.all(factor * 3),
          child: Image.asset(
            'assets/icons/${paintObj.image}',
            width: 13 * factor,
            color: ColorAssets.white,
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}

class PainterNotifier extends ChangeNotifier {
  final FVBPainter paintTool;

  PainterNotifier(this.paintTool);

  void addObject(FVBPaintObj obj) {
    paintTool.paintObjects.add(obj);
    notifyListeners();
  }
}

class PaintObjectNotifier extends ChangeNotifier {
  PaintObjectNotifier();

  void update() {
    notifyListeners();
  }
}
