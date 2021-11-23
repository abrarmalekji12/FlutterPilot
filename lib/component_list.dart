import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/data_type.dart';

final componentList = [
  CRow(),
];

class CRow extends Component {
  CRow()
      : super('Row', [
          ChoiceParameter(name: 'mainAxisAlignment', options: {
            'start': MainAxisAlignment.start,
            'center': MainAxisAlignment.center,
            'end': MainAxisAlignment.end,
            'spaceBetween': MainAxisAlignment.spaceBetween,
            'spaceAround': MainAxisAlignment.spaceAround,
            'spaceEvenly': MainAxisAlignment.spaceEvenly,
          }),
          ChoiceParameter(name: 'crossAxisAlignment', options: {
            'start': CrossAxisAlignment.start,
            'center': CrossAxisAlignment.center,
            'end': CrossAxisAlignment.end,
            'stretch': CrossAxisAlignment.stretch,
            'baseline': CrossAxisAlignment.baseline,
          }),
          ChoiceParameter(name: 'mainAxisSize', options: {
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
      mainAxisAlignment: (parameters[0] as ChoiceParameter).value,
      crossAxisAlignment: (parameters[1] as ChoiceParameter).value,
      mainAxisSize: (parameters[2] as ChoiceParameter).value,
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
          ChoiceParameter(name: 'padding', options: {
            'all': SimpleParameter(
              name: 'all',
              nullable: false,
              paramType: ParamType.double,
            ),
            'only': ComplexParameter('only', [
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
              ),
            ])
          })
        ]);

  @override
  String code() {
    return Padding(
      padding: parameters[0],
    );
  }

  @override
  Widget create() {
    // TODO: implement create
    throw UnimplementedError();
  }
}
