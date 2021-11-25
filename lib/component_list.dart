import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/data_type.dart';

final componentList = {
  'Row': () => CRow(),
  'Column': () => CColumn(),
  'Flex': () => CFlex(),
  'Padding': () => CPadding(),
  'ClipRRect': () => CClipRRect(),
  'Container': () => CContainer(),
};

class Parameters {
  static final paddingParameter = ChoiceParameter(
    name: 'padding',
    options: [
      SimpleParameter<double>(
          name: 'all',
          paramType: ParamType.double,
          evaluate: (value) => EdgeInsets.all(value)),
      ComplexParameter(
          name: 'only',
          params: [
            SimpleParameter<double>(
              name: 'top',
              paramType: ParamType.double,
            ),
            SimpleParameter<double>(
              name: 'left',
              paramType: ParamType.double,
            ),
            SimpleParameter<double>(
              name: 'bottom',
              paramType: ParamType.double,
            ),
            SimpleParameter<double>(
              name: 'right',
              paramType: ParamType.double,
            )
          ],
          evaluate: (List<Parameter> params) {
            return EdgeInsets.only(
                top: params[0].value,
                left: params[1].value,
                bottom: params[2].value,
                right: params[3].value);
          }),
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
        },
      ),
    ],
    defaultValue: 0,
  );
  static final colorParameter = SimpleParameter<String>(
      name: 'color',
      paramType: ParamType.string,
      defaultValue: '#ffffff',
      evaluate: (value) => hexToColor(value));
  static final mainAxisAlignmentParameter = ChoiceValueParameter(
      name: 'mainAxisAlignment',
      options: {
        'start': MainAxisAlignment.start,
        'center': MainAxisAlignment.center,
        'end': MainAxisAlignment.end,
        'spaceBetween': MainAxisAlignment.spaceBetween,
        'spaceAround': MainAxisAlignment.spaceAround,
        'spaceEvenly': MainAxisAlignment.spaceEvenly,
      },
      defaultValue: 'start');
  static final crossAxisAlignmentParameter = ChoiceValueParameter(
      name: 'crossAxisAlignment',
      options: {
        'start': CrossAxisAlignment.start,
        'center': CrossAxisAlignment.center,
        'end': CrossAxisAlignment.end,
        'stretch': CrossAxisAlignment.stretch,
        'baseline': CrossAxisAlignment.baseline,
      },
      defaultValue: 'start');
  static final mainAxisSizeParameter = ChoiceValueParameter(
      name: 'mainAxisSize',
      options: {
        'max': MainAxisSize.max,
        'min': MainAxisSize.min,
      },
      defaultValue: 'max');
  static final axisParameter = ChoiceValueParameter(
      name: 'direction',
      options: {'vertical': Axis.vertical, 'horizontal': Axis.horizontal},
      defaultValue: 'vertical');
  static final borderRadiusParameter = ChoiceParameter(
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
                topLeft: params[0].value,
                bottomLeft: params[1].value,
                topRight: params[2].value,
                bottomRight: params[3].value);
          },
          name: 'only')
    ],
    defaultValue: 0,
  );
  static final widthParameter =
      SimpleParameter<double>(name: 'width', paramType: ParamType.double,defaultValue: 100);
  static final heightParameter =
      SimpleParameter<double>(name: 'height', paramType: ParamType.double,defaultValue: 100);
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
          Parameters.mainAxisAlignmentParameter,
          Parameters.crossAxisAlignmentParameter,
          Parameters.mainAxisSizeParameter
        ]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
    return Row(
      mainAxisAlignment: parameters[0].value,
      crossAxisAlignment:parameters[1].value,
      mainAxisSize: parameters[2].value,
      children: children.map((e) => e.create()).toList(),
    );
  }
}

class CColumn extends MultiHolder {
  CColumn()
      : super('Column', [
          Parameters.mainAxisAlignmentParameter,
          Parameters.crossAxisAlignmentParameter,
          Parameters.mainAxisSizeParameter
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
          Parameters.mainAxisAlignmentParameter,
          Parameters.crossAxisAlignmentParameter,
          Parameters.mainAxisSizeParameter,
          Parameters.axisParameter
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
  CPadding() : super('Padding', [Parameters.paddingParameter]);

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
  CClipRRect() : super('ClipRRect', [Parameters.borderRadiusParameter]);

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
          Parameters.colorParameter,
          Parameters.paddingParameter,
          Parameters.borderRadiusParameter,
          Parameters.widthParameter,
          Parameters.heightParameter,
        ]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
    return Container(
      child: child?.create(),
      margin: parameters[1].value,
      width: parameters[3].value,
      height: parameters[4].value,
      decoration: BoxDecoration(
        color: parameters[0].value,
        borderRadius: parameters[2].value,
      ),
    );
  }
}
