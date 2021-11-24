import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/data_type.dart';

final componentList = [
  CRow(),
  CColumn(),
  CFlex(),
  CPadding(),
];

class Parameters {
  static final paddingParameter = ChoiceParameter(
    name: 'padding',
    options: [
      SimpleParameter(
          name: 'all',
          nullable: false,
          paramType: ParamType.double,
          evaluate: (param) => EdgeInsets.all(param.value)),
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
    ],
  );
  static final colorParameter = SimpleParameter(
      name: 'color', paramType: ParamType.string, nullable: false);
  static final mainAxisAlignmentParameter =
      ChoiceValueParameter(name: 'mainAxisAlignment', options: {
    'start': MainAxisAlignment.start,
    'center': MainAxisAlignment.center,
    'end': MainAxisAlignment.end,
    'spaceBetween': MainAxisAlignment.spaceBetween,
    'spaceAround': MainAxisAlignment.spaceAround,
    'spaceEvenly': MainAxisAlignment.spaceEvenly,
  });
  static final crossAxisAlignmentParameter =
      ChoiceValueParameter(name: 'crossAxisAlignment', options: {
    'start': CrossAxisAlignment.start,
    'center': CrossAxisAlignment.center,
    'end': CrossAxisAlignment.end,
    'stretch': CrossAxisAlignment.stretch,
    'baseline': CrossAxisAlignment.baseline,
  });
  static final mainAxisSizeParameter =
      ChoiceValueParameter(name: 'mainAxisSize', options: {
    'max': MainAxisSize.max,
    'min': MainAxisSize.min,
  });
  static final axisParameter = ChoiceValueParameter(
      name: 'direction',
      options: {'vertical': Axis.vertical, 'horizontal': Axis.horizontal});
  static final borderRadiusParameter = ChoiceValueParameter(
      name: 'borderRadius',
      options: {
        'circular': SimpleParameter(paramType: ParamType.double, name: 'radius', nullable: false,evaluate: (param){
          return BorderRadius.circular(param.value);
        }),
        ''
      });
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

class CContainer extends Holder {
  CContainer()
      : super('Container', [
          Parameters.colorParameter,
          Parameters.paddingParameter,
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
      decoration: BoxDecoration(
        color: parameters[0].value,
      ),
    );
  }
}
