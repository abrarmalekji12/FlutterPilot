import 'package:flutter/material.dart';

import 'constant/app_colors.dart';
import 'constant/font_style.dart';
import 'models/builder_component.dart';
import 'models/component_model.dart';
import 'models/other_model.dart';
import 'models/parameter_info_model.dart';
import 'models/parameter_model.dart';
import 'models/parameter_rule_model.dart';
import 'parameters_list.dart';

final componentList = <String, Component Function()>{
  'MaterialApp': () => CMaterialApp(),
  'Scaffold': () => CScaffold(),
  'AppBar': () => CAppBar(),
  'Drawer': () => CDrawer(),
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
  'ColoredBox': () => CColoredBox(),
  'Visibility': () => CVisibility(),
  'Material': () => CMaterial(),
  'Expanded': () => CExpanded(),
  'IntrinsicWidth' : ()=> CIntrinsicWidth(),
  'IntrinsicHeight' : ()=> CIntrinsicHeight(),
  'Spacer': () => CSpacer(),
  'Center': () => CCenter(),
  'Align': () => CAlign(),
  'Positioned': () => CPositioned(),
  'AspectRatio': () => CAspectRatio(),
  'FractionallySizedBox': () => CFractionallySizedBox(),
  'SafeArea': () => CSafeArea(),
  'Flexible': () => CFlexible(),
  'Card': () => CCard(),
  'SizedBox': () => CSizedBox(),
  'SizedBox.expand': () => CSizedBoxExpand(),
  'SizedBox.shrink': () => CSizedBoxShrink(),
  'SizedBox.fromSize': () => CSizedBoxFromSize(),
  'BackdropFilter': () => CBackdropFilter(),
  'PreferredSize': () => CPreferredSize(),
  'FittedBox': () => CFittedBox(),
  'Text': () => CText(),
  'Icon': () => CIcon(),
  'Switch': () => CSwitch(),
  'CircularProgressIndicator': () => CCircularProgressIndicator(),
  'LinearProgressIndicator': () => CLinearProgressIndicator(),
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
  'InputDecorator': () => CInputDecorator(),
  'InkWell': () => CInkWell(),
  'GestureDetector': () => CGestureDetector(),
  'Tooltip': () => CTooltip(),
  'TextButton': () => CTextButton(),
  'OutlinedButton': () => COutlinedButton(),
  'ElevatedButton': () => CElevatedButton(),
  'FloatingActionButton': () => CFloatingActionButton(),
  'IconButton': () => CIconButton(),
  'Placeholder': () => CPlaceholder(),
  'ListView.builder': () => CListViewBuilder(),
  'GridView.builder': () => CGridViewBuilder(),
  'ListView.Builder': () => CListViewBuilder(),
  'GridView.Builder': () => CGridViewBuilder(),
  'NotRecognizedWidget': () => CNotRecognizedWidget(),
  'DropDownButton': () => CDropDownButton(),
  'DropDownMenuItem': () => CDropDownMenuItem(),
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

class CNotRecognizedWidget extends Component {
  CNotRecognizedWidget() : super('NotRecognized', []);

  @override
  Widget create(BuildContext context) {
    return Container(
      child: Text(
        'Not recognized widget $name',
        style: AppFontStyle.roboto(14, color: Colors.red.shade800),
      ),
      color: const Color(0xfff1f1f1),
    );
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

class CPlaceholder extends Component {
  CPlaceholder()
      : super('Placeholder', [
          Parameters.colorParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Placeholder(
      color: parameters[0].value,
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
      child: child?.build(context),
      stepWidth: parameters[0].value,
      stepHeight: parameters[1].value,
    );
  }
}
class CIntrinsicHeight extends Holder {
  CIntrinsicHeight()
      : super(
      'IntrinsicWidth',
      [
      ],
      required: false);

  @override
  Widget create(BuildContext context) {
    return IntrinsicHeight(
      child: child?.build(context),
    );
  }
}
class CSafeArea extends Holder {
  CSafeArea()
      : super(
            'SafeArea',
            [
              Parameters.enableParameter()
                ..val = false
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('left'),
              Parameters.enableParameter()
                ..val = false
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('right'),
              Parameters.enableParameter()
                ..val = false
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('top'),
              Parameters.enableParameter()
                ..val = false
                ..withRequired(false)
                ..withNamedParamInfoAndSameDisplayName('bottom')
            ],
            required: true);

  @override
  Widget create(BuildContext context) {
    return SafeArea(
      child: child?.build(context) ?? Container(),
      left: parameters[0].value,
      right: parameters[1].value,
      top: parameters[2].value,
      bottom: parameters[3].value,
    );
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

class CAspectRatio extends Holder {
  CAspectRatio()
      : super('AspectRatio', [
          Parameters.widthFactorParameter()
            ..withRequired(true)
            ..withDefaultValue(1)
            ..withNamedParamInfoAndSameDisplayName('aspectRatio'),
        ]);

  @override
  Widget create(BuildContext context) {
    return AspectRatio(
      child: child?.build(context),
      aspectRatio: parameters[0].value,
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

class CDrawer extends Holder {
  CDrawer()
      : super('Drawer', [
          Parameters.backgroundColorParameter(),
          Parameters.elevationParameter(),
          Parameters.shapeBorderParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return Drawer(
      child: child?.build(context),
      backgroundColor: parameters[0].value,
      elevation: parameters[1].value,
      shape: parameters[2].value,
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
        }, [
          'actions'
        ]);

  @override
  Widget create(BuildContext context) {
    return AppBar(
      backgroundColor: parameters[0].value,
      title: childMap['title']?.build(context),
      leading: childMap['leading']?.build(context),
      actions: childrenMap['actions']
          ?.map((e) => e.build(context))
          .toList(growable: false),
      automaticallyImplyLeading: false,
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
          'drawer': null,
          'floatingActionButton': null,
          'bottomNavigationBar': null,
          'bottomSheet': null,
        }, []);

  @override
  Widget create(BuildContext context) {
    return Scaffold(
      appBar: childMap['appBar'] != null
          ? PreferredSize(
              child: childMap['appBar']!.build(context),
              preferredSize: Size(-1, childMap['appBar']!.parameters[1].value))
          : null,
      drawer: childMap['drawer']?.build(context),
      body: childMap['body']?.build(context),
      backgroundColor: parameters[0].value,
      floatingActionButton: childMap['floatingActionButton']?.build(context),
      bottomNavigationBar: childMap['bottomNavigationBar']?.build(context),
      bottomSheet: childMap['bottomSheet']?.build(context),
      resizeToAvoidBottomInset: parameters[1].value,
    );
  }
}

class CDropDownButton extends CustomNamedHolder {
  CDropDownButton()
      : super('DropDownButton', [], {
          'icon': null,
        }, [
          'items'
        ]);

  @override
  Widget create(BuildContext context) {
    return DropdownButton<String>(
        icon: childMap['icon']?.build(context),
        items: (childrenMap['items'] ?? [])
            .map<DropdownMenuItem<String>>(
                (e) => e.buildWithoutKey(context) as DropdownMenuItem<String>)
            .toList(),
        onChanged: (data) {});
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

class CDropDownMenuItem extends ClickableHolder {
  CDropDownMenuItem()
      : super('DropDownMenuItem', [
          Parameters.enableParameter()..withChangeNamed('enabled'),
          Parameters.textParameter()
            ..withNamedParamInfoAndSameDisplayName('value')
            ..withRequired(false)
        ]);

  @override
  String get clickableParamName => 'onTap';

  @override
  Widget create(BuildContext context) {
    return DropdownMenuItem<String>(
      key: key(context),
      child: child?.build(context) ?? Container(),
      onTap: () {
        perform(context);
      },
      enabled: parameters[0].value,
      value: parameters[1].value,
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

class CTooltip extends Holder {
  CTooltip()
      : super('Tooltip', [
          Parameters.textParameter()
            ..withNamedParamInfoAndSameDisplayName('message'),
          Parameters.googleFontTextStyleParameter()
            ..withNamedParamInfoAndSameDisplayName('textStyle'),
          Parameters.paddingParameter(),
          Parameters.marginParameter(),
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('enableFeedback'),
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('preferBelow'),
        ]);

  @override
  Widget create(BuildContext context) {
    return Tooltip(
      message: parameters[0].value,
      textStyle: parameters[1].value,
      padding: parameters[2].value,
      margin: parameters[3].value,
      enableFeedback: parameters[4].value,
      preferBelow: parameters[5].value,
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

class COutlinedButton extends ClickableHolder {
  COutlinedButton()
      : super('OutlinedButton', [Parameters.buttonStyleParameter()]);

  @override
  Widget create(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        perform(context);
      },
      child: child?.build(context) ?? Container(),
      style: parameters[0].value,
    );
  }

  @override
  String get clickableParamName => 'onPressed';
}

class CElevatedButton extends ClickableHolder {
  CElevatedButton()
      : super('ElevatedButton', [
          Parameters.buttonStyleParameter(),
        ]);

  @override
  Widget create(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        perform(context);
      },
      child: child?.build(context) ?? Container(),
      style: parameters[0].value,
    );
  }

  @override
  String get clickableParamName => 'onPressed';
}

// class CBottomNavigationBar extends Cu {
//   CBottomNavigationBar() : super('BottomNavigationBar',[
//   ]);
//
//   @override
//   Widget create(BuildContext context) {
//    return BottomNavigationBar(items: parameters[0].value);
//   }
//
// }
class CInkWell extends ClickableHolder {
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
      onTap: () {
        perform(context);
      },
      child: child?.build(context) ?? Container(),
      enableFeedback: parameters[0].value,
      hoverColor: parameters[1].value,
      focusColor: parameters[2].value,
      splashColor: parameters[3].value,
      highlightColor: parameters[4].value,
      borderRadius: parameters[5].value,
    );
  }

  @override
  String get clickableParamName => 'onTap';
}

class CGestureDetector extends ClickableHolder {
  CGestureDetector() : super('GestureDetector', []);

  @override
  Widget create(BuildContext context) {
    return GestureDetector(
      onTap: () {
        perform(context);
      },
      child: child?.build(context) ?? Container(),
    );
  }

  @override
  String get clickableParamName => 'onTap';
}

class CFloatingActionButton extends ClickableHolder {
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
      onPressed: () {
        perform(context);
      },
      heroTag: null,
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

  @override
  String get clickableParamName => 'onPressed';
}

class CTextButton extends ClickableHolder {
  CTextButton() : super('TextButton', [Parameters.buttonStyleParameter()]);

  @override
  Widget create(BuildContext context) {
    return TextButton(
      onPressed: () {
        perform(context);
      },
      child: child?.build(context) ?? Container(),
      style: parameters[0].value,
    );
  }

  @override
  String get clickableParamName => 'onPressed';
}

class CLinearProgressIndicator extends Component {
  CLinearProgressIndicator()
      : super('LinearProgressIndicator', [
          Parameters.widthParameter()
            ..withDefaultValue(5)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('minHeight'),
          Parameters.widthParameter()
            ..withDefaultValue(null)
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('value'),
          ComplexParameter(
            params: [
              Parameters.colorParameter()
                ..withDefaultValue(AppColors.black)
                ..withChangeNamed(null)
                ..withDisplayName('loading color')
            ],
            evaluate: (params) {
              return AlwaysStoppedAnimation<Color?>(params[0].value);
            },
            info: InnerObjectParameterInfo(
                innerObjectName: 'AlwaysStoppedAnimation',
                namedIfHaveAny: 'valueColor'),
          ),
          Parameters.colorParameter(),
          Parameters.backgroundColorParameter(),
        ]);

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
      : super('CircularProgressIndicator', [
          Parameters.widthParameter()
            ..withDefaultValue(4)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('strokeWidth'),
          Parameters.widthParameter()
            ..withDefaultValue(null)
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('value'),
          ComplexParameter(
            params: [
              Parameters.colorParameter()
                ..withDefaultValue(AppColors.black)
                ..withChangeNamed(null)
                ..withDisplayName('loading color')
            ],
            evaluate: (params) {
              return AlwaysStoppedAnimation<Color?>(params[0].value);
            },
            info: InnerObjectParameterInfo(
                innerObjectName: 'AlwaysStoppedAnimation',
                namedIfHaveAny: 'valueColor'),
          ),
          Parameters.colorParameter(),
          Parameters.backgroundColorParameter(),
        ]);

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
          return null;
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

class CColoredBox extends Holder {
  CColoredBox()
      : super('ColoredBox', [
          Parameters.colorParameter()..withRequired(true),
        ]);

  @override
  Widget create(BuildContext context) {
    return ColoredBox(
      child: child?.build(context),
      color: parameters[0].value,
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

class CBackdropFilter extends Holder {
  CBackdropFilter() : super('BackdropFilter', [Parameters.filterParameter()]);

  @override
  Widget create(BuildContext context) {
    return BackdropFilter(
      child: child?.build(context),
      filter: parameters[0].value,
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
      child: child?.build(context) ?? Container(),
      preferredSize: parameters[0].value,
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
          Parameters.textParameter()..withDefaultValue('Hello World'),
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

class CIconButton extends ClickableComponent {
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
  String get clickableParamName => 'onPressed';

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
      onPressed: () {
        perform(context);
      },
    );
  }
}

class CInputDecorator extends Component {
  CInputDecorator()
      : super('InputDecorator', [
          Parameters.googleFontTextStyleParameter()
            ..withChangeNamed('baseStyle'),
          Parameters.inputDecorationParameter(),
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('isEmpty')
            ..val = false,
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('isFocused')
            ..val = false,
          Parameters.enableParameter()
            ..withNamedParamInfoAndSameDisplayName('expands')
            ..val = false,
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
            ..withRequired(false),
          BooleanParameter(
              required: false,
              val: false,
              info: NamedParameterInfo('obscureText'),
              displayName: 'obscure-text'),
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
    return TextField(
      style: parameters[0].value,
      readOnly: parameters[1].value,
      decoration: parameters[2].value,
      maxLength: parameters[3].value,
      obscureText: parameters[4].value,
    );
  }
}
