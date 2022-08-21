import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/compiler/code_processor.dart';
import '../common/compiler/processor_component.dart';
import '../common/converter/code_converter.dart';
import 'variable_model.dart';
import 'package:get/get.dart';
import '../bloc/state_management/state_management_bloc.dart';
import '../common/common_methods.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../runtime_provider.dart';
import 'actions/action_model.dart';
import 'builder_component.dart';
import 'parameter_rule_model.dart';
import '../code_to_component.dart';
import '../common/logger.dart';
import '../cubit/visual_box_drawer/visual_box_cubit.dart';
import 'parameter_info_model.dart';
import 'parameter_model.dart';

import '../component_list.dart';
import 'project_model.dart';

mixin operations {
  void addChildOperation(Component component, {String? attributeName});

  bool canAddChild({String? attributeName});

  bool canRemoveChild({String? attributeName});

  void removeChildOperation(Component component, {String? attributeName});

  int getChildCount({String? attributeName});

  void replaceChildOperation(Component component, {String? attributeName});
}

final setStateFunction = FVBFunction(
    'setState', null, [FVBArgument('callback', dataType: DataType.fvbFunction)],
    dartCall: (_, instance) {});

final Map<String, Component> componentMap = {};

class ComponentController extends ChangeNotifier {
  void update() {
    notifyListeners();
  }
}

final Map<String, CodeProcessor> processorWithComp = {};
final List<String> refresherUsed = [];
final Map<String,bool> importFiles={};

abstract class Component {
  static final Random random = Random.secure();
  late List<ParameterRuleModel> paramRules;
  List<Parameter> parameters;
  final List<ComponentParameter> componentParameters = [];
  String name;
  String? _id;
  late final String uniqueId;
  bool isConstant;
  Component? parent;
  Component? cloneOf;
  final List<Component> cloneElements = [];
  Rect? boundary;
  int? depth;

  Component(this.name, this.parameters,
      {this.isConstant = false, List<ParameterRuleModel>? rules}) {
    paramRules = rules ?? [];
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    uniqueId = name +
        time.substring(time.length - 10, time.length) +
        random.nextInt(100).toString();
  }

  set setId(final String id) {
    if (_id != null) {
      componentMap.remove(_id);
    }
    _id = id;
    componentMap[id] = this;
  }

  String get id {
    if (_id != null) {
      return _id!;
    }
    setId = '$uniqueId${Random().nextDouble().toStringAsFixed(3)}';
    return _id!;
  }

  void onFreshAdded() {
    if (this is Clickable) {
      (this as Clickable)
          .actionList
          .add(CustomAction(code: (this as Clickable).defaultCode));
    }
  }

  void addComponentParameters(
      final List<ComponentParameter> componentParameters) {
    this.componentParameters.addAll(componentParameters);
  }

  void addRule(ParameterRuleModel ruleModel) {
    paramRules.add(ruleModel);
  }

  String withState(String code, bool clean) {
    if (clean && refresherUsed.contains(id)) {
      return 'Refresher("$id",()=>$code)';
    }
    return code;
  }

  void initComponentParameters(final BuildContext context) {
    if (RuntimeProvider.of(context) == RuntimeMode.edit) {
      for (final element in componentParameters) {
        element.visualBoxCubit = context.read<VisualBoxCubit>();
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

  String metaCode(String string) {
    string += '[id=$id';
    if (this is BuilderComponent) {
      string +=
          '|model=${(this as BuilderComponent).model?.name}|len=${(this as BuilderComponent).itemLengthParameter.code(false)}';
    }
    if (this is Clickable) {
      string +=
          '|action={${(this as Clickable).actionList.map((e) => e.metaCode()).join(':')}}';
    }
    string += ']';
    return string;
  }

  void metaInfoFromCode(
      final String metaCode, final FlutterProject? flutterProject) {
    final list = CodeOperations.splitBy(
        metaCode.substring(1, metaCode.length - 1),
        splitBy: '|');
    for (final value in list) {
      if (value.isNotEmpty) {
        final equalIndex = value.indexOf('=');
        final fieldList = [
          value.substring(0, equalIndex),
          value.substring(equalIndex + 1)
        ];
        switch (fieldList[0]) {
          case 'id':
            setId = fieldList[1];
            break;
          case 'model':
            (this as BuilderComponent).model = flutterProject
                ?.currentScreen.models
                .firstWhereOrNull((element) => element.name == fieldList[1]);
            logger('model setted ${(this as BuilderComponent).model?.name}');
            break;
          case 'len':
            (this as BuilderComponent)
                .itemLengthParameter
                .fromCode(fieldList[1]);
            break;
          case 'action':
            if (this is Clickable) {
              final list = fieldList[1].substring(1, fieldList[1].length - 1);
              if (list.isNotEmpty) {
                if (list.contains(':')) {
                  list.split(':').forEach((e) => (this as Clickable)
                      .fromMetaCodeToAction(e, flutterProject));
                } else {
                  (this as Clickable)
                      .fromMetaCodeToAction(list, flutterProject);
                }
              }
            }
            break;
        }
      }
    }
  }

  static Component? fromCode(
      String? code, final FlutterProject flutterProject) {
    if (code == null || code.isEmpty) {
      return null;
    }
    final String name = code.substring(0, code.indexOf('(', 0));
    final Component comp;
    if (name.contains('[')) {
      final index = code.indexOf('[', 0);
      final compName = name.substring(0, index);
      comp = _getComponentFromName(compName, code, flutterProject);
      comp.metaInfoFromCode(name.substring(index), flutterProject);
    } else {
      comp = _getComponentFromName(name, code, flutterProject);
    }

    final componentCode = code.replaceFirst('$name(', '');
    final parameterCodes = CodeOperations.splitBy(
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
          (comp as Holder).updateChild(Component.fromCode(
              childCode.replaceFirst('child:', ''), flutterProject));
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
              CodeOperations.splitBy(code2.substring(0, code2.length - 1));
          for (final childCode in childrenCodes) {
            componentList.add(Component.fromCode(childCode, flutterProject)!
              ..setParent(comp));
          }
          (comp as MultiHolder).children = componentList;
        }
        break;
      case 4:
        if (comp is BuilderComponent) {
          final List<String> nameList = comp.childMap.keys.toList();
          final List<String> childrenNameList = comp.childrenMap.keys.toList();

          final List<String> removeList = [];
          for (int i = 0; i < parameterCodes.length; i++) {
            final colonIndex = parameterCodes[i].indexOf(':');
            logger(parameterCodes[i]);
            final name = parameterCodes[i].substring(0, colonIndex);
            if (nameList.contains(name)) {
              final builderCode = parameterCodes[i].substring(colonIndex + 1);
              final returnIndex = builderCode.lastIndexOf('return');
              comp.childMap[name] = Component.fromCode(
                  builderCode.substring(
                      returnIndex + 6, builderCode.lastIndexOf(';')),
                  flutterProject)
                ?..setParent(comp);
              final startIndex = builderCode.indexOf('`');
              final endIndex = builderCode.lastIndexOf('`', returnIndex);
              if (startIndex >= 0 &&
                  startIndex < returnIndex &&
                  endIndex >= 0) {
                comp.functionMap[name]!.code =
                    builderCode.substring(startIndex + 1, endIndex);
              } else {
                comp.functionMap[name]!.code = '';
              }
              nameList.remove(name);
              removeList.add(parameterCodes[i]);
            } else if (childrenNameList.contains(name)) {
              final childrenCode = CodeOperations.splitBy(parameterCodes[i]
                  .substring(colonIndex + 2, parameterCodes[i].length - 1));
              comp.childrenMap[name]!.addAll(
                childrenCode.map(
                  (e) =>
                      Component.fromCode(e, flutterProject)!..setParent(comp),
                ),
              );
              removeList.add(parameterCodes[i]);
            }
          }
          for (int i = 0; i < removeList.length; i++) {
            parameterCodes.remove(removeList[i]);
          }
          break;
        } else {
          final List<String> nameList =
              (comp as CustomNamedHolder).childMap.keys.toList();
          final List<String> childrenNameList = comp.childrenMap.keys.toList();

          final removeList = [];
          for (int i = 0; i < parameterCodes.length; i++) {
            final colonIndex = parameterCodes[i].indexOf(':');
            logger(parameterCodes[i]);
            final name = parameterCodes[i].substring(0, colonIndex);
            if (nameList.contains(name)) {
              comp.childMap[name] = Component.fromCode(
                  parameterCodes[i].substring(colonIndex + 1), flutterProject)!
                ..setParent(comp);
              nameList.remove(name);
              removeList.add(parameterCodes[i]);
            } else if (childrenNameList.contains(name)) {
              final childrenCode = CodeOperations.splitBy(parameterCodes[i]
                  .substring(colonIndex + 2, parameterCodes[i].length - 1));
              comp.childrenMap[name]!.addAll(
                childrenCode.map(
                  (e) =>
                      Component.fromCode(e, flutterProject)!..setParent(comp),
                ),
              );
              removeList.add(parameterCodes[i]);
            }
          }
          for (int i = 0; i < removeList.length; i++) {
            parameterCodes.remove(removeList[i]);
          }
        }
        break;

      case 5:
        for (int i = 0; i < parameterCodes.length; i++) {
          final colonIndex = parameterCodes[i].indexOf(':');
          (comp as CustomComponent)
                  .arguments[parameterCodes[i].substring(0, colonIndex)] =
              parameterCodes[i]
                  .substring(colonIndex + 2, parameterCodes[i].length - 1);
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

  static Component _getComponentFromName(final String compName,
      final String code, final FlutterProject flutterProject) {
    if (!componentList.containsKey(compName)) {
      logger('NOT FOUND $compName');
      final custom = flutterProject.customComponents
          .firstWhereOrNull((element) => element.name == compName);
      if (custom != null) {
        return custom.createInstance(null);
      } else {
        return CNotRecognizedWidget()..name = compName;
      }
    }
    return componentList[compName]!();
  }

  Widget build(BuildContext context) {
    final mode = RuntimeProvider.of(context);
    if (mode == RuntimeMode.favorite) {
      return ComponentWidget(
        child: create(context),
      );
    } else if (mode == RuntimeMode.edit) {
      processorWithComp[id] = ProcessorProvider.maybeOf(context)!;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        lookForUIChanges(context);
      });
    } else if (RuntimeProvider.of(context) == RuntimeMode.run) {
      return BlocBuilder<StateManagementBloc, StateManagementState>(
        key: key(context),
        buildWhen: (previous, current) => current.id == id,
        builder: (context, state) {
          ComponentOperationCubit.processor =
              ProcessorProvider.maybeOf(context)!;
          ComponentOperationCubit.componentId=id;
          if (this is Clickable) {
            (this as Clickable).test();
          }
          return ComponentWidget(
            child: create(context),
          );
        },
      );
    }
    ComponentOperationCubit.processor = ProcessorProvider.maybeOf(context)!;
    ComponentOperationCubit.componentId=id;
    if (this is Clickable) {
      (this as Clickable).test();
    }
    return ComponentWidget(
      key: key(context),
      child: create(context),
    );
  }

  Widget buildWithoutKey(BuildContext context) {
    if (RuntimeProvider.of(context) == RuntimeMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        lookForUIChanges(context);
      });
    }

    return create(context);
  }

  void forEach(final void Function(Component) work) async {
    work.call(this);
    forEachInComponentParameter(work);
  }

  key(BuildContext context) {
    switch (RuntimeProvider.of(context)) {
      case RuntimeMode.edit:
        return GlobalObjectKey(this);
      case RuntimeMode.viewOnly:
        return GlobalObjectKey(uniqueId + id);
      case RuntimeMode.run:
        return null;
      case RuntimeMode.preview:
        return GlobalObjectKey(uniqueId + id);
    }
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

  Component? getRootCustomComponent(FlutterProject flutterProject) {
    Component? _tracer = this, _root = this;
    while (_tracer != null && _tracer is! CustomComponent) {
      logger('======= TRACER FIND CUSTOM ROOT ${_tracer.parent?.name}');
      _root = _tracer;
      _tracer = _tracer.parent;
    }

    for (final custom in flutterProject.customComponents) {
      if (custom.root == _root) {
        return custom;
      }
    }
    return flutterProject.rootComponent;
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

  void lookForUIChanges(BuildContext context,
      {bool checkSameCount = true}) async {
    if (GlobalObjectKey(this).currentContext == null) {
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
    while (sameCount < (checkSameCount ? 5 : 1)) {
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
      BlocProvider.of<VisualBoxCubit>(context).visualUpdated();
      logger(
          '======== COMPONENT VISUAL BOX CHANGED  ${boundary?.width} ${renderBox.size.width} ${boundary?.height} ${renderBox.size.height}');
      await Future.delayed(const Duration(milliseconds: 50));
      if (renderBox.attached) {
        position =
            renderBox.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);
      } else {
        break;
      }
    }
  }

  Widget create(BuildContext context);

  String parametersCode(bool clean) {
    String middle = '';
    if (clean && (this is Controller)) {
      middle = 'key:GlobalObjectKey("$id"),';
    }
    if (this is Clickable && clean) {
      final code1 = (this as Clickable)
              .actionList
              .firstWhereOrNull((element) => element is CustomAction)
              ?.arguments[0]
              ?.toString() ??
          '';
      if (code1.isNotEmpty) {
        int start = 0;
        for (final function in (this as Clickable).functions) {
          if (start > code1.length - 1) {
            break;
          }
          final openIndex = code1.indexOf('{', start);
          if (openIndex == -1) {
            break;
          }
          final closeIndex = CodeOperations.findCloseBracket(code1, openIndex,
              CodeProcessor.curlyBracketOpen, CodeProcessor.curlyBracketClose);
          start += closeIndex + 1;
          final functionBody = code1.substring(openIndex + 1, closeIndex);
          middle +=
              '${function.name}:${function.getCleanInstanceCode(functionBody)},';
        }
      } else if ((this as Clickable).functions.isNotEmpty) {
        final function = (this as Clickable).functions.first;
        middle +=
            '${function.name}:${function.getCleanInstanceCode((this as Clickable).actionList.map((e) => '${e.code()};').join(' '))},';
      }
    }
    for (final parameter in parameters) {
      final paramCode = parameter.code(clean);
      if (paramCode.isNotEmpty) {
        middle += '$paramCode,'.replaceAll(',,', ',');
      }
    }
    if (clean) {
      int start = 0;
      int gotIndex = -1;
      while (start < middle.length) {
        if (gotIndex == -1) {
          start = middle.indexOf('{{', start);
          if (start == -1) {
            break;
          }
          start += 2;
          gotIndex = start;
        } else {
          start = middle.indexOf('}}', start);
          if (start == -1) {
            break;
          }
          String innerArea = middle.substring(gotIndex, start);
          if (ComponentOperationCubit.processor.variables.isNotEmpty) {
            // for (final variable in ComponentOperationCubit.codeProcessor.variables.values) {
            //   innerArea = innerArea.replaceAll(variable.name,
            //       '${variable!}[index].${variable.name}');
            // }
            middle =
                middle.replaceRange(gotIndex - 2, start + 2, '\${$innerArea}');
            gotIndex = -1;
            start += 2;
            continue;
          }
        }
      }
    }
    return middle;
  }

  String code({bool clean = true}) {
    final middle = parametersCode(clean);
    String name = this.name;
    if (!clean) {
      name = metaCode(name);
    }
    return withState('$name(\n$middle)', clean);
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

  Component clone(Component? parent, {bool deepClone = false}) {
    final comp = componentList[name]!();
    if (comp is Clickable) {
      if (deepClone) {
        (comp as Clickable).actionList =
            (this as Clickable).actionList.map((e) => e.clone()).toList();
      } else {
        (comp as Clickable).actionList = (this as Clickable).actionList;
      }
    }
    if (deepClone) {
      for (int i = 0; i < parameters.length; i++) {
        comp.parameters[i].cloneOf(parameters[i]);
      }
    } else {
      comp.parameters = parameters;
    }
    if (!deepClone) {
      comp._id = id;
    }
    if (!deepClone) {
      comp.cloneOf = this;
      cloneElements.add(comp);
    }
    comp.parent = parent;
    return comp;
  }

  int get type => 1;

  int get childCount => 0;

  List<Component> getAllClones() {
    final List<Component> clones = [];
    for (final clone in cloneElements) {
      clones.add(clone);
      clones.addAll(clone.getAllClones());
    }
    return clones;
  }

  Component? getOriginal() {
    if (cloneOf?.cloneOf != null) {
      return cloneOf?.getOriginal();
    }
    return cloneOf;
  }
}

abstract class MultiHolder extends Component {
  List<Component> children = [];

  MultiHolder(String name, List<Parameter> parameters,
      {List<ParameterRuleModel>? rules})
      : super(name, parameters, rules: rules);

  @override
  String code({bool clean = true}) {
    final middle = parametersCode(clean);

    String name = this.name;
    if (!clean) {
      name += '[id=$id]';
    }
    String childrenCode = '';
    for (final Component comp in children) {
      childrenCode += '${comp.code(clean: clean)},'.replaceAll(',,', ',');
    }
    return withState('$name(${middle}children:[\n$childrenCode],)', clean);
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

  void addChildren(List<Component> components, {int? index}) {
    if (index != null) {
      children.insertAll(index, components);
    } else {
      children.addAll(components);
    }
    for (final comp in components) {
      comp.setParent(this);
    }
  }

  @override
  Component clone(Component? parent, {bool deepClone = false}) {
    final comp = super.clone(parent, deepClone: deepClone) as MultiHolder;
    comp.children =
        children.map((e) => e.clone(comp, deepClone: deepClone)).toList();
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
  void searchTappedComponent(
      final Offset offset, final List<Component> components) {
    if (boundary?.contains(offset) ?? false) {
      child?.searchTappedComponent(offset, components);
      for (final compParam in componentParameters) {
        for (final comp in compParam.components) {
          final len = components.length;
          comp.searchTappedComponent(offset, components);
          if (len != components.length) {
            break;
          }
        }
      }
      components.add(this);
    }
  }

  @override
  String code({bool clean = true}) {
    final middle = parametersCode(clean);
    String name = this.name;
    if (!clean) {
      name = metaCode(name);
    }
    if (child == null) {
      if (!required) {
        return withState('$name($middle)', clean);
      } else {
        return withState('$name(${middle}child:Container(),)', clean);
      }
    }
    return withState(
        '$name(${middle}child:${child!.code(clean: clean)})', clean);
  }

  @override
  Component clone(Component? parent, {bool deepClone = false}) {
    final comp = super.clone(parent, deepClone: deepClone) as Holder;
    comp.child = child?.clone(comp, deepClone: deepClone);
    return comp;
  }

  @override
  int get type => 3;

  @override
  int get childCount => 1;
}

abstract class ClickableHolder extends Holder with Clickable {
  ClickableHolder(String name, List<Parameter> parameters)
      : super(name, parameters);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: RuntimeProvider.of(context) != RuntimeMode.run,
      child: super.build(context),
    );
  }
}

abstract class ClickableComponent extends Component with Clickable {
  ClickableComponent(String name, List<Parameter> parameters)
      : super(name, parameters);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: RuntimeProvider.of(context) != RuntimeMode.run,
      child: super.build(context),
    );
  }
}

mixin FVBScrollable {
  ScrollController initScrollController(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    if (RuntimeProvider.of(context) == RuntimeMode.edit) {
      scrollController.addListener(() {
        (this as Component).forEach((final Component component) {
          component.lookForUIChanges(context, checkSameCount: false);
        });
      });
    }

    return scrollController;
  }
}
mixin Clickable {
  List<FVBFunction> functions = [];
  List<ActionModel> actionList = [];
  late CodeProcessor _processor;

  void methods(List<FVBFunction> function) {
    functions.addAll(function);
    _processor=CodeProcessor.build(name: (this as Component).name);
  }

  void test() {
    _processor.parentProcessor=ComponentOperationCubit.processor;
    final processor = CodeProcessor(
        scopeName: (this as Component).name,
        parentProcessor:    _processor.parentProcessor!.clone(
            CodeProcessor.testConsoleCallback, CodeProcessor.testOnError),
        consoleCallback: CodeProcessor.testConsoleCallback,
        onError: CodeProcessor.testOnError);
    for(final fun1 in functions) {
      processor.functions.remove(fun1.name);
    }
    for (final ActionModel action in actionList) {
      if (action is CustomAction) {
        processor.executeCode(action.arguments[0],
            declarativeOnly: true, type: OperationType.checkOnly);
        _processor.executeCode(action.arguments[0], declarativeOnly: true);
      }
    }


  }

  String get defaultCode {
    return functions.map((function) => '''
           ${DataType.dataTypeToCode(function.returnType)} ${function.name}(${function.arguments.map((e) => '${DataType.dataTypeToCode(e.dataType)} ${e.name}').join(',')}){
           // TODO: Implement Logic Here
           }
          ''').join('\n');
  }

  performCustomAction(
      BuildContext context, ActionModel action, List<dynamic>? arguments,
      {CodeProcessor? processor2, String? name}) {
    final function = name != null
        ? functions.firstWhereOrNull((e) => e.name == name)
        : (functions.isNotEmpty ? functions.first : null);
    if (function == null) {
      return;
    }
    return _processor.functions[function.name]
        ?.execute(_processor, null, arguments ?? []);
  }

  perform(BuildContext context, {List? arguments, String? name}) {
    if (RuntimeProvider.of(context) == RuntimeMode.run) {
      for (final action in actionList) {
        if (action is CustomAction) {
          return performCustomAction(context, action, arguments, name: name);
        } else {
          action.perform(context);
        }
      }
    }
  }

  String get eventCode {
    String code = '';
    for (final action in actionList) {
      final actionCode = action.code();
      if (actionCode.isNotEmpty) {
        code += actionCode + ';\n';
      }
    }
    return code;
  }

  List<String>? getParams(final String code) {
    if (code.isEmpty) {
      return null;
    }
    final codeList = code
        .substring(code.indexOf('<') + 1, code.indexOf('>'))
        .split('-')
        .map((element) => element != 'null' ? element : '')
        .toList(growable: false);
    return codeList;
  }

  void fromMetaCodeToAction(String code, final FlutterProject? flutterProject) {
    if (code.startsWith('CA')) {
      final endIndex = CodeOperations.findCloseBracket(
          code, 2, '<'.codeUnits.first, '>'.codeUnits.first);
      actionList.add(CustomAction(
          code:
              String.fromCharCodes(base64Decode(code.substring(3, endIndex)))));
    } else if (code.startsWith('NPISA')) {
      final name = code.substring(code.indexOf('<') + 1, code.indexOf('>'));
      actionList
          .add(NewPageInStackAction(getUIScreenWithName(name, flutterProject)));
    } else if (code.startsWith('RCPISA')) {
      final name = code.substring(code.indexOf('<') + 1, code.indexOf('>'));
      actionList.add(ReplaceCurrentPageInStackAction(
          getUIScreenWithName(name, flutterProject)));
    } else if (code.startsWith('NBISA')) {
      actionList.add(GoBackInStackAction());
    } else if (code.startsWith('SBSISA')) {
      final name = code.substring(code.indexOf('<') + 1, code.indexOf('>'));
      actionList.add(ShowBottomSheetInStackAction(
          getUIScreenWithName(name, flutterProject)));
    } else if (code.startsWith('HBSISA')) {
      // actionList.add(HideBottomSheetInStackAction());
    } else if (code.startsWith('SSBA')) {
      final list = getParams(code.substring(4));
      final action = ShowSnackBarAction();
      if (list != null) {
        (action.arguments[0] as Parameter).fromCode(list[0]);
        (action.arguments[1] as Parameter).fromCode(list[1]);
      }
      actionList.add(action);
    } else if (code.startsWith('SDISA')) {
      final list = getParams(code.substring(5));
      actionList.add(ShowDialogInStackAction(args: list));
    } else if (code.startsWith('SCDISA')) {
      final name = code.substring(code.indexOf('<') + 1, code.indexOf('>'));
      UIScreen? selectedUiScreen;
      for (final UIScreen uiScreen in flutterProject?.uiScreens ?? []) {
        if (uiScreen.name == name) {
          selectedUiScreen = uiScreen;
          break;
        }
      }
      actionList.add(ShowCustomDialogInStackAction(uiScreen: selectedUiScreen));
    }
  }

  UIScreen? getUIScreenWithName(String name, FlutterProject? flutterProject) {
    for (final UIScreen uiScreen in flutterProject?.uiScreens ?? []) {
      if (uiScreen.name == name) {
        return uiScreen;
      }
    }
    return null;
  }
}

abstract class CustomNamedHolder extends Component {
  Map<String, Component?> childMap = {};
  Map<String, List<Component>> childrenMap = {};

  CustomNamedHolder(String name, List<Parameter> parameters,
      List<String> childMap, List<String> childrenMap,
      {List<ParameterRuleModel>? rules})
      : super(name, parameters, rules: rules) {
    for (final child in childMap) {
      this.childMap[child] = null;
    }
    for (final children in childrenMap) {
      this.childrenMap[children] = [];
    }
  }

  void addOrUpdateChildWithKey(String key, Component? component) {
    if (childMap.containsKey(key)) {
      childMap[key]?.setParent(null);
      childMap[key] = component;
      component?.setParent(this);
    } else if (component != null) {
      childrenMap[key]!.add(component);
      component.setParent(this);
    }
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
      if (this is BuilderComponent) {
        for (final child in childMap.keys) {
          for (final comp
              in (this as BuilderComponent).builtList[child] ?? []) {
            final len = components.length;
            comp.searchTappedComponent(offset, components);
            if (len != components.length) {
              break;
            }
          }
        }
      } else {
        for (final child in childMap.values) {
          if (child == null) {
            continue;
          }
          child.searchTappedComponent(offset, components);
        }
        for (final children in childrenMap.values) {
          for (final child in children) {
            child.searchTappedComponent(offset, components);
          }
        }
      }
      components.add(this);
      return;
    }
  }

  @override
  String code({bool clean = true}) {
    final middle = parametersCode(clean);
    String name = this.name;
    if (!clean) {
      name = metaCode(name);
    }
    String childrenCode = '';
    for (final child in childMap.keys) {
      if (childMap[child] != null) {
        childrenCode += '$child:${childMap[child]!.code(clean: clean)},'
            .replaceAll(',,', ',');
      }
    }

    for (final child in childrenMap.keys) {
      if (childrenMap[child]?.isNotEmpty ?? false) {
        childrenCode +=
            '$child:[${childrenMap[child]!.map((e) => (e.code(clean: clean) + ',').replaceAll(',,', ',')).join('')}],'
                .replaceAll(',,', ',');
      }
    }
    return withState('$name($middle$childrenCode)', clean);
  }

  @override
  Component clone(Component? parent, {bool deepClone = false}) {
    final comp = super.clone(parent, deepClone: deepClone) as CustomNamedHolder;
    comp.childMap = childMap.map((key, value) =>
        MapEntry(key, value?.clone(comp, deepClone: deepClone)));
    comp.childrenMap = childrenMap.map((key, value) => MapEntry(
        key, value.map((e) => e.clone(comp, deepClone: deepClone)).toList()));
    return comp;
  }

  @override
  int get type => 4;

  String? replaceChild(Component oldComp, Component? comp) {
    String? compKey;
    bool fromChildMap = true;
    for (final String key in childMap.keys) {
      if (childMap[key] == oldComp) {
        compKey = key;
        fromChildMap = true;
        break;
      }
    }
    for (final String key in childrenMap.keys) {
      if (childrenMap[key]!.contains(oldComp)) {
        compKey = key;
        fromChildMap = false;
        break;
      }
    }
    if (compKey != null) {
      if (fromChildMap) {
        childMap[compKey] = comp;
        comp?.setParent(this);
      } else {
        final int index = childrenMap[compKey]!.indexOf(oldComp);
        childrenMap[compKey]!.removeAt(index);
        if (comp != null) {
          if (index < childrenMap[compKey]!.length) {
            childrenMap[compKey]!.insert(index, comp);
          } else {
            childrenMap[compKey]!.add(comp);
          }
        }
      }
      return compKey;
    }
    return null;
  }

  @override
  int get childCount => -2;
}

class CustomComponentImpl extends Component {
  CustomComponent customComponent;

  CustomComponentImpl(this.customComponent) : super(customComponent.name, []);

  @override
  Widget create(BuildContext context) {
    return customComponent.root?.clone(parent).create(context) ?? Container();
  }
}

abstract class CustomComponent extends Component {
  String? extensionName;
  late final CodeProcessor processor;
  String actionCode;
  Component? root;
  List<CustomComponent> objects = [];
  Map<String, String> arguments = {};

  CustomComponent(
      {required this.extensionName,
      required String name,
      this.root,
      this.actionCode = '',
      List<VariableModel>? variables})
      : super(name, []) {
    processor = CodeProcessor.build(
        processor: ComponentOperationCubit.currentProject!.processor,
        name: name);
    if (this is StatefulComponent) {
      processor.functions['setState'] = FVBFunction('setState', null, [
        FVBArgument('callback', dataType: DataType.fvbFunction)
      ], dartCall: (arguments, instance) {
        (arguments[0] as FVBFunction).execute(processor, null, []);
        (arguments[1] as CodeProcessor).consoleCallback.call('api:refresh|$id');
      });
    }
    processor.variables.addAll((variables ?? [])
        .asMap()
        .map((key, value) => MapEntry(value.name, value)));
  }

  Map<String, FVBVariable> get variables => processor.variables;

  set variables(Map<String, FVBVariable> value) {
    processor.variables.clear();
    processor.variables.addAll(value);
  }

  @override
  String code({bool clean = true}) {
    String middle = '';
    String name = this.name;
    if (!clean) {
      name = metaCode(name);
    }
    for (final argument in arguments.entries) {
      if (clean) {
        middle +=
            '${argument.key.contains('this.') ? argument.key.substring(5) : argument.key}:${argument.value},';
      } else {
        middle += '${argument.key}:`${argument.value}`,';
      }
    }
    return withState('$name($middle)', clean);
  }

  CustomComponent get getRootClone {
    CustomComponent? rootClone = cloneOf as CustomComponent?;
    while (rootClone!.cloneOf != null) {
      rootClone = rootClone.cloneOf as CustomComponent?;
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

    for (final object in objects) {
      object.forEach(work);
    }
    for (final clone in cloneElements) {
      clone.forEach(work);
    }
    forEachInComponentParameter(work);
  }

  @override
  Widget build(BuildContext context) {

    if (RuntimeProvider.of(context) == RuntimeMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        lookForUIChanges(context);
      });
    }

    processor.destroyProcess(deep: false);
    processor.executeCode(actionCode);
    final constructor = processor.functions[processor.scopeName];
    if (constructor != null) {
      if (arguments.isNotEmpty) {
        arguments.removeWhere((key, value) =>
            constructor.arguments
                .firstWhereOrNull((arg) => arg.argName == key) ==
            null);
      }
      for (final arg in constructor.arguments) {
        final name = arg.argName;
        if (!arguments.containsKey(name)) {
          arguments[name] = '';
        }
      }
    }
    if (RuntimeProvider.of(context) != RuntimeMode.favorite) {
      processor.callConstructor(arguments, ProcessorProvider.maybeOf(context)!);
      (cloneOf as CustomComponent?)?.variables = processor.variables;
    }
    if (this is StatefulComponent) {
      if (RuntimeProvider.of(context) == RuntimeMode.run) {
        processor.functions['initState']?.execute(processor, null, []);
      }
    }

    return ProcessorProvider(
      processor,
      BlocBuilder<StateManagementBloc, StateManagementState>(
          key: key(context),
          buildWhen: (previous, current) => current.id == id,
          builder: (context, state) {
            if (RuntimeProvider.of(context) == RuntimeMode.run) {
              processor.functions['build']?.execute(processor, null, [context]);
            }
            variables['context'] =
                FVBVariable('context', DataType.dynamic, value: context);
            return ComponentWidget(
              child: create(context),
            );
          }),
    );
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
      objects[i].arguments = oldObject.arguments;
      objects[i].actionCode = oldObject.actionCode;
      replaceChildOfParent(oldObject, objects[i]);
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
  Component clone(Component? parent, {bool deepClone = false}) {
    final CustomComponent customComponent = (this is StatelessComponent)
        ? StatelessComponent(name: name, actionCode: actionCode)
        : StatefulComponent(name: name, actionCode: actionCode);
    customComponent.name = name;
    if (deepClone) {
      for (int i = 0; i < parameters.length; i++) {
        customComponent.parameters[i].cloneOf(parameters[i]);
      }
    } else {
      customComponent.parameters = parameters;
    }

    customComponent.arguments = arguments;
    customComponent.actionCode = actionCode;
    customComponent.variables =
        variables.map((key, value) => MapEntry(key, value.clone()));
    customComponent.root = root?.clone(parent, deepClone: deepClone);
    if (!deepClone) {
      customComponent.cloneOf = this;
      cloneElements.add(customComponent);
    }
    return customComponent;
  }

  CustomComponent createInstance(Component? root) {
    final compCopy = clone(root) as CustomComponent;
    compCopy.arguments = (arguments.map((key, value) => MapEntry(key, '')));
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

class ABC extends StatefulWidget {
  const ABC({Key? key}) : super(key: key);

  @override
  State<ABC> createState() => _ABCState();
}

class _ABCState extends State<ABC> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class StatelessComponent extends CustomComponent {
  static const defaultActionCode = ''' 
   void build(context){
      // this will be called when the component is built
   }
      ''';

  StatelessComponent(
      {required String name,
      super.actionCode = defaultActionCode,
      super.variables,
      Component? root})
      : super(extensionName: 'StatelessWidget', name: name, root: root) {
    if (root != null) {
      root.setParent(this);
    }
  }

  factory StatelessComponent.fromJson(Map<String, dynamic> data) {
    return StatelessComponent(
      name: data['name'],
      actionCode: data['action_code'] ?? defaultActionCode,
      variables: data['variables'] != null
          ? List<VariableModel>.from(data['variables']!
              .map((e) => VariableModel.fromJson(e..['uiAttached'] = true)))
          : null,
    );
  }

  @override
  String implementationCode() {
    if (root == null) {
      return '';
    }
    final CodeProcessor processor = CodeProcessor(
      consoleCallback: (value, {List<dynamic>? arguments}) {
        return null;
      },
      onError: (error, line) {},
      scopeName: this.processor.scopeName,
    );

    processor.executeCode(actionCode, type: OperationType.checkOnly);
    final vars = processor.functions[processor.scopeName]?.arguments ?? [];
    return '''class $name extends StatelessWidget {
          ${vars.map((e) => 'final ${e.varDeclarationCode}').join(' ')}
          ${processor.variables.isNotEmpty ? '' : 'const'} $name({${vars.map((e) => 'required ${e.name}').join(',')}${vars.isNotEmpty ? ',' : ''}Key? key}) : super(key: key);
        
           ${FVBEngine.instance.getDartCode(processor, actionCode, (p0) {
      if (p0 == 'build') {
        return 'return ${root!.code()};';
      }
      return null;
    })}
         }
    ''';
  }
}

class StatefulComponent extends CustomComponent {
  static const defaultActionCode = ''' 
     void initState(){
      // this will be called when the component is created
      }
      void build(context){
      // this will be called when the component is built
      }
      ''';

  StatefulComponent(
      {required String name,
      super.actionCode = defaultActionCode,
      super.variables,
      Component? root})
      : super(extensionName: 'StatefulWidget', name: name, root: root) {
    if (root != null) {
      root.setParent(this);
    }
  }

  factory StatefulComponent.fromJson(Map<String, dynamic> data) {
    return StatefulComponent(
      name: data['name'],
      actionCode: data['action_code'] ?? defaultActionCode,
      variables: data['variables'] != null
          ? List<VariableModel>.from(
              data['variables']!.map((e) => VariableModel.fromJson(e)))
          : null,
    );
  }

  @override
  String implementationCode() {
    if (root == null) {
      return '';
    }
    final CodeProcessor processor = CodeProcessor(
      consoleCallback: (value, {List<dynamic>? arguments}) {
        return null;
      },
      onError: (error, line) {},
      scopeName: this.processor.scopeName,
    );
    processor.executeCode(actionCode, type: OperationType.checkOnly);
    return '''
  class $name extends StatefulWidget {
  const $name({Key? key}) : super(key: key);

  @override
  State<$name> createState() => _${name}State();
}

class _${name}State extends State<$name> {
  ${FVBEngine.instance.getDartCode(processor, actionCode, (p0) {
      if (p0 == 'build') {
        return 'return ${root!.code()};';
      } else if (p0 == 'initState') {
        return 'super.initState();';
      }
      return null;
    })}
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
