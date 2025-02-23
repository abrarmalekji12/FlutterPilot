import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/app_config_code.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/constants/processor_constant.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';

import '../../../bloc/state_management/state_management_bloc.dart';
import '../../../code_operations.dart';
import '../../../collections/project_info_collection.dart';
import '../../../common/logger.dart';
import '../../../components/component_impl.dart';
import '../../../components/component_list.dart';
import '../../../cubit/component_operation/operation_cubit.dart';
import '../../../cubit/component_selection/component_selection_cubit.dart';
import '../../../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../../../data/remote/firestore/firebase_bridge.dart';
import '../../../injector.dart';
import '../../../parameters_list.dart';
import '../../../runtime_provider.dart';
import '../../../ui/boundary_widget.dart';
import '../../../ui/paint_tools/paint_tools.dart';
import '../../actions/action_model.dart';
import '../../builder_component.dart';
import '../../parameter_info_model.dart';
import '../../parameter_model.dart';
import '../../parameter_rule_model.dart';
import '../../project_model.dart';
import 'custom_component.dart';

enum ResizeType {
  verticalAndHorizontal,
  symmetricResize,
  verticalOnly,
  horizontalOnly,
  scale
}

enum MoveType { self, child }

final Map<String, int> controllerIds = {};

mixin Resizable {
  ResizeType get resizeType;

  void updateRadius(double radius) {
    throw Exception('Not implemented');
  }

  bool get canUpdateRadius => false;

  Offset? get visualOffset {
    final r = radius;
    if (r == null) {
      return null;
    }
    return Offset(radius!, radius!);
  }

  double? get radius => null;

  void onResize(Size change);

  List<Parameter> get resizeAffectedParameters;
}

void linearChange(Parameter parameter, double value, double update) {
  final updated = value + update;
  if (updated >= 0.01) {
    if (parameter is SimpleParameter) {
      parameter.enable = true;
    }
    parameter.compiler.code = updated.toStringAsFixed(2);
  }
}

void symmetricChange(Parameter parameter, double value, Size update) {
  final updated = value + (update.width != 0 ? update.width : update.height);
  if (updated >= 0.01) {
    if (parameter is SimpleParameter) {
      parameter.enable = true;
    }
    parameter.compiler.code = updated.toStringAsFixed(2);
  }
}

mixin Movable {
  void onMove(Offset offset);

  MoveType get moveType;

  List<Parameter> get movableAffectedParameters;
}
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

final Map<String, Processor> processorWithComp = {};
final List<String> refresherUsed = [];
final Map<String, bool> importFiles = {};
final UserProjectCollection _collection = sl<UserProjectCollection>();

class Ancestor {
  final Component component;
  final Screen? screen;

  Ancestor(this.component, [this.screen]);
}

final formatter = DartFormatter();

class ComponentDefaultParamConfig {
  final bool padding, width, height, visibility, alignment;

  ComponentDefaultParamConfig({
    this.padding = false,
    this.width = false,
    this.height = false,
    this.visibility = false,
    this.alignment = false,
  });
}

const int kWidthIndex = 0;
const int kHeightIndex = 1;
const int kPaddingIndex = 2;
const int kVisibleIndex = 3;
const int kAlignIndex = 4;
const int kAnimationIndex = 5;

abstract class Component {
  final int? boundaryRepaintDelay;
  static final Random random = Random.secure();
  late List<ParameterRuleModel> paramRules;
  List<Parameter> parameters;
  final List<Parameter?> defaultParam = List.filled(6, null);
  final List<ComponentParameter> componentParameters = [];
  String name;
  String? cid;
  late final String uniqueId;
  bool isConstant;
  dynamic parent;
  Component? cloneOf;
  final List<Component> cloneElements = [];
  Rect? _boundary;
  int? depth;
  bool autoHandleKey = true;

  bool get parentAffected => false;

  String? get import => null;

  Component(this.name, this.parameters,
      {this.isConstant = false,
      this.boundaryRepaintDelay,
      List<ParameterRuleModel>? rules,
      ComponentDefaultParamConfig? defaultParamConfig}) {
    if (defaultParamConfig?.width ?? false) {
      defaultParam[kWidthIndex] = Parameters.widthParameter(initial: null);
    }
    if (defaultParamConfig?.height ?? false) {
      defaultParam[kHeightIndex] = Parameters.heightParameter(initial: null);
    }
    if (defaultParamConfig?.padding ?? false) {
      defaultParam[kPaddingIndex] = Parameters.paddingParameter();
    }
    if (defaultParamConfig?.visibility ?? false) {
      defaultParam[kVisibleIndex] = Parameters.visibleParameter;
    }
    if (defaultParamConfig?.alignment ?? false) {
      defaultParam[kAlignIndex] = Parameters.alignmentParameter()
        ..defaultValue = null
        ..withRequired(false);
    }
    defaultParam[kAnimationIndex] = Parameters.animationsParameter;
    paramRules = rules ?? [];
    uniqueId = name + '-' + randomIdOf(5);
  }

  set boundary(Rect? r) => _boundary = r;

  bool get hasImageAsset {
    return (name == 'Image.asset' && parameters.isNotEmpty) ||
        (name == 'Image' &&
            (parameters[0] as ChoiceParameter).val ==
                (parameters[0] as ChoiceParameter).options[0]);
  }

  Ancestor get ancestor {
    Component component = this;
    while (component.parent != null) {
      if (component.parent is ComponentParameter) {
        component = (component.parent as ComponentParameter).parent;
      } else {
        component = component.parent;
      }
    }
    final screen = collection.project!.screens.firstWhereOrNull(
        (element) => element.rootComponent?.id == component.id);
    if (screen != null) {
      return Ancestor(component, screen);
    }
    final custom = collection.project!.customComponents.firstWhereOrNull(
        (element) => element.rootComponent?.id == component.id);
    if (custom != null) {
      return Ancestor(custom, null);
    }
    return Ancestor(component);
  }

  Rect? get boundary {
    if (_boundary != null) {
      return Rect.fromLTWH(_boundary!.left - 1, _boundary!.top - 1,
          _boundary!.width + 2, _boundary!.height + 2);
    }
    if (this is CustomComponent) {
      return (this as CustomComponent).rootComponent?.boundary;
    }
    for (final obj in cloneElements) {
      final b = obj.boundary;
      if (b != null) {
        return b;
      }
    }
    return null;
  }

  void onDispose() {}

  Processor? parentProcessor(Viewable? screen, Component root) {
    if (parent == null) {
      if (root is CustomComponent) {
        return root.processor;
      } else {
        return screen?.processor.functions['build']?.processor ??
            collection.project!.processor;
      }
    }
    if (parent is BuilderComponent) {
      String? key = (parent as BuilderComponent)
          .childMap
          .entries
          .firstWhereOrNull((element) => element.value == this)
          ?.key;
      key ??= (parent as BuilderComponent)
          .childrenMap
          .entries
          .firstWhereOrNull((element) => element.value.contains(this))
          ?.key;
      if (key != null && parent is Component) {
        if ((parent as BuilderComponent).processorMap.containsKey(key)) {
          return (parent as BuilderComponent).processorMap[key];
        }
        final processor = Processor.build(
            name: key,
            parent: (parent as Component).parentProcessor(screen, root));
        (parent as BuilderComponent)
            .functionMap[key]
            ?.execute(processor, null, [], defaultProcessor: processor);
        return processor;
      }
    }
    return (parent! is Component
            ? parent!
            : (parent as ComponentParameter).parent)
        .parentProcessor(screen, root);
  }

  set setId(final String id) {
    if (cid != null) {
      componentMap.remove(cid);
    }
    cid = id;
    componentMap[id] = this;
  }

  String get id {
    if (cid != null) {
      return cid!;
    }
    setId = '$uniqueId${randomIdOf(2)}';
    return cid!;
  }

  void onFreshAdded() {
    if (this is Clickable) {
      (this as Clickable)
          .actionList
          .add(CustomAction(code: (this as Clickable).defaultCode));
    }
    for (final parameter in parameters) {
      if (parameter is SimpleParameter && parameter.initialValue != null) {
        parameter.compiler.code = parameter.initialValue!;
      }
    }
  }

  void addComponentParameters(
      final List<ComponentParameter> componentParameters) {
    componentParameters.forEach((element) {
      element.parent = this;
    });
    this.componentParameters.addAll(componentParameters);
  }

  void addRule(ParameterRuleModel ruleModel) {
    paramRules.add(ruleModel);
  }

  String _parametersCode(List<Parameter?> params) {
    String middle = '';
    for (final parameter in params) {
      if (parameter?.generateCode ?? false) {
        final paramCode = parameter!.code(true);
        if (paramCode.isNotEmpty) {
          middle += '$paramCode,';
        }
      }
    }
    return middle;
  }

  String withState(String code, bool clean) {
    String withRefresher() {
      if (clean && refresherUsed.contains(id)) {
        return 'Refresher("$id",()=>$code)';
      }
      return code;
    }

    String outputCode = withRefresher();
    final insets = (defaultParam[2]?.value) as EdgeInsets?;

    if ((defaultParam[0]?.compiler.code.isNotEmpty ?? false) ||
        (defaultParam[1]?.compiler.code.isNotEmpty ?? false)) {
      outputCode = 'SizedBox(child:$outputCode,${_parametersCode([
            defaultParam[0],
            defaultParam[1]
          ])})';
    }
    if (insets != null &&
        (insets.top > 0 ||
            insets.bottom > 0 ||
            insets.left > 0 ||
            insets.right > 0)) {
      outputCode =
          'Padding(child:$outputCode,${_parametersCode([defaultParam[2]])})';
    }

    if (defaultParam[3] != null &&
        (defaultParam[3] as BooleanParameter).compiler.code.isNotEmpty) {
      outputCode =
          'Visibility(${_parametersCode([defaultParam[3]])}child:$outputCode)';
    }
    if (defaultParam[4] != null &&
        (defaultParam[4] as ChoiceValueParameter).val != null) {
      outputCode =
          'Align(${_parametersCode([defaultParam[4]])}child:$outputCode)';
    }
    if ((defaultParam[5] as ComplexParameter).enable) {
      final durationCode =
          (defaultParam[5] as ComplexParameter).params[0].code(true);
      outputCode =
          '${outputCode}.animate(${durationCode.length > 1 ? durationCode : ''})';
      for (final p
          in ((defaultParam[5] as ComplexParameter).params[1] as ListParameter)
              .params) {
        final duration = (p as ComplexParameter).params[1].code(true);
        final delay = p.params[2].code(true);
        final curve = p.params[3].code(true);
        switch (p.params[0].value) {
          case 'slideLeftToRight':
            outputCode =
                '$outputCode.slideX(begin: -1, end: 0,$duration$delay$curve,)';
            break;
          case 'slideRightToLeft':
            outputCode =
                '$outputCode.slideX(begin: 1, end: 0,$duration$delay$curve,)';
            break;
          case 'slideTopToBottom':
            outputCode =
                '$outputCode.slideY(begin: -1, end: 0,$duration$delay$curve,)';
            break;
          case 'slideBottomToTop':
            outputCode =
                '$outputCode.slideY(begin: 1, end: 0,$duration$delay$curve,)';
            break;

          case 'scaleUpHorizontal':
            outputCode =
                '$outputCode.scaleX(begin:0, end: 1,$duration$delay$curve,)';
            break;
          case 'scaleDownHorizontal':
            outputCode =
                '$outputCode.scaleX(begin:2, end: 1,$duration$delay$curve,)';
            break;
          case 'scaleUpVertical':
            outputCode =
                '$outputCode.scaleY(begin:0, end: 1,$duration$delay$curve,)';
            break;
          case 'scaleDownVertical':
            outputCode =
                '$outputCode.scaleY(begin:2, end: 1,$duration$delay$curve,)';
            break;
          case 'scaleUp':
            outputCode =
                '$outputCode.scaleXY(begin:0, end: 1,$duration$delay$curve,)';
            break;

          case 'scaleDown':
            outputCode =
                '$outputCode.scaleXY(begin:2, end: 1,$duration$delay$curve,)';
            break;
          case 'fadeIn':
            outputCode = '$outputCode.fadeIn($duration$delay$curve,)';
            break;
          case 'fadeOut':
            outputCode = '$outputCode.fadeOut($duration$delay$curve,)';
            break;

          case 'saturate':
            outputCode = '$outputCode.saturate($duration$delay$curve,)';
            break;
          case 'desaturate':
            outputCode = '$outputCode.desaturate($duration$delay$curve,)';
            break;
        }
      }
    }

    return outputCode;
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
    // if (this is BuilderComponent) {
    //   string +=
    //       '|model=${(this as BuilderComponent).model?.name}';
    // }
    if (this is Clickable) {
      string +=
          '|action={${(this as Clickable).actionList.map((e) => e.metaCode()).join(':')}}';
    }
    if (this is FVBPainter) {
      final objs = (this as FVBPainter).paintObjects;
      try {
        string += '|paint={${objs.map((e) {
          final json = e.toJson();
          final units = jsonEncode(json).codeUnits;
          return base64Encode(units);
        }).join(':')}}';
      } on Exception catch (error) {
        print('CUSTOM PAINT CODE GENERATION $error');
      }
    }
    string += ']';
    return string;
  }

  Map<String, dynamic> metaToJson() {
    return {
      if ((this is Clickable) && (this as Clickable).actionList.isNotEmpty)
        'actions':
            (this as Clickable).actionList.map((e) => e.toJson()).toList(),
      if ((this is FVBPainter) && (this as FVBPainter).paintObjects.isNotEmpty)
        'paintObjects':
            (this as FVBPainter).paintObjects.map((e) => e.toJson()).toList(),
    };
  }

  void metaInfoFromJson(
      Map<String, dynamic> json, final FVBProject? flutterProject) {
    if (this is FVBPainter) {
      (this as FVBPainter).paintObjects.addAll(
          List.from(json['paintObjects'] ?? [])
              .map((e) => FVBPaintObj.fromJson(e)));
    }

    if (this is Clickable) {
      for (int i = 0; i < (json['actions']?.length ?? 0); i++) {
        (this as Clickable)
            .actionList
            .add(CustomAction()..fromJson(json['actions'][i]));
      }
    }
  }

  void metaInfoFromCode(final String metaCode, final FVBProject? project) {
    final list = CodeOperations.splitBy(
        metaCode.substring(1, metaCode.length - 1),
        splitBy: pipeCodeUnit);
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
          case 'paint':
            if (this is FVBPainter) {
              final list = fieldList[1].substring(1, fieldList[1].length - 1);
              list.split(':').forEach((e) => (this as FVBPainter)
                  .paintObjects
                  .add(FVBPaintObj.fromJson(
                      jsonDecode(String.fromCharCodes(base64Decode(e))))));
            }
            break;
          case 'model':
            // if(this is! BuilderComponent){
            //   return;
            // }
            // print('NAME ${metaCode}');
            // (this as BuilderComponent).model = flutterProject
            //     ?.currentScreen.models
            //     .firstWhereOrNull((element) => element.name == fieldList[1]);
            // logger('model setted ${(this as BuilderComponent).model?.name}');
            break;
          case 'len':
            (this as BuilderComponent)
                .parameters[0]
                .fromCode(fieldList[1], project);
            break;
          case 'action':
            if (this is Clickable) {
              final list = fieldList[1].substring(1, fieldList[1].length - 1);
              if (list.isNotEmpty) {
                if (list.contains(':')) {
                  list.split(':').forEach((e) =>
                      (this as Clickable).fromMetaCodeToAction(e, project));
                } else {
                  (this as Clickable).fromMetaCodeToAction(list, project);
                }
              }
            }
            break;
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final meta = metaToJson();
    return {
      'id': id,
      'name': name,
      'parameters': parameters.map((e) => e.toJson()).toList(),
      'defaultParameters': defaultParam.map((e) => e?.toJson()).toList(),
      if (this is Holder)
        'child': (this as Holder).child?.toJson()
      else if (this is MultiHolder)
        'children': (this as MultiHolder)
            .children
            .map((e) => jsonEncode(e.toJson()))
            .toList()
      else if (this is CustomNamedHolder) ...{
        'childMap': (this as CustomNamedHolder).childMap.map(
              (key, value) => MapEntry(
                key,
                value?.toJson(),
              ),
            ),
        'childrenMap': (this as CustomNamedHolder).childrenMap.map(
              (key, value) => MapEntry(
                key,
                value.map((e) => e.toJson()).toList(),
              ),
            ),
        if (this is BuilderComponent) ...{
          'functions': (this as BuilderComponent)
              .functionMap
              .map<String, dynamic>((key, value) => MapEntry(key, value.code))
        }
      } else if (this is CustomComponent &&
          (this as CustomComponent).arguments.isNotEmpty) ...{
        'arguments': (this as CustomComponent).arguments
      }
    }..addAll(meta);
  }

  String generateParametersCode(bool clean) {
    String middle = '';
    try {
      if (clean && (this is Controller)) {
        final kId = id;
        // if(controllerIds.containsKey(kId)) {
        //   final v=controllerIds[kId]??0;
        //   middle = 'key:GlobalObjectKey("$kId${v}"),';
        //   controllerIds[kId]=v+1;
        // }
        // else{
        middle = 'key:GlobalObjectKey("$kId"),';
        // controllerIds[kId]=1;
        // }
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
            if (start >= code1.length - 1) {
              break;
            }
            final openIndex = code1.indexOf('{', start);
            if (openIndex == -1) {
              break;
            }
            final closeIndex = CodeOperations.findCloseBracket(
                code1, openIndex, curlyBracketOpen, curlyBracketClose);
            if (closeIndex != null) {
              final roundClose = code1.lastIndexOf(')', openIndex);
              if (roundClose != -1) {
                function.isAsync =
                    code1.substring(roundClose, openIndex).contains('async');
              }
              start += closeIndex + 1;
              final functionBody = code1.substring(openIndex + 1, closeIndex);

              middle +=
                  '${function.name}:${function.getCleanInstanceCode(functionBody)},';
            }
          }
        } else if ((this as Clickable).functions.isNotEmpty) {
          final function = (this as Clickable).functions.first;
          middle +=
              '${function.name}:${function.getCleanInstanceCode((this as Clickable).actionList.map((e) => '${e.code()};').join(' '))},';
        }
      }
      for (final parameter in parameters) {
        if (parameter.generateCode || !clean) {
          final paramCode = parameter.code(clean);
          if (paramCode.isNotEmpty) {
            middle += '$paramCode,';
          }
        }
      }
      // if (clean) {
      //   int start = 0;
      //   int gotIndex = -1;
      //   while (start < middle.length-1) {
      //     if (gotIndex == -1) {
      //       start = middle.indexOf('{{', start);
      //       if (start == -1) {
      //         break;
      //       }
      //       start += 2;
      //       gotIndex = start;
      //     } else {
      //       start = middle.indexOf('}}', start);
      //       if (start == -1) {
      //         break;
      //       }
      //       String innerArea = middle.substring(gotIndex, start);
      //       if (ComponentOperationCubit.processor.variables.isNotEmpty) {
      //         // for (final variable in ComponentOperationCubit.codeProcessor.variables.values) {
      //         //   innerArea = innerArea.replaceAll(variable.name,
      //         //       '${variable!}[index].${variable.name}');
      //         // }
      //         print('MIDDLE ${gotIndex - 2} ${start + 2}');
      //         middle =
      //             middle.replaceRange(
      //                 gotIndex - 2, start + 2, '\${$innerArea}');
      //         gotIndex = -1;
      //         start += 2;
      //         continue;
      //       }
      //     }
      //   }
      // }
    } on Exception catch (e) {
      print('PARAMETERS ERROR ${e.toString()}');
    }
    return middle;
  }

  code({bool clean = true}) {
    if (!clean) {
      return toJson();
    }
    final middle = generateParametersCode(clean);
    String name = this.name;
    if (!clean) {
      name = metaCode(name);
    }
    return withState('$name($middle)', clean);
  }

  factory Component.fromJson(json, final FVBProject? project,
      {List<CustomComponent>? customs}) {
    if (json is String) {
      return Component._fromCode(json, project, customs: customs)!;
    }
    final comp = _getComponentFromName(json['name'],
        flutterProject: project, template: customs);
    if (json['id'] != null) {
      comp.setId = json['id'];
    }
    if (json['meta'] != null) {
      comp.metaInfoFromJson(json['meta'] ?? {}, project);
    } else
      comp.metaInfoFromJson(json, project);

    if (comp is CustomComponent) {
      comp.arguments.clear();
      comp.arguments
          .addAll(List.of(json['arguments'] ?? []).whereType<String>());
    } else {
      for (int i = 0;
          i < (json['parameters']?.length ?? 0) && i < comp.parameters.length;
          i++) {
        comp.parameters[i].fromJson(json['parameters'][i], project);
      }
      for (int i = 0;
          i < (json['defaultParameters']?.length ?? 0) &&
              i < comp.defaultParam.length;
          i++) {
        if (json['defaultParameters'][i] != null) {
          comp.defaultParam[i]?.fromJson(json['defaultParameters'][i], project);
        }
      }
      if (comp is Holder && json['child'] != null) {
        comp.updateChild(
            Component.fromJson(json['child'], project, customs: customs));
      }

      if (comp is MultiHolder && json['children'] != null) {
        comp.children = (json['children'] as List)
            .map((e) => Component.fromJson(
                e is String ? jsonDecode(e) : e, project,
                customs: customs)
              ..setParent(comp))
            .toList();
      }
      if (comp is CustomNamedHolder) {
        if (json['childMap'] != null) {
          comp.childMap = (json['childMap'] as Map).map((k, v) => MapEntry(
              k,
              v != null
                  ? (Component.fromJson(v, project, customs: customs)
                    ..setParent(comp))
                  : null));
        }
        if (json['childrenMap'] != null) {
          comp.childrenMap = (json['childrenMap'] as Map).map(
            (k, v) => MapEntry(
              k,
              List.from(v)
                  .map((e) => Component.fromJson(e, project, customs: customs)
                    ..setParent(comp))
                  .toList(),
            ),
          );
        }
        if (comp is BuilderComponent) {
          final Map<String, dynamic> functionMap = json['functions'] ?? {};
          for (final function in functionMap.entries)
            comp.functionMap[function.key]?.code = function.value;
        }
      }
      for (final p in [...comp.parameters, ...comp.defaultParam]) {
        if (p is UsableParam && (p as UsableParam).usableName != null) {
          project?.commonParams
              .firstWhereOrNull(
                  (element) => element.name == (p as UsableParam).usableName)
              ?.connected
              .add(comp);
        }
      }
    }
    return comp;
  }

  static Component? _fromCode(String? code, final FVBProject? project,
      {List<CustomComponent>? customs}) {
    if (code == null || code.isEmpty) {
      return null;
    }
    final String name = code.substring(0, code.indexOf('(', 0));
    final Component comp;
    if (name.contains('[')) {
      final index = code.indexOf('[', 0);
      final compName = name.substring(0, index);
      comp = _getComponentFromName(compName,
          flutterProject: project, template: customs);
      comp.metaInfoFromCode(name.substring(index), project);
    } else {
      comp = _getComponentFromName(name,
          flutterProject: project, template: customs);
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
          (comp as Holder).updateChild(Component._fromCode(
              childCode.replaceFirst('child:', ''), project,
              customs: customs));
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
            componentList.add(
                Component._fromCode(childCode, project, customs: customs)!
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
              final startIndex = builderCode.indexOf('`');
              final returnIndex = builderCode.indexOf('`return');
              comp.childMap[name] = Component._fromCode(
                  builderCode.substring(
                      returnIndex + 7, builderCode.lastIndexOf(';')),
                  project,
                  customs: customs)
                ?..setParent(comp);
              final endIndex = returnIndex;
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
                  (e) => Component._fromCode(e, project, customs: customs)!
                    ..setParent(comp),
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
            if (colonIndex != -1) {
              final name = parameterCodes[i].substring(0, colonIndex);
              if (nameList.contains(name)) {
                comp.childMap[name] = Component._fromCode(
                    parameterCodes[i].substring(colonIndex + 1), project,
                    customs: customs)
                  ?..setParent(comp);
                nameList.remove(name);
                removeList.add(parameterCodes[i]);
              } else if (childrenNameList.contains(name)) {
                final childrenCode = CodeOperations.splitBy(parameterCodes[i]
                    .substring(colonIndex + 2, parameterCodes[i].length - 1));
                comp.childrenMap[name]!.clear();
                comp.childrenMap[name]!.addAll(
                  childrenCode.map(
                    (e) => Component._fromCode(e, project, customs: customs)!
                      ..setParent(comp),
                  ),
                );
                removeList.add(parameterCodes[i]);
              }
            }
          }
          for (int i = 0; i < removeList.length; i++) {
            parameterCodes.remove(removeList[i]);
          }
        }
        break;

      case 5:
        (comp as CustomComponent).arguments.clear();
        for (int i = 0; i < parameterCodes.length; i++) {
          final colonIndex = parameterCodes[i].indexOf(':');
          comp.arguments.add(parameterCodes[i]
              .substring(colonIndex + 2, parameterCodes[i].length - 1));
        }
        break;
      case 1:
        break;
    }
    final List<Parameter> parameters = [...comp.parameters];
    final List<String> removeList = [];
    for (int i = 0; i < parameters.length; i++) {
      if (parameterCodes.isNotEmpty) {
        final Parameter parameter = parameters[i];
        if (parameter.info.getName() != null) {
          final paramPrefix =
              '${parameter.info is NamedParameterInfo ? (parameter.info as NamedParameterInfo).name : (parameter.info as InnerObjectParameterInfo).namedIfHaveAny!}:';
          for (final paramCode in parameterCodes) {
            if (paramCode.startsWith(paramPrefix)) {
              parameter.fromCode(paramCode, project);
              parameterCodes.remove(paramCode);
              break;
            }
          }
        } else if (i < parameterCodes.length) {
          parameter.fromCode(parameterCodes[i], project);
          removeList.add(parameterCodes[i]);
        }
      }
    }

    for (final value in removeList) {
      parameterCodes.remove(value);
    }
    final list =
        comp.defaultParam.whereType<Parameter>().toList(growable: false);
    for (int i = 0; i < list.length; i++) {
      if (parameterCodes.length > i) {
        list[i].fromCode(parameterCodes[i], project);
      }
    }
    for (final p in comp.parameters) {
      if (p is UsableParam && (p as UsableParam).usableName != null) {
        project?.commonParams
            .firstWhereOrNull(
                (element) => element.name == (p as UsableParam).usableName)
            ?.connected
            .add(comp);
      }
    }
    return comp;
  }

  static Component _getComponentFromName(final String compName,
      {FVBProject? flutterProject, List<CustomComponent>? template}) {
    if (!componentList.containsKey(compName)) {
      final custom = (flutterProject?.customComponents ?? template!)
          .firstWhereOrNull((element) => element.name == compName);
      if (custom != null) {
        return custom.createInstance(null);
      } else {
        // for (final model in flutterProject.favouriteList) {
        //   final comp = model.components
        //       .firstWhereOrNull((element) => element.name == compName);
        //   if (comp != null) {
        //     return comp;
        //   }
        // }
        throw Exception('Custom-Component $compName not found!!');
      }
    }
    return componentList[compName]!();
  }

  Widget build(BuildContext context) {
    final mode = RuntimeProvider.of(context);
    final processor = ProcessorProvider.maybeOf(context)!;
    if (mode == RuntimeMode.favorite) {
      if (this is Controller) {
        return StatefulComponentWidget(
          child: (context) => create(context),
          component: (this as Controller),
        );
      }
      return ComponentWidget(child: create(context), component: this);
    } else if (mode == RuntimeMode.edit) {
      processorWithComp[id] = processor;
    } else if (RuntimeProvider.of(context) == RuntimeMode.run) {
      return BlocBuilder<StateManagementBloc, StateManagementState>(
        buildWhen: (previous, current) =>
            current.id == id && current.mode == mode,
        builder: (context, state) {
          _initParamSetup(processor);
          if (this is Controller) {
            return StatefulComponentWidget(
              child: (context) => create(context),
              component: (this as Controller),
            );
          }
          return ComponentWidget(child: create(context), component: this);
        },
      );
    }
    if (this is Controller) {
      return BlocConsumer<StateManagementBloc, StateManagementState>(
        buildWhen: (previous, current) =>
            current.id == id && current.mode == mode,
        listenWhen: (previous, current) =>
            current.id == id && current.mode == mode,
        listener: (context, state) {
          if (this is Clickable) {
            _initParamSetup(processor);
            (this as Clickable).test();
          }
          if (state is StateManagementUpdatedState) {
            context
                .read<VisualBoxCubit>()
                .visualUpdated(ViewableProvider.maybeOf(context)!);
          }
        },
        builder: (context, state) {
          _handleUIChanges(context);
          _initParamSetup(processor);
          return StatefulComponentWidget(
            child: (context) => create(context),
            component: (this as Controller),
          );
        },
      );
    }
    return BlocConsumer<StateManagementBloc, StateManagementState>(
      buildWhen: (previous, current) =>
          current.id == id && current.mode == mode,
      listenWhen: (previous, current) =>
          current.id == id && current.mode == mode,
      listener: (context, state) {
        if (this is Clickable) {
          _initParamSetup(processor);
          (this as Clickable).test();
        }
        if (state is StateManagementUpdatedState) {
          context
              .read<VisualBoxCubit>()
              .visualUpdated(ViewableProvider.maybeOf(context)!);
        }
      },
      builder: (context, state) {
        _initParamSetup(processor);
        _handleUIChanges(context);
        return ComponentWidget(child: create(context), component: this);
      },
    );
  }

  void _initParamSetup(Processor processor) {
    OperationCubit.paramProcessor = processor;
    processComponent = this;
    Processor.errorMessage = '';
    Processor.error = false;
  }

  void _handleUIChanges(BuildContext context) {
    Future.delayed(Duration.zero, () {
      if (context.mounted) lookForUIChanges(context);
    });
  }

  Widget buildWithoutKey(BuildContext context) {
    if (RuntimeProvider.of(context) == RuntimeMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        lookForUIChanges(context);
      });
    }

    return create(context);
  }

  bool forEachWithClones(final bool Function(Component) work) {
    if (work.call(this)) {
      return true;
    }
    forEachInComponentParameter(work, withClone: true);
    return false;
  }

  bool forEach(final bool Function(Component) work) {
    if (work.call(this)) {
      return true;
    }
    forEachInComponentParameter(work, withClone: false);
    return false;
  }

  GlobalKey? key(BuildContext context) {
    switch (RuntimeProvider.of(context)) {
      case RuntimeMode.edit:
        return GlobalObjectKey(this);
      case RuntimeMode.viewOnly:
        return GlobalObjectKey(uniqueId + id);
      case RuntimeMode.run || RuntimeMode.debug:
        return null;
      case RuntimeMode.preview:
        return GlobalObjectKey(uniqueId + id);
      case RuntimeMode.favorite:
        break;
    }
    return null;
  }

  bool forEachInComponentParameter(final bool Function(Component) work,
      {required bool withClone}) {
    for (final ComponentParameter componentParameter in componentParameters) {
      for (final component in componentParameter.components) {
        if (work.call(component)) {
          return true;
        }
        if (withClone) {
          if (component.forEachWithClones(work)) {
            return true;
          }
        } else {
          if (component.forEach(work)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Component getLastRoot() {
    Component? tracer = this;
    while (tracer!.parent != null) {
      tracer = tracer.parent;
    }
    return tracer;
  }

  bool isAttachedToScreen(Viewable screen) {
    return cloneElements.any((e) => screen.rootComponent == e.getLastRoot());
  }

  Component? getRootCustomComponent(
      FVBProject flutterProject, Viewable screen) {
    dynamic _tracer = this, _root = this;
    while (_tracer != null && _tracer is! CustomComponent) {
      _root = _tracer;
      _tracer = _tracer.parent;
    }

    for (final custom in flutterProject.customComponents) {
      if (custom.rootComponent == _root) {
        return custom;
      }
    }
    return screen.rootComponent;
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
          (comp.child as CustomComponent).rootComponent ==
              reversedTree[i - 1]) {
        logger('======= TRACER FIND CUSTOM ROOT ${comp.child?.name}');
        return comp.child;
      } else if (comp is MultiHolder) {
        for (final childComp in comp.children) {
          if (childComp is CustomComponent &&
              childComp.rootComponent == reversedTree[i - 1]) {
            logger('======= TRACER FIND CUSTOM ROOT ${childComp.name}');
            return childComp;
          }
        }
      } else if (comp is CustomNamedHolder) {
        for (final childComp in comp.childMap.values) {
          if (childComp is CustomComponent &&
              childComp.rootComponent == reversedTree[i - 1]) {
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
          (comp.child as CustomComponent).rootComponent ==
              reversedTree[i + 1]) {
        logger('======= TRACER FIND CUSTOM ROOT ${comp.child?.name}');
        return comp.child;
      } else if (comp is MultiHolder) {
        for (final childComp in comp.children) {
          if (childComp is CustomComponent &&
              childComp.rootComponent == reversedTree[i + 1]) {
            logger('======= TRACER FIND CUSTOM ROOT ${childComp.name}');
            return childComp;
          }
        }
      } else if (comp is CustomNamedHolder) {
        for (final childComp in comp.childMap.values) {
          if (childComp is CustomComponent &&
              childComp.rootComponent == reversedTree[i + 1]) {
            logger('======= TRACER FIND CUSTOM ROOT ${childComp.name}');
            return childComp;
          }
        }
      }
    }
    return _root;
  }

  Offset? _position(RenderObject object, RenderBox ancestorRenderBox) {
    if (object.parent != null) {
      if (object is RenderBox) {
        return object.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);
      } else {
        if (object is RenderSliver) {
          return object.paintBounds.topLeft;
        } else {
          throw Exception('NOT HANDLED POSITION FOR $name => ${object}');
        }
      }
    }
    return null;
  }

  Size _size(RenderObject object) {
    if (object is RenderBox) {
      try {
        return object.size;
      } catch (e) {
        sl<SelectionCubit>().showError(
            this, 'RenderBox has no size', AnalysisErrorType.overflow);
        throw e;
      }
    } else if (object is RenderSliver) {
      try {
        return object.paintBounds.size;
      } catch (e) {
        sl<SelectionCubit>().showError(
            this, 'SliverBox has no size', AnalysisErrorType.overflow);
        throw e;
      }
    } else {
      throw Exception('NOT HANDLED SIZE FOR $name => ${object}');
    }
  }

  int _depth(RenderObject object) {
    if (object is RenderBox) {
      return object.depth;
    } else if (object is RenderSliver) {
      return object.depth;
    } else {
      throw Exception('NOT HANDLED DEPTH FOR $name => ${object}');
    }
  }

  bool _attached(RenderObject object) {
    if (object is RenderBox) {
      return object.attached;
    } else if (object is RenderSliver) {
      return object.attached;
    } else {
      throw Exception('NOT HANDLED POSITION FOR $name => ${object}');
    }
  }

  void updateBoundary(Viewable screen) {
    if (GlobalObjectKey(this).currentContext == null) {
      return;
    }
    final RenderObject object = GlobalObjectKey(this)
        .currentContext!
        .findRenderObject() as RenderObject;
    final ancestorRenderBox = GlobalObjectKey(screen.id)
        .currentContext!
        .findRenderObject() as RenderBox;
    Offset? position = _position(object, ancestorRenderBox);
    if (position == null) {
      return;
    }
    final size = _size(object);
    this.boundary =
        Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    depth = _depth(object);
  }

  void lookForUIChanges(BuildContext context,
      {bool initialCheck = true, bool checkForNeighbors = true}) async {
    if (GlobalObjectKey(this).currentContext == null) {
      return;
    }
    final screen = ViewableProvider.maybeOf(context);
    if (screen == null) {
      return;
    }
    final RenderObject object = GlobalObjectKey(this)
        .currentContext!
        .findRenderObject() as RenderObject;
    final ancestorRenderBox = GlobalObjectKey(screen.id)
        .currentContext!
        .findRenderObject() as RenderBox;
    Offset? position = _position(object, ancestorRenderBox);
    if (position == null) {
      return;
    }
    int sameCount = 1;
    final count =
        (boundaryRepaintDelay == null ? 1 : (boundaryRepaintDelay! / 10));
    while (sameCount <= count) {
      final size = _size(object);
      if (boundary != null) {
        sameCount++;
      }
      final b =
          Rect.fromLTWH(position!.dx, position.dy, size.width, size.height);
      depth = _depth(object);
      // if (context.mounted)
      if (b != this.boundary) {
        sl<VisualBoxCubit>().visualUpdated(screen);
      }
      this.boundary = b;
      await Future.delayed(const Duration(milliseconds: 10));
      if (_attached(object)) {
        position = _position(object, ancestorRenderBox);
      } else {
        break;
      }
    }
  }

  Widget create(BuildContext context);

  void searchTappedComponent(Offset offset, Set<Component> components) {
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

  Component clone(parent, {required bool deepClone, required bool connect}) {
    if (!componentList.containsKey(name)) {
      return CNotRecognizedWidget();
    }
    final comp = componentList[name]!();
    if (comp is Clickable) {
      if (deepClone) {
        (comp as Clickable).actionList =
            (this as Clickable).actionList.map((e) => e.clone()).toList();
      } else {
        (comp as Clickable).actionList = (this as Clickable).actionList;
      }
    }
    if (comp is FVBPainter) {
      if (deepClone) {
        (comp as FVBPainter).paintObjects.clear();
        (comp as FVBPainter)
            .paintObjects
            .addAll((this as FVBPainter).paintObjects.map((e) => e.clone));
      } else {
        (comp as FVBPainter).paintObjects = (this as FVBPainter).paintObjects;
      }
    }
    if (deepClone) {
      for (int i = 0; i < parameters.length; i++) {
        if (comp.parameters[i] is ComponentParameter) {
          final param = comp.parameters[i] as ComponentParameter;
          param.parent = comp;
          param.components.addAll(
            (parameters[i] as ComponentParameter).components.map(
                  (e) =>
                      e.clone(param, deepClone: deepClone, connect: deepClone),
                ),
          );
        } else {
          comp.parameters[i].cloneOf(parameters[i], connect);
        }
      }
      for (int i = 0; i < defaultParam.length; i++) {
        if (defaultParam[i] != null) {
          comp.defaultParam[i]?.cloneOf(defaultParam[i]!, connect);
        }
      }
    } else {
      cloneComponentParam(
          ComponentParameter componentParameter, ComponentParameter param) {
        componentParameter.parent = comp;
        componentParameter.components.addAll(param.components
            .map((e) => e.clone(param, deepClone: false, connect: true)));
        return componentParameter;
      }

      comp.parameters = List.generate(parameters.length, (index) {
        if (parameters[index] is! ComponentParameter) {
          return parameters[index];
        } else {
          return cloneComponentParam(
              comp.parameters[index] as ComponentParameter,
              parameters[index] as ComponentParameter);
        }
      });
      for (int i = 0; i < defaultParam.length; i++)
        comp.defaultParam[i] = defaultParam[i];
    }
    if (!deepClone) {
      comp.cid = id;
    }
    if (!deepClone && connect) {
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
    if (cloneOf == null) {
      return this;
    }
    return cloneOf;
  }
}

abstract class MultiHolder extends Component {
  List<Component> children = [];

  MultiHolder(String name, List<Parameter> parameters,
      {List<ParameterRuleModel>? rules,
      ComponentDefaultParamConfig? defaultParamConfig})
      : super(name, parameters,
            rules: rules, defaultParamConfig: defaultParamConfig);

  Axis get direction => Axis.vertical;

  @override
  String code({bool clean = true}) {
    final middle = generateParametersCode(clean);

    String name = this.name;
    if (!clean) {
      name += '[id=$id]';
    }
    String childrenCode = '';
    for (final Component comp in children) {
      final String ccode = comp.code(clean: clean);
      if (ccode.isNotEmpty) {
        childrenCode += '${ccode},';
      }
    }
    return withState('$name(${middle}children:[$childrenCode],)', clean);
  }

  @override
  bool forEachWithClones(bool Function(Component) work) {
    if (work.call(this)) {
      return true;
    }
    for (final child in children) {
      if (child.forEachWithClones(work)) {
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
    for (final child in children) {
      if (child.forEach(work)) {
        return true;
      }
    }
    if (forEachInComponentParameter(work, withClone: false)) {
      return true;
    }
    return false;
  }

  void addChild(Component component, {int? index}) {
    if (index == null) {
      children.add(component);
    } else {
      children.insert(index, component);
    }
    component.setParent(this);
    if (component is CustomComponent) {
      component.rootComponent?.parent = this;
    }
    cloneElements.forEach((element) {
      (element as MultiHolder).addChild(
          component.clone(element, connect: true, deepClone: false),
          index: index);
    });
  }

  int removeChild(Component component) {
    final index = children.indexOf(component);
    component.setParent(null);
    children.removeAt(index);
    getAllClones().forEach((element) {
      (element as MultiHolder).children.removeAt(index);
    });
    return index;
  }

  void replaceChild(Component old, Component component) {
    component.setParent(this);
    final index = children.indexOf(old);
    children.removeAt(index);
    children.insert(index, component);
    if (component is CustomComponent) {
      component.rootComponent?.parent = this;
    }
    getAllClones().forEach((element) {
      (element as MultiHolder).children.removeAt(index);
      (element).children.insert(
          index, component.clone(null, deepClone: false, connect: true));
    });
  }

  @override
  void searchTappedComponent(Offset offset, Set<Component> components) {
    if (boundary?.contains(offset) ?? false) {
      if (this is CIndexedStack) {
        final index = (this as CIndexedStack).index;
        if (index >= 0) {
          children[index].searchTappedComponent(offset, components);
        }
      } else {
        for (final child in children) {
          child.searchTappedComponent(offset, components);
        }
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
  Component clone(parent, {bool deepClone = false, bool connect = false}) {
    final comp = super.clone(parent, deepClone: deepClone, connect: connect)
        as MultiHolder;
    comp.children = children
        .map((e) => e.clone(comp, deepClone: deepClone, connect: connect))
        .toList();
    return comp;
  }

  @override
  int get type => 2;

  @override
  int get childCount => -1;
}

abstract class Holder extends Component {
  Component? _child;
  bool required;

  Holder(String name, List<Parameter> parameters,
      {this.required = false,
      super.boundaryRepaintDelay,
      List<ParameterRuleModel>? rules,
      ComponentDefaultParamConfig? defaultParamConfig})
      : super(name, parameters,
            rules: rules, defaultParamConfig: defaultParamConfig);

  Component? get child => _child;

  set child(Component? comp) => _child = comp;

  void updateChild(Component? child) {
    // this.child?.setParent(null);
    this._child = child;
    if (child != null) {
      child.setParent(this);
    }
    cloneElements.forEach((element) {
      (element as Holder)
          .updateChild(child?.clone(element, deepClone: false, connect: true));
    });
  }

  @override
  bool forEachWithClones(bool Function(Component) work) {
    if (work.call(this)) {
      return true;
    }
    if (child != null) {
      if (child!.forEachWithClones(work)) {
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
    if (child != null) {
      if (child!.forEach(work)) {
        return true;
      }
    }

    if (forEachInComponentParameter(work, withClone: false)) {
      return true;
    }
    return false;
  }

  @override
  void searchTappedComponent(
      final Offset offset, final Set<Component> components) {
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
    final middle = generateParametersCode(clean);
    String name = this.name;
    if (!clean) {
      name = metaCode(name);
    }
    if (child == null) {
      if (!required) {
        return withState('$name($middle)', clean);
      } else {
        return withState('$name(${middle}child:Offstage(),)', clean);
      }
    }
    return withState(
        '$name(${middle}child:${child!.code(clean: clean)})', clean);
  }

  @override
  Component clone(parent, {bool deepClone = false, bool connect = false}) {
    final comp =
        super.clone(parent, deepClone: deepClone, connect: connect) as Holder;
    comp.updateChild(
        child?.clone(comp, deepClone: deepClone, connect: connect));
    return comp;
  }

  @override
  int get type => 3;

  @override
  int get childCount => 1;
}

abstract class ClickableHolder extends Holder with Clickable {
  ClickableHolder(
    String name,
    List<Parameter> parameters, {
    super.defaultParamConfig,
    super.boundaryRepaintDelay,
  }) : super(
          name,
          parameters,
        );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: RuntimeProvider.of(context) != RuntimeMode.run,
      child: super.build(context),
    );
  }
}

abstract class ClickableComponent extends Component with Clickable {
  ClickableComponent(String name, List<Parameter> parameters,
      {ComponentDefaultParamConfig? config})
      : super(name, parameters, defaultParamConfig: config);

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
        (this as Component).forEachWithClones((final Component component) {
          component.lookForUIChanges(context, initialCheck: false);
          return false;
        });
      });
    }

    return scrollController;
  }
}
mixin Clickable {
  List<FVBFunction> functions = [];
  List<ActionModel> actionList = [];
  late Processor _processor;

  void methods(List<FVBFunction> function) {
    functions.addAll(function);
    _processor = Processor.build(name: (this as Component).name);
  }

  void test() {
    _processor.parentProcessor = OperationCubit.paramProcessor;
    final processor = Processor(
        scopeName: (this as Component).name,
        parentProcessor: _processor.parentProcessor!
            .clone(Processor.testConsoleCallback, Processor.testOnError, false),
        consoleCallback: Processor.testConsoleCallback,
        onError: Processor.testOnError);
    for (final fun1 in functions) {
      processor.functions.remove(fun1.name);
    }
    for (final ActionModel action in actionList) {
      if (action is CustomAction) {
        final oldError = Processor.error;
        processor.executeCode(action.arguments[0], declarativeOnly: true);
        _processor.executeCode(action.arguments[0], declarativeOnly: true);
        final cubit = sl<SelectionCubit>();
        if (!oldError &&
            Processor.errorMessage.isNotEmpty &&
            !_processor.errorSuppress &&
            processComponent != null) {
          cubit.showError(
              processComponent!, Processor.errorMessage, AnalysisErrorType.code,
              action: action);
        }
      }
    }
  }

  String get defaultCode {
    final code = functions.map((function) => '''
           ${DataType.dataTypeToCode(function.returnType)}${function.canReturnNull ? '?' : ''} ${function.name}(${function.arguments.map((e) => '${DataType.dataTypeToCode(e.dataType)} ${e.name}').join(',')}){
           ${function.code == null ? '' : function.code!}
           }
          ''').join('\n');
    return formatter.format(code);
  }

  performCustomAction(
      BuildContext context, ActionModel action, List<dynamic>? arguments,
      {String? name, final Processor? processor}) {
    final function = name != null
        ? functions.firstWhereOrNull((e) => e.name == name)
        : (functions.isNotEmpty ? functions.first : null);
    if (function == null) {
      return;
    }

    _processor.parentProcessor =
        processor ?? ProcessorProvider.maybeOf(context)!;
    _processor.executeCode(action.arguments[0],
        declarativeOnly: true, type: OperationType.regular);
    if (_processor.functions.containsKey(function.name)) {
      final out = _processor.functions[function.name]!
          .execute(_processor, null, arguments ?? []);
      return out;
    }
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
        /// TODO: Check if need backslash N
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

  void fromMetaCodeToAction(String code, final FVBProject? project) {
    if (code.startsWith('CA')) {
      final endIndex = CodeOperations.findCloseBracket(
          code, 2, '<'.codeUnits.first, '>'.codeUnits.first);
      actionList.add(CustomAction(
          code:
              String.fromCharCodes(base64Decode(code.substring(3, endIndex)))));
    } else if (code.startsWith('NPISA')) {
      final name = code.substring(code.indexOf('<') + 1, code.indexOf('>'));
      actionList.add(NewPageInStackAction(getUIScreenWithName(name, project)));
    } else if (code.startsWith('RCPISA')) {
      final name = code.substring(code.indexOf('<') + 1, code.indexOf('>'));
      actionList.add(
          ReplaceCurrentPageInStackAction(getUIScreenWithName(name, project)));
    } else if (code.startsWith('NBISA')) {
      actionList.add(GoBackInStackAction());
    } else if (code.startsWith('SBSISA')) {
      final name = code.substring(code.indexOf('<') + 1, code.indexOf('>'));
      actionList.add(
          ShowBottomSheetInStackAction(getUIScreenWithName(name, project)));
    } else if (code.startsWith('HBSISA')) {
      // actionList.add(HideBottomSheetInStackAction());
    } else if (code.startsWith('SSBA')) {
      final list = getParams(code.substring(4));
      final action = ShowSnackBarAction();
      if (list != null) {
        (action.arguments[0] as Parameter).fromCode(list[0], project);
        (action.arguments[1] as Parameter).fromCode(list[1], project);
      }
      actionList.add(action);
    } else if (code.startsWith('SDISA')) {
      final list = getParams(code.substring(5));
      actionList.add(ShowDialogInStackAction(args: list));
    } else if (code.startsWith('SCDISA')) {
      final name = code.substring(code.indexOf('<') + 1, code.indexOf('>'));
      for (final Screen uiScreen in project?.screens ?? []) {
        if (uiScreen.name == name) {
          break;
        }
      }
      // actionList.add(ShowCustomDialogInStackAction(comp: selectedUiScreen));
    }
  }

  Screen? getUIScreenWithName(String name, FVBProject? flutterProject) {
    for (final Screen uiScreen in flutterProject?.screens ?? []) {
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
      {List<ParameterRuleModel>? rules, ComponentDefaultParamConfig? config})
      : super(name, parameters, rules: rules, defaultParamConfig: config) {
    for (final child in childMap) {
      this.childMap[child] = null;
    }
    for (final children in childrenMap) {
      this.childrenMap[children] = [];
    }
  }

  get direction => Axis.vertical;

  void addOrUpdateChildWithKey(String key, Component? component, {int? index}) {
    if (childMap.containsKey(key)) {
      childMap[key]?.setParent(null);
      childMap[key] = component;
      component?.setParent(this);
    } else {
      if (index != null) {
        childrenMap[key]!.removeAt(index);
      }
      if (component != null) {
        if (index != null) {
          childrenMap[key]!.insert(index, component);
        } else {
          childrenMap[key]!.add(component);
        }
        component.setParent(this);
      }
    }
    cloneElements.forEach((element) {
      (element as CustomNamedHolder).addOrUpdateChildWithKey(
          key, component?.clone(element, deepClone: false, connect: true));
    });
  }

  void updateChild(Component oldComponent, Component? component) {
    oldComponent.setParent(null);
    component?.setParent(this);
    String? key;
    for (final entry in childMap.entries) {
      if (entry.value == oldComponent) {
        childMap[entry.key] = component;
        key = entry.key;
        break;
      }
    }
    int index = -1;
    if (key == null) {
      for (final entry in childrenMap.entries) {
        if ((index = entry.value.indexOf(oldComponent)) != -1) {
          entry.value.removeAt(index);
          if (component != null) {
            entry.value.insert(index, component);
          }
          key = entry.key;
          break;
        }
      }
    }
    if (key != null) {
      cloneElements.forEach((element) {
        if (index >= 0) {
          (element as CustomNamedHolder).updateChild(
              element.childrenMap[key]![index],
              component?.clone(element, deepClone: false, connect: true));
        } else {
          (element as CustomNamedHolder).updateChild(element.childMap[key]!,
              component?.clone(element, deepClone: false, connect: true));
        }
      });
    }
  }

  @override
  bool forEachWithClones(bool Function(Component) work) {
    if (work.call(this)) {
      return true;
    }
    // if(this is BuilderComponent){
    //   for(final list in (this as BuilderComponent).builtList.values){
    //    for(final v in list){
    //      if(work.call(v)){
    //        return true;
    //      }
    //    }
    //   }
    // }
    for (final child in childMap.values) {
      if (child != null) {
        if (child.forEachWithClones(work)) {
          return true;
        }
      }
    }
    for (final children in childrenMap.values) {
      for (final child in children) {
        if (child.forEachWithClones(work)) {
          return true;
        }
      }
    }
    if (this is BuilderComponent) {
      for (final list in (this as BuilderComponent).builtList.values) {
        for (final comp in list) {
          if (comp.forEachWithClones(work)) {
            return true;
          }
        }
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
    for (final child in childMap.values) {
      if (child != null) {
        if (child.forEach(work)) {
          return true;
        }
      }
    }
    for (final children in childrenMap.values) {
      for (final child in children) {
        if (child.forEach(work)) {
          return true;
        }
      }
    }

    if (forEachInComponentParameter(work, withClone: false)) {
      return true;
    }
    return false;
  }

  @override
  void searchTappedComponent(Offset offset, Set<Component> components) {
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
        for (final child in childMap.entries) {
          if (child.value == null ||
              (child.key == 'drawer' && !fvbNavigationBloc.model.drawer)) {
            continue;
          }
          child.value?.searchTappedComponent(offset, components);
        }
        for (final children in childrenMap.values) {
          for (final child in children) {
            child.searchTappedComponent(offset, components);
          }
        }
      }
      components.add(this);
    }
  }

  @override
  String code({bool clean = true}) {
    try {
      final middle = generateParametersCode(clean);
      String name = this.name;
      if (!clean) {
        name = metaCode(name);
      }
      String childrenCode = '';
      for (final child in childMap.keys) {
        if (childMap[child] != null) {
          childrenCode += '$child:${childMap[child]!.code(clean: clean)},';
        }
      }

      for (final child in childrenMap.keys) {
        if (childrenMap[child]?.isNotEmpty ?? false) {
          childrenCode +=
              '$child:[${childrenMap[child]!.map((e) => (e.code(clean: clean) + ',')).join('')}],';
        }
      }
      if (this is CMaterialApp && clean && _collection.project != null) {
        childrenCode +=
            AppConfigCode.generateMaterialCode(_collection.project!);
      }
      return withState('$name($middle$childrenCode)', clean);
    } on Exception catch (e) {
      print('$name ${e.toString()}');
    }
    return '';
  }

  @override
  Component clone(parent, {bool deepClone = false, bool connect = false}) {
    final comp = super.clone(parent, deepClone: deepClone, connect: connect)
        as CustomNamedHolder;
    comp.childMap = childMap.map((key, value) => MapEntry(
        key, value?.clone(comp, deepClone: deepClone, connect: connect)));
    comp.childrenMap = childrenMap.map(
      (key, value) => MapEntry(
        key,
        value
            .map((e) => e.clone(comp, deepClone: deepClone, connect: connect))
            .toList(),
      ),
    );
    return comp;
  }

  @override
  int get type => 4;

  MapEntry<String, bool>? getKey(Component component) {
    String? compKey;
    bool fromChildMap = true;
    for (final String key in childMap.keys) {
      if (childMap[key] == component) {
        compKey = key;
        fromChildMap = true;
        break;
      }
    }
    if (compKey == null) {
      for (final String key in childrenMap.keys) {
        if (childrenMap[key]!.contains(component)) {
          compKey = key;
          fromChildMap = false;
          break;
        }
      }
    }
    return compKey != null
        ? MapEntry<String, bool>(compKey, fromChildMap)
        : null;
  }

  String? replaceChild(Component oldComp, Component? comp) {
    final entry = getKey(oldComp);
    final compKey = entry?.key;
    final fromChildMap = entry?.value ?? true;
    if (compKey != null) {
      if (fromChildMap) {
        childMap[compKey] = comp;
        comp?.setParent(this);
        cloneElements.forEach((element) => (element as CustomNamedHolder)
            .addOrUpdateChildWithKey(compKey,
                comp?.clone(element, deepClone: false, connect: true)));
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
        cloneElements.forEach((element) => (element as CustomNamedHolder)
            .addOrUpdateChildWithKey(
                compKey, comp?.clone(element, deepClone: false, connect: true),
                index: index));
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
    return customComponent.rootComponent
            ?.clone(parent, deepClone: false, connect: false)
            .create(context) ??
        Container();
  }
}

enum UpdateType { add, remove }

class StreamComponent extends Component {
  final Stream<Component> stream;

  StreamComponent(this.stream) : super('StreamComponent', []);

  @override
  Widget create(BuildContext context) {
    return StreamBuilder<Component>(
      builder: (context, value) {
        if (value.hasData && value.data != null) {
          return value.data!.build(context);
        }
        return const Offstage();
      },
      stream: stream,
    );
  }
}

class ComponentWidget extends StatelessWidget {
  final Widget child;
  final Component component;

  const ComponentWidget(
      {Key? key, required this.child, required this.component})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget output = component.autoHandleKey
        ? KeyedSubtree(
            child: child,
            key: component.key(context),
          )
        : child;

    if (component.defaultParam[0] != null ||
        component.defaultParam[1] != null) {
      final width = component.defaultParam[0]?.value;
      final height = component.defaultParam[1]?.value;
      if (width != null || height != null) {
        output = SizedBox(
          width: width,
          height: height,
          child: output,
        );
      }
    }
    if (component.defaultParam[2] != null) {
      final value = component.defaultParam[2]!.value;
      if (value != null) {
        output = Padding(
          padding: value,
          child: output,
        );
      }
    }
    if (component.defaultParam[3] != null &&
        component.defaultParam[3]!.compiler.code.isNotEmpty) {
      final value = component.defaultParam[3]!.value;
      if (value == false) {
        output = Visibility(
          visible: value,
          child: output,
        );
      }
    }
    if (component.defaultParam[4] != null) {
      final value = component.defaultParam[4]!.value;
      if (value != null) {
        output = Align(
          alignment: value,
          child: output,
        );
      }
    }
    final mode = RuntimeProvider.of(context);
    if (component.defaultParam[5] != null &&
        mode != RuntimeMode.favorite &&
        mode != RuntimeMode.preview) {
      if ((component.defaultParam[5] as ComplexParameter).enable) {
        final state = context.read<StateManagementBloc>().state;
        output = output.animate(
            delay:
                (component.defaultParam[5] as ComplexParameter).params[0].value,
            key: (RuntimeProvider.of(context) == RuntimeMode.edit &&
                    state is StateManagementUpdatedState &&
                    state.id == component.id)
                ? UniqueKey()
                : null);
        for (final p in ((component.defaultParam[5] as ComplexParameter)
                .params[1] as ListParameter)
            .params) {
          final duration = (p as ComplexParameter).params[1].value;
          final delay = p.params[2].value;
          final curve = p.params[3].value;
          switch (p.params[0].rawValue) {
            case 'slideLeftToRight':
              output = (output as Animate).slideX(
                  begin: -1,
                  end: 0,
                  duration: duration,
                  delay: delay,
                  curve: curve);
              break;
            case 'slideRightToLeft':
              output = (output as Animate).slideX(
                  begin: 1,
                  end: 0,
                  duration: duration,
                  delay: delay,
                  curve: curve);
              break;
            case 'slideTopToBottom':
              output = (output as Animate).slideY(
                  begin: -1,
                  end: 0,
                  duration: duration,
                  delay: delay,
                  curve: curve);
              break;
            case 'slideBottomToTop':
              output = (output as Animate).slideY(
                  begin: 1,
                  end: 0,
                  duration: duration,
                  delay: delay,
                  curve: curve);
              break;

            case 'scaleUpHorizontal':
              output = (output as Animate).scaleX(
                duration: duration,
                delay: delay,
                curve: curve,
                begin: 0,
                end: 1,
              );
              break;
            case 'scaleDownHorizontal':
              output = (output as Animate).scaleX(
                duration: duration,
                delay: delay,
                curve: curve,
                begin: 2,
                end: 1,
              );
              break;
            case 'scaleUpVertical':
              output = (output as Animate).scaleY(
                duration: duration,
                delay: delay,
                curve: curve,
                begin: 0,
                end: 1,
              );
              break;
            case 'scaleDownVertical':
              output = (output as Animate).scaleY(
                duration: duration,
                delay: delay,
                curve: curve,
                begin: 2,
                end: 1,
              );
              break;
            case 'scaleUp':
              output = (output as Animate).scaleXY(
                duration: duration,
                delay: delay,
                curve: curve,
                begin: 0,
                end: 1,
              );
              break;

            case 'scaleDown':
              output = (output as Animate).scaleXY(
                duration: duration,
                delay: delay,
                curve: curve,
                begin: 2,
                end: 1,
              );
              break;
            case 'fadeIn':
              output = (output as Animate).fadeIn(
                duration: duration,
                delay: delay,
                curve: curve,
              );
              break;
            case 'fadeOut':
              output = (output as Animate).fadeOut(
                duration: duration,
                delay: delay,
                curve: curve,
              );
              break;

            case 'saturate':
              output = (output as Animate).saturate(
                duration: duration,
                delay: delay,
                curve: curve,
              );
              break;
            case 'desaturate':
              output = (output as Animate).desaturate(
                duration: duration,
                delay: delay,
                curve: curve,
              );
              break;
          }
        }
        Future.delayed((output as Animate).duration).then((value) {
          component.forEach((p0) {
            p0._handleUIChanges(context);
            return false;
          });
        });
      }
    }

    return output;
  }
}

class StatefulComponentWidget extends StatefulWidget {
  final Widget Function(BuildContext) child;
  final Controller component;

  const StatefulComponentWidget(
      {Key? key, required this.child, required this.component})
      : super(key: key);

  @override
  State<StatefulComponentWidget> createState() => _StatefulComponentState();
}

class _StatefulComponentState extends State<StatefulComponentWidget>
    with TickerProviderStateMixin {
  @override
  void didChangeDependencies() {
    widget.component.applyValues(context, this);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final comp = (widget.component as Component);
    return ComponentWidget(
      child: widget.child.call(context),
      component: comp,
    );
  }
}
