import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/enums.dart';
import 'package:flutter_builder/parameter_info.dart';
import 'package:flutter_builder/parameter_model.dart';

final componentList = {
  'Scaffold': () => CScaffold(),
  'AppBar': () => CAppBar(),
  'Row': () => CRow(),
  'Column': () => CColumn(),
  'Flex': () => CFlex(),
  'Padding': () => CPadding(),
  'ClipRRect': () => CClipRRect(),
  'Container': () => CContainer(),
  'Expanded': () => CExpanded(),
  'Center': () => CCenter(),
  'FractionallySizedBox': () => CFractionallySizedBox(),
  'Flexible': () => CFlexible(),
  'Card': () => CCard(),
  'SizedBox': () => CSizedBox(),
  'Text': () => CText(),
};

class Parameters {
  static paddingParameter() => ChoiceParameter(
        name: 'padding',
        info: NamedParameterInfo('padding'),
        options: [
          SimpleParameter<double>(
              name: 'all',
              info: InnerObjectParameterInfo(
                innerObjectName: 'EdgeInsets.all',
              ),
              paramType: ParamType.double,
              evaluate: (value) => EdgeInsets.all(value)),
          ComplexParameter(
            name: 'only',
            info: InnerObjectParameterInfo(
              innerObjectName: 'EdgeInsets.only',
            ),
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
            },
          ),
          ComplexParameter(
            name: 'symmetric',
            info: InnerObjectParameterInfo(
              innerObjectName: 'EdgeInsets.symmetric',
            ),
            params: [
              SimpleParameter<double>(
                name: 'horizontal',
                info: NamedParameterInfo('horizontal'),
                paramType: ParamType.double,
              ),
              SimpleParameter<double>(
                name: 'vertical',
                info: NamedParameterInfo('vertical'),
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

  static decorationParameter() => ComplexParameter(
          params: [
            colorParameter()..withDefaultValue(const Color(0xff000000)),
            borderRadiusParameter(),
            borderParameter()
          ],
          name: 'decoration',
          evaluate: (params) {
            return BoxDecoration(
              color: params[0].value,
              borderRadius: params[1].value,
              border: params[2].value,
            );
          },
          info: InnerObjectParameterInfo(
              innerObjectName: 'BoxDecoration', namedIfHaveAny: 'decoration'));

  static borderParameter() => ChoiceParameter(
      name: 'border',
      // info: NamedParameterInfo('border'),
      options: [
        ComplexParameter(
          info: InnerObjectParameterInfo(
              innerObjectName: 'Border.all', namedIfHaveAny: 'border'),
          params: [
            colorParameter()..withDefaultValue(const Color(0xffffffff)),
            widthParameter()
              ..withDefaultValue(2)
              ..withRequired(true),
          ],
          name: 'all',
          evaluate: (params) => Border.all(
            color: params[0].value,
            width: params[1].value,
          ),
        ),
        NullParameter(displayName: 'none', info: NamedParameterInfo('border'))
      ],
      defaultValue: 1);

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

  static marginParameter() => paddingParameter()
    ..withDisplayName('margin')
    ..withInfo(NamedParameterInfo('margin'));

  static SimpleParameter colorParameter() => SimpleParameter<Color>(
        name: 'color',
        paramType: ParamType.other,
        defaultValue: const Color(0xff000000),
        inputType: ParamInputType.color,
        info: NamedParameterInfo('color'),
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
        defaultValue: 'start',
      );

  static crossAxisAlignmentParameter() => ChoiceValueParameter(
        name: 'crossAxisAlignment',
        options: {
          'start': CrossAxisAlignment.start,
          'center': CrossAxisAlignment.center,
          'end': CrossAxisAlignment.end,
          'stretch': CrossAxisAlignment.stretch,
          'baseline': CrossAxisAlignment.baseline,
        },
        defaultValue: 'start',
      );

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
        info: NamedParameterInfo('borderRadius'),
        options: [
          SimpleParameter<double>(
              name: 'circular',
              info: InnerObjectParameterInfo(
                  innerObjectName: 'BorderRadius.circular'),
              paramType: ParamType.double,
              evaluate: (value) {
                return BorderRadius.circular(value);
              }),
          ComplexParameter(
            info:
                InnerObjectParameterInfo(innerObjectName: 'BorderRadius.only'),
            params: [
              SimpleParameter<double>(
                  paramType: ParamType.double,
                  name: 'topLeft',
                  info: InnerObjectParameterInfo(
                      innerObjectName: 'Radius.circular',
                      namedIfHaveAny: 'topLeft')),
              SimpleParameter<double>(
                  paramType: ParamType.double,
                  name: 'bottomLeft',
                  info: InnerObjectParameterInfo(
                      innerObjectName: 'Radius.circular',
                      namedIfHaveAny: 'bottomLeft')),
              SimpleParameter<double>(
                  paramType: ParamType.double,
                  name: 'topRight',
                  info: InnerObjectParameterInfo(
                      innerObjectName: 'Radius.circular',
                      namedIfHaveAny: 'topRight')),
              SimpleParameter<double>(
                  paramType: ParamType.double,
                  name: 'bottomRight',
                  info: InnerObjectParameterInfo(
                      innerObjectName: 'Radius.circular',
                      namedIfHaveAny: 'bottomRight')),
            ],
            evaluate: (List<Parameter> params) {
              return BorderRadius.only(
                topLeft: Radius.circular(params[0].value),
                bottomLeft: Radius.circular(params[1].value),
                topRight: Radius.circular(params[2].value),
                bottomRight: Radius.circular(params[3].value),
              );
            },
            name: 'only',
          )
        ],
        defaultValue: 0,
      );

  static SimpleParameter widthParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('width'),
      name: 'width',
      required: false,
      paramType: ParamType.double,
      defaultValue: 100);

  static SimpleParameter heightParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('height'),
      name: 'height',
      required: false,
      paramType: ParamType.double,
      defaultValue: 100);

  static SimpleParameter flexParameter() => SimpleParameter<int>(
      info: NamedParameterInfo('flex'),
      name: 'flex',
      required: true,
      paramType: ParamType.int,
      defaultValue: 1);

  static borderSideParameter() => ChoiceParameter(
      info: NamedParameterInfo('borderSide'),
      options: [
        ComplexParameter(
            info: InnerObjectParameterInfo(
              innerObjectName: 'BorderSide',
            ),
            params: [
              colorParameter(),
              widthParameter()
                ..withRequired(true)
                ..withDefaultValue(2)
            ],
            evaluate: (params) {
              return BorderSide(
                color: params[0].value,
                width: params[1].value,
              );
            }),
        ConstantValueParameter(
            displayName: 'None',
            constantValue: BorderSide.none,
            constantValueInString: 'BorderSide.none',
            paramType: ParamType.other)
      ],
      defaultValue: 0);

  static shapeBorderParameter() => ChoiceParameter(
          options: [
            NullParameter(displayName: 'None'),
            ComplexParameter(
              name: 'Round Rectangular Border',
              params: [
                borderRadiusParameter(),
                borderSideParameter(),
              ],
              evaluate: (params) {
                return RoundedRectangleBorder(
                    borderRadius: params[0].value, side: params[1].value);
              },
              info: InnerObjectParameterInfo(
                  innerObjectName: 'RoundedRectangleBorder'),
            )
          ],
          name: 'Shape Border',
          defaultValue: 0,
          info: NamedParameterInfo('shape'));

  static SimpleParameter widthFactorParameter() => SimpleParameter<double>(
      paramType: ParamType.double,
      defaultValue: null,
      inputType: ParamInputType.sliderZeroToOne,
      name: 'width factor',
      required: false,
      info: NamedParameterInfo('widthFactor'));

  static SimpleParameter heightFactorParameter() => SimpleParameter<double>(
      paramType: ParamType.double,
      defaultValue: null,
      inputType: ParamInputType.sliderZeroToOne,
      name: 'height factor',
      required: false,
      info: NamedParameterInfo('heightFactor'));

  static SimpleParameter elevationParameter() => SimpleParameter<double>(
      paramType: ParamType.double,
      defaultValue: 1,
      required: false,
      info: NamedParameterInfo('elevation'),
      name: 'elevation');
  static final toolbarHeight = heightParameter()
    ..withRequired(true)
    ..withDisplayName('toolbar-height')
    ..withInfo(NamedParameterInfo('toolbarHeight'))
    ..withDefaultValue(55);
}

class CExpanded extends Holder {
  CExpanded() : super('Expanded', [Parameters.flexParameter()],required: true);

  @override
  Widget create(BuildContext context) {
    return Expanded(
        flex: parameters[0].value, child: child?.build(context) ?? Container());
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
      child: child?.build(context),
      widthFactor: parameters[0].value,
      heightFactor: parameters[1].value,
    );
  }
}

class CFractionallySizedBox extends Holder {
  CFractionallySizedBox()
      : super('FractionallySizedBox', [
          Parameters.widthFactorParameter()..withDefaultValue(1),
          Parameters.heightFactorParameter()..withDefaultValue(1),
          Parameters.alignmentParameter()
        ]);

  @override
  Widget create(BuildContext context) {
    return FractionallySizedBox(
      child: child?.build(context),
      widthFactor: parameters[0].value,
      heightFactor: parameters[1].value,
      alignment: parameters[2].value,
    );
  }
}

class CFlexible extends Holder {
  CFlexible() : super('Flexible', [Parameters.flexParameter()],required: true);

  @override
  Widget create(BuildContext context) {
    return Flexible(
      flex: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CCard extends Holder {
  CCard()
      : super('Card', [
          Parameters.colorParameter(),
          Parameters.shapeBorderParameter(),
          Parameters.elevationParameter(),
          Parameters.marginParameter(),
          Parameters.colorParameter()
            ..withDisplayName('shadowColor')
            ..withInfo(
              NamedParameterInfo('shadowColor'),
            ),
        ]);

  @override
  Widget create(BuildContext context) {
    return Card(
      color: parameters[0].value,
      shape: parameters[1].value,
      elevation: parameters[2].value,
      margin: parameters[3].value,
      child: child?.build(context),
    );
  }
}

class CAppBar extends CustomNamedHolder {
  CAppBar()
      : super('AppBar', [
          Parameters.colorParameter()
            ..withDefaultValue(const Color(0xff0000ff))
            ..withDisplayName('background-color')
            ..withInfo(NamedParameterInfo('backgroundColor')),
          Parameters.toolbarHeight
        ], {
          'title': null,
          'leading': null,
        });

  @override
  Widget create(BuildContext context) {
    return AppBar(
      backgroundColor: parameters[0].value,
      title: children['title']?.build(context),
      leading: children['leading']?.build(context),
    );
  }
}

class CScaffold extends CustomNamedHolder {
  CScaffold()
      : super('Scaffold', [
          Parameters.colorParameter()
            ..withDisplayName('background-color')
            ..withDefaultValue(const Color(0xffffffff))
            ..withInfo(NamedParameterInfo('backgroundColor'))
        ], {
          'appBar': ['AppBar'],
          'body': null,
          'floatingActionButton': null
        });

  @override
  Widget create(BuildContext context) {
    return Scaffold(
      appBar: children['appBar'] != null
          ? PreferredSize(
              child: children['appBar']!.build(context),
              preferredSize: Size(-1, children['appBar']!.parameters[1].value))
          : null,
      body: children['body']?.build(context),
      backgroundColor: parameters[0].value,
      floatingActionButton: children['floatingActionButton']?.build(context),
    );
  }
}

class CRow extends MultiHolder {
  CRow()
      : super('Row', [
          Parameters.mainAxisAlignmentParameter(),
          Parameters.crossAxisAlignmentParameter(),
          Parameters.mainAxisSizeParameter()
        ]);

  @override
  Widget create(BuildContext context) {
    return Row(
      mainAxisAlignment: parameters[0].value,
      crossAxisAlignment: parameters[1].value,
      mainAxisSize: parameters[2].value,
      children: children.map((e) => e.build(context)).toList(),
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
  Widget create(BuildContext context) {
    return Column(
      mainAxisAlignment: (parameters[0] as ChoiceValueParameter).value,
      crossAxisAlignment: (parameters[1] as ChoiceValueParameter).value,
      mainAxisSize: (parameters[2] as ChoiceValueParameter).value,
      children: children.map((e) => e.build(context)).toList(),
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
  Widget create(BuildContext context) {
    return Flex(
      mainAxisAlignment: (parameters[0] as ChoiceValueParameter).value,
      crossAxisAlignment: (parameters[1] as ChoiceValueParameter).value,
      mainAxisSize: (parameters[2] as ChoiceValueParameter).value,
      children: children.map((e) => e.build(context)).toList(),
      direction: (parameters[3] as ChoiceValueParameter).value,
    );
  }
}

class CPadding extends Holder {
  CPadding() : super('Padding', [Parameters.paddingParameter()]);

  @override
  Widget create(BuildContext context) {
    return Padding(
      padding: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CClipRRect extends Holder {
  CClipRRect() : super('ClipRRect', [Parameters.borderRadiusParameter()]);

  @override
  Widget create(BuildContext context) {
    return ClipRRect(
      child: child?.build(context),
      borderRadius: parameters[0].value,
    );
  }
}

class CContainer extends Holder {
  CContainer()
      : super('Container', [
          Parameters.paddingParameter(),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.marginParameter(),
          Parameters.alignmentParameter(),
          Parameters.decorationParameter()
        ]);

  @override
  Widget create(BuildContext context) {
    return Container(
      child: child?.build(context),
      padding: parameters[0].value,
      width: parameters[1].value,
      height: parameters[2].value,
      margin: parameters[3].value,
      alignment: parameters[4].value,
      decoration: parameters[5].value,
    );
  }
}

class CSizedBox extends Holder {
  CSizedBox()
      : super('SizedBox', [
          Parameters.widthParameter()..withDefaultValue(50),
          Parameters.heightParameter()..withDefaultValue(50),
        ]);

  @override
  Widget create(BuildContext context) {
    return SizedBox(
      child: child?.build(context),
      width: parameters[0].value,
      height: parameters[1].value,
    );
  }
}

class CText extends Component {
  CText()
      : super('Text', [
          SimpleParameter<String>(
              name: 'text', paramType: ParamType.string, defaultValue: ''),
          ComplexParameter(
            info: InnerObjectParameterInfo(
                innerObjectName: 'TextStyle', namedIfHaveAny: 'style'),
            params: [
              SimpleParameter<double>(
                  name: 'font-size',
                  info: NamedParameterInfo('fontSize'),
                  paramType: ParamType.double,
                  defaultValue: 13),
              Parameters.colorParameter(),
              ChoiceValueParameter(
                options: {
                  'w200': FontWeight.w200,
                  'w300': FontWeight.w300,
                  'w400': FontWeight.w400,
                  'w500': FontWeight.w500,
                  'normal': FontWeight.normal,
                  'w600': FontWeight.w600,
                  'w700': FontWeight.w700,
                  'w800': FontWeight.w800,
                  'w900': FontWeight.w900,
                },
                defaultValue: 'normal',
                name: 'fontWeight',
              ),
            ],
            name: 'Style',
            evaluate: (params) {
              return TextStyle(
                  fontSize: params[0].value,
                  color: params[1].value,
                  fontWeight: params[2].value);
            },
          )
        ]);

  @override
  Widget create(BuildContext context) {
    return Text(
      parameters[0].value,
      style: parameters[1].value,
    );
  }
}
