import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:shimmer/shimmer.dart';

import '../common/analyzer/render_models.dart';
import '../constant/color_assets.dart';
import '../models/builder_component.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/parameter_info_model.dart';
import '../models/parameter_model.dart';
import '../models/parameter_rule_model.dart';
import '../parameter/parameters_list.dart';
import '../runtime_provider.dart';
import '../ui/build_view/build_view.dart';

class CContainer extends Holder with Resizable, Movable, CRenderModel {
  CContainer()
      : super('Container', [
          Parameters.paddingParameter(),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.marginParameter(),
          Parameters.alignmentParameter()
            ..withDefaultValue(null)
            ..withRequired(false),
          Parameters.decorationParameter(),
          Parameters.clipBehaviourParameter('none'),
        ], rules: []) {
    addRule(ParameterRuleModel(
        changedParameter: (parameters[5] as ComplexParameter).params[5],
        anotherParameter: (parameters[5] as ComplexParameter).params[1],
        onChange: (param1, param2) {
          if (param1.value == BoxShape.circle) {
            (param2 as ChoiceParameter).resetParameter();
            return 'Circle box-shape can not have Border-Radius';
          }
          return null;
        }));
    addRule(ParameterRuleModel(
        changedParameter: (parameters[5] as ComplexParameter).params[2],
        anotherParameter: (parameters[5] as ComplexParameter).params[1],
        onChange: (param1, param2) {
          if ((param1 as ChoiceParameter).val == param1.options[2]) {
            (param2 as ChoiceParameter).resetParameter();
            return 'Only uniform border can have Border-Radius';
          }
          return null;
        }));
  }

  @override
  get canUpdateRadius => true;

  @override
  double? get radius =>
      ((parameters[5] as ComplexParameter).params[1].value as BorderRadius?)
          ?.topLeft
          .x;

  @override
  void updateRadius(double radius) {}

  @override
  bool get settle => true;

  @override
  Widget create(BuildContext context) {
    return Container(
      padding: parameters[0].value,
      width: parameters[1].value,
      height: parameters[2].value,
      margin: parameters[3].value,
      alignment: parameters[4].value,
      decoration: parameters[5].value,
      clipBehavior: parameters[6].value,
      child: child?.build(context),
    );
  }

  @override
  void onResize(Size size) {
    linearChange(parameters[1], (parameters[1].value ?? boundary?.width ?? 0),
        size.width);
    linearChange(parameters[2], (parameters[2].value ?? boundary?.height ?? 0),
        size.height);
  }

  @override
  ResizeType get resizeType => ResizeType.verticalAndHorizontal;

  @override
  void onMove(Offset offset) {
    (parameters[0] as ChoiceParameter).val =
        (parameters[0] as ChoiceParameter).options[2];
    final only =
        ((parameters[0] as ChoiceParameter).options[2] as ComplexParameter);
    linearChange(
        only.params[0], only.params[0].value ?? boundary?.top ?? 0, offset.dy);
    linearChange(
        only.params[1], only.params[1].value ?? boundary?.left ?? 0, offset.dx);
  }

  @override
  MoveType get moveType => MoveType.child;

  @override
  List<Parameter> get movableAffectedParameters => [parameters[0]];

  @override
  List<Parameter> get resizeAffectedParameters =>
      [parameters[0], parameters[1]];

  @override
  Size get childSize => Size(parameters[1].value ?? double.infinity,
      parameters[2].value ?? double.infinity);

  @override
  Size get size => Size(parameters[1].value ?? double.infinity,
      parameters[2].value ?? double.infinity);

  @override
  EdgeInsets get margin => (parameters[3].value ?? EdgeInsets.zero);

  @override
  EdgeInsets get padding => (parameters[0].value ?? EdgeInsets.zero);
}

class CAnimatedDefaultTextStyle extends Holder {
  CAnimatedDefaultTextStyle()
      : super('AnimatedDefaultTextStyle', [
          Parameters.durationParameter,
          Parameters.googleFontTextStyleParameter,
          Parameters.textAlignParameter,
          Parameters.overflowParameter
            ..withDefaultValue('clip')
            ..withRequired(true),
          Parameters.curveParameter
        ]);

  @override
  Widget create(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: parameters[0].value,
      style: parameters[1].value,
      textAlign: parameters[2].value,
      overflow: parameters[3].value,
      curve: parameters[4].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CDefaultTextStyle extends Holder {
  CDefaultTextStyle()
      : super('DefaultTextStyle', [
          Parameters.googleFontTextStyleParameter,
          Parameters.textAlignParameter,
          Parameters.overflowParameter
            ..withDefaultValue('clip')
            ..withRequired(true),
        ]);

  @override
  Widget create(BuildContext context) {
    return DefaultTextStyle(
      style: parameters[0].value,
      textAlign: parameters[1].value,
      overflow: parameters[2].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CAnimatedContainer extends Holder with Resizable {
  CAnimatedContainer()
      : super('AnimatedContainer', [
          Parameters.durationParameter,
          Parameters.paddingParameter(),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.marginParameter(),
          Parameters.alignmentParameter()
            ..withDefaultValue(null)
            ..withRequired(false),
          Parameters.decorationParameter(),
          Parameters.curveParameter
        ], rules: []) {
    addRule(ParameterRuleModel(
        changedParameter: (parameters[6] as ComplexParameter).params[5],
        anotherParameter: (parameters[6] as ComplexParameter).params[1],
        onChange: (param1, param2) {
          if (param1.value == BoxShape.circle) {
            (param2 as ChoiceParameter).resetParameter();
            return 'Circle box-shape can not have Border-Radius';
          }
          return null;
        }));
    addRule(ParameterRuleModel(
        changedParameter: (parameters[6] as ComplexParameter).params[2],
        anotherParameter: (parameters[6] as ComplexParameter).params[1],
        onChange: (param1, param2) {
          if ((param1 as ChoiceParameter).val == param1.options[2]) {
            (param2 as ChoiceParameter).resetParameter();
            return 'Only uniform border can have Border-Radius';
          }
          return null;
        }));
  }

  @override
  void onResize(Size size) {
    linearChange(parameters[2], (parameters[2].value ?? boundary?.width ?? 0),
        size.width);
    linearChange(parameters[3], (parameters[3].value ?? boundary?.height ?? 0),
        size.height);
  }

  @override
  ResizeType get resizeType => ResizeType.verticalAndHorizontal;

  @override
  List<Parameter> get resizeAffectedParameters =>
      [parameters[2], parameters[3]];

  @override
  Widget create(BuildContext context) {
    return AnimatedContainer(
      duration: parameters[0].value,
      padding: parameters[1].value,
      width: parameters[2].value,
      height: parameters[3].value,
      margin: parameters[4].value,
      alignment: parameters[5].value,
      decoration: parameters[6].value,
      curve: parameters[7].value,
      child: child?.build(context),
    );
  }
}

class CColoredBox extends Holder {
  CColoredBox()
      : super('ColoredBox', [
          Parameters.colorParameter..withRequired(true),
        ]);

  @override
  Widget create(BuildContext context) {
    return ColoredBox(
      color: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CColorFiltered extends Holder {
  CColorFiltered()
      : super('ColorFiltered', [
          Parameters.colorFilterParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return ClipRRect(
      child: ColorFiltered(
        colorFilter: parameters[0].value,
        child: child?.build(context),
      ),
    );
  }
}

class COffstage extends Holder {
  COffstage()
      : super('Offstage', [
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('offstage'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Offstage(
      offstage: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CInkWell extends ClickableHolder {
  CInkWell()
      : super(
            'InkWell',
            [
              Parameters.enableParameter()
                ..withNamedParamInfoAndSameDisplayName('enableFeedback'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('hoverColor'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('focusColor'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('splashColor'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('highlightColor'),
              Parameters.borderRadiusParameter(),
            ],
            defaultParamConfig: ComponentDefaultParamConfig(
              width: true,
              height: true,
              padding: true,
            )) {
    methods([
      FVBFunction('onTap', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onDoubleTap', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onLongPress', null, [], returnType: DataType.fvbVoid),
      FVBFunction(
          'onHover',
          null,
          [
            FVBArgument('value', dataType: DataType.fvbBool),
          ],
          returnType: DataType.fvbVoid),
      FVBFunction(
          'onFocusChange',
          null,
          [
            FVBArgument('value', dataType: DataType.fvbBool),
          ],
          returnType: DataType.fvbVoid),
      FVBFunction(
          'onHighlightChanged',
          null,
          [
            FVBArgument('value', dataType: DataType.fvbBool),
          ],
          returnType: DataType.fvbVoid),
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return InkWell(
      onTap: () {
        perform(context);
      },
      onDoubleTap: () {
        perform(context, name: 'onDoubleTap');
      },
      onLongPress: () {
        perform(context, name: 'onLongPress');
      },
      onHover: (value) {
        perform(context, name: 'onHover', arguments: [value]);
      },
      onFocusChange: (value) {
        perform(context, name: 'onFocusChange', arguments: [value]);
      },
      onHighlightChanged: (value) {
        perform(context, name: 'onHighlightChanged', arguments: [value]);
      },
      enableFeedback: parameters[0].value,
      hoverColor: parameters[1].value,
      focusColor: parameters[2].value,
      splashColor: parameters[3].value,
      highlightColor: parameters[4].value,
      borderRadius: parameters[5].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CIconButton extends ClickableComponent {
  CIconButton()
      : super(
            'IconButton',
            [
              ComponentParameter(
                multiple: false,
                info: NamedParameterInfo('icon'),
              ),
              Parameters.widthParameter()
                ..withDefaultValue(24.0)
                ..withRequired(true)
                ..withNamedParamInfoAndSameDisplayName('iconSize'),
              Parameters.colorParameter..withDefaultValue(ColorAssets.black),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('splashColor'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('hoverColor'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('highlightColor'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('focusColor'),
              Parameters.enableParameter()
                ..withNamedParamInfoAndSameDisplayName('enableFeedback'),
              Parameters.alignmentParameter(),
              Parameters.paddingParameter()..withRequired(true),
              Parameters.textParameter()
                ..withNamedParamInfoAndSameDisplayName('tooltip'),
              Parameters.iconButtonStyle()
            ],
            config: ComponentDefaultParamConfig(
              visibility: true,
              padding: true,
            )) {
    addComponentParameters([parameters[0] as ComponentParameter]);
    methods([FVBFunction('onPressed', null, [], returnType: DataType.fvbVoid)]);
  }

  @override
  Widget create(BuildContext context) {
    initComponentParameters(context);
    return IconButton(
      iconSize: parameters[1].value,
      color: parameters[2].value,
      splashColor: parameters[3].value,
      hoverColor: parameters[4].value,
      highlightColor: parameters[5].value,
      focusColor: parameters[6].value,
      enableFeedback: parameters[7].value,
      alignment: parameters[8].value,
      padding: parameters[9].value,
      tooltip: parameters[10].value,
      style: parameters[11].value,
      onPressed: () {
        perform(context);
      },
      icon: (parameters[0] as ComponentParameter).build() ?? Container(),
    );
  }
}

class CGestureDetector extends ClickableHolder {
  CGestureDetector() : super('GestureDetector', []) {
    methods([
      FVBFunction('onTap', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onDoubleTap', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onLongPress', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onSecondaryTap', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onSecondaryLongPress', null, [],
          returnType: DataType.fvbVoid),
      FVBFunction('onDoubleTapCancel', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onTapCancel', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onLongPressUp', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onPanCancel', null, [], returnType: DataType.fvbVoid),
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return GestureDetector(
      onTap: () {
        perform(context);
      },
      onDoubleTap: () {
        perform(context, name: 'onDoubleTap');
      },
      onLongPress: () {
        perform(context, name: 'onLongPress');
      },
      onSecondaryTap: () {
        perform(context, name: 'onSecondaryTap');
      },
      onSecondaryLongPress: () {
        perform(context, name: 'onSecondaryLongPress');
      },
      onDoubleTapCancel: () {
        perform(context, name: 'onDoubleTapCancel');
      },
      onTapCancel: () {
        perform(context, name: 'onTapCancel');
      },
      onLongPressUp: () {
        perform(context, name: 'onLongPressUp');
      },
      onPanCancel: () {
        perform(context, name: 'onPanCancel');
      },
      child: child?.build(context) ?? Container(),
    );
  }
}

class CFloatingActionButton extends ClickableHolder {
  CFloatingActionButton()
      : super(
            'FloatingActionButton',
            [
              Parameters.backgroundColorParameter(),
              Parameters.foregroundColorParameter(),
              Parameters.elevationParameter(),
              Parameters.enableParameter()
                ..withNamedParamInfoAndSameDisplayName('enableFeedback'),
              Parameters.textParameter()
                ..withNamedParamInfoAndSameDisplayName('tooltip'),
              Parameters.elevationParameter()
                ..withNamedParamInfoAndSameDisplayName('hoverElevation'),
              Parameters.elevationParameter()
                ..withNamedParamInfoAndSameDisplayName('focusElevation'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('hoverColor'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('focusColor'),
              Parameters.colorParameter
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('splashColor'),
            ],
            defaultParamConfig: ComponentDefaultParamConfig(
              padding: true,
              width: true,
              visibility: true,
              alignment: true,
              height: true,
            ),
            boundaryRepaintDelay: 400) {
    methods([FVBFunction('onPressed', null, [], returnType: DataType.fvbVoid)]);
  }

  @override
  Widget create(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        perform(context);
      },
      heroTag: null,
      backgroundColor: parameters[0].value,
      foregroundColor: parameters[1].value,
      elevation: parameters[2].value,
      enableFeedback: parameters[3].value,
      tooltip: parameters[4].value,
      hoverElevation: parameters[5].value,
      focusElevation: parameters[6].value,
      hoverColor: parameters[7].value,
      focusColor: parameters[8].value,
      splashColor: parameters[9].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CTextButton extends ClickableHolder {
  CTextButton()
      : super('TextButton', [Parameters.buttonStyleParameter()],
            defaultParamConfig: ComponentDefaultParamConfig(
              padding: true,
              width: true,
              height: true,
            )) {
    methods([FVBFunction('onPressed', null, [], returnType: DataType.fvbVoid)]);
  }

  @override
  Widget create(BuildContext context) {
    return TextButton(
      onPressed: () {
        perform(context);
      },
      style: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CSizedBox extends Holder with Resizable, CRenderModel {
  CSizedBox()
      : super('SizedBox', [
          Parameters.widthParameter()..withDefaultValue(50.0),
          Parameters.heightParameter()..withDefaultValue(50.0),
        ]);

  @override
  Widget create(BuildContext context) {
    return SizedBox(
      width: parameters[0].value,
      height: parameters[1].value,
      child: child?.build(context),
    );
  }

  @override
  void onResize(Size size) {
    linearChange(parameters[0], (parameters[0].value ?? boundary?.width ?? 0),
        size.width);
    linearChange(parameters[1], (parameters[1].value ?? boundary?.height ?? 0),
        size.height);
  }

  @override
  Size get childSize => Size(parameters[0].value ?? double.infinity,
      parameters[1].value ?? double.infinity);

  @override
  Size get size => Size(parameters[0].value ?? double.infinity,
      parameters[1].value ?? double.infinity);

  @override
  ResizeType get resizeType => ResizeType.verticalAndHorizontal;

  @override
  List<Parameter> get resizeAffectedParameters =>
      [parameters[0], parameters[1]];

  @override
  EdgeInsets get margin => EdgeInsets.zero;
}

class CShimmerFromColors extends Holder {
  CShimmerFromColors()
      : super('Shimmer.fromColors', [
          Parameters.enableParameter(),
          Parameters.colorParameter
            ..withNamedParamInfoAndSameDisplayName('baseColor')
            ..withRequired(true)
            ..withDefaultValue(ColorAssets.white),
          Parameters.colorParameter
            ..withNamedParamInfoAndSameDisplayName('highlightColor')
            ..withRequired(true)
            ..withDefaultValue(ColorAssets.shimmerColor),
          Parameters.durationParameter
            ..compiler.code = 'Duration(milliseconds: 500)',
        ]);

  @override
  Widget create(BuildContext context) {
    final period = parameters[3].value;
    return Shimmer.fromColors(
      key: ValueKey(period),
      enabled: parameters[0].value,
      baseColor: parameters[1].value,
      highlightColor: parameters[2].value,
      period: period,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CForm extends Holder with Clickable, Controller {
  CForm()
      : super('Form', [
          Parameters.autoValidateMode,
        ]) {
    methods([FVBFunction('onChanged', null, [], returnType: DataType.fvbVoid)]);
    assign('key', (context, ticker) => GlobalKey<FormState>(),
        'GlobalKey<FormState>()');
  }

  @override
  Widget create(BuildContext context) {
    return Form(
      key: values['key'],
      onChanged: () {
        perform(context);
      },
      autovalidateMode: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CBackdropFilter extends Holder {
  CBackdropFilter() : super('BackdropFilter', [Parameters.filterParameter()]);

  @override
  Widget create(BuildContext context) {
    return BackdropFilter(
      filter: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CSizedBoxShrink extends Holder {
  CSizedBoxShrink() : super('SizedBox.shrink', []);

  @override
  Widget create(BuildContext context) {
    return SizedBox.shrink(
      child: child?.build(context),
    );
  }
}

class CSizedBoxFromSize extends Holder {
  CSizedBoxFromSize()
      : super('SizedBox.fromSize', [
          Parameters.sizeParameter()
            ..withNamedParamInfoAndSameDisplayName('size')
            ..withRequired(false)
        ]);

  @override
  Widget create(BuildContext context) {
    return SizedBox.fromSize(
      size: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CSizedBoxExpand extends Holder {
  CSizedBoxExpand() : super('SizedBox.expand', []);

  @override
  Widget create(BuildContext context) {
    return SizedBox.expand(
      child: child?.build(context),
    );
  }
}

class CPreferredSize extends Holder {
  CPreferredSize()
      : super('PreferredSize', [
          Parameters.sizeParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return PreferredSize(
      preferredSize: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CFittedBox extends Holder {
  CFittedBox()
      : super('FittedBox', [
          Parameters.boxFitParameter(),
          Parameters.alignmentParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return FittedBox(
      fit: parameters[0].value,
      alignment: parameters[1].value,
      child: child?.build(context),
    );
  }
}

class CMaterial extends Holder {
  CMaterial()
      : super('Material', [
          Parameters.colorParameter..withDefaultValue(const Color(0x00000000))
        ]);

  @override
  Widget create(BuildContext context) {
    return Material(
      color: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CExpanded extends Holder with CParentFlexModel {
  CExpanded() : super('Expanded', [Parameters.flexParameter()], required: true);

  @override
  int get flex => parameters[0].value;

  @override
  Widget create(BuildContext context) {
    return Expanded(
      flex: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CIntrinsicWidth extends Holder {
  CIntrinsicWidth()
      : super(
            'IntrinsicWidth',
            [
              Parameters.widthParameter()
                ..withDefaultValue(null)
                ..withNamedParamInfoAndSameDisplayName('stepWidth'),
              Parameters.widthParameter()
                ..withDefaultValue(null)
                ..withNamedParamInfoAndSameDisplayName('stepHeight')
            ],
            required: false);

  @override
  Widget create(BuildContext context) {
    return IntrinsicWidth(
      stepWidth: parameters[0].value,
      stepHeight: parameters[1].value,
      child: child?.build(context),
    );
  }
}

class CIntrinsicHeight extends Holder {
  CIntrinsicHeight() : super('IntrinsicWidth', [], required: false);

  @override
  Widget create(BuildContext context) {
    return IntrinsicHeight(
      child: child?.build(context),
    );
  }
}

class CSafeArea extends Holder with CRenderModel {
  CSafeArea()
      : super(
            'SafeArea',
            [
              Parameters.enableParameter()
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('top'),
              Parameters.enableParameter()
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('bottom'),
              Parameters.enableParameter()
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('left'),
              Parameters.enableParameter()
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('right')
            ],
            required: true);

  @override
  Widget create(BuildContext context) {
    return Padding(
      padding: RuntimeProvider.of(context) == RuntimeMode.run
          ? EdgeInsets.only(
              top: parameters[0].value
                  ? (defaultDeviceInfo?.safeAreas.top ?? 0)
                  : 0,
              bottom: parameters[1].value
                  ? (defaultDeviceInfo?.safeAreas.bottom ?? 0)
                  : 0,
              left: parameters[2].value
                  ? (defaultDeviceInfo?.safeAreas.left ?? 0)
                  : 0,
              right: parameters[3].value
                  ? (defaultDeviceInfo?.safeAreas.right ?? 0)
                  : 0,
            )
          : EdgeInsets.zero,
      child: child?.build(context) ?? Container(),
    );
  }

  @override
  Size get childSize => Size.infinite;

  @override
  EdgeInsets get margin => EdgeInsets.zero;

  @override
  Size get size => Size.infinite;
}

class CHero extends Holder {
  CHero()
      : super('Hero', [
          Parameters.tagParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Hero(
      tag: parameters[0].value,
      child: child?.build(context) ?? const Offstage(),
    );
  }
}

class CCenter extends Holder {
  CCenter()
      : super('Center', [
          Parameters.widthFactorParameter(),
          Parameters.heightFactorParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Center(
      widthFactor: parameters[0].value,
      heightFactor: parameters[1].value,
      child: child?.build(context),
    );
  }
}

class CPositioned extends Holder with Movable {
  CPositioned()
      : super('Positioned', [
          Parameters.nullableDoubleParameter('left'),
          Parameters.nullableDoubleParameter('right'),
          Parameters.nullableDoubleParameter('top'),
          Parameters.nullableDoubleParameter('bottom'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Positioned(
      left: parameters[0].value,
      right: parameters[1].value,
      top: parameters[2].value,
      bottom: parameters[3].value,
      child: child?.build(context) ?? Container(),
    );
  }

  @override
  MoveType get moveType => MoveType.self;

  @override
  void onMove(Offset offset) {
    linearChange(parameters[0], parameters[0].value ?? 0, offset.dx);
    linearChange(parameters[2], parameters[2].value ?? 0, offset.dy);
  }

  @override
  List<Parameter> get movableAffectedParameters =>
      [parameters[0], parameters[2]];
}

class CAlign extends Holder {
  CAlign()
      : super('Align', [
          Parameters.alignmentParameter(),
          Parameters.widthFactorParameter(),
          Parameters.heightFactorParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Align(
      alignment: parameters[0].value,
      widthFactor: parameters[1].value,
      heightFactor: parameters[2].value,
      child: child?.build(context),
    );
  }
}

class CAspectRatio extends Holder {
  CAspectRatio() : super('AspectRatio', [Parameters.aspectParameter()]);

  @override
  Widget create(BuildContext context) {
    return AspectRatio(
      aspectRatio: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CFractionallySizedBox extends Holder {
  CFractionallySizedBox()
      : super('FractionallySizedBox', [
          Parameters.widthFactorParameter()..withDefaultValue(1.0),
          Parameters.heightFactorParameter()..withDefaultValue(1.0),
          Parameters.alignmentParameter()
        ]);

  @override
  Widget create(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: parameters[0].value,
      heightFactor: parameters[1].value,
      alignment: parameters[2].value,
      child: child?.build(context),
    );
  }
}

class CFlexible extends Holder with CParentFlexModel {
  CFlexible() : super('Flexible', [Parameters.flexParameter()], required: true);

  @override
  int get flex => parameters[0].value;

  @override
  Widget create(BuildContext context) {
    return Flexible(
      flex: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

///TODO(AddReplacement):
class CVisibility extends CustomNamedHolder {
  CVisibility()
      : super(
          'Visibility',
          [
            Parameters.visibleParameter,
          ],
          ['child', 'replacement'],
          [],
        );

  @override
  Widget create(BuildContext context) {
    return Visibility(
      visible: parameters[0].value,
      child: childMap['child']?.build(context) ?? const Offstage(),
      replacement:
          childMap['replacement']?.build(context) ?? const SizedBox.shrink(),
    );
  }
}
