import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import '../common/responsive/responsive_widget.dart';
import 'parameter_rule_model.dart';
import '../code_to_component.dart';
import '../common/logger.dart';
import '../cubit/visual_box_drawer/visual_box_cubit.dart';
import 'parameter_info_model.dart';
import 'parameter_model.dart';

import '../component_list.dart';

abstract class Component {
  late List<ParameterRuleModel> paramRules;
  List<Parameter> parameters;
  final List<ComponentParameter> componentParameters = [];
  String name;
  late String id;
  bool isConstant;
  Component? parent;
  Rect? boundary;
  int? depth;

  Component(this.name, this.parameters,
      {this.isConstant = false, List<ParameterRuleModel>? rules}) {
    paramRules = rules ?? [];
    id =
        '${DateTime.now().millisecondsSinceEpoch}${Random().nextDouble().toStringAsFixed(3)}';
  }

  void addComponentParameters(
      final List<ComponentParameter> componentParameters) {
    this.componentParameters.addAll(componentParameters);
  }

  void addRule(ParameterRuleModel ruleModel) {
    paramRules.add(ruleModel);
  }

  void initComponentParameters(final BuildContext context) {
    if (!(Get.isDialogOpen ?? false)) {
      for (var element in componentParameters) {
        element.visualBoxCubit =
            BlocProvider.of<VisualBoxCubit>(context, listen: false);
      }
    }
  }

  ParameterRuleModel? validateParameters(final Parameter changedParameter) {
    if (paramRules.isEmpty) {
      return null;
    }
    for (final rule in paramRules) {
      if (rule.changedParameter == changedParameter ||
          rule.anotherParameter == changedParameter) {
        if (rule.hold()) {
          return rule;
        }
      }
    }
    return null;
  }

  void metaInfoFromCode(final String metaCode) {
    final list = metaCode.substring(1, metaCode.length - 1).split('|');
    for (final value in list) {
      if (value.isNotEmpty) {
        final fieldList = value.split('=');
        switch (fieldList[0]) {
          case 'id':
            id = fieldList[1];
            break;
        }
      }
    }
  }

  ScrollController initScrollController(BuildContext context) {
    return ScrollController()
      ..addListener(() {
        forEach((Component component) {
          component.lookForUIChanges(context);
        });
      });
  }

  static Component? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    final String name = code.substring(0, code.indexOf('(', 0));
    final Component comp;
    if (name.contains('[')) {
      final index = code.indexOf('[', 0);
      final compName = name.substring(0, index);
      if (!componentList.containsKey(compName)) {
        Fluttertoast.showToast(
            msg:
                'No widget with name $compName found, please clear cookies and reload App.');
        return null;
      }
      comp = componentList[compName]!();
      comp.metaInfoFromCode(name.substring(index));
    } else {
      if (!componentList.containsKey(name)) {
        Fluttertoast.showToast(
            msg:
                'No widget with name $name found, please clear cookies and reload App.');
        return null;
      }
      comp = componentList[name]!();
    }

    final componentCode = code.replaceFirst('$name(', '');
    final parameterCodes = CodeOperations.splitByComma(
        componentCode.substring(0, componentCode.length - 1));

    switch (comp.type) {
      case 3:
        int index = -1;
        for (int i = 0; i < parameterCodes.length; i++) {
          if (parameterCodes[i].startsWith('child:')) {
            index = i;
            break;
          }
        }
        if (index != -1) {
          final childCode = parameterCodes.removeAt(index);
          (comp as Holder).updateChild(
              Component.fromCode(childCode.replaceFirst('child:', '')));
        }
        break;
      case 2:
        int index = -1;
        for (int i = 0; i < parameterCodes.length; i++) {
          if (parameterCodes[i].startsWith('children:')) {
            index = i;
            break;
          }
        }
        if (index != -1) {
          final childCode = parameterCodes.removeAt(index);
          final code2 = childCode.replaceFirst('children:[', '');
          final List<Component> componentList = [];
          final List<String> childrenCodes =
              CodeOperations.splitByComma(code2.substring(0, code2.length - 1));
          for (final childCode in childrenCodes) {
            componentList.add(Component.fromCode(childCode)!..setParent(comp));
          }
          (comp as MultiHolder).children = componentList;
        }
        break;
      case 4:
        final List<String> nameList =
            (comp as CustomNamedHolder).childMap.keys.toList();
        final removeList = [];
        for (int i = 0; i < parameterCodes.length; i++) {
          final colonIndex = parameterCodes[i].indexOf(':');
          final name = parameterCodes[i].substring(0, colonIndex);
          if (nameList.contains(name)) {
            comp.childMap[name] =
                Component.fromCode(parameterCodes[i].substring(colonIndex + 1))!
                  ..setParent(comp);
            nameList.remove(name);
            removeList.add(parameterCodes[i]);
          }
        }
        for (int i = 0; i < removeList.length; i++) {
          parameterCodes.remove(removeList[i]);
        }
        break;
      case 1:
        break;
    }
    for (int i = 0; i < comp.parameters.length; i++) {
      final Parameter parameter = comp.parameters[i];
      if (parameter.info is NamedParameterInfo ||
          (parameter.info is InnerObjectParameterInfo &&
              (parameter.info as InnerObjectParameterInfo).namedIfHaveAny !=
                  null)) {
        final paramPrefix =
            '${parameter.info is NamedParameterInfo ? (parameter.info as NamedParameterInfo).name : (parameter.info as InnerObjectParameterInfo).namedIfHaveAny!}:';
        for (final paramCode in parameterCodes) {
          if (paramCode.startsWith(paramPrefix)) {
            parameter.fromCode(paramCode);
            parameterCodes.remove(paramCode);

            break;
          }
        }
      } else {
        parameter.fromCode(parameterCodes[i]);
      }
    }
    return comp;
  }

  Widget build(BuildContext context) {
    if (!ResponsiveWidget.isSmallScreen(context)) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        lookForUIChanges(context);
      });
    }

    return ComponentWidget(
      key: GlobalObjectKey(this),
      child: create(context),
    );
  }

  void forEach(final void Function(Component) work) async {
    work.call(this);
    forEachInComponentParameter(work);
  }

  void forEachInComponentParameter(final void Function(Component) work) {
    for (final ComponentParameter componentParameter in componentParameters) {
      for (final component in componentParameter.components) {
        work.call(component);
      }
    }
  }

  Component getLastRoot() {
    Component? tracer = this;
    while (tracer!.parent != null) {
      logger('======= TRACER FIND ROOT ${tracer.parent?.name}');
      tracer = tracer.parent;
    }
    return tracer;
  }

  Component? getCustomComponentRoot() {
    Component? _tracer = this, _root = this;
    final List<Component> tree = [];
    while (_tracer != null && _tracer is! CustomComponent) {
      logger('======= TRACER FIND CUSTOM ROOT ${_tracer.parent?.name}');
      tree.add(_tracer);
      _root = _tracer;
      _tracer = _tracer.parent;
    }
    final reversedTree = tree.toList();
    for (int i = 1; i < reversedTree.length; i++) {
      final comp = reversedTree[i];
      if (comp is Holder &&
          comp.child is CustomComponent &&
          (comp.child as CustomComponent).root == reversedTree[i - 1]) {
        logger('======= TRACER FIND CUSTOM ROOT ${comp.child?.name}');
        return comp.child;
      } else if (comp is MultiHolder) {
        for (final childComp in comp.children) {
          if (childComp is CustomComponent &&
              childComp.root == reversedTree[i - 1]) {
            logger('======= TRACER FIND CUSTOM ROOT ${childComp.name}');
            return childComp;
          }
        }
      } else if (comp is CustomNamedHolder) {
        for (final childComp in comp.childMap.values) {
          if (childComp is CustomComponent &&
              childComp.root == reversedTree[i - 1]) {
            logger('======= TRACER FIND CUSTOM ROOT ${childComp.name}');
            return childComp;
          }
        }
      }
    }
    return _root;
  }

  Component? getLastCustomComponentRoot() {
    Component? _tracer = this, _root = this;
    final List<Component> tree = [];
    while (_tracer != null && _tracer is! CustomComponent) {
      logger('======= TRACER FIND CUSTOM ROOT ${_tracer.parent?.name}');
      tree.add(_tracer);
      _root = _tracer;
      _tracer = _tracer.parent;
    }
    final reversedTree = tree.reversed.toList();
    for (int i = 0; i < reversedTree.length - 1; i++) {
      final comp = reversedTree[i];
      if (comp is Holder &&
          comp.child is CustomComponent &&
          (comp.child as CustomComponent).root == reversedTree[i + 1]) {
        logger('======= TRACER FIND CUSTOM ROOT ${comp.child?.name}');
        return comp.child;
      } else if (comp is MultiHolder) {
        for (final childComp in comp.children) {
          if (childComp is CustomComponent &&
              childComp.root == reversedTree[i + 1]) {
            logger('======= TRACER FIND CUSTOM ROOT ${childComp.name}');
            return childComp;
          }
        }
      } else if (comp is CustomNamedHolder) {
        for (final childComp in comp.childMap.values) {
          if (childComp is CustomComponent &&
              childComp.root == reversedTree[i + 1]) {
            logger('======= TRACER FIND CUSTOM ROOT ${childComp.name}');
            return childComp;
          }
        }
      }
    }
    return _root;
  }

  void lookForUIChanges(BuildContext context) async {
    if (Get.isDialogOpen ?? false) {
      return;
    }
    final RenderBox renderBox =
        GlobalObjectKey(this).currentContext!.findRenderObject() as RenderBox;
    final ancestorRenderBox = const GlobalObjectKey('device window')
        .currentContext!
        .findRenderObject();
    Offset position =
        renderBox.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);
    int sameCount = 0;
    while (sameCount < 5) {
      if ((boundary?.left ?? position.dx) - position.dx < 0.5 &&
          (boundary?.top ?? position.dy) - position.dy < 0.5 &&
          (boundary?.width ?? renderBox.size.width) - renderBox.size.width <
              0.5 &&
          (boundary?.height ?? renderBox.size.height) - renderBox.size.height <
              0.5) {
        sameCount++;
      }
      boundary = Rect.fromLTWH(position.dx, position.dy, renderBox.size.width,
          renderBox.size.height);
      depth = renderBox.depth;
      BlocProvider.of<VisualBoxCubit>(context, listen: false).visualUpdated();
      logger(
          '======== COMPONENT VISUAL BOX CHANGED  ${boundary?.width} ${renderBox.size.width} ${boundary?.height} ${renderBox.size.height}');
      await Future.delayed(const Duration(milliseconds: 50));
      position =
          renderBox.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);
    }
  }

  Widget create(BuildContext context);

  String code({bool clean = true}) {
    String middle = '';
    for (final parameter in parameters) {
      final paramCode = parameter.code(clean);
      if (paramCode.isNotEmpty) {
        middle += '$paramCode,'.replaceAll(',,', ',');
        if (clean) {
          middle += '\n';
        }
      }
    }

    String name = this.name;
    if (!clean) {
      name += '[id=$id]';
    }
    if (middle.trim().isEmpty) {
      return '$name()';
    }
    return '$name(\n$middle)';
  }

  void searchTappedComponent(Offset offset, List<Component> components) {
    if (boundary?.contains(offset) ?? false) {
      for (final compParam in componentParameters) {
        for (final comp in compParam.components) {
          comp.searchTappedComponent(offset, components);
        }
      }
      components.add(this);
      return;
    }
  }

  void setParent(Component? component) {
    parent = component;
  }

  Component clone(Component? parent, {bool cloneParam = false}) {
    final comp = componentList[name]!();
    if (cloneParam) {
      for (int i = 0; i < parameters.length; i++) {
        comp.parameters[i].cloneOf(parameters[i]);
      }
    } else {
      comp.parameters = parameters;
    }
    comp.parent = parent;
    return comp;
  }

  int get type => 1;

  int get childCount => 0;
}

abstract class MultiHolder extends Component {
  List<Component> children = [];

  MultiHolder(String name, List<Parameter> parameters,
      {List<ParameterRuleModel>? rules})
      : super(name, parameters, rules: rules);

  @override
  String code({bool clean = true}) {
    String middle = '';
    for (final para in parameters) {
      final paramCode = para.code(clean);
      if (paramCode.isNotEmpty) {
        middle += '$paramCode,'.replaceAll(',,', ',');
        if (clean) {
          middle += '\n';
        }
      }
    }

    String name = this.name;
    if (!clean) {
      name += '[id=$id]';
    }
    String childrenCode = '';
    for (final Component comp in children) {
      childrenCode += '${comp.code(clean: clean)},'.replaceAll(',,', ',');
    }
    return '$name(\n${middle}children:[\n$childrenCode\n],\n)';
  }

  @override
  void forEach(void Function(Component) work) {
    work.call(this);
    for (final child in children) {
      child.forEach(work);
    }

    forEachInComponentParameter(work);
  }

  void addChild(Component component, {int? index}) {
    if (index == null) {
      children.add(component);
    } else {
      children.insert(index, component);
    }
    component.setParent(this);
    if (component is CustomComponent) {
      component.root?.parent = this;
    }
  }

  int removeChild(Component component) {
    final index = children.indexOf(component);
    component.setParent(null);
    children.removeAt(index);
    return index;
  }

  void replaceChild(Component old, Component component) {
    component.setParent(this);
    final index = children.indexOf(old);
    children.removeAt(index);
    children.insert(index, component);
    if (component is CustomComponent) {
      component.root?.parent = this;
    }
  }

  @override
  void searchTappedComponent(Offset offset, List<Component> components) {
    if (boundary?.contains(offset) ?? false) {
      for (final child in children) {
        child.searchTappedComponent(offset, components);
      }
      for (final compParam in componentParameters) {
        for (final comp in compParam.components) {
          comp.searchTappedComponent(offset, components);
        }
      }
      components.add(this);
    }
  }

  void addChildren(List<Component> components) {
    children.addAll(components);
    for (final comp in components) {
      comp.setParent(this);
    }
  }

  @override
  Component clone(Component? parent, {bool cloneParam = false}) {
    final comp = componentList[name]!() as MultiHolder;
    if (cloneParam) {
      for (int i = 0; i < parameters.length; i++) {
        comp.parameters[i].cloneOf(parameters[i]);
      }
    } else {
      comp.parameters = parameters;
    }
    comp.parent = parent;
    comp.children =
        children.map((e) => e.clone(comp, cloneParam: cloneParam)).toList();
    return comp;
  }

  @override
  int get type => 2;

  @override
  int get childCount => -1;
}

abstract class Holder extends Component {
  Component? child;
  bool required;

  Holder(String name, List<Parameter> parameters,
      {this.required = false, List<ParameterRuleModel>? rules})
      : super(name, parameters, rules: rules);

  void updateChild(Component? child) {
    this.child?.setParent(null);
    this.child = child;
    if (child != null) {
      child.setParent(this);
    }
  }

  void addComponent(Component? component) {
    child = component;
    component?.setParent(child);
  }

  @override
  void forEach(void Function(Component) work) {
    work.call(this);
    if (child != null) {
      child!.forEach(work);
    }

    forEachInComponentParameter(work);
  }

  @override
  void searchTappedComponent(Offset offset, List<Component> components) {
    if (boundary?.contains(offset) ?? false) {
      child?.searchTappedComponent(offset, components);
      for (final compParam in componentParameters) {
        for (final comp in compParam.components) {
          comp.searchTappedComponent(offset, components);
        }
      }
      components.add(this);
    }
  }

  @override
  String code({bool clean = true}) {
    String middle = '';
    for (final para in parameters) {
      final paramCode = para.code(clean);
      if (paramCode.isNotEmpty) {
        final paramCode = para.code(clean);
        if (paramCode.isNotEmpty) {
          middle += '$paramCode,'.replaceAll(',,', ',');
          if (clean) {
            middle += '\n';
          }
        }
      }
    }
    String name = this.name;
    if (!clean) {
      name += '[id=$id]';
    }
    if (child == null) {
      if (!required) {
        return '$name(\n$middle\n),';
      } else {
        return '$name(\n${middle}child:Container(),\n)';
      }
    }
    return '$name(\n${middle}child:${child!.code(clean: clean)}\n)';
  }

  @override
  Component clone(Component? parent, {bool cloneParam = false}) {
    final comp = componentList[name]!() as Holder;
    if (cloneParam) {
      for (int i = 0; i < parameters.length; i++) {
        comp.parameters[i].cloneOf(parameters[i]);
      }
    } else {
      comp.parameters = parameters;
    }
    comp.parent = parent;
    comp.child = child?.clone(comp, cloneParam: cloneParam);
    return comp;
  }

  @override
  int get type => 3;

  @override
  int get childCount => 1;
}

abstract class CustomNamedHolder extends Component {
  Map<String, Component?> childMap = {};
  Map<String, List<Component>> childrenMap = {};

  late Map<String, List<String>?> selectable;

  CustomNamedHolder(String name, List<Parameter> parameters, this.selectable,
      List<String> childrenMap,
      {List<ParameterRuleModel>? rules})
      : super(name, parameters, rules: rules) {
    for (final child in selectable.keys) {
      childMap[child] = null;
    }
    for (final children in childrenMap) {
      this.childrenMap[children] = [];
    }
  }

  void updateChildWithKey(String key, Component? component) {
    childMap[key]?.setParent(null);
    childMap[key] = component;
    component?.setParent(this);
  }

  void updateChild(Component? oldComponent, Component? component) {
    oldComponent?.setParent(null);
    component?.setParent(this);
    for (final entry in childMap.entries) {
      if (entry.value == oldComponent) {
        childMap[entry.key] = component;
        return;
      }
    }
  }

  @override
  void forEach(void Function(Component) work) {
    work.call(this);
    for (final child in childMap.values) {
      if (child != null) {
        child.forEach(work);
      }
    }
    for (final children in childrenMap.values) {
      for (final child in children) {
        child.forEach(work);
      }
    }

    forEachInComponentParameter(work);
  }

  @override
  void searchTappedComponent(Offset offset, List<Component> components) {
    if (boundary?.contains(offset) ?? false) {
      for (final child in childMap.values) {
        if (child == null) {
          continue;
        }
        child.searchTappedComponent(offset, components);
      }
      components.add(this);
      return;
    }
  }

  @override
  String code({bool clean = true}) {
    String middle = '';
    for (final para in parameters) {
      final paramCode = para.code(clean);
      if (paramCode.isNotEmpty) {
        final paramCode = para.code(clean);
        if (paramCode.isNotEmpty) {
          middle += '$paramCode,'.replaceAll(',,', ',');
          if (clean) {
            middle += '\n';
          }
        }
      }
    }
    String name = this.name;
    if (!clean) {
      name += '[id=$id]';
    }
    String childrenCode = '';
    for (final child in childMap.keys) {
      if (childMap[child] != null) {
        childrenCode += '$child:${childMap[child]!.code(clean: clean)},'
            .replaceAll(',,', ',');
      }
    }
    return '$name(\n$middle$childrenCode\n)';
  }

  @override
  Component clone(Component? parent, {bool cloneParam = false}) {
    final comp = componentList[name]!() as CustomNamedHolder;
    if (cloneParam) {
      for (int i = 0; i < parameters.length; i++) {
        comp.parameters[i].cloneOf(parameters[i]);
      }
    } else {
      comp.parameters = parameters;
    }
    comp.parent = parent;
    comp.childMap = childMap.map((key, value) =>
        MapEntry(key, value?.clone(comp, cloneParam: cloneParam)));
    comp.childrenMap = childrenMap.map((key, value) => MapEntry(
        key, value.map((e) => e.clone(comp, cloneParam: cloneParam)).toList()));
    return comp;
  }

  @override
  int get type => 4;

  String? replaceChild(Component oldComp, Component? comp) {
    late final String? compKey;
    for (final String key in childMap.keys) {
      if (childMap[key] == oldComp) {
        compKey = key;
        break;
      }
    }
    if (compKey != null) {
      childMap[compKey] = comp;
      comp?.setParent(this);
      return compKey;
    }
  }

  @override
  int get childCount => -2;
}

abstract class CustomComponent extends Component {
  String? extensionName;
  Component? root;
  CustomComponent? cloneOf;
  List<CustomComponent> objects = [];

  CustomComponent(
      {required this.extensionName, required String name, this.root})
      : super(name, []);

  CustomComponent get getRootClone {
    CustomComponent? rootClone = cloneOf;
    while (rootClone!.cloneOf != null) {
      rootClone = rootClone.cloneOf;
    }
    return rootClone;
  }

  @override
  Widget create(BuildContext context) {
    return root?.build(context) ?? Container();
  }

  void updateRoot(Component? root) {
    this.root?.setParent(null);
    this.root = root;
  }

  @override
  void forEach(void Function(Component) work) {
    work.call(this);
    if (root != null) {
      root!.forEach(work);
    }

    forEachInComponentParameter(work);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      lookForUIChanges(context);
    });
    return ComponentWidget(key: GlobalObjectKey(this), child: create(context));
  }

  @override
  void searchTappedComponent(Offset offset, List<Component> components) {
    if (root?.boundary?.contains(offset) ?? false) {
      root?.searchTappedComponent(offset, components);
      components.add(this);
    }
  }

  void notifyChanged() {
    for (int i = 0; i < objects.length; i++) {
      final oldObject = objects[i];
      objects[i] = clone(objects[i].parent) as CustomComponent;
      replaceChildOfParent(oldObject, objects[i]);
      final tracer = objects[i].getLastRoot();
      if (tracer is CustomComponent) {
        tracer.notifyChanged();
      }
    }
  }

  void replaceChildOfParent(Component comOld, Component comp) {
    switch (comOld.parent?.type) {
      case 2:
        //MultiHolder
        (comOld.parent as MultiHolder).replaceChild(comOld, comp);
        break;
      case 3:
        //Holder
        (comOld.parent as Holder).updateChild(comp);
        break;
      case 4:
        //CustomNamedHolder
        (comOld.parent as CustomNamedHolder).replaceChild(comOld, comp);
        break;
      case 5:
        (comOld.parent as CustomComponent).root = comp;
    }
  }

  String implementationCode();

  @override
  int get type => 5;

  @override
  int get childCount => 0;

  @override
  Component clone(Component? parent, {bool cloneParam = false}) {
    final comp2 = StatelessComponent(
      name: name,
    );
    comp2.name = name;
    if (cloneParam) {
      for (int i = 0; i < parameters.length; i++) {
        comp2.parameters[i].cloneOf(parameters[i]);
      }
    } else {
      comp2.parameters = parameters;
    }
    comp2.root = root?.clone(parent, cloneParam: cloneParam);
    comp2.cloneOf = this;

    return comp2;
  }

  CustomComponent createInstance(Component? root) {
    final compCopy = clone(root) as CustomComponent;
    objects.add(compCopy);

    return compCopy;
  }

  static Component findSameLevelComponent(
      CustomComponent copy, CustomComponent original, Component object) {
    Component? tracer = object;
    final List<List<Parameter>> paramList = [];
    logger('=== FIND FIRST LEVEL');
    while (tracer != original.root?.parent) {
      logger('TRACER ${tracer?.name}');
      paramList.add(tracer!.parameters);
      tracer = tracer.parent;
    }
    tracer = copy;
    for (final param in paramList.reversed) {
      logger('TRACER2 ${tracer?.name}');
      tracer = findChildWithParam(tracer!, param);
    }
    return tracer!;
  }

  static Component? findChildWithParam(
      final Component component, final List<Parameter> params) {
    switch (component.type) {
      case 3:
        return (component as Holder).child!;
      case 2:
        return (component as MultiHolder)
            .children
            .firstWhere((element) => element.parameters == params);
      case 4:
        return (component as CustomNamedHolder).childMap.values.firstWhere(
            (element) => element != null && element.parameters == params);
      case 5:
        return (component as CustomComponent).root;
    }
    return null;
  }
}

class StatelessComponent extends CustomComponent {
  StatelessComponent({required String name, Component? root})
      : super(extensionName: 'StatelessWidget', name: name, root: root) {
    if (root != null) {
      root.setParent(this);
    }
  }

  @override
  String implementationCode() {
    if (root == null) {
      return '';
    }
    return '''class $name extends StatelessWidget {
          const $name({Key? key}) : super(key: key);
        
          @override
          Widget build(BuildContext context) {
          return ${root!.code()};
          }
         }
    ''';
  }
}

class ComponentWidget extends StatelessWidget {
  final Widget child;

  const ComponentWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
