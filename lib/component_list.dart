import 'package:flutter/material.dart';
import 'models/parameter_rule_model.dart';
import 'parameters_list.dart';
import 'models/component_model.dart';
import 'constant/app_colors.dart';

import 'models/other_model.dart';
import 'models/parameter_info_model.dart';
import 'models/parameter_model.dart';

final componentList = {
  'MaterialApp': () => CMaterialApp(),
  'Scaffold': () => CScaffold(),
  'AppBar': () => CAppBar(),
  'Row': () => CRow(),
  'Column': () => CColumn(),
  'Stack': () => CStack(),
  'Wrap': () => CWrap(),
  'ListView': () => CListView(),
  'Flex': () => CFlex(),
  'SingleChildScrollView': () => CSingleChildScrollView(),
  'Padding': () => CPadding(),
  'ClipRRect': () => CClipRRect(),
  'Container': () => CContainer(),
  'Visibility': () => CVisibility(),
  'Material': () => CMaterial(),
  'Expanded': () => CExpanded(),
  'Spacer': () => CSpacer(),
  'Center': () => CCenter(),
  'Align': () => CAlign(),
  'Positioned': () => CPositioned(),
  'FractionallySizedBox': () => CFractionallySizedBox(),
  'Flexible': () => CFlexible(),
  'Card': () => CCard(),
  'SizedBox': () => CSizedBox(),
  'FittedBox': () => CFittedBox(),
  'Text': () => CText(),
  'Icon': () => CIcon(),
  'Switch': () => CSwitch(),
  'Checkbox': () => CCheckbox(),
  'Radio': () => CRadio(),
  'Image.asset': () => CImage(),
  'Image.network': () => CImageNetwork(),
  'CircleAvatar': () => CCircleAvatar(),
  'Divider': () => CDivider(),
  'Opacity': () => COpacity(),
  'Transform.rotate': () => CTransformRotate(),
  'Transform.scale': () => CTransformScale(),
  'Transform.translate': () => CTransformTranslate(),
  'VerticalDivider': () => CVerticalDivider(),
  'RichText': () => CRichText(),
  'TextField': () => CTextField(),
  'InkWell': () => CInkWell(),
  'TextButton': () => CTextButton(),
  'OutlinedButton': () => COutlinedButton(),
  'ElevatedButton': () => CElevatedButton(),
  'FloatingActionButton': () => CFloatingActionButton(),
  'IconButton': () => CIconButton(),
};

class CMaterialApp extends CustomNamedHolder {
  CMaterialApp()
      : super('MaterialApp', [
          Parameters.colorParameter()
            ..inputCalculateAs =
                ((color, forward) => (color as Color).withAlpha(255))
            ..withRequired(false),
          Parameters.textParameter()
            ..withNamedParamInfoAndSameDisplayName('title'),
          Parameters.themeDataParameter()..withChangeNamed('theme'),
          Parameters.themeDataParameter()
            ..withChangeNamed('darkTheme')
            ..withDisplayName('Dark Theme'),
          Parameters.themeModeParameter(),
        ], {
          'home': null
        }, []);

  @override
  Widget create(BuildContext context) {
    return MaterialApp(
      home: childMap['home']?.build(context),
      color: parameters[0].value,
      title: parameters[1].value,
      theme: parameters[2].value,
      darkTheme: parameters[3].value,
      themeMode: parameters[4].value,
    );
  }
}

class CRichText extends Component {
  CRichText()
      : super('RichText', [
          Parameters.textSpanParameter()
            ..withInfo(InnerObjectParameterInfo(
                innerObjectName: 'TextSpan', namedIfHaveAny: 'text'))
        ]);

  @override
  Widget create(BuildContext context) {
    return RichText(text: parameters[0].value);
  }
}

class CCheckbox extends Component {
  CCheckbox()
      : super('Checkbox', [
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('value'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Checkbox(
      onChanged: (bool) {},
      value: parameters[0].value,
    );
  }
}

class CRadio extends Component {
  CRadio()
      : super('Radio', [
          Parameters.shortStringParameter()
            ..withDefaultValue('1')
            ..withNamedParamInfoAndSameDisplayName('value'),
          Parameters.shortStringParameter()
            ..withDefaultValue('1')
            ..withNamedParamInfoAndSameDisplayName('groupValue'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Radio<String>(
      onChanged: (bool) {},
      value: parameters[0].value,
      groupValue: parameters[1].value,
    );
  }
}

class CSwitch extends Component {
  CSwitch()
      : super('Switch', [
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('value'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Switch(onChanged: (bool value) {}, value: parameters[0].value);
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

class CExpanded extends Holder {
  CExpanded() : super('Expanded', [Parameters.flexParameter()], required: true);

  @override
  Widget create(BuildContext context) {
    return Expanded(
        flex: parameters[0].value, child: child?.build(context) ?? Container());
  }
}

class CSpacer extends Component {
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

class CPositioned extends Holder {
  CPositioned()
      : super('Positioned', [
          Parameters.directionParameter()
            ..withDisplayName('left')
            ..withInfo(NamedParameterInfo('left')),
          Parameters.directionParameter()
            ..withDisplayName('right')
            ..withInfo(NamedParameterInfo('right')),
          Parameters.directionParameter()
            ..withDisplayName('top')
            ..withInfo(NamedParameterInfo('top')),
          Parameters.directionParameter()
            ..withDisplayName('bottom')
            ..withInfo(NamedParameterInfo('bottom')),
        ]);

  @override
  Widget create(BuildContext context) {
    return Positioned(
      child: child?.build(context) ?? Container(),
      left: parameters[0].value,
      right: parameters[1].value,
      top: parameters[2].value,
      bottom: parameters[3].value,
    );
  }
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
      child: child?.build(context),
      alignment: parameters[0].value,
      widthFactor: parameters[1].value,
      heightFactor: parameters[2].value,
    );
  }
}

class CSingleChildScrollView extends Holder {
  CSingleChildScrollView()
      : super('SingleChildScrollView', [
          Parameters.axisParameter()
            ..withNamedParamInfoAndSameDisplayName('scrollDirection')
            ..withDefaultValue('vertical'),
          Parameters.paddingParameter()..withRequired(false)
        ]);

  @override
  Widget create(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: parameters[0].value,
      padding: parameters[1].value,
      child: child?.build(context),
      controller: initScrollController(context),
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
  CFlexible() : super('Flexible', [Parameters.flexParameter()], required: true);

  @override
  Widget create(BuildContext context) {
    return Flexible(
      flex: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CVisibility extends Holder {
  CVisibility()
      : super('Visibility', [
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('visible'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Visibility(
      visible: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class COpacity extends Holder {
  COpacity()
      : super('Opacity', [
          Parameters.widthFactorParameter()
            ..withInfo(NamedParameterInfo('opacity'))
            ..withDefaultValue(1)
            ..withDisplayName('opacity')
            ..withRequired(true),
        ]);

  @override
  Widget create(BuildContext context) {
    return Opacity(
      opacity: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CTransformRotate extends Holder {
  CTransformRotate()
      : super('Transform.rotate', [
          Parameters.angleParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Transform.rotate(
      angle: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CTransformScale extends Holder {
  CTransformScale()
      : super('Transform.scale', [
          Parameters.widthFactorParameter()
            ..withDefaultValue(1)
            ..withNamedParamInfoAndSameDisplayName('scale')
            ..withRequired(true),
        ]);

  @override
  Widget create(BuildContext context) {
    return Transform.scale(
      scale: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CTransformTranslate extends Holder {
  CTransformTranslate()
      : super('Transform.translate', [
          Parameters.offsetParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Transform.translate(
      offset: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CDivider extends Component {
  CDivider()
      : super(
          'Divider',
          [
            Parameters.colorParameter()..withDefaultValue(AppColors.grey),
            Parameters.heightParameter()..withDefaultValue(20),
            Parameters.thicknessParameter(),
            Parameters.heightParameter()
              ..withDefaultValue(0)
              ..withDisplayName('indent')
              ..withInfo(NamedParameterInfo('indent'))
              ..withRequired(false),
            Parameters.heightParameter()
              ..withDefaultValue(0)
              ..withDisplayName('end-indent')
              ..withInfo(NamedParameterInfo('endIndent'))
              ..withRequired(false)
          ],
        );

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
}

class CVerticalDivider extends Component {
  CVerticalDivider()
      : super(
          'VerticalDivider',
          [
            Parameters.colorParameter()..withDefaultValue(AppColors.grey),
            Parameters.widthParameter()..withDefaultValue(20),
            Parameters.thicknessParameter(),
            Parameters.heightParameter()
              ..withDefaultValue(0)
              ..withDisplayName('indent')
              ..withInfo(NamedParameterInfo('indent'))
              ..withRequired(false),
            Parameters.heightParameter()
              ..withDefaultValue(0)
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

class CCard extends Holder {
  CCard()
      : super('Card', [
          Parameters.colorParameter()..withDefaultValue(AppColors.white),
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
        }, []);

  @override
  Widget create(BuildContext context) {
    return AppBar(
      backgroundColor: parameters[0].value,
      title: childMap['title']?.build(context),
      leading: childMap['leading']?.build(context),
    );
  }
}

class CScaffold extends CustomNamedHolder {
  CScaffold()
      : super('Scaffold', [
          Parameters.backgroundColorParameter(),
          BooleanParameter(
            required: false,
            val: false,
            displayName: 'resize to avoid bottom inset',
            info: NamedParameterInfo('resizeToAvoidBottomInset'),
          ),
        ], {
          'appBar': ['AppBar'],
          'body': null,
          'floatingActionButton': null,
          'bottomNavigationBar': null,
          'bottomSheet': null,
        }, [
          'actions'
        ]);

  @override
  Widget create(BuildContext context) {
    return Scaffold(
      appBar: childMap['appBar'] != null
          ? PreferredSize(
              child: childMap['appBar']!.build(context),
              preferredSize: Size(-1, childMap['appBar']!.parameters[1].value))
          : null,
      body: childMap['body']?.build(context),
      backgroundColor: parameters[0].value,
      floatingActionButton: childMap['floatingActionButton']?.build(context),
      bottomNavigationBar: childMap['bottomNavigationBar']?.build(context),
      bottomSheet: childMap['bottomSheet']?.build(context),
      resizeToAvoidBottomInset: parameters[1].value,
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

class CWrap extends MultiHolder {
  CWrap()
      : super('Wrap', [
          Parameters.wrapAlignmentParameter(),
          Parameters.wrapCrossAxisAlignmentParameter(),
          Parameters.axisParameter()..withDefaultValue('horizontal'),
          Parameters.widthParameter()
            ..withDefaultValue(0.0)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('spacing'),
          Parameters.widthParameter()
            ..withDefaultValue(0.0)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('runSpacing'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Wrap(
      children: children.map((e) => e.build(context)).toList(),
      alignment: parameters[0].value,
      crossAxisAlignment: parameters[1].value,
      direction: parameters[2].value,
      spacing: parameters[3].value,
      runSpacing: parameters[4].value,
    );
  }
}

class CStack extends MultiHolder {
  CStack()
      : super('Stack', [
          Parameters.alignmentParameter(),
          Parameters.stackFitParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Stack(
      alignment: parameters[0].value,
      fit: parameters[1].value,
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CListView extends MultiHolder {
  CListView()
      : super('ListView', [
          Parameters.paddingParameter(),
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
          BooleanParameter(
              displayName: 'reverse',
              required: true,
              val: false,
              info: NamedParameterInfo('reverse'))
        ]);

  @override
  Widget create(BuildContext context) {
    return ListView(
      children: children.map((e) => e.build(context)).toList(),
      padding: parameters[0].value,
      scrollDirection: parameters[1].value,
      reverse: parameters[2].value,
      controller: initScrollController(context),
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
  CPadding()
      : super('Padding', [Parameters.paddingParameter()..withRequired(true)]);

  @override
  Widget create(BuildContext context) {
    return Padding(
      padding: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CClipRRect extends Holder {
  CClipRRect()
      : super('ClipRRect',
            [Parameters.borderRadiusParameter()..withRequired(true)]);

  @override
  Widget create(BuildContext context) {
    return ClipRRect(
      child: child?.build(context),
      borderRadius: parameters[0].value,
    );
  }
}

class CCircleAvatar extends Holder {
  CCircleAvatar()
      : super('CircleAvatar', [
          Parameters.radiusParameter(),
          Parameters.backgroundColorParameter(),
          Parameters.foregroundColorParameter(),
          // Parameters.radiusParameter()
          //   ..withDisplayName('minimum radius')
          //   ..withInfo(NamedParameterInfo('minRadius')),
          // Parameters.radiusParameter()
          //   ..withDisplayName('maximum radius')
          //   ..withInfo(NamedParameterInfo('maxRadius')),
        ]);

  @override
  Widget create(BuildContext context) {
    return CircleAvatar(
      radius: parameters[0].value,
      backgroundColor: parameters[1].value,
      foregroundColor: parameters[2].value,
      child: child?.build(context),
      // maxRadius: parameters[3].value,
      // minRadius: parameters[4].value,
    );
  }
}

class COutlinedButton extends Holder {
  COutlinedButton()
      : super('OutlinedButton', [Parameters.buttonStyleParameter()]);

  @override
  Widget create(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      child: child?.build(context) ?? Container(),
      style: parameters[0].value,
    );
  }
}

class CElevatedButton extends Holder {
  CElevatedButton()
      : super('ElevatedButton', [
          Parameters.buttonStyleParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      child: child?.build(context) ?? Container(),
      style: parameters[0].value,
    );
  }
}

class CInkWell extends Holder {
  CInkWell()
      : super('InkWell', [
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('enableFeedback'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('hoverColor'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('focusColor'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('splashColor'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('highlightColor'),
          Parameters.borderRadiusParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: child?.build(context) ?? Container(),
      enableFeedback: parameters[0].value,
      hoverColor: parameters[1].value,
      focusColor: parameters[2].value,
      splashColor: parameters[3].value,
      highlightColor: parameters[4].value,
      borderRadius: parameters[5].value,
    );
  }
}

class CFloatingActionButton extends Holder {
  CFloatingActionButton()
      : super('FloatingActionButton', [
          Parameters.backgroundColorParameter(),
          Parameters.foregroundColorParameter(),
          Parameters.elevationParameter(),
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('enableFeedback'),
          Parameters.textParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('tooltip'),
          Parameters.elevationParameter()
            ..withNamedParamInfoAndSameDisplayName('hoverElevation'),
          Parameters.elevationParameter()
            ..withNamedParamInfoAndSameDisplayName('focusElevation'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('hoverColor'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('focusColor'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('splashColor'),
        ]);

  @override
  Widget create(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {},
      child: child?.build(context) ?? Container(),
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
    );
  }
}

class CTextButton extends Holder {
  CTextButton() : super('TextButton', [Parameters.buttonStyleParameter()]);

  @override
  Widget create(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: child?.build(context) ?? Container(),
      style: parameters[0].value,
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
        ], rules: []) {
    addRule(ParameterRuleModel(
        changedParameter: (parameters[5] as ComplexParameter).params[5],
        anotherParameter: (parameters[5] as ComplexParameter).params[1],
        onChange: (param1, param2) {
          if (param1.value == BoxShape.circle) {
            (param2 as ChoiceParameter).resetParameter();
            return 'Circle box-shape can not have Border-Radius';
          }
        }));
    addRule(ParameterRuleModel(
        changedParameter: (parameters[5] as ComplexParameter).params[2],
        anotherParameter: (parameters[5] as ComplexParameter).params[1],
        onChange: (param1, param2) {
          if ((param1 as ChoiceParameter).val == param1.options[2]) {
            (param2 as ChoiceParameter).resetParameter();
            return 'Only uniform border can have Border-Radius';
          }
        }));
  }

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

class CFittedBox extends Holder {
  CFittedBox()
      : super('FittedBox', [
          Parameters.boxFitParameter(),
          Parameters.alignmentParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return FittedBox(
      child: child?.build(context),
      fit: parameters[0].value,
      alignment: parameters[1].value,
    );
  }
}

class CMaterial extends Holder {
  CMaterial()
      : super('Material', [
          Parameters.colorParameter()..withDefaultValue(const Color(0x00000000))
        ]);

  @override
  Widget create(BuildContext context) {
    return Material(
      child: child?.build(context),
      color: parameters[0].value,
    );
  }
}

class CText extends Component {
  CText()
      : super('Text', [
          Parameters.textParameter(),
          Parameters.googleFontTextStyleParameter(),
          Parameters.textAlignParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Text(
      parameters[0].value,
      style: parameters[1].value,
      textAlign: parameters[2].value,
    );
  }
}

class CImageNetwork extends Component {
  CImageNetwork()
      : super('Image.network', [
          Parameters.textParameter()..withDisplayName('url'),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.boxFitParameter(),
          Parameters.colorParameter()
            ..withDefaultValue(null)
            ..withRequired(false),
        ]);

  @override
  Widget create(BuildContext context) {
    return Image.network(
      parameters[0].value,
      width: parameters[1].value,
      height: parameters[2].value,
      fit: parameters[3].value,
      color: parameters[4].value,
    );
  }
}

class CIcon extends Component {
  CIcon()
      : super('Icon', [
          Parameters.iconParameter(),
          Parameters.widthParameter()
            ..withNamedParamInfoAndSameDisplayName('size'),
          Parameters.colorParameter()
            ..withDefaultValue(null)
            ..withRequired(false),
          Parameters.textParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('semanticLabel')
        ]);

  @override
  Widget create(BuildContext context) {
    return Icon(
      parameters[0].value,
      size: parameters[1].value,
      color: parameters[2].value,
      semanticLabel: parameters[3].value,
    );
  }
}

class CImage extends Component {
  CImage()
      : super('Image.asset', [
          Parameters.imageParameter(),
          Parameters.widthParameter(),
          Parameters.heightParameter(),
          Parameters.colorParameter()
            ..withDefaultValue(null)
            ..withRequired(false),
          Parameters.boxFitParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return parameters[0].value != null &&
            (parameters[0].value as ImageData).bytes != null
        ? Image.memory(
            (parameters[0].value as ImageData).bytes!,
            width: parameters[1].value,
            height: parameters[2].value,
            color: parameters[3].value,
            fit: parameters[4].value,
          )
        : Icon(
            Icons.error,
            color: Colors.red,
            size: parameters[1].value,
          );
  }
}

class CIconButton extends Component {
  CIconButton()
      : super('IconButton', [
          ComponentParameter(
            multiple: false,
            info: NamedParameterInfo('icon'),
          ),
          Parameters.widthParameter()
            ..withDefaultValue(24)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('iconSize'),
          Parameters.colorParameter()..withDefaultValue(AppColors.black),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('splashColor'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('hoverColor'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('highlightColor'),
          Parameters.colorParameter()
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('focusColor'),
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('enableFeedback'),
          Parameters.alignmentParameter(),
          Parameters.paddingParameter()..withRequired(true),
          Parameters.textParameter()
            ..withNamedParamInfoAndSameDisplayName('tooltip')
        ]) {
    addComponentParameters([parameters[0] as ComponentParameter]);
  }

  @override
  Widget create(BuildContext context) {
    initComponentParameters(context);
    return IconButton(
      icon: (parameters[0] as ComponentParameter).build() ?? Container(),
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
      onPressed: () {},
    );
  }
}

class CTextField extends Component {
  CTextField()
      : super('TextField', [
          Parameters.googleFontTextStyleParameter(),
          BooleanParameter(
              required: true,
              val: false,
              info: NamedParameterInfo('readOnly'),
              displayName: 'readOnly'),
          Parameters.inputDecorationParameter(),
          Parameters.flexParameter()
            ..withNamedParamInfoAndSameDisplayName('maxLength')
            ..withRequired(false)
        ]) {
    addComponentParameters([
      (parameters[2] as ComplexParameter).params[10] as ComponentParameter,
      (parameters[2] as ComplexParameter).params[11] as ComponentParameter,
      (parameters[2] as ComplexParameter).params[12] as ComponentParameter,
    ]);
  }

  @override
  Widget create(BuildContext context) {
    initComponentParameters(context);
    return IgnorePointer(
      ignoring: true,
      child: TextField(
        style: parameters[0].value,
        readOnly: parameters[1].value,
        decoration: parameters[2].value,
        maxLength: parameters[3].value,
      ),
    );
  }
}
