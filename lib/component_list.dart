import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/data_type.dart';

final componentList = [
  CRow(),
];

class Parameters{
  static final paddingParameter=ChoiceParameter(
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
    ],
  );
  static final colorParameter=SimpleParameter(name: 'color', paramType: ParamType.string, nullable: false);
}
class CRow extends Component {
  CRow()
      : super('Row', [
          ChoiceValueParameter(name: 'mainAxisAlignment', options: {
            'start': MainAxisAlignment.start,
            'center': MainAxisAlignment.center,
            'end': MainAxisAlignment.end,
            'spaceBetween': MainAxisAlignment.spaceBetween,
            'spaceAround': MainAxisAlignment.spaceAround,
            'spaceEvenly': MainAxisAlignment.spaceEvenly,
          }),
          ChoiceValueParameter(name: 'crossAxisAlignment', options: {
            'start': CrossAxisAlignment.start,
            'center': CrossAxisAlignment.center,
            'end': CrossAxisAlignment.end,
            'stretch': CrossAxisAlignment.stretch,
            'baseline': CrossAxisAlignment.baseline,
          }),
          ChoiceValueParameter(name: 'mainAxisSize', options: {
            'max': MainAxisSize.max,
            'min': MainAxisSize.min,
          }),
          MultiComponentParameter(name: 'children'),
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
      children: (parameters[3] as MultiComponentParameter)
              .components
              ?.map((e) => e.create())
              .toList() ??
          [],
    );
  }
}

class CPadding extends Component {
  CPadding()
      : super('Padding', [
         Parameters.paddingParameter
        ]);

  @override
  String code() {
    return '';
  }

  @override
  Widget create() {
   return Padding(
     padding: parameters[0].value,
   );
  }
}

class CContainer extends Component {
  CContainer() : super('Container', [
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

    );
  }

}
