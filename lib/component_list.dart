import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/data_type.dart';
import 'package:flutter_builder/parameter_model.dart';

final componentList = {
  'Row': () => CRow(),
  'Column': () => CColumn(),
  'Flex': () => CFlex(),
  'Padding': () => CPadding(),
  'ClipRRect': () => CClipRRect(),
  'Container': () => CContainer(),
  'Text': () => CText(),
};

class Parameters {
  static paddingParameter() => ChoiceParameter(
        name: 'padding',
        info: NamedParameterInfo('padding'),
        options: [
          SimpleParameter<double>(
            info: InnerObjectParameterInfo(innerObjectName: 'EdgeInsets.all',),
              name: 'all',
              paramType: ParamType.double,
              evaluate: (value) => EdgeInsets.all(value)),
          ComplexParameter(
            name: 'only',
            info: InnerObjectParameterInfo(innerObjectName: 'EdgeInsets.only',),
            params: [
              SimpleParameter<double>(
                name: 'top',
                info: NamedParameterInfo('top'),
                paramType: ParamType.double,
              ),
              SimpleParameter<double>(
                name: 'left',
                info: NamedParameterInfo('left'),
                paramType: ParamType.double,
              ),
              SimpleParameter<double>(
                name: 'bottom',
                info: NamedParameterInfo('bottom'),
                paramType: ParamType.double,
              ),
              SimpleParameter<double>(
                name: 'right',
                info: NamedParameterInfo('right'),
                paramType: ParamType.double,
              )
            ],
            evaluate: (List<Parameter> params) {
              return EdgeInsets.only(
                top: params[0].value,
                left: params[1].value,
                bottom: params[2].value,
                right: params[3].value,
              );
            }, generateCode: (String middle) {
              return 'EdgeInsets.only($middle)';
          },
          ),
          ComplexParameter(
            name: 'symmetric',
            params: [
              SimpleParameter<double>(
                name: 'horizontal',
                paramType: ParamType.double,
              ),
              SimpleParameter<double>(
                name: 'vertical',
                paramType: ParamType.double,
              ),
            ],
            evaluate: (List<Parameter> params) {
              return EdgeInsets.symmetric(
                horizontal: params[0].value,
                vertical: params[1].value,
              );
            }, generateCode: (String middle) {
              return 'EdgeInsets.symmetric($middle)';
          },
          ),
        ],
        defaultValue: 0,
      );

  static alignmentParameter() => ChoiceValueParameter(
      name: 'alignment',
      options: {
        'centerLeft': Alignment.centerLeft,
        'center': Alignment.center,
        'centerRight': Alignment.centerRight,
        'topLeft': Alignment.topLeft,
        'topRight': Alignment.topRight,
        'bottomLeft': Alignment.bottomLeft,
        'bottomRight': Alignment.bottomRight,
      },
      defaultValue: 'center');

  static marginParameter() => paddingParameter().copyWith('margin');

  static colorParameter() => SimpleParameter<String>(
        name: 'color',
        paramType: ParamType.string,
        defaultValue: '#000000',
    evaluate: (value) => hexToColor(value)
      );

  static mainAxisAlignmentParameter() => ChoiceValueParameter(
      name: 'mainAxisAlignment',
      options: {
        'start': MainAxisAlignment.start,
        'center': MainAxisAlignment.center,
        'end': MainAxisAlignment.end,
        'spaceBetween': MainAxisAlignment.spaceBetween,
        'spaceAround': MainAxisAlignment.spaceAround,
        'spaceEvenly': MainAxisAlignment.spaceEvenly,
      },
      defaultValue: 'start',);

  static crossAxisAlignmentParameter() => ChoiceValueParameter(
      name: 'crossAxisAlignment',
      options: {
        'start': CrossAxisAlignment.start,
        'center': CrossAxisAlignment.center,
        'end': CrossAxisAlignment.end,
        'stretch': CrossAxisAlignment.stretch,
        'baseline': CrossAxisAlignment.baseline,
      },
      defaultValue: 'start', );

  static mainAxisSizeParameter() => ChoiceValueParameter(
      name: 'mainAxisSize',
      options: {
        'max': MainAxisSize.max,
        'min': MainAxisSize.min,
      },
      defaultValue: 'max');

  static axisParameter() => ChoiceValueParameter(
      name: 'direction',
      options: {'vertical': Axis.vertical, 'horizontal': Axis.horizontal},
      defaultValue: 'vertical');

  static borderRadiusParameter() => ChoiceParameter(
        name: 'borderRadius',
        options: [
          SimpleParameter<double>(
              paramType: ParamType.double,
              name: 'circular',
              evaluate: (value) {
                return BorderRadius.circular(value);
              }),
          ComplexParameter(
              params: [
                SimpleParameter<double>(
                  paramType: ParamType.double,
                  name: 'topLeft',
                ),
                SimpleParameter<double>(
                  paramType: ParamType.double,
                  name: 'bottomLeft',
                ),
                SimpleParameter<double>(
                  paramType: ParamType.double,
                  name: 'topRight',
                ),
                SimpleParameter<double>(
                  paramType: ParamType.double,
                  name: 'bottomRight',
                ),
              ],
              evaluate: (List<Parameter> params) {
                return BorderRadius.only(
                  topLeft: Radius.circular(params[0].value),
                  bottomLeft: Radius.circular(params[1].value),
                  topRight: Radius.circular(params[2].value),
                  bottomRight: Radius.circular(params[3].value),
                );
              },
              name: 'only', generateCode: (String middle) {
                return 'BorderRadius.only(\n$middle)';
          })
        ],
        defaultValue: 0,
      );

  static widthParameter() => SimpleParameter<double>(
      name: 'width', paramType: ParamType.double, defaultValue: 100);

  static heightParameter() => SimpleParameter<double>(
      name: 'height', paramType: ParamType.double, defaultValue: 100);
}

Color hexToColor(String code) {
  if (code.length == 7) {
    return Color(
        (int.tryParse(code.substring(1, 7), radix: 16) ?? 0) + 0xFF000000);
  }
  return Colors.white;
}

class CRow extends MultiHolder {
  CRow()
      : super('Row', [
          Parameters.mainAxisAlignmentParameter(),
          Parameters.crossAxisAlignmentParameter(),
          Parameters.mainAxisSizeParameter()
        ]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
    return Row(
      mainAxisAlignment: parameters[0].value,
      crossAxisAlignment: parameters[1].value,
      mainAxisSize: parameters[2].value,
      children: children.map((e) => e.create()).toList(),
    );
  }
}

class CColumn extends MultiHolder {
  CColumn()
      : super('Column', [
          Parameters.mainAxisAlignmentParameter(),
          Parameters.crossAxisAlignmentParameter(),
          Parameters.mainAxisSizeParameter()
        ]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
    return Column(
      mainAxisAlignment: (parameters[0] as ChoiceValueParameter).value,
      crossAxisAlignment: (parameters[1] as ChoiceValueParameter).value,
      mainAxisSize: (parameters[2] as ChoiceValueParameter).value,
      children: children.map((e) => e.create()).toList(),
    );
  }
}

class CFlex extends MultiHolder {
  CFlex()
      : super('Flex', [
          Parameters.mainAxisAlignmentParameter(),
          Parameters.crossAxisAlignmentParameter(),
          Parameters.mainAxisSizeParameter(),
          Parameters.axisParameter()
        ]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
    return Flex(
      mainAxisAlignment: (parameters[0] as ChoiceValueParameter).value,
      crossAxisAlignment: (parameters[1] as ChoiceValueParameter).value,
      mainAxisSize: (parameters[2] as ChoiceValueParameter).value,
      children: children.map((e) => e.create()).toList(),
      direction: (parameters[3] as ChoiceValueParameter).value,
    );
  }
}

class CPadding extends Holder {
  CPadding() : super('Padding', [Parameters.paddingParameter()]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
    return Padding(
      padding: parameters[0].value,
      child: child?.create(),
    );
  }
}

class CClipRRect extends Holder {
  CClipRRect() : super('ClipRRect', [Parameters.borderRadiusParameter()]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
    return ClipRRect(
      child: child?.create(),
      borderRadius: parameters[0].value,
    );
  }
}

class CContainer extends Holder {
  CContainer()
      : super('Container', [
          Parameters.colorParameter(),
          Parameters.paddingParameter(),
          Parameters.borderRadiusParameter(),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.marginParameter(),
          Parameters.alignmentParameter(),
        ]);

  @override
  String code() {
    String middle='';
    for(final para in parameters){
      middle+=para.code;
    }
    return 'Container($middle),';
  }

  @override
  Widget create() {
    return Container(
      child: child?.create(),
      padding: parameters[1].value,
      width: parameters[3].value,
      height: parameters[4].value,
      margin: parameters[5].value,
      alignment: parameters[6].value,
      decoration: BoxDecoration(
        color: parameters[0].value,
        borderRadius: parameters[2].value,
      ),
    );
  }
}

class CText extends Component {
  CText()
      : super('Text', [
          SimpleParameter<String>(
              name: 'text', paramType: ParamType.string, defaultValue: ''),
          ComplexParameter(
              params: [
                SimpleParameter<double>(
                    name: 'font-size',
                    paramType: ParamType.double,
                    defaultValue: 13),
                Parameters.colorParameter(),
                ChoiceValueParameter(options: {
                  'w200': FontWeight.w200,
                  'w300': FontWeight.w300,
                  'w400': FontWeight.w400,
                  'w500': FontWeight.w500,
                  'normal': FontWeight.normal,
                  'w600': FontWeight.w600,
                  'w700': FontWeight.w700,
                  'w800': FontWeight.w800,
                  'w900': FontWeight.w900,
                }, defaultValue: 'normal', name: 'font-weight'),
              ],
              name: 'Style',
              evaluate: (params) {
                return TextStyle(
                    fontSize: params[0].value,
                    color: params[1].value,
                    fontWeight: params[2].value);
              }, generateCode: (String ) { return ''; })
        ]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
    return Text(
      parameters[0].value,
      style: parameters[1].value,
    );
  }
}
