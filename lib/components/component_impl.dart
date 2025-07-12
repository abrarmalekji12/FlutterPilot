import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../bloc/paint_obj/paint_obj_bloc.dart';
import '../common/analyzer/render_models.dart';
import '../common/converter/string_operation.dart';
import '../common/firebase_image.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../data/remote/firestore/firebase_bridge.dart';
import '../injector.dart';
import '../models/builder_component.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/other_model.dart';
import '../models/parameter_info_model.dart';
import '../models/parameter_model.dart';
import '../parameter/parameters_list.dart';
import '../runtime_provider.dart';
import '../ui/paint_tools/paint_tools.dart';
import '../widgets/divider/dashed_divider.dart';

const kFalse = 'false';
const kTrue = 'true';
mixin FVBPainter {
  List<FVBPaintObj> paintObjects = [];
}

class CRichText extends Component {
  CRichText()
      : super('RichText', [
          Parameters.textAlignParameter,
          Parameters.textSpanParameter()
            ..withInfo(InnerObjectParameterInfo(innerObjectName: 'TextSpan', namedIfHaveAny: 'text')),
          Parameters.overflowParameter
            ..withRequired(true)
            ..withDefaultValue('clip')
        ]);

  @override
  Widget create(BuildContext context) {
    return RichText(
      textAlign: parameters[0].value,
      text: parameters[1].value,
      overflow: parameters[2].value,
    );
  }
}

class CCustomPaint extends Component with Resizable, FVBPainter {
  CCustomPaint()
      : super('CustomPaint', [
          Parameters.painterParameter(),
          Parameters.sizeParameter(defaultValue: 0)..withChangeNamed('size'),
        ]);

  @override
  Widget create(BuildContext context) {
    final size = parameters[1].value ?? Size.zero;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: BlocBuilder<PaintObjBloc, PaintObjState>(
        buildWhen: (state1, state2) => state2 is PaintObjSelectionUpdatedState,
        builder: (context, state) {
          return Stack(
            children: [
              CustomPaint(
                painter: parameters[0].value,
                size: size,
              ),
              for (final obj in paintObjects)
                BlocBuilder<PaintObjBloc, PaintObjState>(
                    buildWhen: (state1, state2) => state2 is! PaintObjUpdateState || state2.obj == obj,
                    builder: (context, state) {
                      final b = obj.boundary;
                      return Positioned(
                        left: b.left,
                        top: b.top,
                        child: SizedBox(
                          width: b.width,
                          height: b.height,
                          child: CustomPaint(
                            size: obj.size,
                            painter: obj.painter,
                          ),
                        ),
                      );
                    }),
            ],
          );
        },
      ),
    );
  }

  @override
  String? get import => '${StringOperation.toSnakeCase(parameters[0].displayName!)}${parameters[0].hashCode}';

  String get implCode {
    return '''
    import 'package:flutter/material.dart';
    import 'package:${collection.project!.packageName}/common/extensions.dart';
    import 'dart:math';
    
    class ${StringOperation.toCamelCase(parameters[0].displayName!)}${parameters[0].hashCode} extends CustomPainter {
    @override
    void paint(Canvas canvas,Size size){
    Paint paint;
    ${paintObjects.map((e) => '// Draw ${e.name} \n${e.dartCode}').join('\n')}
     }
      @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
    }
    ''';
    // return '''class ${StringOperation.toCamelCase(parameters[0].displayName!)}${(parameters[0] as CodeParameter).actionCode.hashCode} extends CustomPainter {
    // ${(parameters[0] as CodeParameter).actionCode}
    // }
    // ''';
  }

  @override
  void onResize(Size size) {
    final params = (parameters[1] as ComplexParameter).params;
    linearChange(params[0], (params[0].value ?? boundary?.width ?? 0), size.width);
    linearChange(params[1], (params[1].value ?? boundary?.height ?? 0), size.height);
  }

  @override
  ResizeType get resizeType => ResizeType.verticalAndHorizontal;

  @override
  List<Parameter> get resizeAffectedParameters {
    final params = (parameters[1] as ComplexParameter).params;
    return [params[0], params[1]];
  }
}

class CNotRecognizedWidget extends Component {
  CNotRecognizedWidget() : super('NotRecognized', []);

  @override
  Widget create(BuildContext context) {
    return Container(
      child: Text(
        'Not recognized widget $name',
        style: AppFontStyle.lato(14, color: Colors.red.shade800),
      ),
      color: const Color(0xfff1f1f1),
    );
  }
}

class CPlaceholder extends Component {
  CPlaceholder()
      : super('Placeholder', [
          Parameters.colorParameter,
        ]);

  @override
  Widget create(BuildContext context) {
    return Placeholder(
      color: parameters[0].value,
    );
  }
}

class CSwitch extends Component with Clickable {
  CSwitch()
      : super(
            'Switch',
            [
              Parameters.enableParameter()..withNamedParamInfoAndSameDisplayName('value'),
              Parameters.choiceValueFromEnum(MaterialTapTargetSize.values,
                  optional: false, require: false, name: 'materialTapTargetSize', defaultValue: null),
              Parameters.configColorParameter('activeColor'),
              Parameters.configColorParameter('focusColor'),
              Parameters.configColorParameter('hoverColor'),
              Parameters.configColorParameter('activeTrackColor'),
              Parameters.configColorParameter('inactiveTrackColor'),
              Parameters.configColorParameter('inactiveThumbColor'),
            ],
            defaultParamConfig: ComponentDefaultParamConfig(
              padding: true,
              visibility: true,
              alignment: true,
            )) {
    methods([
      FVBFunction('onChanged', null, [FVBArgument('value', dataType: DataType.fvbBool)], returnType: DataType.fvbVoid)
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return Switch(
      onChanged: (bool value) {
        perform(context, arguments: [value]);
      },
      value: parameters[0].value,
      materialTapTargetSize: parameters[1].value,
      activeColor: parameters[2].value,
      focusColor: parameters[3].value,
      hoverColor: parameters[4].value,
      activeTrackColor: parameters[5].value,
      inactiveTrackColor: parameters[6].value,
      inactiveThumbColor: parameters[7].value,
    );
  }
}

class CBackButton extends ClickableComponent {
  CBackButton()
      : super('BackButton', [
          Parameters.colorParameter
            ..withRequired(false)
            ..defaultValue = null
        ]) {
    methods([
      FVBFunction('onPressed', 'App.pop(context);', [], returnType: DataType.fvbVoid),
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return BackButton(
      color: parameters[0].value,
      onPressed: () {
        perform(context);
      },
    );
  }
}

class CCloseButton extends ClickableComponent {
  CCloseButton()
      : super('CloseButton', [
          Parameters.colorParameter
            ..withRequired(false)
            ..defaultValue = null
        ]) {
    methods([
      FVBFunction('onPressed', 'App.pop(context);', [], returnType: DataType.fvbVoid),
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return CloseButton(
      color: parameters[0].value,
      onPressed: () {
        perform(context);
      },
    );
  }
}

class CSlider extends Component {
  CSlider()
      : super('Slider', [
          Parameters.widthParameter()
            ..withDefaultValue(1)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('value'),
          Parameters.widthParameter()
            ..withDefaultValue(0)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('min'),
          Parameters.widthParameter()
            ..withDefaultValue(0)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('max'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Slider(
      onChanged: (value) {},
      value: parameters[0].value,
      min: parameters[1].value,
      max: parameters[2].value,
    );
  }
}

class CSpacer extends Component with CParentFlexModel {
  CSpacer()
      : super('Spacer', [
          Parameters.flexParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Spacer(
      flex: parameters[0].value,
    );
  }

  @override
  int get flex => parameters[0].value;
}

class CDivider extends Component with Resizable {
  CDivider()
      : super(
            'Divider',
            [
              Parameters.colorParameter
                ..withDefaultValue(null)
                ..withRequired(false),
              Parameters.heightParameter()..withDefaultValue(20.0),
              Parameters.thicknessParameter(),
              Parameters.heightParameter()
                ..withDefaultValue(0.0)
                ..withDisplayName('indent')
                ..withInfo(NamedParameterInfo('indent'))
                ..withRequired(false),
              Parameters.heightParameter()
                ..withDefaultValue(0.0)
                ..withDisplayName('end-indent')
                ..withInfo(NamedParameterInfo('endIndent'))
                ..withRequired(false)
            ],
            defaultParamConfig: ComponentDefaultParamConfig(width: true));

  @override
  Widget create(BuildContext context) {
    return Divider(
      color: parameters[0].value,
      height: parameters[1].value,
      thickness: parameters[2].value,
      indent: parameters[3].value,
      endIndent: parameters[4].value,
    );
  }

  @override
  void onResize(Size size) {
    linearChange(parameters[1], (parameters[1].value ?? boundary?.width ?? 0), size.height);
  }

  @override
  ResizeType get resizeType => ResizeType.verticalOnly;

  @override
  List<Parameter> get resizeAffectedParameters => [parameters[1]];
}

class CVerticalDivider extends Component {
  CVerticalDivider()
      : super(
          'VerticalDivider',
          [
            Parameters.colorParameter..withDefaultValue(ColorAssets.grey),
            Parameters.widthParameter()..withDefaultValue(20.0),
            Parameters.thicknessParameter(),
            Parameters.heightParameter()
              ..withDefaultValue(0.0)
              ..withDisplayName('indent')
              ..withInfo(NamedParameterInfo('indent'))
              ..withRequired(false),
            Parameters.heightParameter()
              ..withDefaultValue(0.0)
              ..withDisplayName('end-indent')
              ..withInfo(NamedParameterInfo('endIndent'))
              ..withRequired(false)
          ],
        );

  @override
  Widget create(BuildContext context) {
    return VerticalDivider(
      color: parameters[0].value,
      width: parameters[1].value,
      thickness: parameters[2].value,
      indent: parameters[3].value,
      endIndent: parameters[4].value,
    );
  }
}

class CDashedLine extends Component with CLeafRenderModel {
  CDashedLine()
      : super(
          'DashedLine',
          [
            Parameters.widthParameter(),
            Parameters.heightParameter(),
            Parameters.axisParameter(),
            Parameters.colorParameter
              ..withDefaultValue(
                ColorAssets.black,
              ),
            Parameters.widthParameter(initial: '2')..withNamedParamInfoAndSameDisplayName('dash'),
            Parameters.widthParameter(initial: '2')..withNamedParamInfoAndSameDisplayName('gap'),
          ],
          defaultParamConfig: ComponentDefaultParamConfig(
            padding: true,
          ),
        );

  @override
  String? get import => 'dashed_line';

  @override
  Widget create(BuildContext context) {
    return DashedLine(
      width: parameters[0].value,
      height: parameters[1].value,
      direction: parameters[2].value,
      color: parameters[3].value,
      dash: parameters[4].value,
      gap: parameters[5].value,
    );
  }

  @override
  Size? get fixedSize => null;

  @override
  Future<Size> size(Size size) async {
    return Size(parameters[0].value, parameters[1].value);
  }
}

class CText extends Component with CLeafRenderModel {
  CText({String? text})
      : super(
            'Text',
            [
              Parameters.textParameter(required: true, defaultValue: 'Write Text Here')..compiler.code = text ?? '',
              Parameters.googleFontTextStyleParameter..withRequired(false),
              Parameters.textAlignParameter,
              Parameters.overflowParameter,
            ],
            defaultParamConfig: ComponentDefaultParamConfig(
              padding: true,
              width: true,
              height: true,
              visibility: true,
              alignment: true,
            ));

  @override
  Future<Size> size(Size size) async {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: parameters[0].value,
        style: parameters[1].value,
      ),
      textDirection: TextDirection.ltr,
      textAlign: parameters[2].value,
    );
    painter.layout(
      maxWidth: size.width,
    );
    return painter.size;
  }

  @override
  Widget create(BuildContext context) {
    return Text(
      parameters[0].value,
      style: parameters[1].value,
      textAlign: parameters[2].value,
      overflow: parameters[3].value,
    );
  }

  @override
  Size? get fixedSize => null;
}

class CImageNetwork extends Component with Resizable {
  CImageNetwork()
      : super('Image.network', [
          Parameters.textParameter(defaultValue: '', required: true)..withDisplayName('url'),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.boxFitParameter(),
          Parameters.colorParameter
            ..withDefaultValue(null)
            ..withRequired(false),
          Parameters.filterQualityParameter(),
        ]);

  @override
  void onResize(Size size) {
    linearChange(parameters[1], (parameters[1].value ?? boundary?.width ?? 0), size.width);
    linearChange(parameters[2], (parameters[2].value ?? boundary?.height ?? 0), size.height);
  }

  @override
  ResizeType get resizeType => ResizeType.verticalAndHorizontal;

  @override
  List<Parameter> get resizeAffectedParameters => [parameters[1], parameters[2]];

  @override
  Widget create(BuildContext context) {
    final path = parameters[0].value;
    final w = parameters[1].value;
    final h = parameters[2].value;
    if (path is String && path.isEmpty) {
      final iconSize=((w != null ? w : 0) + (h != null ? h : 0)) / 3;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        lookForUIChanges(context, initialCheck: false);
      });
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        width: w,
        height: h,
        alignment: Alignment.center,
        child: Icon(
          Icons.image,
          size: iconSize!=0?iconSize:30,
          color: Colors.grey,
        ),
      );
    }
    return Image.network(
      path,
      width: w,
      height: h,
      fit: parameters[3].value,
      color: parameters[4].value,
      filterQuality: parameters[5].value,
      errorBuilder: (error, _, __) => FVBImageNetworkError(
        path: path,
        width: w,
        height: h,
      ),
      frameBuilder: (context, widget, v, wasAsync) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          lookForUIChanges(context, initialCheck: false);
        });
        return widget;
      },
    );
  }
}

class CSvgPictureNetwork extends Component {
  CSvgPictureNetwork()
      : super('SvgPicture.network', [
          Parameters.textParameter()..withDisplayName('url'),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.boxFitParameter(),
          Parameters.colorFilterParameter('srcIn')
        ]);

  @override
  Widget create(BuildContext context) {
    return SvgPicture.network(
      parameters[0].value,
      width: parameters[1].value,
      height: parameters[2].value,
      fit: parameters[3].value,
      colorFilter: parameters[4].value,
    );
  }
}

class CIcon extends Component with Resizable, CRenderModel {
  CIcon({String? icon})
      : super(
          'Icon',
          [
            Parameters.iconParameter(),
            Parameters.widthParameter(
              config: const VisualConfig(
                labelVisible: false,
                width: 0.5,
                icon: Icons.width_full,
              ),
            )..withNamedParamInfoAndSameDisplayName('size'),
            Parameters.colorParameter
              ..config = const VisualConfig(labelVisible: false, width: 0.5)
              ..withDefaultValue(ColorAssets.black)
              ..withRequired(false),
            Parameters.textParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('semanticLabel')
          ],
          defaultParamConfig: ComponentDefaultParamConfig(padding: true, alignment: true),
        ) {
    if (icon != null) {
      (parameters[0] as ChoiceValueParameter).update(icon);
    }
  }

  @override
  Widget create(BuildContext context) {
    return Icon(
      parameters[0].value,
      size: parameters[1].value,
      color: parameters[2].value,
      semanticLabel: parameters[3].value,
    );
  }

  @override
  void onResize(Size size) {
    linearChange(parameters[1], (parameters[1].value ?? 24), (size.width + size.height) / 2);
  }

  @override
  ResizeType get resizeType => ResizeType.symmetricResize;

  @override
  List<Parameter> get resizeAffectedParameters => [parameters[1]];

  @override
  Size get size {
    final v = parameters[1].value;
    if (v == null) {
      return const Size(24, 24);
    }
    final value = min<double>(v, 40);
    return Size(value, value);
  }

  @override
  Size get childSize => Size.zero;

  @override
  EdgeInsets get margin => EdgeInsets.zero;
}

class CImageAsset extends Component with Resizable {
  CImageAsset()
      : super('Image.asset', [
          Parameters.imageParameter(),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.colorParameter
            ..withDefaultValue(null)
            ..withRequired(false),
          Parameters.boxFitParameter(),
          Parameters.filterQualityParameter(),
        ]);

  @override
  void onResize(Size size) {
    linearChange(parameters[1], (parameters[1].value ?? boundary?.width ?? 0), size.width);
    linearChange(parameters[2], (parameters[2].value ?? boundary?.height ?? 0), size.height);
  }

  @override
  ResizeType get resizeType => ResizeType.verticalAndHorizontal;

  @override
  List<Parameter> get resizeAffectedParameters => [parameters[1], parameters[2]];

  @override
  Widget create(BuildContext context) {
    final image = parameters[0].value as FVBImage?;
    return _handleAssetImage(context, image, parameters[1].value, parameters[2].value, parameters);
  }
}

Widget loadImage(BuildContext context, FVBImage image, double? w, double? h, List<Parameter> parameters) {
  if (image.bytes!.isEmpty) {
    return FVBImageNetworkError(
      path: image.path ?? image.name!,
      width: w,
      height: h,
    );
  }
  return Image.memory(
    image.bytes!,
    errorBuilder: (error, _, __) => FVBImageNetworkError(
      path: image.path ?? image.name!,
      width: w,
      height: h,
    ),
    width: w,
    height: h,
    color: parameters[3].value,
    fit: parameters[4].value,
    filterQuality: parameters[5].value,
  );
}

_handleAssetImage(BuildContext context, FVBImage? image, double? width, double? height, List<Parameter> parameters) {
  return image?.name != null
      ? (image!.bytes != null
          ? loadImage(context, image, width, height, parameters)
          : FutureBuilder<FVBImage?>(
              future: dataBridge.getPublicImage(image.name!),
              builder: (context, data) {
                if (data.hasData) {
                  if (data.data != null) {
                    image.bytes = data.data?.bytes;
                    return loadImage(context, data.data!, width, height, parameters);
                  } else {
                    return FVBImageNetworkError(path: image.name ?? '');
                  }
                }
                return Container(
                  child: const Icon(Icons.image, color: Colors.grey, size: 30),
                  width: parameters[1].value,
                  height: parameters[2].value,
                );
              }))
      : Icon(
          Icons.error,
          size: width,
          color: Colors.red,
        );
}

class CImage extends Component with Resizable, CLeafRenderModel {
  CImage()
      : super(
            'Image',
            [
              ChoiceParameter(
                options: [
                  Parameters.imageParameter(),
                  Parameters.textParameter(defaultValue: '', required: true)..withDisplayName('url'),
                  Parameters.bytesParameter(required: true),
                ],
                name: 'Source',
              ),
              Parameters.widthParameter(),
              Parameters.heightParameter(),
              Parameters.colorParameter
                ..withDefaultValue(null)
                ..withRequired(false),
              Parameters.boxFitParameter(),
              Parameters.filterQualityParameter(),
              Parameters.alignmentParameter(),
              Parameters.blendModeParameter(name: 'colorBlendMode'),
            ],
            defaultParamConfig: ComponentDefaultParamConfig(padding: true, alignment: true)) {
    autoHandleKey = false;
  }

  @override
  String code({bool clean = true}) {
    if (!clean) {
      return super.code(clean: clean);
    }
    final middle = generateParametersCode(clean);
    String name = switch ((parameters[0] as ChoiceParameter).selectedIndex) {
      0 => 'Image.asset',
      1 => 'Image.network',
      2 => 'Image.memory',
      _ => ''
    };
    if (!clean) {
      name = metaCode(name);
    }
    return withState('$name($middle)', clean);
  }

  Widget loadImage(BuildContext context, FVBImage image) {
    final w = parameters[1].value;
    final h = parameters[2].value;
    return Image.memory(
      image.bytes!,
      key: key(context),
      errorBuilder: (error, _, __) => FVBImageNetworkError(
        path: image.path ?? image.name!,
        width: w,
        height: h,
      ),
      frameBuilder: (context, child, _, __) {
        if (parent is Component && RuntimeProvider.of(context) == RuntimeMode.edit) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            ViewableProvider.maybeOf(context)?.rootComponent?.forEach((p0) {
              p0.lookForUIChanges(context);
              return false;
            });
          });
        }
        return child;
      },
      width: w,
      height: h,
      color: parameters[3].value,
      fit: parameters[4].value,
      filterQuality: parameters[5].value,
      alignment: parameters[6].value,
      colorBlendMode: parameters[7].value,
    );
  }

  @override
  void onResize(Size size) {
    linearChange(parameters[1], (parameters[1].value ?? boundary?.width ?? 0), size.width);
    linearChange(parameters[2], (parameters[2].value ?? boundary?.height ?? 0), size.height);
  }

  @override
  ResizeType get resizeType => ResizeType.verticalAndHorizontal;

  @override
  List<Parameter> get resizeAffectedParameters => [parameters[1], parameters[2]];

  @override
  Widget create(BuildContext context) {
    final choice = (parameters[0] as ChoiceParameter);

    final w = parameters[1].value;
    final h = parameters[2].value;
    if (choice.val == choice.options[0]) {
      final image = parameters[0].value as FVBImage?;
      return _handleAssetImage(context, image, w, h, parameters);
    } else if (choice.val == choice.options[1]) {
      final path = parameters[0].value;
      return Image.network(
        path,
        key: key(context),
        width: w,
        height: h,
        color: parameters[3].value,
        fit: parameters[4].value,
        filterQuality: parameters[5].value,
        errorBuilder: (error, _, __) => FVBImageNetworkError(
          path: path,
          width: w,
          height: h,
        ),
        frameBuilder: (context, widget, v, wasAsync) {
          if (RuntimeProvider.of(context) == RuntimeMode.edit) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              lookForUIChanges(context, initialCheck: false);
            });
          }
          return widget;
        },
      );
    } else if (choice.val == choice.options[2]) {
      final bytes = parameters[0].value;
      return Image.memory(
        bytes ?? Uint8List.fromList([]),
        key: key(context),
        width: w,
        height: h,
        color: parameters[3].value,
        fit: parameters[4].value,
        filterQuality: parameters[5].value,
        errorBuilder: (error, _, __) => FVBImageNetworkError(
          path: 'Invalid Bytes',
          width: w,
          height: h,
        ),
        frameBuilder: (context, widget, v, wasAsync) {
          if (RuntimeProvider.of(context) == RuntimeMode.edit) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              lookForUIChanges(context, initialCheck: false);
            });
          }
          return widget;
        },
      );
    }
    return const Offstage();
  }

  Future<ui.Image> bytesToImage(Uint8List bytes) async {
    // copy from decodeImageFromList of package:flutter/painting.dart
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  @override
  Future<Size> size(Size size) async {
    double? width = parameters[1].value, height = parameters[2].value;
    final fit = parameters[4].value;
    if (width != null && height != null && size.width >= width && size.height >= height) {
      return Size(width, height);
    }
    final choice = (parameters[0] as ChoiceParameter);
    final Size imageSize;
    if (choice.val == choice.options[0]) {
      final fvbImage = choice.val?.value as FVBImage?;
      if (fvbImage?.bytes != null) {
        final image = await bytesToImage(fvbImage!.bytes!);
        imageSize = Size(image.width.toDouble(), image.height.toDouble());
      } else {
        imageSize = Size.zero;
      }
    } else {
      final path = parameters[0].value;

      final img = uiImageCache.containsKey(path) ? uiImageCache[path]! : (await getImage(path));

      imageSize = Size(img.width.toDouble(), img.height.toDouble());
    }
    return fitImage(fit, width, height, imageSize, size);
  }

  Future<ui.Image> getImage(String path) async {
    final completer = Completer<ImageInfo>();
    final img = NetworkImage(path);
    img.resolve(const ImageConfiguration()).addListener(ImageStreamListener((info, _) {
      completer.complete(info);
    }));
    final ImageInfo imageInfo = await completer.future;
    uiImageCache[path] = imageInfo.image;
    return imageInfo.image;
  }

  @override
  Size get fixedSize {
    final width = parameters[1].value;
    final height = parameters[2].value;
    return Size(width ?? double.infinity, height ?? double.infinity);
  }
}

Size fitImage(BoxFit fit, double? width, double? height, Size imageSize, Size availableSize) {
  final scale = imageSize.width / imageSize.height;
  switch (fit) {
    case BoxFit.fill:
      final w = width != null && width >= 0
          ? width
          : (imageSize.width > availableSize.width ? availableSize.width : imageSize.width);
      return Size(w, height != null ? height : w / scale);
    case BoxFit.contain:
      // TODO: Handle this case.
      break;
    case BoxFit.cover:
      // TODO: Handle this case.
      break;
    case BoxFit.fitWidth:
      // TODO: Handle this case.
      break;
    case BoxFit.fitHeight:
      // TODO: Handle this case.
      break;
    case BoxFit.none:
      // TODO: Handle this case.
      break;
    case BoxFit.scaleDown:
      // TODO: Handle this case.
      break;
  }
  return Size.zero;
}

class CSvgImage extends Component {
  CSvgImage()
      : super('SvgPicture.asset', [
          Parameters.imageParameter(),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.colorFilterParameter('srcIn'),
          Parameters.boxFitParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return parameters[0].value != null && (parameters[0].value as FVBImage).bytes != null
        ? SvgPicture.memory(
            (parameters[0].value as FVBImage).bytes!,
            width: parameters[1].value,
            height: parameters[2].value,
            colorFilter: parameters[3].value,
            fit: parameters[4].value,
          )
        : Icon(
            Icons.error,
            color: Colors.red,
            size: parameters[1].value,
          );
  }
}

class CInputDecorator extends Holder {
  CInputDecorator()
      : super('InputDecorator', [
          Parameters.googleFontTextStyleParameter..withChangeNamed('baseStyle'),
          Parameters.inputDecorationParameter(),
          Parameters.enableParameter(false)..withNamedParamInfoAndSameDisplayName('isEmpty'),
          Parameters.enableParameter(
            false,
          )..withNamedParamInfoAndSameDisplayName('isFocused'),
          Parameters.enableParameter(false)..withNamedParamInfoAndSameDisplayName('expands'),
        ]) {
    addComponentParameters([
      (parameters[1] as ComplexParameter).params[10] as ComponentParameter,
      (parameters[1] as ComplexParameter).params[11] as ComponentParameter,
      (parameters[1] as ComplexParameter).params[12] as ComponentParameter,
    ]);
  }

  @override
  Widget create(BuildContext context) {
    initComponentParameters(context);
    return InputDecorator(
      baseStyle: parameters[0].value,
      decoration: parameters[1].value,
      isEmpty: parameters[2].value,
      isFocused: parameters[3].value,
      expands: parameters[4].value,
      child: child?.build(context),
    );
  }
}

class CTextField extends Component with Clickable, Controller {
  CTextField()
      : super(
            'TextField',
            [
              Parameters.textInputTypeParameter(),
              Parameters.googleFontTextStyleParameter..withRequired(false),
              Parameters.enableParameter(false)..withNamedParamInfoAndSameDisplayName('readOnly'),
              Parameters.inputDecorationParameter(),
              Parameters.flexParameter()
                ..withNamedParamInfoAndSameDisplayName('maxLength')
                ..withRequired(false),
              BooleanParameter(
                  required: false,
                  val: false,
                  info: NamedParameterInfo('obscureText', defaultValue: kFalse),
                  displayName: 'obscure-text'),
              Parameters.textInputActionParameter(),
            ],
            defaultParamConfig: ComponentDefaultParamConfig(
              padding: true,
              width: true,
              height: true,
            )) {
    addComponentParameters([
      (parameters[3] as ComplexParameter).params[10] as ComponentParameter,
      (parameters[3] as ComplexParameter).params[11] as ComponentParameter,
      (parameters[3] as ComplexParameter).params[12] as ComponentParameter,
    ]);
    methods([
      FVBFunction('onChanged', null, [FVBArgument('value', dataType: DataType.string, nullable: false)],
          returnType: DataType.fvbVoid),
      FVBFunction('onSubmitted', null, [FVBArgument('value', dataType: DataType.string, nullable: false)],
          returnType: DataType.fvbVoid),
      FVBFunction('onTap', null, [], returnType: DataType.fvbVoid),
    ]);
    assign('controller', (_, vsync) => TextEditingController(), 'TextEditingController()');
  }

  @override
  Widget create(BuildContext context) {
    return TextField(
      keyboardType: parameters[0].value,
      controller: values['controller'],
      onChanged: (value) {
        perform(context, arguments: [value]);
      },
      onTap: () {
        perform(context, arguments: [], name: 'onTap');
      },
      onSubmitted: (value) {
        perform(context, arguments: [value], name: 'onSubmitted');
      },
      style: parameters[1].value,
      readOnly: parameters[2].value,
      maxLength: parameters[4].value,
      obscureText: parameters[5].value,
      textInputAction: parameters[6].value,
      decoration: parameters[3].value,
    );
  }
}

class CTextFormField extends Component with Clickable {
  CTextFormField()
      : super('TextFormField', [
          Parameters.textInputTypeParameter(),
          Parameters.googleFontTextStyleParameter,
          BooleanParameter(required: true, val: false, info: NamedParameterInfo('readOnly'), displayName: 'readOnly'),
          Parameters.inputDecorationParameter(),
          Parameters.flexParameter()
            ..withNamedParamInfoAndSameDisplayName('maxLength')
            ..withRequired(false),
          BooleanParameter(
              required: false, val: false, info: NamedParameterInfo('obscureText'), displayName: 'obscure-text'),
          Parameters.textInputActionParameter(),
        ]) {
    addComponentParameters([
      (parameters[3] as ComplexParameter).params[10] as ComponentParameter,
      (parameters[3] as ComplexParameter).params[11] as ComponentParameter,
      (parameters[3] as ComplexParameter).params[12] as ComponentParameter,
    ]);
    methods([
      FVBFunction('onChanged', null, [FVBArgument('value', dataType: DataType.string, nullable: false)],
          returnType: DataType.fvbVoid),
      FVBFunction('validator', null, [FVBArgument('value', dataType: DataType.string, nullable: true)],
          returnType: DataType.string, canReturnNull: true),
    ]);
  }

  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget create(BuildContext context) {
    initComponentParameters(context);
    return TextFormField(
      keyboardType: parameters[0].value,
      controller: RuntimeProvider.of(context) == RuntimeMode.run ? textEditingController : null,
      onChanged: (value) {
        perform(context, arguments: [value]);
      },
      validator: (value) {
        final out = perform(context, arguments: [value], name: 'validator');
        return out;
      },
      style: parameters[1].value,
      readOnly: parameters[2].value,
      maxLength: parameters[4].value,
      obscureText: parameters[5].value,
      textInputAction: parameters[6].value,
      decoration: parameters[3].value,
    );
  }
}

class CLoadingIndicator extends Component {
  CLoadingIndicator()
      : super('LoadingIndicator', [
          Parameters.indicatorTypeParameter(),
          Parameters.backgroundColorParameter(),
          Parameters.widthParameter()
            ..withDefaultValue(null)
            ..withNamedParamInfoAndSameDisplayName('strokeWidth'),
          Parameters.colorListParameter([const Color(0xff009FFD), const Color(0xff2A2A72)]),
          Parameters.enableParameter()
            ..val = false
            ..withNamedParamInfoAndSameDisplayName('pause')
        ]);

  @override
  Widget create(BuildContext context) {
    return LoadingIndicator(
      indicatorType: parameters[0].value,
      backgroundColor: parameters[1].value,
      strokeWidth: parameters[2].value,
      colors: parameters[3].value,
      pause: parameters[4].value,
    );
  }
}

class CLinearProgressIndicator extends Component {
  CLinearProgressIndicator()
      : super(
            'LinearProgressIndicator',
            [
              Parameters.widthParameter()
                ..withDefaultValue(5.0)
                ..withRequired(true)
                ..withNamedParamInfoAndSameDisplayName('minHeight'),
              Parameters.widthParameter()
                ..withDefaultValue(null)
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('value'),
              ComplexParameter(
                params: [
                  Parameters.colorParameter
                    ..withDefaultValue(ColorAssets.black)
                    ..withChangeNamed(null)
                    ..withDisplayName('loading color')
                ],
                evaluate: (params) {
                  return AlwaysStoppedAnimation<Color?>(params[0].value);
                },
                info: InnerObjectParameterInfo(innerObjectName: 'AlwaysStoppedAnimation', namedIfHaveAny: 'valueColor'),
              ),
              Parameters.colorParameter,
              Parameters.backgroundColorParameter(),
            ],
            defaultParamConfig: ComponentDefaultParamConfig(padding: true, width: true, height: true, alignment: true));

  @override
  Widget create(BuildContext context) {
    return LinearProgressIndicator(
      minHeight: parameters[0].value,
      value: parameters[1].value,
      valueColor: parameters[2].value,
      color: parameters[3].value,
      backgroundColor: parameters[4].value,
    );
  }
}

class CCircularProgressIndicator extends Component {
  CCircularProgressIndicator()
      : super(
            'CircularProgressIndicator',
            [
              Parameters.widthParameter()
                ..withDefaultValue(4.0)
                ..withRequired(true)
                ..withNamedParamInfoAndSameDisplayName('strokeWidth'),
              Parameters.widthParameter()
                ..withDefaultValue(null)
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('value'),
              ComplexParameter(
                params: [
                  Parameters.colorParameter
                    ..withDefaultValue(ColorAssets.black)
                    ..withChangeNamed(null)
                    ..withDisplayName('loading color')
                ],
                evaluate: (params) {
                  return AlwaysStoppedAnimation<Color?>(params[0].value);
                },
                info: InnerObjectParameterInfo(innerObjectName: 'AlwaysStoppedAnimation', namedIfHaveAny: 'valueColor'),
              ),
              Parameters.colorParameter,
              Parameters.backgroundColorParameter(),
            ],
            defaultParamConfig: ComponentDefaultParamConfig(padding: true, width: true, height: true, alignment: true));

  @override
  Widget create(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: parameters[0].value,
      value: parameters[1].value,
      valueColor: parameters[2].value,
      color: parameters[3].value,
      backgroundColor: parameters[4].value,
    );
  }
}
