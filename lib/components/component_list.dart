import 'package:flutter/material.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';

import '../common/analyzer/render_models.dart';
import '../constant/color_assets.dart';
import '../constant/string_constant.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../injector.dart';
import '../models/builder_component.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/fvb_ui_core/component/custom_component.dart';
import '../models/parameter_info_model.dart';
import '../models/parameter_model.dart';
import '../models/project_model.dart';
import '../parameter/parameters_list.dart';
import '../runtime_provider.dart';
import 'component_impl.dart';
import 'holder_impl.dart';
import 'scrollable_impl.dart';

final componentImages = <String, String>{
  'Container': 'container',
  'SizedBox': 'sizedbox',
  'Text': 'text',
  'TextField': 'textfield',
  'Align': 'alignment',
  'AspectRatio': 'aspectratio',
  'BackButton': 'backbutton',
  'BottomNavigationBar': 'bottomnavigation',
  'Card': 'card',
  'Center': 'center',
  'CheckBox': 'checkbox',
  'CircleAvatar': 'circleavatar',
  'CircularProgressIndicator': 'circular_loading',
  'Column': 'column',
  'CustomPaint': 'custompaint',
  'DefaultTextStyle': 'defaulttextstyle',
  'AnimatedTextStyle': 'defaulttextstyle',
  'Divider': 'divider',
  'DropdownButton': 'dropdown',
  'ElevatedButton': 'elevated_button',
  'Expanded': 'expanded',
  'GestureDetector': 'gesture_detector',
  'GridView': 'gridview',
  'GridView.builder': 'gridview',
  'IfCondition': 'if_condition',
  'Image': 'image',
  'Inkwell': 'inkwell',
  'LinearProgressIndicator': 'linear_loading',
  'Opacity': 'opacity',
  'AnimatedOpacity': 'opacity',
  'Padding': 'padding',
  'PageView': 'pageview',
  'PageView.builder': 'pageview',
  'PopupMenuButton': 'popupmenu',
  'Positioned': 'positioned',
  'Radio': 'radio',
  'RichText': 'richtext',
  'Transform.rotate': 'rotate',
  'Row': 'row',
  'Scale': 'scale',
  'SingleChildScrollView': 'singlechildscrollview',
  'Slider': 'slider',
  'Spacer': 'spacer',
  'Stack': 'stack',
  'Switch': 'switch',
  'TextButton': 'textbutton',
  'Tooltip': 'tooltip',
  'VerticalDivider': 'vertical_divider',
  'Visibility': 'visibility',
};

final componentList = <String, Component Function()>{
  'MaterialApp': () => CMaterialApp(),
  'Scaffold': () => CScaffold(),
  'AppBar': () => CAppBar(),
  'Drawer': () => CDrawer(),
  'Row': () => CRow(),
  'Column': () => CColumn(),
  'Stack': () => CStack(),
  'IndexedStack': () => CIndexedStack(),
  'Wrap': () => CWrap(),
  'ListView': () => CListView(),
  'GridView': () => CGridView(),
  'ListTile': () => CListTile(),
  'Flex': () => CFlex(),
  'SingleChildScrollView': () => CSingleChildScrollView(),
  'CustomScrollView': () => CCustomScrollView(),
  'Padding': () => CPadding(),
  'ClipRRect': () => CClipRRect(),
  'ClipOval': () => CClipOval(),
  'DropdownButtonHideUnderline': () => CDropdownButtonHideUnderline(),
  'Container': () => CContainer(),
  'Offstage': () => COffstage(),
  'AnimatedContainer': () => CAnimatedContainer(),
  'AnimatedSwitcher': () => CAnimatedSwitcher(),
  'AnimatedDefaultTextStyle': () => CAnimatedDefaultTextStyle(),
  'DefaultTextStyle': () => CDefaultTextStyle(),
  'ColoredBox': () => CColoredBox(),
  'ColorFiltered': () => CColorFiltered(),
  'Visibility': () => CVisibility(),
  'Material': () => CMaterial(),
  'Expanded': () => CExpanded(),
  'IntrinsicWidth': () => CIntrinsicWidth(),
  'IntrinsicHeight': () => CIntrinsicHeight(),
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
  'SliverToBoxAdapter': () => CSliverToBoxAdapter(),
  'SliverAppBar': () => CSliverAppBar(),
  'Shimmer.fromColors': () => CShimmerFromColors(),
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
  'LoadingIndicator': () => CLoadingIndicator(),
  'Checkbox': () => CCheckbox(),
  'Radio': () => CRadio(),
  'Image.asset': () => CImageAsset(),
  'Image': () => CImage(),
  'Image.network': () => CImageNetwork(),
  'SvgPicture.network': () => CSvgPictureNetwork(),
  'SvgPicture.asset': () => CSvgImage(),
  'CircleAvatar': () => CCircleAvatar(),
  'Divider': () => CDivider(),
  'Opacity': () => COpacity(),
  'AnimatedOpacity': () => CAnimatedOpacity(),
  'Transform.rotate': () => CTransformRotate(),
  'Transform.scale': () => CTransformScale(),
  'Transform.translate': () => CTransformTranslate(),
  'VerticalDivider': () => CVerticalDivider(),
  'DashedLine': () => CDashedLine(),
  'RichText': () => CRichText(),
  'CustomPaint': () => CCustomPaint(),
  'TextField': () => CTextField(),
  'TextFormField': () => CTextFormField(),
  'Form': () => CForm(),
  'InputDecorator': () => CInputDecorator(),
  'InkWell': () => CInkWell(),
  'GestureDetector': () => CGestureDetector(),
  'Tooltip': () => CTooltip(),
  'BackButton': () => CBackButton(),
  'CloseButton': () => CCloseButton(),
  'TextButton': () => CTextButton(),
  'OutlinedButton': () => COutlinedButton(),
  'ElevatedButton': () => CElevatedButton(),
  'FloatingActionButton': () => CFloatingActionButton(),
  'IconButton': () => CIconButton(),
  'Placeholder': () => CPlaceholder(),
  'Builder': () => CBuilder(),
  'LayoutBuilder': () => CLayoutBuilder(),
  'StatefulBuilder': () => CStatefulBuilder(),
  'GridView.builder': () => CGridViewBuilder(),
  'PageView.builder': () => CPageViewBuilder(),
  'ListView.builder': () => CListViewBuilder(),
  'ListView.separated': () => CListViewSeparated(),
  'NotRecognizedWidget': () => CNotRecognizedWidget(),
  'DataLoaderWidget': () => CDataLoaderWidget(),
  'DropdownButton': () => CDropDownButton(),
  'DropdownMenuItem': () => CDropdownMenuItem(),
  'IfCondition': () => IfCondition(),
  'ElseIfCondition': () => ElseIfCondition(),
  'Hero': () => CHero(),
  'TabBar': () => CTabBar(),
  'Tab': () => CTab(),
  'TabBarView': () => CTabBarView(),
  'BottomNavigationBar': () => CBottomNavigationBar(),
  'BottomNavigationBarItem': () => CBottomNavigationBarItem(),
  'NavigationRail': () => CNavigationRail(),
  'NavigationRailDestination': () => CNavigationRailDestination(),
  'PopupMenuButton': () => CPopupMenuButton(),
  'PopupMenuItem': () => CPopupMenuItem(),
};

final componentCreatedCache = componentList.map((k, v) => MapEntry(k, v()));

class CMaterialApp extends CustomNamedHolder with ComplexRenderModel {
  CMaterialApp()
      : super('MaterialApp', [
    Parameters.colorParameter
      ..inputCalculateAs = ((color, forward) => (color as Color).withAlpha(255))
      ..withRequired(false),
    Parameters.textParameter(defaultValue: 'App', required: true)
      ..withNamedParamInfoAndSameDisplayName('title'),
    Parameters.themeModeParameter(),
    Parameters.themeDataParameter()
      ..withChangeNamed('theme'),
    Parameters.themeDataParameter()
      ..withChangeNamed('darkTheme')
      ..withDisplayName('Dark Theme'),
  ], [
    'home'
  ], []) {
    autoHandleKey = false;
  }

  @override
  String code({bool clean = true}) {
    if (clean) {}
    return super.code(clean: clean);
  }

  @override
  Widget create(BuildContext context) {
    return MaterialApp(
      color: parameters[0].value,
      title: parameters[1].value,
      themeMode: parameters[2].value,
      theme: parameters[3].value,
      darkTheme: parameters[4].value,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigationKey,
      // scrollBehavior: MyCustomScrollBehavior(),
      home: switch (ViewableProvider.maybeOf(context)) {
        Screen s => s.build(context),
        CustomComponent c => c.build(context),
        _ => childMap['home']?.build(context)
      },
    );
  }

  @override
  ComponentSize childSize(String child) {
    switch (child) {
      case 'home':
        return ComponentSize.infinite;
    }
    return ComponentSize.infinite;
  }

  @override
  Size get size => Size.infinite;
}

class IfCondition extends CustomNamedHolder {
  IfCondition()
      : super('IfCondition', [
    Parameters.enableParameter(true, false)
      ..displayName = 'condition',
  ], [
    'if',
    'else'
  ], [
    'else_if'
  ]);

  @override
  String code({bool clean = true}) {
    if (clean) {
      return '${parameters[0].compiler.code}?${childMap['if']?.code(clean: clean)}:${childMap['else']?.code(
          clean: clean)}';
    } else {
      return super.code(clean: clean);
    }
  }

  @override
  Widget create(BuildContext context) {
    if (parameters[0].value == true) {
      return childMap['if']?.build(context) ?? const Offstage();
    }
    for (final Component val in (childrenMap['else_if'] ?? [])) {
      if (val is ElseIfCondition && val.parameters[0].value == true) {
        return val.build(context);
      }
    }
    return childMap['else']?.build(context) ?? const Offstage();
  }
}

class ElseIfCondition extends CustomNamedHolder {
  ElseIfCondition()
      : super('ElseIfCondition', [
    Parameters.enableParameter(false, false)
      ..displayName = 'condition',
  ], [
    'if',
  ], []);

  @override
  Widget create(BuildContext context) {
    return childMap['if']?.build(context) ?? Container();
  }
}

class CCheckbox extends ClickableComponent {
  CCheckbox()
      : super('Checkbox', [
    Parameters.enableParameter(true, false)
      ..withNamedParamInfoAndSameDisplayName('value'),
    Parameters.materialTapSizeParameter,
    Parameters.configColorParameter('activeColor'),
    Parameters.WidgetStatePropertyParameter<Color?>(
        Parameters.backgroundColorParameter()
          ..withDisplayName('fillColor')
          ..withChangeNamed(null),
        'fillColor'),
    Parameters.configColorParameter('focusColor'),
    Parameters.configColorParameter('hoverColor'),
  ]) {
    methods([
      FVBFunction('onChanged', null, [FVBArgument('value', dataType: DataType.fvbBool, nullable: true)],
          returnType: DataType.fvbVoid)
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return Checkbox(
      onChanged: (bool? b) {
        perform(context, arguments: [b]);
      },
      value: parameters[0].value,
      materialTapTargetSize: parameters[1].value,
      activeColor: parameters[2].value,
      fillColor: parameters[3].value,
      focusColor: parameters[4].value,
      hoverColor: parameters[5].value,
    );
  }
}

class CRadio extends ClickableComponent {
  CRadio()
      : super('Radio', [
    Parameters.dynamicValueParameter()
      ..withDefaultValue(1)
      ..withNamedParamInfoAndSameDisplayName('value'),
    Parameters.dynamicValueParameter()
      ..withDefaultValue(1)
      ..withNamedParamInfoAndSameDisplayName('groupValue'),
    Parameters.choiceValueFromEnum(MaterialTapTargetSize.values,
        optional: false, require: false, name: 'materialTapTargetSize', defaultValue: null),
    Parameters.enableParameter(false)
      ..withNamedParamInfoAndSameDisplayName('toggleable'),
    Parameters.configColorParameter('activeColor'),
    Parameters.WidgetStatePropertyParameter<Color?>(
        Parameters.backgroundColorParameter()
          ..withDisplayName('fillColor')
          ..withChangeNamed(null),
        'fillColor'),
    Parameters.configColorParameter('focusColor'),
    Parameters.configColorParameter('hoverColor'),
  ]) {
    methods([
      FVBFunction('onChanged', null, [FVBArgument('value', dataType: DataType.fvbDynamic)],
          returnType: DataType.fvbVoid)
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return Radio<dynamic>(
      onChanged: (value) {
        perform(context, arguments: [value]);
      },
      value: parameters[0].value,
      groupValue: parameters[1].value,
      materialTapTargetSize: parameters[2].value,
      toggleable: parameters[3].value,
      activeColor: parameters[4].value,
      fillColor: parameters[5].value,
      focusColor: parameters[6].value,
      hoverColor: parameters[7].value,
    );
  }
}

class CAnimatedOpacity extends COpacity {
  CAnimatedOpacity() : super() {
    parameters.add(Parameters.durationParameter);
  }

  @override
  Widget create(BuildContext context) {
    return AnimatedOpacity(
      opacity: parameters[0].value,
      duration: parameters[1].value,
      child: child?.build(context),
    );
  }
}

class CAnimatedSwitcher extends Holder {
  CAnimatedSwitcher()
      : super('AnimatedSwitcher', [
    Parameters.durationParameter,
  ]);

  @override
  Widget create(BuildContext context) {
    return AnimatedSwitcher(
      duration: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class COpacity extends Holder {
  COpacity()
      : super('Opacity', [
    Parameters.widthFactorParameter()
      ..withInfo(NamedParameterInfo('opacity'))
      ..withDefaultValue(1.0)
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
      ..withDefaultValue(1.0)
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
      backgroundColor: parameters[0].value,
      elevation: parameters[1].value,
      shape: parameters[2].value,
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

class CCard extends Holder {
  CCard()
      : super(
      'Card',
      [
        Parameters.colorParameter..withDefaultValue(ColorAssets.white),
        Parameters.shapeBorderParameter(),
        Parameters.elevationParameter(),
        Parameters.marginParameter(),
        Parameters.colorParameter
          ..withDisplayName('shadowColor')
          ..withInfo(
            NamedParameterInfo('shadowColor'),
          ),
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
        width: true,
        height: true,
      ));

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

class CAppBar extends CustomNamedHolder with CRenderModel, Resizable {
  CAppBar()
      : super('AppBar', [
    Parameters.colorParameter
      ..withDefaultValue(null)
      ..withRequired(false)
      ..withDisplayName('background-color')
      ..withInfo(NamedParameterInfo('backgroundColor')),
    Parameters.toolbarHeight,
    Parameters.elevationParameter()
      ..withDefaultValue(null)
      ..withRequired(false),
    Parameters.enableParameter(null, false)
      ..withNamedParamInfoAndSameDisplayName('centerTitle')
      ..val = null
      ..withRequired(false),
    Parameters.shapeBorderParameter(),
    Parameters.foregroundColorParameter(),
    Parameters.clipBehaviourParameter(),
    Parameters.doubleParameter('leadingWidth'),
    Parameters.configColorParameter('shadowColor'),
    Parameters.primaryParameter(true),
    Parameters.doubleParameter('titleSpacing'),
    Parameters.configColorParameter('surfaceTintColor'),
    Parameters.boolConfigParameter('forceMaterialTransparency', false),
    Parameters.configGoogleFontTextStyleParameter('titleTextStyle')
  ], [
    'title',
    'leading',
    'flexibleSpace'
  ], [
    'actions'
  ]);

  @override
  get direction => Axis.horizontal;

  @override
  bool get parentAffected => true;

  @override
  void onResize(Size size) {
    linearChange(parameters[1], (parameters[1].value ?? boundary?.width ?? 0), size.height);
  }

  @override
  ResizeType get resizeType => ResizeType.verticalOnly;

  @override
  List<Parameter> get resizeAffectedParameters => [parameters[1]];

  @override
  Widget create(BuildContext context) {
    return AppBar(
      backgroundColor: parameters[0].value,
      toolbarHeight: parameters[1].value,
      automaticallyImplyLeading: false,
      elevation: parameters[2].value,
      centerTitle: parameters[3].value,
      shape: parameters[4].value,
      foregroundColor: parameters[5].value,
      clipBehavior: parameters[6].value,
      leadingWidth: parameters[7].value,
      shadowColor: parameters[8].value,
      primary: parameters[9].value,
      titleSpacing: parameters[10].value,
      surfaceTintColor: parameters[11].value,
      forceMaterialTransparency: parameters[12].value,
      titleTextStyle: parameters[13].value,
      title: childMap['title']?.build(context),
      leading: childMap['leading']?.build(context),
      flexibleSpace: childMap['flexibleSpace']?.build(context),
      actions: childrenMap['actions']?.map((e) => e.build(context)).toList(growable: false),
    );
  }

  @override
  Size get size => Size(double.infinity, parameters[1].value);

  @override
  Size get childSize => Size(double.infinity, parameters[1].value);

  @override
  EdgeInsets get margin => EdgeInsets.zero;
}

class MyTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

class CTabBar extends CustomNamedHolder with Controller, Clickable {
  CTabBar()
      : super('TabBar', [
    Parameters.enableParameter(false)
      ..withNamedParamInfoAndSameDisplayName('isScrollable', optional: true),
    Parameters.configColorParameter('labelColor'),
    Parameters.configColorParameter('unselectedLabelColor'),
    Parameters.configColorParameter('indicatorColor'),
    Parameters.googleFontTextStyleParameter
      ..withNamedParamInfoAndSameDisplayName('labelStyle', inner: true)
      ..withRequired(false),
    Parameters.googleFontTextStyleParameter
      ..withNamedParamInfoAndSameDisplayName('unselectedLabelStyle', inner: true)
      ..withRequired(false),
    Parameters.paddingParameter(),
    Parameters.paddingParameter()
      ..withNamedParamInfoAndSameDisplayName('indicatorPadding')
      ..withRequired(true),
    Parameters.paddingParameter()
      ..withNamedParamInfoAndSameDisplayName('labelPadding')
      ..withRequired(true),
    Parameters.decorationParameter()
      ..withRequired(false)
      ..withInnerNamedParamInfoAndDisplayName('indicator', 'BoxDecoration'),
    Parameters.scrollPhysicsParameter,
    Parameters.choiceValueFromEnum(
      TabBarIndicatorSize.values,
      optional: true,
      require: false,
      name: 'indicatorSize',
      defaultValue: null,
    )
  ], [], [
    'tabs'
  ]) {
    controls([
      SelectionControl('page', () => List.generate(childrenMap['tabs']!.length, (i) => (i + 1).toString()), (p0) {
        (values['controller'] as TabController?)?.index = int.parse(p0) - 1;
      }, () => (((values['controller'] as TabController?)?.index ?? 0) + 1).toString())
    ]);
    methods([
      FVBFunction('onTap', null, [FVBArgument('value', dataType: DataType.fvbInt)], returnType: DataType.fvbVoid)
    ]);
    childrenMap['tabs']!.addAll({CTab(), CTab(), CTab()});
    assign('controller', (_, vsync) => TabController(length: childrenMap['tabs']!.length, vsync: vsync),
        'TabController(${childrenMap['tabs']!.length})');
  }

  @override
  Axis get direction => Axis.horizontal;

  @override
  Widget create(BuildContext context) {
    return TabBar(
      controller: values['controller']!,
      isScrollable: parameters[0].value,
      labelColor: parameters[1].value,
      unselectedLabelColor: parameters[2].value,
      indicatorColor: parameters[3].value,
      labelStyle: parameters[4].value,
      unselectedLabelStyle: parameters[5].value,
      padding: parameters[6].value,
      indicatorPadding: parameters[7].value,
      labelPadding: parameters[8].value,
      indicator: parameters[9].value,
      physics: parameters[10].value,
      indicatorSize: parameters[11].value,
      onTap: (value) {
        perform(context, name: 'onTap', arguments: [value]);
      },
      tabs: childrenMap['tabs']!.map((e) => e.build(context)).toList(growable: false),
    );
  }
}

class CTab extends CustomNamedHolder {
  CTab()
      : super('Tab', [
    Parameters.textParameter()
      ..withDefaultValue('tab')
      ..withRequired(false)
      ..withNamedParamInfoAndSameDisplayName('text'),
    Parameters.heightParameter()
      ..withDefaultValue(null)
      ..withRequired(false),
    Parameters.marginParameter()
      ..withRequired(true)
      ..withNamedParamInfoAndSameDisplayName('iconMargin')
  ], [
    'child',
    'icon'
  ], []) {
    final param = (parameters[2] as ChoiceParameter);
    param.val = param.options[1];
    (param.val as ComplexParameter).params[0].compiler.code = '10';
  }

  @override
  Axis get direction => Axis.horizontal;

  @override
  Widget create(BuildContext context) {
    return Tab(
      text: parameters[0].value,
      height: parameters[1].value,
      iconMargin: parameters[2].value,
      child: childMap['child']?.build(context),
      icon: childMap['icon']?.build(context),
    );
  }
}

class CScaffold extends CustomNamedHolder with ComplexRenderModel {
  CScaffold()
      : super('Scaffold', [
    Parameters.backgroundColorParameter(),
    BooleanParameter(
      required: false,
      val: false,
      displayName: 'resize to avoid bottom inset',
      info: NamedParameterInfo('resizeToAvoidBottomInset'),
    ),
  ], [
    'appBar',
    'body',
    'drawer',
    'endDrawer',
    'floatingActionButton',
    'bottomNavigationBar',
    'bottomSheet',
  ], []) {
    autoHandleKey = false;
  }

  @override
  String code({bool clean = true}) {
    try {
      if (!clean) {
        return super.code(clean: clean);
      }
      final middle = generateParametersCode(clean);
      String name = this.name;
      if (!clean) {
        name = metaCode(name);
      }
      String childrenCode = '';
      for (final child in childMap.keys) {
        if (childMap[child] != null) {
          final childComp = childMap[child]!;
          if (child == 'appBar' && childComp is! CAppBar && childComp is! CPreferredSize) {
            childrenCode +=
            '$child:PreferredSize(preferredSize: Size.fromHeight(kToolbarHeight),child:${childComp.code(
                clean: clean)}),';
          } else {
            childrenCode += '$child:${childComp.code(clean: clean)},';
          }
        }
      }

      for (final child in childrenMap.keys) {
        if (childrenMap[child]?.isNotEmpty ?? false) {
          childrenCode += '$child:[${childrenMap[child]!.map((e) => (e.code(clean: clean) + ',')).join('')}],';
        }
      }
      return withState('$name($middle$childrenCode)', clean);
    } on Exception catch (e) {
      print('$name ${e.toString()}');
    }
    return '';
  }

  @override
  Widget create(BuildContext context) {
    return Scaffold(
      restorationId: id,
      key: key(context),
      backgroundColor: parameters[0].value,
      resizeToAvoidBottomInset: parameters[1].value,
      appBar: childMap['appBar'] != null && childMap['appBar'] is CAppBar
          ? PreferredSize(
        child: childMap['appBar']!.build(context),
        preferredSize: Size.fromHeight(childMap['appBar']!.parameters[1].value),
      )
          : PreferredSize(
        child: childMap['appBar']?.build(context) ?? const Offstage(),
        preferredSize: const Size.fromHeight(kToolbarHeight),
      ),
      drawer: RuntimeProvider(
          runtimeMode: RuntimeProvider.of(context),
          child: ProcessorProvider(
            processor: ProcessorProvider.maybeOf(context)!,
            child: BlocBuilder<CreationCubit, CreationState>(
              buildWhen: (prev, state) {
                if (fvbNavigationBloc.model.drawer ||
                    fvbNavigationBloc.model.endDrawer ||
                    fvbNavigationBloc.model.dialog ||
                    fvbNavigationBloc.model.bottomSheet) {
                  return true;
                }
                return false;
              },
              builder: (context, state) {
                // final original=(getOriginal())!.cloneElements.last;
                // return (original as CustomNamedHolder).
                return childMap['drawer']?.build(context) ?? const Offstage();
              },
            ),
          )),
      endDrawer: childMap['endDrawer'] != null
          ? RuntimeProvider(
          runtimeMode: RuntimeProvider.of(context),
          child: ProcessorProvider(
            processor: ProcessorProvider.maybeOf(context)!,
            child: BlocBuilder<CreationCubit, CreationState>(
              buildWhen: (prev, state) {
                if (fvbNavigationBloc.model.drawer ||
                    fvbNavigationBloc.model.endDrawer ||
                    fvbNavigationBloc.model.dialog ||
                    fvbNavigationBloc.model.bottomSheet) {
                  return true;
                }
                return false;
              },
              builder: (context, state) {
                // final original=(getOriginal())!.cloneElements.last;
                // return (original as CustomNamedHolder).
                return childMap['endDrawer']?.build(context) ?? const Offstage();
              },
            ),
          ))
          : null,
      body: childMap['body']?.build(context),
      floatingActionButton: childMap['floatingActionButton']?.build(context),
      bottomNavigationBar: childMap['bottomNavigationBar']?.build(context),
      bottomSheet: childMap['bottomSheet']?.build(context),
    );
  }

  @override
  Size get size => Size.infinite;

  @override
  ComponentSize childSize(String child) {
    switch (child) {
      case 'body':
        return const ComponentSize(Size.infinite, margin: EdgeInsets.only(top: kToolbarHeight));
    }
    return ComponentSize.infinite;
  }
}

class CChip extends CustomNamedHolder with ComplexRenderModel, Clickable {

  CChip()
      : super('Chip', [
    Parameters.backgroundColorParameter(),
    Parameters.WidgetStatePropertyParameter<Color?>(
        Parameters.colorParameter..withChangeNamed(null),
        'color'),
    Parameters.paddingParameter()
      ..withChangeNamed('labelPadding'),
    Parameters.paddingParameter(),
    Parameters.elevationParameter(),
    Parameters.shapeBorderParameter(),
    Parameters.clipBehaviourParameter(),
    Parameters.configColorParameter('shadowColor'),
    Parameters.configColorParameter('surfaceTintColor'),
  ], [
    'label',
    'deleteIcon',
    'avatar',
  ], []) {
    autoHandleKey = false;
    methods([
      FVBFunction('onDeleted', null, [], returnType: DataType.fvbVoid)
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return Chip(
      backgroundColor: parameters[0].value,
      color: parameters[1].value,
      labelPadding: parameters[2].value,
      padding: parameters[3].value,
      elevation: parameters[4].value,
      shape: parameters[5].value,
      clipBehavior: parameters[6].value,
      shadowColor: parameters[7].value,
      surfaceTintColor: parameters[8].value,
      label: childMap['label']?.build(context) ?? Container(),
      deleteIcon: childMap['deleteIcon']?.build(context),
      avatar: childMap['avatar']?.build(context),
      onDeleted: () {
        perform(context, name: 'onDeleted');
      },
    );
  }

  @override
  Size get size => Size.infinite;

  @override
  ComponentSize childSize(String child) {
    return ComponentSize.infinite;
  }
}

class CListTile extends CustomNamedHolder with ComplexRenderModel, Clickable {
  CListTile()
      : super('ListTile', [
    Parameters.paddingParameter()
      ..withNamedParamInfoAndSameDisplayName('contentPadding'),
    Parameters.configColorParameter('tileColor'),
    Parameters.configColorParameter('textColor'),
    Parameters.choiceValueFromEnum(
      ListTileStyle.values,
      optional: true,
      require: false,
      name: 'style',
      defaultValue: null,
    ),
    Parameters.boolConfigParameter('enabled', true),
    Parameters.boolConfigParameter('autofocus', false),
    Parameters.boolConfigParameter('selected', false),
    Parameters.boolConfigParameter('dense', null),
    Parameters.configColorParameter('focusColor'),
    Parameters.configColorParameter('splashColor'),
    Parameters.configColorParameter('hoverColor'),
    Parameters.configColorParameter('selectedColor'),
    Parameters.configColorParameter('iconColor'),
    Parameters.configColorParameter('selectedTileColor'),
    Parameters.shapeBorderParameter()
      ..withRequired(false),
    Parameters.doubleParameter('horizontalTitleGap'),
    Parameters.boolConfigParameter('isThreeLine', false),
    Parameters.doubleParameter('minLeadingWidth'),
    Parameters.doubleParameter('minVerticalPadding'),
    Parameters.visualDensityParameter,
    Parameters.boolConfigParameter('enableFeedback', null),
  ], [
    'title',
    'subtitle',
    'trailing',
    'leading',
  ], []) {
    autoHandleKey = false;
    methods([
      FVBFunction('onTap', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onLongPress', null, [], returnType: DataType.fvbVoid),
      FVBFunction(
          'onFocusChange',
          null,
          [
            FVBArgument(
              'value',
              dataType: DataType.fvbBool,
            ),
          ],
          returnType: DataType.fvbVoid),
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return ListTile(
      key: key(context),
      contentPadding: parameters[0].value,
      tileColor: parameters[1].value,
      textColor: parameters[2].value,
      style: parameters[3].value,
      enabled: parameters[4].value,
      autofocus: parameters[5].value,
      selected: parameters[6].value,
      dense: parameters[7].value,
      focusColor: parameters[8].value,
      splashColor: parameters[9].value,
      hoverColor: parameters[10].value,
      selectedColor: parameters[11].value,
      iconColor: parameters[12].value,
      selectedTileColor: parameters[13].value,
      shape: parameters[14].value,
      horizontalTitleGap: parameters[15].value,
      isThreeLine: parameters[16].value,
      minLeadingWidth: parameters[17].value,
      minVerticalPadding: parameters[18].value,
      visualDensity: parameters[19].value,
      enableFeedback: parameters[20].value,
      title: childMap['title']?.build(context),
      subtitle: childMap['subtitle']?.build(context),
      trailing: childMap['trailing']?.build(context),
      leading: childMap['leading']?.build(context),
      onTap: () {
        perform(context);
      },
      onLongPress: () {
        perform(context, name: 'onLongPress');
      },
      onFocusChange: (value) {
        perform(context, name: 'onFocusChange', arguments: [value]);
      },
    );
  }

  @override
  Size get size => Size.infinite;

  @override
  ComponentSize childSize(String child) {
    return ComponentSize.infinite;
  }
}

class CPopupMenuButton extends CustomNamedHolder with Clickable, Controller {
  CPopupMenuButton()
      : super('PopupMenuButton', [
    Parameters.enableParameter(),
    Parameters.dynamicValueParameter()
      ..withNamedParamInfoAndSameDisplayName('initialValue')
      ..withRequired(false),
    Parameters.paddingParameter(
      defaultVal: 0,
      required: true,
      allValue: 8.0,
    ),
    Parameters.offsetParameter(),
    Parameters.colorParameter,
    Parameters.elevationParameter()
      ..withDefaultValue(null)
      ..withRequired(false),
    Parameters.textParameter()
      ..withChangeNamed('tooltip'),
    Parameters.choiceValueFromEnum(PopupMenuPosition.values,
        optional: false, require: false, name: 'position', defaultValue: null),
    Parameters.widthParameter()
      ..withChangeNamed('iconSize')
      ..withDefaultValue(null),
    Parameters.widthParameter()
      ..withChangeNamed('splashRadius')
      ..withDefaultValue(null),
    Parameters.clipBehaviourParameter('none')
  ], [
    'icon',
    'child',
  ], [
    'itemBuilder'
  ]) {
    methods([
      FVBFunction(
          'onSelected',
          null,
          [
            FVBArgument('value', dataType: DataType.fvbDynamic),
          ],
          returnType: DataType.fvbVoid),
      FVBFunction('onCanceled', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onOpened', null, [], returnType: DataType.fvbVoid)
    ]);
    controls([
      ButtonControl('Popup', (value) => value != true ? 'show' : 'hide', (value) {
        if (value != true) {
          (GlobalObjectKey(this).currentState as PopupMenuButtonState).showButtonMenu();
          return true;
        }
        Navigator.of(GlobalObjectKey(this).currentContext!).pop();
        return false;
      })
    ]);
    autoHandleKey = false;
  }

  @override
  Widget create(BuildContext context) {
    if ((list[0] as ButtonControl).value == true) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        (GlobalObjectKey(this).currentState as PopupMenuButtonState).showButtonMenu();
      });
    }

    return PopupMenuButton(
      key: key(context),
      enabled: parameters[0].value,
      initialValue: parameters[1].value,
      padding: parameters[2].value,
      offset: parameters[3].value,
      color: parameters[4].value,
      elevation: parameters[5].value,
      tooltip: parameters[6].value,
      position: parameters[7].value,
      iconSize: parameters[8].value,
      splashRadius: parameters[9].value,

      /// TODO: Uncomment this
      // clipBehavior: parameters[10].value,
      itemBuilder: (BuildContext context) {
        return childrenMap['itemBuilder']!
            .whereType<CPopupMenuItem>()
            .map((e) => (e.create(context) as BinderWidget<PopupMenuItem>).value)
            .toList(growable: false);
      },
      icon: childMap['icon']?.build(context),
      child: childMap['child']?.build(context),
      onCanceled: () {
        perform(context, name: 'onCanceled');
      },

      /// TODO: UNCOMMENT
      // onOpened: () {
      //   perform(context, name: 'onOpened');
      // },
      onSelected: (data) {
        perform(context, arguments: [data], name: 'onSelected');
      },
    );
  }
}

class CDropDownButton extends CustomNamedHolder with Clickable, Controller {
  CDropDownButton()
      : super(
      'DropdownButton',
      [
        Parameters.dynamicValueParameter()
          ..withNamedParamInfoAndSameDisplayName('value')
          ..withRequired(false),
        Parameters.intElevationParameter
          ..withDefaultValue(8)
          ..withRequired(true),
        Parameters.googleFontTextStyleParameter,
        Parameters.borderRadiusParameter(),
        Parameters.enableFeedbackParameter()
      ],
      ['icon', 'hint', 'underline'],
      ['items'],
      config: ComponentDefaultParamConfig(padding: true, width: true, height: true)) {
    methods([
      FVBFunction(
          'onChanged',
          null,
          [
            FVBArgument('value', dataType: DataType.fvbDynamic),
          ],
          returnType: DataType.fvbVoid),
      FVBFunction('onTap', null, [], returnType: DataType.fvbVoid)
    ]);
    controls([
      ButtonControl('Dropdown', (value) => value != true ? 'show' : 'hide', (value) {
        if (value != true) {
          GestureDetector? detector;
          void searchForGestureDetector(BuildContext element) {
            element.visitChildElements((element) {
              if (element.widget is GestureDetector) {
                detector = element.widget as GestureDetector;
                return;
              } else {
                searchForGestureDetector(element);
              }

              return;
            });
          }

          searchForGestureDetector(GlobalObjectKey(this).currentContext!);
          detector!.onTap!.call();
          return true;
        }
        Navigator.of(GlobalObjectKey(this).currentContext!).pop();
        return false;
      })
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return DropdownButton<dynamic>(
      value: parameters[0].value,
      elevation: parameters[1].value,
      style: parameters[2].value,
      borderRadius: parameters[3].value,
      enableFeedback: parameters[4].value,
      onChanged: (data) {
        perform(context, arguments: [data]);
      },
      onTap: () {
        perform(context, name: 'onTap');
      },
      icon: childMap['icon']?.build(context),
      selectedItemBuilder: (context) =>
          (List.castFrom<Component, CDropdownMenuItem>(childrenMap['items']
              ?.map((e) => (e).clone(this, deepClone: false, connect: true))
              .toList(growable: false) ??
              []))
              .map<DropdownMenuItem>((e) => e.create(context) as DropdownMenuItem)
              .toList(),
      hint: childMap['hint']?.build(context),
      underline: childMap['underline']?.build(context),
      items: (childrenMap['items'] ?? [])
          .map<DropdownMenuItem>((e) => e.buildWithoutKey(context) as DropdownMenuItem)
          .toList(),
    );
  }

  @override
  Component clone(parent, {bool deepClone = false, bool connect = false}) {
    final cloneComp = super.clone(parent, deepClone: deepClone, connect: connect);
    if (deepClone) {
      (cloneComp as Clickable).actionList = actionList.map((e) => e.clone()).toList();
    } else {
      (cloneComp as Clickable).actionList = actionList;
    }
    return cloneComp;
  }
}

class CRow extends MultiHolder with CFlexModel {
  CRow()
      : super(
      'Row',
      [
        Parameters.mainAxisAlignmentParameter(),
        Parameters.crossAxisAlignmentParameter(),
        Parameters.mainAxisSizeParameter()
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
        padding: true,
        width: true,
        visibility: true,
        alignment: true,
        height: true,
      ));

  @override
  Axis get direction => Axis.horizontal;

  @override
  Widget create(BuildContext context) {
    return Row(
      mainAxisAlignment: parameters[0].value,
      crossAxisAlignment: parameters[1].value,
      mainAxisSize: parameters[2].value,
      children: children.map((e) => e.build(context)).toList(),
    );
  }

  @override
  CrossAxisAlignment get crossAxisAlignment => parameters[1].value;

  @override
  MainAxisSize get mainAxisSize => parameters[2].value;
}

class CPageView extends MultiHolder with Controller {
  CPageView()
      : super('PageView', [
    Parameters.axisParameter()
      ..withInfo(NamedParameterInfo('scrollDirection')),
    BooleanParameter(displayName: 'reverse', required: true, val: false, info: NamedParameterInfo('reverse')),
    BooleanParameter(
      displayName: 'page-snapping',
      required: true,
      val: true,
      info: NamedParameterInfo('pageSnapping'),
    ),
    Parameters.clipBehaviourParameter('hardEdge'),
  ]) {}

  @override
  Widget create(BuildContext context) {
    assign('pageController', (_, vsync) => PageController(), 'PageController()');
    return PageView(
      scrollDirection: parameters[0].value,
      reverse: parameters[1].value,
      pageSnapping: parameters[2].value,
      clipBehavior: parameters[3].value,
      controller: values['pageController']!,
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CColumn extends MultiHolder with CFlexModel {
  CColumn()
      : super(
      'Column',
      [
        Parameters.mainAxisAlignmentParameter(),
        Parameters.crossAxisAlignmentParameter(),
        Parameters.mainAxisSizeParameter()
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
        padding: true,
        width: true,
        visibility: true,
        alignment: true,
        height: true,
      ));

  @override
  Widget create(BuildContext context) {
    return Column(
      mainAxisAlignment: (parameters[0] as ChoiceValueParameter).value,
      crossAxisAlignment: (parameters[1] as ChoiceValueParameter).value,
      mainAxisSize: (parameters[2] as ChoiceValueParameter).value,
      children: children.map((e) => e.build(context)).toList(),
    );
  }

  @override
  CrossAxisAlignment get crossAxisAlignment => (parameters[0] as ChoiceValueParameter).value;

  @override
  MainAxisSize get mainAxisSize => (parameters[2] as ChoiceValueParameter).value;
}

class CWrap extends MultiHolder {
  CWrap()
      : super(
      'Wrap',
      [
        Parameters.wrapAlignmentParameter(),
        Parameters.wrapCrossAxisAlignmentParameter(),
        Parameters.axisParameter()
          ..withDefaultValue('horizontal'),
        Parameters.widthParameter()
          ..withDefaultValue(0.0)
          ..withRequired(true)
          ..withNamedParamInfoAndSameDisplayName('spacing'),
        Parameters.widthParameter()
          ..withDefaultValue(0.0)
          ..withRequired(true)
          ..withNamedParamInfoAndSameDisplayName('runSpacing'),
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
        padding: true,
        width: true,
        visibility: true,
        alignment: true,
        height: true,
      ));

  @override
  Widget create(BuildContext context) {
    return Wrap(
      alignment: parameters[0].value,
      crossAxisAlignment: parameters[1].value,
      direction: parameters[2].value,
      spacing: parameters[3].value,
      runSpacing: parameters[4].value,
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CStack extends MultiHolder {
  CStack()
      : super(
      'Stack',
      [
        Parameters.alignmentParameter(),
        Parameters.stackFitParameter(),
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
        padding: true,
        width: true,
        visibility: true,
        alignment: true,
        height: true,
      ));

  @override
  Widget create(BuildContext context) {
    return Stack(
      alignment: parameters[0].value,
      fit: parameters[1].value,
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CIndexedStack extends MultiHolder {
  int index = 0;

  CIndexedStack()
      : super(
      'IndexedStack',
      [
        Parameters.alignmentParameter(),
        Parameters.intConfigParameter(),
        Parameters.clipBehaviourParameter('hardEdge'),
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
        padding: true,
        width: true,
        height: true,
        visibility: true,
        alignment: true,
      ));

  @override
  Widget create(BuildContext context) {
    return IndexedStack(
      alignment: parameters[0].value,
      index: index = parameters[1].value,
      clipBehavior: parameters[2].value,
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CDropdownMenuItem extends ClickableHolder {
  CDropdownMenuItem()
      : super('DropdownMenuItem', [
    Parameters.enableParameter()
      ..withChangeNamed('enabled'),
    Parameters.dynamicValueParameter()
      ..withNamedParamInfoAndSameDisplayName('value')
      ..withDefaultValue(DateTime.now().toIso8601String())
      ..withRequired(true),
    Parameters.alignmentParameter()
      ..info = NamedParameterInfo('alignment')
      ..withDefaultValue('centerLeft')
      ..withRequired(true),
  ]) {
    autoHandleKey = false;
  }

  @override
  Widget create(BuildContext context) {
    return DropdownMenuItem(
      key: key(context),
      enabled: parameters[0].value,
      value: parameters[1].value,
      alignment: parameters[2].value,
      child: child?.build(context) ?? Container(),
      onTap: () {
        perform(context);
      },
    );
  }
}

class CFlex extends MultiHolder {
  CFlex()
      : super(
      'Flex',
      [
        Parameters.mainAxisAlignmentParameter(),
        Parameters.crossAxisAlignmentParameter(),
        Parameters.mainAxisSizeParameter(),
        Parameters.axisParameter()
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
          padding: true,
          width: true,
          height: true,
          alignment: true,
          visibility: true));

  @override
  Axis get direction => parameters.last.value;

  @override
  Widget create(BuildContext context) {
    return Flex(
      mainAxisAlignment: (parameters[0] as ChoiceValueParameter).value,
      crossAxisAlignment: (parameters[1] as ChoiceValueParameter).value,
      mainAxisSize: (parameters[2] as ChoiceValueParameter).value,
      direction: (parameters[3] as ChoiceValueParameter).value,
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CPadding extends Holder with CRenderModel {
  CPadding() : super('Padding', [Parameters.paddingParameter()
    ..withRequired(true)
  ]);

  @override
  Widget create(BuildContext context) {
    return Padding(
      padding: parameters[0].value,
      child: child?.build(context),
    );
  }

  @override
  Size get childSize => Size.infinite;

  @override
  EdgeInsets get margin => parameters[0].value;

  @override
  Size get size => Size.infinite;
}

class CTooltip extends Holder {
  CTooltip()
      : super('Tooltip', [
    Parameters.textParameter(defaultValue: '', required: true)
      ..withNamedParamInfoAndSameDisplayName('message'),
    Parameters.googleFontTextStyleParameter
      ..withChangeNamed('textStyle')
      ..withDisplayName('textStyle'),
    Parameters.paddingParameter(),
    Parameters.marginParameter(),
    Parameters.enableParameter(null)
      ..withNamedParamInfoAndSameDisplayName('enableFeedback'),
    Parameters.enableParameter(null)
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
  CClipRRect() : super('ClipRRect', [Parameters.borderRadiusParameter()
    ..withRequired(true)
  ]);

  @override
  Widget create(BuildContext context) {
    return ClipRRect(
      borderRadius: parameters[0].value,
      child: child?.build(context),
    );
  }
}

class CClipOval extends Holder {
  CClipOval() : super('ClipOval', []);

  @override
  Widget create(BuildContext context) {
    return ClipOval(
      child: child?.build(context),
    );
  }
}

class CDropdownButtonHideUnderline extends Holder {
  CDropdownButtonHideUnderline() : super('DropdownButtonHideUnderline', []);

  @override
  Widget create(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: child?.build(context) ?? const Offstage(),
    );
  }
}

class CCircleAvatar extends Holder with Resizable {
  CCircleAvatar()
      : super(
      'CircleAvatar',
      [
        Parameters.radiusParameter(),
        Parameters.backgroundColorParameter(),
        Parameters.foregroundColorParameter(),
        // Parameters.radiusParameter()
        //   ..withDisplayName('minimum radius')
        //   ..withInfo(NamedParameterInfo('minRadius')),
        // Parameters.radiusParameter()
        //   ..withDisplayName('maximum radius')
        //   ..withInfo(NamedParameterInfo('maxRadius')),
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
        padding: true,
        visibility: true,
        alignment: true,
      ),
      boundaryRepaintDelay: 400);

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

  @override
  void onResize(Size change) {
    symmetricChange(parameters[0], (parameters[0].value ?? ((boundary?.width ?? 0) / 2)), change / 2);
  }

  @override
  List<Parameter> get resizeAffectedParameters => [parameters[0]];

  @override
  ResizeType get resizeType => ResizeType.symmetricResize;
}

class COutlinedButton extends ClickableHolder {
  COutlinedButton()
      : super('OutlinedButton', [Parameters.buttonStyleParameter()],
      defaultParamConfig: ComponentDefaultParamConfig(
        padding: true,
        width: true,
        visibility: true,
        alignment: true,
        height: true,
      )) {
    methods([FVBFunction('onPressed', null, [], returnType: DataType.fvbVoid)]);
  }

  @override
  Widget create(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        perform(context);
      },
      style: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class CElevatedButton extends ClickableHolder {
  CElevatedButton()
      : super(
      'ElevatedButton',
      [
        Parameters.buttonStyleParameter(),
      ],
      defaultParamConfig: ComponentDefaultParamConfig(
        padding: true,
        width: true,
        visibility: true,
        alignment: true,
        height: true,
      )) {
    methods([
      FVBFunction('onPressed', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onLongPress', null, [], returnType: DataType.fvbVoid),
      FVBFunction('onHover', null, [FVBArgument('value', dataType: DataType.fvbBool, nullable: false)],
          returnType: DataType.fvbVoid),
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        perform(context);
      },
      onLongPress: () {
        perform(context, name: 'onLongPress');
      },
      // onHover: (value) {
      //   perform(context, name: 'onHover', arguments: [value]);
      // },
      style: parameters[0].value,
      child: child?.build(context) ?? Container(),
    );
  }
}

class ComponentSize {
  final Size size;
  final EdgeInsets margin;

  const ComponentSize(this.size, {
    this.margin = EdgeInsets.zero,
  });

  static const infinite = ComponentSize(Size.infinite);

  double get width => size.width;

  double get height => size.height;

  Size totalSize(Size boundary) {
    return Size(
      size.width == double.infinity ? boundary.width : size.width,
      size.height == double.infinity ? boundary.height : size.height,
    );
  }

  Size childSize(Size boundary) {
    final total = totalSize(boundary);
    return Size(total.width - margin.horizontal, total.height - margin.vertical);
  }
}
