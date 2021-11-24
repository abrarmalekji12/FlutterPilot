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
      SimpleParameter(
          name: 'all',
          nullable: false,
          defaultValue: 0,
          paramType: ParamType.double,
          evaluate: (param) => EdgeInsets.all(param.rawValue)),
      ComplexParameter(
          name: 'only',
          params: [
            SimpleParameter(
              name: 'top',
              nullable: false,
              paramType: ParamType.double,
            ),
            SimpleParameter(
              name: 'left',
              nullable: false,
              paramType: ParamType.double,
            ),
            SimpleParameter(
              name: 'bottom',
              nullable: false,
              paramType: ParamType.double,
            ),
            SimpleParameter(
              name: 'right',
              nullable: false,
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
          SimpleParameter(
            name: 'horizontal',
            nullable: true,
            paramType: ParamType.double,
          ),
          SimpleParameter(
            name: 'vertical',
            nullable: true,
            paramType: ParamType.double,
          ),
        ],
        evaluate: (List<Parameter> params) {
          return EdgeInsets.only(
              top: params[0].value,
              left: params[1].value,
              bottom: params[2].value,
              right: params[3].value);
        },
      ),
    ], defaultValue: 0,
  );
  static final colorParameter = SimpleParameter(
      name: 'color',
      paramType: ParamType.string,
      nullable: false,
      defaultValue: '0xffffffff',evaluate: (param)=>Color(param.value));
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
        SimpleParameter(
            paramType: ParamType.double,
            name: 'circular',
            nullable: false,
            evaluate: (param) {
              return BorderRadius.all(param.value);
            }),
        ComplexParameter(
            params: [
              SimpleParameter(
                  paramType: ParamType.double, name: 'topLeft', nullable: true),
              SimpleParameter(
                  paramType: ParamType.double,
                  name: 'bottomLeft',
                  nullable: true),
              SimpleParameter(
                  paramType: ParamType.double,
                  name: 'topRight',
                  nullable: true),
              SimpleParameter(
                  paramType: ParamType.double,
                  name: 'bottomRight',
                  nullable: true),
            ],
            evaluate: (List<Parameter> params) {
              return BorderRadius.only(
                  topLeft: params[0].value,
                  bottomLeft: params[1].value,
                  topRight: params[2].value,
                  bottomRight: params[3].value);
            },
            name: 'only')
      ], defaultValue: 0,);
  static final widthParameter = SimpleParameter(
      name: 'width', paramType: ParamType.double, nullable: true);
  static final heightParameter = SimpleParameter(
      name: 'height', paramType: ParamType.double, nullable: true);
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
    throw Row(
      mainAxisAlignment: (parameters[0] as ChoiceValueParameter).value,
      crossAxisAlignment: (parameters[1] as ChoiceValueParameter).value,
      mainAxisSize: (parameters[2] as ChoiceValueParameter).value,
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
    throw Column(
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
    throw Flex(
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
      padding: parameters[1].value,
      width: parameters[3].value,
      height: parameters[4].value,
      decoration: BoxDecoration(
        color: parameters[0].value,
        borderRadius: parameters[2].value,
      ),
    );
  }
}
