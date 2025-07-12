import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';

import '../common/analyzer/render_models.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../enums.dart';
import '../models/builder_component.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/input_types/range_input.dart';
import '../models/parameter_info_model.dart';
import '../models/parameter_model.dart';
import '../parameter/parameters_list.dart';
import 'component_impl.dart';
import 'component_list.dart';

class CSingleChildScrollView extends Holder
    with FVBScrollable, CBoxScrollModel {
  CSingleChildScrollView()
      : super('SingleChildScrollView', [
          Parameters.axisParameter()
            ..withNamedParamInfoAndSameDisplayName('scrollDirection')
            ..withDefaultValue('vertical'),
          Parameters.paddingParameter()..withRequired(false),
        ]);

  @override
  Widget create(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: parameters[0].value,
      padding: parameters[1].value,
      controller: initScrollController(context),
      child: child?.build(context),
    );
  }

  @override
  Axis get direction => parameters[0].value ?? Axis.vertical;

  @override
  List<Component> get children => [if (child != null) child!];
}

class CGridView extends MultiHolder with FVBScrollable, CBoxScrollModel {
  CGridView()
      : super(
          'GridView',
          [
            Parameters.paddingParameter(),
            Parameters.sliverDelegate(),
            Parameters.scrollPhysicsParameter,
            Parameters.enableParameter(false)
              ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
          ],
          defaultParamConfig: ComponentDefaultParamConfig(
            width: true,
            height: true,
          ),
        );

  @override
  Widget create(BuildContext context) {
    return GridView(
      padding: parameters[0].value,
      gridDelegate: parameters[1].value,
      physics: parameters[2].value,
      shrinkWrap: parameters[3].value,
      controller: initScrollController(context),
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CListView extends MultiHolder with FVBScrollable, CBoxScrollModel {
  CListView()
      : super(
          'ListView',
          [
            Parameters.paddingParameter(),
            Parameters.axisParameter()
              ..withInfo(NamedParameterInfo('scrollDirection')),
            BooleanParameter(
                displayName: 'reverse',
                required: true,
                val: false,
                info: NamedParameterInfo('reverse')),
            Parameters.enableParameter(false)
              ..withRequired(true)
              ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
            Parameters.clipBehaviourParameter('hardEdge'),
          ],
          defaultParamConfig: ComponentDefaultParamConfig(
            width: true,
            height: true,
          ),
        );

  @override
  Axis get direction => parameters[1].value;

  @override
  Widget create(BuildContext context) {
    return ListView(
      padding: parameters[0].value,
      scrollDirection: parameters[1].value,
      reverse: parameters[2].value,
      shrinkWrap: parameters[3].value,
      clipBehavior: parameters[4].value,
      controller: initScrollController(context),
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CTabBarView extends MultiHolder with Controller {
  CTabBarView()
      : super('TabBarView', [
          SimpleParameter<String>(
              name: 'Tab-bar ID',
              defaultValue: null,
              inputType: ParamInputType.simple,
              required: false,
              generateCode: false),
          Parameters.widthParameter()
            ..withRequired(true)
            ..withDefaultValue(1.0)
            ..withNamedParamInfoAndSameDisplayName('viewportFraction',
                optional: true),
          Parameters.scrollPhysicsParameter,
          Parameters.clipBehaviourParameter('hardEdge')
        ]) {
    assign('controller', (_, vsync) {
      var id = parameters[0].value;
      FVBInstance? value;
      value = lookUp(OperationCubit.paramProcessor, id);
      if (value == null) {
        final root = getCustomComponentRoot();
        if (root != null) {
          root.forEachWithClones((p0) {
            if (p0 is CTabBar) {
              id = p0.id;
              value = lookUp(OperationCubit.paramProcessor, id);
              return true;
            }
            return false;
          });
        }
        parameters[0].compiler.code = id;
      }
      return value?.variables['controller']?.value.variables['_dart']?.value ??
          TabController(length: children.length, vsync: vsync);
    }, '');
    autoHandleKey = false;
  }

  @override
  Axis get direction => parameters[1].value;

  @override
  Widget create(BuildContext context) {
    return TabBarView(
      key: key(context),
      controller: values['controller'],
      viewportFraction: parameters[1].value,
      physics: parameters[2].value,
      clipBehavior: parameters[3].value,
      children: children.map((e) => e.build(context)).toList(),
    );
  }
}

class CNavigationRail extends CustomNamedHolder with Clickable {
  CNavigationRail()
      : super('NavigationRail', [
          Parameters.intConfigParameter(name: 'selectedIndex'),
          Parameters.boolConfigParameter('extended', false),
          Parameters.configColorParameter('backgroundColor'),
          Parameters.elevationParameter(defaultValue: null),
          Parameters.textStyleParameter(name: 'unselectedLabelTextStyle'),
          Parameters.textStyleParameter(name: 'selectedLabelTextStyle'),
          Parameters.doubleParameter('groupAlignment',
              inputOption: RangeInput<double>(-1, 1, 0.01)),
          Parameters.doubleParameter('minExtendedWidth'),
          Parameters.doubleParameter('minWidth'),
          Parameters.boolConfigParameter('useIndicator', null),
          Parameters.configColorParameter('indicatorColor'),
          Parameters.shapeBorderParameter(
              name: 'indicatorShape', required: false),
        ], [
          'leading',
          'trailing',
        ], [
          'destinations'
        ]) {
    childrenMap['destinations']!.addAll({
      CNavigationRailDestination(name: 'Home', icon: 'home'),
      CNavigationRailDestination(name: 'Dashboard', icon: 'apps'),
      CNavigationRailDestination(name: 'About', icon: 'info'),
    });
    methods([
      FVBFunction(
          'onDestinationSelected',
          null,
          [
            FVBArgument('value', dataType: DataType.fvbInt, nullable: false),
          ],
          returnType: DataType.fvbVoid)
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return NavigationRail(
      destinations: childrenMap['destinations']!
          .whereType<CNavigationRailDestination>()
          .map((e) =>
              (e.create(context) as BinderWidget<NavigationRailDestination>)
                  .value)
          .toList(growable: false),
      selectedIndex: parameters[0].value,
      extended: parameters[1].value,
      backgroundColor: parameters[2].value,
      elevation: parameters[3].value,
      unselectedLabelTextStyle: parameters[4].value,
      selectedLabelTextStyle: parameters[5].value,
      groupAlignment: parameters[6].value,
      minExtendedWidth: parameters[7].value,
      minWidth: parameters[8].value,
      useIndicator: parameters[9].value,
      indicatorColor: parameters[10].value,
      indicatorShape: parameters[11].value,
      onDestinationSelected: (value) {
        perform(context, arguments: [value]);
      },
      leading: childMap['leading']?.build(context),
      trailing: childMap['trailing']?.build(context),
    );
  }
}

class CNavigationRailDestination extends CustomNamedHolder {
  CNavigationRailDestination({String? name, String? icon})
      : super('NavigationRailDestination', [], [
          'label',
          'icon',
          'selectedIcon',
        ], []) {
    childMap['icon'] = CIcon(icon: icon);
    childMap['label'] = CText(text: name);
    autoHandleKey = false;
  }

  @override
  Widget create(BuildContext context) {
    return BinderWidget<NavigationRailDestination>(
      NavigationRailDestination(
        label: childMap['label']!.build(context),
        icon: childMap['icon']!.build(context),
        selectedIcon: childMap['selectedIcon']?.build(context),
      ),
      key: key(context),
    );
  }
}

class CBottomNavigationBar extends CustomNamedHolder with Clickable {
  CBottomNavigationBar()
      : super('BottomNavigationBar', [
          Parameters.intConfigParameter()
            ..withRequired(true)
            ..withDefaultValue(0)
            ..withNamedParamInfoAndSameDisplayName('currentIndex'),
          Parameters.backgroundColorParameter(),
          Parameters.choiceValueFromEnum(BottomNavigationBarType.values,
              optional: true, require: false, defaultValue: null, name: 'type'),
          Parameters.elevationParameter(),
          Parameters.configColorParameter('unselectedItemColor'),
          Parameters.configColorParameter('selectedItemColor'),
          Parameters.widthParameter()
            ..withDefaultValue(24.0)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('iconSize'),
          Parameters.googleFontTextStyleParameter
            ..withNamedParamInfoAndSameDisplayName('unselectedLabelStyle',
                inner: true),
          Parameters.googleFontTextStyleParameter
            ..withNamedParamInfoAndSameDisplayName('selectedLabelStyle',
                inner: true),
          Parameters.configColorParameter('fixedColor'),
          Parameters.widthParameter()
            ..withDefaultValue(14.0)
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('selectedFontSize'),
          Parameters.enableParameter(null)
            ..withNamedParamInfoAndSameDisplayName('showSelectedLabels')
            ..withRequired(false),
          Parameters.enableParameter(null)
            ..withNamedParamInfoAndSameDisplayName('showUnselectedLabels')
            ..withRequired(false)
        ], [], [
          'items'
        ]) {
    childrenMap['items']!.addAll({
      CBottomNavigationBarItem(),
      CBottomNavigationBarItem(),
      CBottomNavigationBarItem(),
    });
    methods([
      FVBFunction(
          'onTap',
          null,
          [
            FVBArgument('value', dataType: DataType.fvbInt, nullable: false),
          ],
          returnType: DataType.fvbVoid)
    ]);
  }

  @override
  Widget create(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: parameters[0].value,
      backgroundColor: parameters[1].value,
      type: parameters[2].value,
      elevation: parameters[3].value,
      unselectedItemColor: parameters[4].value,
      selectedItemColor: parameters[5].value,
      iconSize: parameters[6].value,
      unselectedLabelStyle: parameters[7].value,
      selectedLabelStyle: parameters[8].value,
      fixedColor: parameters[9].value,
      selectedFontSize: parameters[10].value,
      showSelectedLabels: parameters[11].value,
      showUnselectedLabels: parameters[12].value,
      onTap: (value) {
        perform(context, arguments: [value]);
      },
      items: childrenMap['items']!
          .whereType<CBottomNavigationBarItem>()
          .map((e) =>
              (e.create(context) as BinderWidget<BottomNavigationBarItem>)
                  .value)
          .toList(growable: false),
    );
  }
}

class CBottomNavigationBarItem extends CustomNamedHolder {
  CBottomNavigationBarItem()
      : super('BottomNavigationBarItem', [
          Parameters.backgroundColorParameter(),
          Parameters.textParameter()
            ..withDefaultValue('')
            ..withRequired(false)
            ..enable = true
            ..withNamedParamInfoAndSameDisplayName('label'),
          Parameters.textParameter()
            ..withDefaultValue(null)
            ..withRequired(false)
            ..withNamedParamInfoAndSameDisplayName('tooltip')
        ], [
          'icon',
          'activeIcon'
        ], []) {
    childMap['icon'] = CIcon();
    autoHandleKey = false;
  }

  @override
  Widget create(BuildContext context) {
    return BinderWidget<BottomNavigationBarItem>(
      BottomNavigationBarItem(
        backgroundColor: parameters[0].value,
        label: parameters[1].value,
        tooltip: parameters[2].value,
        icon: childMap['icon']!.build(context),
        activeIcon: childMap['activeIcon']?.build(context),
      ),
      key: key(context),
    );
  }
}

class CPopupMenuItem extends Holder with Clickable {
  CPopupMenuItem()
      : super('PopupMenuItem', [
          Parameters.dynamicValueParameter()
            ..withDefaultValue(1)
            ..withNamedParamInfoAndSameDisplayName('value'),
          Parameters.paddingParameter(),
          Parameters.heightParameter()
            ..withDefaultValue(48.0)
            ..withRequired(true),
          Parameters.enableParameter(),
          Parameters.textStyleParameter(name: 'textStyle')
        ]) {
    autoHandleKey = false;
    methods([FVBFunction('onTap', null, [], returnType: DataType.fvbVoid)]);
  }

  @override
  Widget create(BuildContext context) {
    return BinderWidget<PopupMenuItem>(
      PopupMenuItem(
        key: key(context),
        value: parameters[0].value,
        padding: parameters[1].value,
        height: parameters[2].value,
        enabled: parameters[3].value,
        textStyle: parameters[4].value,
        onTap: () {
          perform(context, arguments: []);
        },
        child: child?.build(context),
      ),
    );
  }
}

class CCustomScrollView extends CustomNamedHolder with FVBScrollable {
  CCustomScrollView()
      : super('CustomScrollView', [
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
          BooleanParameter(
              displayName: 'reverse',
              required: true,
              val: false,
              info: NamedParameterInfo('reverse')),
          Parameters.enableParameter(false)
            ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
          Parameters.clipBehaviourParameter('hardEdge'),
        ], [], [
          'slivers'
        ]);

  @override
  Widget create(BuildContext context) {
    return CustomScrollView(
      scrollDirection: parameters[0].value,
      reverse: parameters[1].value,
      shrinkWrap: parameters[2].value,
      clipBehavior: parameters[3].value,
      controller: initScrollController(context),
      slivers:
          childrenMap['slivers']?.map((e) => e.build(context)).toList() ?? [],
    );
  }
}

class CSliverToBoxAdapter extends Holder {
  CSliverToBoxAdapter() : super('SliverToBoxAdapter', []) {
    autoHandleKey = false;
  }

  @override
  Widget create(BuildContext context) {
    return SliverToBoxAdapter(
      key: key(context),
      child: child?.build(context),
    );
  }
}

class CSliverAppBar extends CustomNamedHolder {
  CSliverAppBar()
      : super('SliverAppBar', [
          Parameters.colorParameter
            ..withDefaultValue(null)
            ..withRequired(false)
            ..withDisplayName('background-color')
            ..withInfo(NamedParameterInfo('backgroundColor')),
          Parameters.toolbarHeight,
          Parameters.elevationParameter()
            ..withDefaultValue(null)
            ..withRequired(false),
          Parameters.enableParameter(null)
            ..withNamedParamInfoAndSameDisplayName('centerTitle')
            ..val = null
            ..withRequired(false),
          Parameters.heightParameter()
            ..withNamedParamInfoAndSameDisplayName('collapsedHeight'),
          Parameters.heightParameter()
            ..withNamedParamInfoAndSameDisplayName('expandedHeight'),
          Parameters.enableParameter(false)
            ..withNamedParamInfoAndSameDisplayName('floating'),
          Parameters.enableParameter(false)
            ..withNamedParamInfoAndSameDisplayName('pinned'),
          Parameters.primaryParameter()
        ], [
          'title',
          'leading',
          'flexibleSpace'
        ], [
          'actions'
        ]) {
    autoHandleKey = false;
  }

  @override
  Widget create(BuildContext context) {
    return SliverAppBar(
      key: key(context),
      backgroundColor: parameters[0].value,
      toolbarHeight: parameters[1].value,
      automaticallyImplyLeading: false,
      elevation: parameters[2].value,
      centerTitle: parameters[3].value,
      collapsedHeight: parameters[4].value,
      expandedHeight: parameters[5].value,
      floating: parameters[6].value,
      pinned: parameters[7].value,
      primary: parameters[8].value,
      title: childMap['title']?.build(context),
      leading: childMap['leading']?.build(context),
      flexibleSpace: childMap['flexibleSpace']?.build(context),
      actions: childrenMap['actions']
          ?.map((e) => e.build(context))
          .toList(growable: false),
    );
  }
}

class CListViewBuilder extends BuilderComponent
    with FVBScrollable, CBoxScrollModel {
  CListViewBuilder()
      : super(
          'ListView.builder',
          [
            Parameters.itemLengthParameter,
            Parameters.axisParameter()
              ..withInfo(NamedParameterInfo('scrollDirection')),
            Parameters.paddingParameter(),
            Parameters.enableParameter(false)
              ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
            Parameters.enableParameter(false)
              ..withNamedParamInfoAndSameDisplayName('reverse'),
            Parameters.scrollPhysicsParameter
          ],
          childBuilder: [
            'itemBuilder',
          ],
          childrenBuilder: [],
          functionMap: {
            'itemBuilder': itemBuilderFunction,
          },
          config: ComponentDefaultParamConfig(
            width: true,
            height: true,
          ),
        );

  @override
  Axis get direction => parameters[1].value;

  @override
  Widget create(BuildContext context) {
    init();
    return ListView.builder(
      itemCount: parameters[0].value,
      scrollDirection: parameters[1].value,
      padding: parameters[2].value,
      shrinkWrap: parameters[3].value,
      reverse: parameters[4].value,
      physics: parameters[5].value,
      controller: initScrollController(context),
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', [context, index]);
      },
    );
  }

  @override
  List<Component> get children =>
      [if (childMap.containsKey('itemBuilder')) childMap['itemBuilder']!];
}

class CListViewSeparated extends BuilderComponent
    with FVBScrollable, CBoxScrollModel {
  CListViewSeparated()
      : super(
          'ListView.separated',
          [
            Parameters.itemLengthParameter,
            Parameters.axisParameter()
              ..withInfo(NamedParameterInfo('scrollDirection')),
            Parameters.paddingParameter(),
            Parameters.enableParameter(false)
              ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
            Parameters.scrollPhysicsParameter,
          ],
          childBuilder: ['itemBuilder', 'separatorBuilder'],
          childrenBuilder: [],
          functionMap: {
            'itemBuilder': itemBuilderFunction,
            'separatorBuilder': separatorBuilderFunction
          },
          config: ComponentDefaultParamConfig(
            width: true,
            height: true,
          ),
        ) {
    childMap['separatorBuilder'] = CDivider();
  }

  @override
  Axis get direction => parameters[1].value;

  @override
  Widget create(BuildContext context) {
    init();
    return ListView.separated(
      controller: initScrollController(context),
      scrollDirection: parameters[1].value,
      padding: parameters[2].value,
      shrinkWrap: parameters[3].value,
      physics: parameters[4].value,
      itemCount: parameters[0].value,
      separatorBuilder: (BuildContext context, int index) {
        return builder(context, 'separatorBuilder', [context, index]);
      },
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', [context, index]);
      },
    );
  }

  @override
  List<Component> get children => [
        if (childMap.containsKey('itemBuilder')) childMap['itemBuilder']!,
        if (childMap.containsKey('separatorBuilder'))
          childMap['separatorBuilder']!
      ];
}

class CGridViewBuilder extends BuilderComponent with FVBScrollable {
  CGridViewBuilder()
      : super('GridView.builder', [
          Parameters.itemLengthParameter,
          Parameters.sliverDelegate(),
          Parameters.scrollPhysicsParameter,
          Parameters.paddingParameter(),
        ], childBuilder: [
          'itemBuilder',
        ], childrenBuilder: [], functionMap: {
          'itemBuilder': itemBuilderFunction,
        });

  @override
  Widget create(BuildContext context) {
    init();
    return GridView.builder(
      controller: initScrollController(context),
      itemCount: parameters[0].value,
      gridDelegate: parameters[1].value,
      physics: parameters[2].value,
      padding: parameters[3].value,
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', [context, index]);
      },
    );
  }
}

class BinderWidget<T> extends InheritedWidget {
  final T value;

  BinderWidget(this.value, {super.key}) : super(child: const Offstage());

  @override
  bool updateShouldNotify(BinderWidget<T> oldWidget) {
    return value != oldWidget.value;
  }
}
