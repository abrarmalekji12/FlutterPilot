import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_classes.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';

import './component_model.dart';
import '../../../bloc/state_management/state_management_bloc.dart';
import '../../../code_operations.dart';
import '../../../common/analyzer/package_analyzer.dart';
import '../../../common/converter/code_converter.dart';
import '../../../common/converter/string_operation.dart';
import '../../../common/logger.dart';
import '../../../data/remote/firestore/firebase_bridge.dart';
import '../../../injector.dart';
import '../../../runtime_provider.dart';
import '../../../ui/boundary_widget.dart';
import '../../local_model.dart';
import '../../parameter_model.dart';
import '../../project_model.dart';
import '../../variable_model.dart';

sealed class CustomComponent extends Component with Viewable {
  String? extensionName;
  late final Processor processor;
  String actionCode;
  Component? rootComponent;
  final DateTime? dateCreated;
  List<CustomComponent> objects = [];
  List<String> arguments = [];
  List<VariableModel> argumentVariables = [];
  FVBProject? project;
  bool previewEnable;
  late FVBClass componentClass;
  final String userId;
  final String id;

  CustomComponent(
      {required this.extensionName,
      required String name,
      required this.id,
      this.dateCreated,
      this.previewEnable = false,
      this.rootComponent,
      required this.userId,
      this.actionCode = '',
      this.project,
      List<VariableModel>? variables,
      List<VariableModel>? parentVars,
      Processor? parent})
      : super(name, []) {
    componentClass = FVBClass.create(
      name,
      funs: [FVBFunction(name, '', fromVariablesToArguments())],
      vars: argumentVariables.asMap().map(
            (key, value) => MapEntry(value.name, () => value),
          ),
      subclassOf: widgetClass,
    );
    processor = Processor.build(
        parent: parent ??
            (parentVars != null
                ? (sl<Processor>().clone((p0, {arguments}) {
                    return null;
                  }, (p0, p1) {}, true)
                  ..variables.removeWhere((key, value) =>
                      value is! VariableModel || value.deletable)
                  ..variables.addAll(parentVars
                      .asMap()
                      .map((key, value) => MapEntry(value.name, value))))
                : (project?.processor ?? systemProcessor)),
        name: name);
    if (this is StatefulComponent) {
      processor.functions['setState'] = FVBFunction('setState', null, [
        FVBArgument('callback', dataType: DataType.fvbFunction)
      ], dartCall: (arguments, instance) {
        if (Processor.operationType != OperationType.checkOnly) {
          (arguments[0] as FVBFunction).execute(processor, null, []);
          (arguments[1] as Processor).consoleCallback.call('api:refresh|$id');
        }
      });
    }
    processor.variables.addAll((variables ?? [])
        .asMap()
        .map((key, value) => MapEntry(value.name, value)));
  }

  @override
  set setId(String id) {
    super.setId = id;
  }

  String get fileName => StringOperation.toSnakeCase(name);

  List<FVBArgument> fromVariablesToArguments() {
    return argumentVariables
        .map((e) => FVBArgument(e.name,
            dataType: e.dataType,
            type: e.value == null
                ? FVBArgumentType.placed
                : FVBArgumentType.optionalNamed,
            defaultVal: e.value))
        .toList(growable: false);
  }

  get argumentDeclarationCode => argumentVariables
      .map((e) => 'final ${DataType.dataTypeToCode(e.dataType)} ${e.name};')
      .join('\n');

  get argumentConstructorCode =>
      argumentVariables
          .map((e) => 'this.${e.name}=${LocalModel.valueToCode(e.value)}')
          .join(',') +
      (argumentVariables.isNotEmpty ? ',' : '');

  void updateArgument(UpdateType update, VariableModel model) {
    switch (update) {
      case UpdateType.add:
        argumentVariables.add(model);
        objects.forEach((element) {
          element.arguments.add('');
        });
        break;
      case UpdateType.remove:
        final index = argumentVariables.indexOf(model);
        argumentVariables.remove(model);
        variables.remove(model.name);
        objects.forEach((element) {
          element.arguments.removeAt(index);
        });
        break;
    }
    updateClassVariables();
  }

  void updateClassVariables() {
    objects.forEach((element) {
      element.argumentVariables = argumentVariables;
    });
    cloneElements.forEach((comp) {
      (comp as CustomComponent).argumentVariables = argumentVariables;
    });
    componentClass.fvbVariables.clear();
    componentClass.fvbVariables.addAll(argumentVariables
        .asMap()
        .map((key, value) => MapEntry(value.name, () => value)));
    componentClass.fvbFunctions[name] = FVBFunction(
        name,
        '',
        argumentVariables
            .map((e) => FVBArgument('this.${e.name}',
                dataType: e.dataType,
                type: e.value == null
                    ? FVBArgumentType.placed
                    : FVBArgumentType.optionalNamed,
                defaultVal: e.value))
            .toList(growable: false));
  }

  CustomComponent? findClone(Component cRoot) {
    if (cRoot == rootComponent) {
      return this;
    }
    if (objects.isEmpty) {
      return null;
    }
    for (final object in objects) {
      final comp = object.findClone(cRoot);
      if (comp != null) {
        return object;
      }
    }
    return null;
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
    for (int i = 0; i < argumentVariables.length; i++) {
      final argument = argumentVariables[i];
      if (clean) {
        if (arguments[i].isNotEmpty)
          middle += '${argument.name}:${arguments[i]},';
      } else {
        middle += '${argument.name}:`${arguments[i]}`,';
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
    return rootComponent?.build(context) ?? Container();
  }

  void updateRoot(Component? root) {
    this.rootComponent?.setParent(null);
    this.rootComponent = root;
    root?.setParent(this);
    getAllClones().forEach((element) {
      (element as CustomComponent).rootComponent?.setParent(null);
      element.rootComponent =
          root?.clone(element, deepClone: false, connect: true);
    });
  }

  @override
  bool forEachWithClones(bool Function(Component) work) {
    if (work.call(this)) {
      return true;
    }
    if (rootComponent != null) {
      if (rootComponent!.forEachWithClones(work)) return true;
    }

    for (final object in objects) {
      if (object.forEachWithClones(work)) {
        return true;
      }
    }
    for (final clone in cloneElements) {
      if (clone.forEachWithClones(work)) {
        return true;
      }
    }
    if (forEachInComponentParameter(work, withClone: true)) {
      return true;
    }
    return false;
  }

  @override
  bool forEach(bool Function(Component) work) {
    if (work.call(this)) {
      return true;
    }
    if (rootComponent != null) {
      if (rootComponent!.forEach(work)) return true;
    }

    for (final object in objects) {
      if (object.forEach(work)) {
        return true;
      }
    }
    if (forEachInComponentParameter(work, withClone: false)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mode = RuntimeProvider.of(context);

    if (mode == RuntimeMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        lookForUIChanges(context);
      });
    }

    final parentProcessor = ProcessorProvider.maybeOf(context)!;
    processor.destroyProcess(deep: false);
    processor.executeCode(actionCode);
    applyVariables(parentProcessor);
    // (cloneOf as CustomComponent?)?.variables = processor.variables;
    variables['context'] =
        FVBVariable('context', DataType.fvbDynamic, value: context);

    if (mode != RuntimeMode.favorite) {
      if (this is StatefulComponent) {
        processor.functions['initState']?.execute(processor, null, []);
      }
    }
    return ProcessorProvider(
      processor: processor,
      child: BlocConsumer<StateManagementBloc, StateManagementState>(
          listener: (_, state) {
            if (state is StateManagementUpdatedState &&
                state.id == id &&
                state.mode == mode) {
              processor.destroyProcess(deep: false);
              processor.executeCode(actionCode);
              applyVariables(parentProcessor);
              variables['context'] =
                  FVBVariable('context', DataType.fvbDynamic, value: context);
              processor.functions['initState']?.execute(processor, null, []);
            }
          },
          buildWhen: (previous, current) =>
              current.id == id && current.mode == mode,
          builder: (context, state) {
            if (RuntimeProvider.of(context) != RuntimeMode.favorite)
              processor.functions['build']?.execute(processor, null, [context],
                  defaultProcessor: processor);
            return ComponentWidget(
              child: create(context),
              component: this,
            );
          }),
    );
  }

  @override
  void searchTappedComponent(Offset offset, Set<Component> components) {
    if (rootComponent != null) {
      if (GlobalObjectKey(rootComponent!).currentState != null &&
          (rootComponent?.boundary?.contains(offset) ?? false)) {
        components.add(this);
      }
      rootComponent?.searchTappedComponent(offset, components);
    }
    for (final cloneRoot
        in ((getOriginal() as CustomComponent?)?.getAllClones()) ?? []) {
      if (((cloneRoot as CustomComponent)
                  .rootComponent
                  ?.boundary
                  ?.contains(offset) ??
              false) &&
          GlobalObjectKey(cloneRoot).currentState != null) {
        cloneRoot.rootComponent?.searchTappedComponent(offset, components);
        components.add(cloneRoot);
      }
    }
  }

  void notifyChanged() {
    for (int i = 0; i < objects.length; i++) {
      final oldObject = objects[i];
      objects[i] = clone(objects[i].parent) as CustomComponent;
      // objects[i].root = root?.clone(objects[i].parent);
      objects[i].arguments = oldObject.arguments;
      objects[i].actionCode = oldObject.actionCode;
      objects[i].argumentVariables = oldObject.argumentVariables;
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
        (comOld.parent as CustomComponent).rootComponent = comp;
    }
  }

  String implementationCode(FVBProject project);

  @override
  int get type => 5;

  @override
  int get childCount => 0;

  @override
  Component clone(parent,
      {bool deepClone = false, FVBProject? project, bool connect = false}) {
    final CustomComponent customComponent = (this is StatelessComponent)
        ? StatelessComponent(
            name: name,
            id: randomId,
            actionCode: actionCode,
            project: project ?? this.project,
            parent: processor.parentProcessor,
            userId: userId,
          )
        : StatefulComponent(
            id: randomId,
            name: name,
            actionCode: actionCode,
            project: project ?? this.project,
            parent: processor.parentProcessor,
            userId: userId,
          );
    customComponent.name = name;
    customComponent.parent = parent;
    if (deepClone) {
      for (int i = 0; i < parameters.length; i++) {
        customComponent.parameters[i].cloneOf(parameters[i], connect);
      }
      customComponent.argumentVariables
          .addAll(argumentVariables.map((e) => e.clone()));
      customComponent.updateClassVariables();
      customComponent.arguments = arguments.map((e) => e).toList();
    } else {
      customComponent.parameters = parameters;
      customComponent.argumentVariables = argumentVariables;
      customComponent.componentClass = componentClass;
      customComponent.arguments = arguments;
    }
    customComponent.variables =
        variables.map((key, value) => MapEntry(key, value.clone()));
    customComponent.rootComponent =
        rootComponent?.clone(parent, deepClone: deepClone, connect: connect);
    if (!deepClone) {
      customComponent.cloneOf = this;
      cloneElements.add(customComponent);
    }
    return customComponent;
  }

  CustomComponent createInstance(Component? root) {
    final compCopy = clone(root, connect: true) as CustomComponent;
    compCopy.arguments = List.generate(argumentVariables.length, (index) => '');
    objects.add(compCopy);
    return compCopy;
  }

  static Component findSameLevelComponent(
      CustomComponent copy, CustomComponent original, Component object) {
    Component? tracer = object;
    final List<List<Parameter>> paramList = [];
    logger('=== FIND FIRST LEVEL');
    while (tracer != original.rootComponent?.parent) {
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
        return (component as CustomComponent).rootComponent;
    }
    return null;
  }

  Map<String, dynamic> toMainJson({String? newName}) {
    return {
      'id': id,
      'code': rootComponent?.toJson(),
      'name': newName ?? name,
      'projectId': project?.id,
      'userId': userId,
      'previewEnable': previewEnable,
      'type': this is StatefulComponent ? 1 : 0,
      'updatedAt': Timestamp.now(),
      'createdAt': dateCreated != null
          ? FirebaseDataBridge.timestampToDate(dateCreated)
          : null,
      'arguments':
          argumentVariables.map((e) => e.toJson()).toList(growable: false),
      'actionCode': actionCode,
      'variables': variables.values
          .where((element) =>
              element is VariableModel &&
              element.uiAttached &&
              !element.isDynamic)
          .map((e) => e.toJson())
          .toList(),
    };
  }

  static CustomComponent fromJson(final Map<String, dynamic> json,
      {List<VariableModel>? parentVars, FVBProject? project}) {
    CustomComponent component;
    if (json['type'] == 0 || json['type'] == 'stateless') {
      component = StatelessComponent.fromJson(json,
          parentVars: parentVars, project: project);
    } else {
      component = StatefulComponent.fromJson(json,
          parentVars: parentVars, project: project);
    }
    component.argumentVariables.addAll(((json['arguments'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => VariableModel.fromJson(e..['uiAttached'] = true)));
    component.updateClassVariables();
    return component;
  }

  void applyVariables(Processor processor, {Processor? target}) {
    final argValue = arguments.isEmpty
        ? argumentVariables.map((e) => e.value).toList(growable: false)
        : arguments.map((e) {
            final output = processor.process(CodeOperations.trim(e)!,
                config: const ProcessorConfig());
            return output.value;
          }).toList(growable: false);
    if (this is StatefulComponent) {
      (target ?? this.processor).variables['widget'] = FVBVariable(
          'widget', DataType.fvbInstance(name),
          value: componentClass.createInstance(
              (target ?? this.processor), argValue));
    } else {
      for (int i = 0; i < argumentVariables.length; i++) {
        (target ?? this.processor).variables[argumentVariables[i].name] =
            argumentVariables[i].clone()
              ..setValue(
                  processor,
                  (argValue.length > i ? argValue[i] : null) ??
                      argumentVariables[i].value);
      }
    }
  }
}

class StatelessComponent extends CustomComponent {
  static const _defaultActionCode = '''
   void build(context){
      // this will be called when the component is built
   }
      ''';

  String get defaultActionCode {
    return _defaultActionCode;
  }

  StatelessComponent(
      {required String name,
      super.actionCode,
      super.variables,
      super.previewEnable,
      required super.id,
      required super.userId,
      super.dateCreated,
      super.project,
      Component? root,
      List<VariableModel>? parentVars,
      Processor? parent})
      : super(
          extensionName: 'StatelessWidget',
          name: name,
          rootComponent: root,
          parentVars: parentVars,
          parent: parent,
        ) {
    if (root != null) {
      root.setParent(this);
    }
    if (actionCode.isEmpty) {
      actionCode = defaultActionCode;
    }
  }

  factory StatelessComponent.fromJson(Map<String, dynamic> data,
      {List<VariableModel>? parentVars, required FVBProject? project}) {
    return StatelessComponent(
        userId: data['userId'] ?? '',
        name: data['name'],
        id: data['id'],
        previewEnable: data['previewEnable'] ?? false,
        project: project,
        dateCreated: FirebaseDataBridge.timestampToDate(data['dateCreated']) ??
            DateTime.now(),
        actionCode: data['actionCode'] ?? '',
        variables: data['variables'] != null
            ? List<VariableModel>.from(data['variables']!
                .map((e) => VariableModel.fromJson(e..['uiAttached'] = true)))
            : null,
        parentVars: parentVars);
  }

  @override
  String implementationCode(FVBProject project) {
    if (rootComponent == null) {
      return '';
    }
    final Processor processor = Processor(
      consoleCallback: (value, {List<dynamic>? arguments}) {
        return null;
      },
      onError: (error, line) {},
      scopeName: this.processor.scopeName,
    );

    processor.executeCode(actionCode, type: OperationType.checkOnly);

    /// TODO(ConstStateless): Check if all arguments are final, make constructor const
    /// Make sure Custom Component body don't have class or enum declarations
    return '''
    ${PackageAnalyzer.getPackages(project, rootComponent, actionCode)}
        
    class $name extends StatelessWidget {
         $argumentDeclarationCode
          $name({${argumentConstructorCode}Key? key}) : super(key: key);
        
           ${FVBEngine.instance.getDartCode(processor, actionCode, (p0) {
      if (p0 == 'build') {
        return FunctionModifier('Widget ', 'return ${rootComponent!.code()};');
      }
      return null;
    })}
    
         }
    ''';
  }

  @override
  set id(String id) {
    this.cid = id;
  }
}

class StatefulComponent extends CustomComponent {
  static const _defaultActionCode = '''
    
     void initState(){
      // this will be called when the component is created
      }
      void build(context){
      // this will be called when the component is built
      }
      ''';

  String get defaultActionCode {
    return _defaultActionCode;
  }

  StatefulComponent(
      {required String name,
      super.actionCode,
      super.variables,
      super.previewEnable,
      super.dateCreated,
      required super.id,
      required super.project,
      required super.userId,
      Component? root,
      List<VariableModel>? parentVars,
      Processor? parent})
      : super(
            extensionName: 'StatefulWidget',
            name: name,
            rootComponent: root,
            parentVars: parentVars,
            parent: parent) {
    if (root != null) {
      root.setParent(this);
    }
    if (actionCode.isEmpty) {
      actionCode = defaultActionCode;
    }
  }

  factory StatefulComponent.fromJson(Map<String, dynamic> data,
      {List<VariableModel>? parentVars, required FVBProject? project}) {
    return StatefulComponent(
      name: data['name'],
      project: project,
      previewEnable: data['previewEnable'] ?? false,
      actionCode: data['actionCode'] ?? '',
      dateCreated: FirebaseDataBridge.timestampToDate(data['dateCreated']) ??
          DateTime.now(),
      id: data['id'],
      variables: data['variables'] != null
          ? List<VariableModel>.from(
              data['variables']!.map((e) => VariableModel.fromJson(e)))
          : null,
      parentVars: parentVars,
      userId: data['userId'] ?? '',
    );
  }

  @override
  String implementationCode(FVBProject project) {
    if (rootComponent == null) {
      return '';
    }
    final Processor processor = Processor(
      consoleCallback: (value, {List<dynamic>? arguments}) {
        return null;
      },
      onError: (error, line) {},
      scopeName: this.processor.scopeName,
    );
    processor.executeCode(actionCode, type: OperationType.checkOnly);
    return '''${PackageAnalyzer.getPackages(project, rootComponent, actionCode)}    
        
  class $name extends StatefulWidget {
  $argumentDeclarationCode
  const $name({${argumentConstructorCode}Key? key}) : super(key: key);

  @override
  State<$name> createState() => _${name}State();
}

class _${name}State extends State<$name> {
  ${FVBEngine.instance.getDartCode(processor, actionCode, (p0) {
      if (p0 == 'build') {
        return FunctionModifier('Widget ', 'return ${rootComponent!.code()};');
      } else if (p0 == 'initState') {
        return FunctionModifier('void ', 'super.initState();');
      }
      return null;
    })}
}
    ''';
  }

  @override
  set id(String id) {
    this.id = id;
  }
}
