import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_classes.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';

import '../bloc/state_management/state_management_bloc.dart';
import '../code_operations.dart';
import '../components/custom/load_data.dart';
import '../components/holder_impl.dart';
import '../injector.dart';
import '../parameter/parameters_list.dart';
import '../runtime_provider.dart';
import 'fvb_ui_core/component/component_model.dart';
import 'parameter_info_model.dart';
import 'parameter_model.dart';

abstract class BuilderComponent extends CustomNamedHolder {
  // LocalModel? model;
  final Map<String, List<Component>> builtList = {};
  final Map<String, FVBFunction> functionMap;
  Map<String, Processor> processorMap = {};
  final Map<String, DataType> genericValues = {};

  // late SimpleParameter<int> itemLengthParameter;

  BuilderComponent(String name, List<Parameter> parameters,
      {required List<String> childBuilder,
      required List<String> childrenBuilder,
      required this.functionMap,
      List<String>? generics,
      ComponentDefaultParamConfig? config})
      : super(name, parameters, childBuilder, childrenBuilder, config: config) {
    for (final generic in generics ?? []) {
      genericValues[generic] = DataType.fvbDynamic;
    }
    // itemLengthParameter =
    //     SimpleParameter<int>(name: countName, defaultValue: 5, required: true);
  }

  @override
  Component clone(parent, {bool deepClone = false, bool connect = false}) {
    final clone = (super.clone(parent, deepClone: deepClone, connect: connect)
        as BuilderComponent);
    // clone.model = model;
    // clone.itemLengthParameter = deepClone
    //     ? (SimpleParameter<int>()..cloneOf(itemLengthParameter))
    //     : itemLengthParameter;
    clone.processorMap = processorMap;
    if (deepClone) {
      clone.functionMap.clear();
      clone.functionMap.addAll(
          functionMap.map((key, value) => MapEntry(key, value.clone())));
    } else {
      clone.functionMap.clear();
      clone.functionMap.addAll(functionMap);
    }
    return clone;
  }

  Widget builder(BuildContext context, String name, List<dynamic> args,
      {Component? Function()? defaultComp}) {
    final Component child = childMap[name] ??
        childrenMap[name]?[0] ??
        defaultComp?.call() ??
        CContainer();
    // if (model != null) {
    //   for (int i = 0; i < (model?.variables.length ?? 0); i++) {
    //     ComponentOperationCubit.processor
    //         .localVariables[model!.variables[i].name] = model!.values[index][i];
    //   }
    // }
    final parent = ProcessorProvider.maybeOf(context) ??
        ViewableProvider.maybeOf(context)?.processor ??
        collection.project!.processor;
    final processor = Processor.build(
      name: name,
      parent: parent,
      generics: genericValues,
    );
    final function = functionMap[name];
    function?.processor = processor;
    final component = child.clone(this, deepClone: false, connect: true);
    final index = args.isNotEmpty ? (args.last is int ? args.last : 0) : 0;
    final list = builtList[name]??[];
    if (index < list.length) {
      list.removeAt(index);
      list.insert(index, component);
    } else {
      list.add(component);
    }
    if (Processor.error) {
      return Container();
    }
    if (function != null) {
      function.execute(parent, null, args,
          defaultProcessor: processor,
          filtered: Processor.cleanCode(function.code ?? '', processor));
    }
    function?.processor = processor;
    processorMap[name] = processor;
    if (RuntimeProvider.of(context) == RuntimeMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        lookForUIChanges(context);
      });
    }
    return ProcessorProvider(
      processor: processor,
      child: Builder(builder: (context) {
        return component.build(context);
      }),
    );
  }

  void init() {
    processorMap.clear();
    for (final child in childMap.keys) {
      builtList[child] = [];
    }

    childMap.forEach((key, value) {
      value?.cloneElements.clear();
    });
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   for (int i = 0; i < (model?.variables.length ?? 0); i++) {
    //     ComponentOperationCubit.codeProcessor
    //         .modelVariables.remove(model!.variables[i].name);
    //   }
    //   ComponentOperationCubit.codeProcessor.modelVariables.remove('index');
    //   ComponentOperationCubit.codeProcessor.modelVariables.remove('count');
    // });
  }

  @override
  String code({bool clean = true}) {
    try {
      final middle = generateParametersCode(clean);
      final String defaultCode = CContainer().code(clean: clean);
      final Map<String, String> itemsCode = childMap.map((key, value) =>
          MapEntry(key, (value?.code(clean: clean) ?? defaultCode)));
      String name = this.name;
      if (!clean) {
        name = metaCode(name);
      }
      // final List<DynamicVariableModel> usedVariables = [];

      if (clean) {
        // itemCount = ', itemCount:${model?.listVariableName}.length,';
        // if (model != null) {
        //   itemCount = ', itemCount:${model?.listVariableName}.length,';
        //   for (String itemCode in itemsCode.values) {
        //     int start = 0;
        //     int gotIndex = -1;
        //     logger('ITEM CODE $itemCode');
        //     while (start != -1 && start < itemCode.length) {
        //       if (gotIndex == -1) {
        //         start = itemCode.indexOf('\${', start);
        //         logger('START ++ $start');
        //         if (start == -1) {
        //           break;
        //         }
        //         start += 2;
        //         gotIndex = start;
        //       } else {
        //         start = itemCode.indexOf('}', start);
        //         if (start == -1) {
        //           break;
        //         }
        //         String innerArea = itemCode.substring(gotIndex, start);
        //         if (model != null && model!.variables.isNotEmpty) {
        //           for (final variable in model!.variables) {
        //             innerArea = innerArea.replaceAll(variable.name,
        //                 '${model!.listVariableName}[index].${variable.name}');
        //             // if (!usedVariables.contains(variable)) {
        //             //   usedVariables.add(variable);
        //             // }
        //           }
        //           itemCode = itemCode.replaceRange(
        //               gotIndex - 2, start + 1, '\${$innerArea}');
        //           gotIndex = -1;
        //           start += 2;
        //           continue;
        //         }
        //       }
        //     }
        //   }
        //
        // }
        return withState('''$name($middle 
        ${itemsCode.entries.map((entry) => '${entry.key}:(${functionMap[entry.key]!.arguments.map((e) => !e.dataType.equals(DataType.fvbDynamic) ? '${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''} ${e.argName}' : e.name).join(', ')}){ ${functionMap[entry.key]!.code}  return ${entry.value};}').join(',')})''',
            clean);
      }
      return '''$name($middle 
        ${itemsCode.entries.map((entry) => '${entry.key}:(){`${functionMap[entry.key]?.code ?? ''}`return${entry.value};}').join(',')}),''';
      // return '$name(\n${middle}child:${child!.code(clean: clean)}\n)';
    } on Exception catch (e) {
      print('$name ${e.toString()}');
    }
    return '';
  }
}

FVBFunction get itemBuilderFunction => FVBFunction(
      'itemBuilder',
      '',
      [
        FVBArgument('context', dataType: DataType.fvbDynamic, nullable: false),
        FVBArgument('index', dataType: DataType.fvbInt, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

FVBFunction get builderFunction => FVBFunction(
      'builder',
      '',
      [
        FVBArgument('context', dataType: DataType.fvbDynamic, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

FVBFunction get onLoadFunction => FVBFunction(
      'onLoad',
      '',
      [
        FVBArgument('context', dataType: DataType.fvbDynamic, nullable: false),
        FVBArgument('data', dataType: DataType.fvbDynamic, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

FVBFunction get onLoadingFunction => FVBFunction(
      'onLoading',
      '',
      [
        FVBArgument('context', dataType: DataType.fvbDynamic, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

FVBFunction get onErrorFunction => FVBFunction(
      'onError',
      '',
      [
        FVBArgument('context', dataType: DataType.fvbDynamic, nullable: false),
        FVBArgument('error', dataType: DataType.string, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

FVBFunction get layoutBuilderFunction => FVBFunction(
      'builder',
      '',
      [
        FVBArgument('context', dataType: DataType.fvbDynamic, nullable: false),
        FVBArgument('constraints',
            dataType: DataType.fvbInstance('BoxConstraints'), nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

FVBFunction get stateFulBuilderFunction => FVBFunction(
      'builder',
      '',
      [
        FVBArgument('context', dataType: DataType.fvbDynamic, nullable: false),
        FVBArgument('setState2',
            dataType: DataType.fvbInstance('setState'), nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

get separatorBuilderFunction => FVBFunction(
      'separatorBuilder',
      '',
      [
        FVBArgument('context', dataType: DataType.fvbDynamic, nullable: false),
        FVBArgument('index', dataType: DataType.fvbInt, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

class CPageViewBuilder extends BuilderComponent with Controller, Clickable {
  CPageViewBuilder()
      : super('PageView.builder', [
          Parameters.itemLengthParameter,
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
          Parameters.enableParameter(true, true)
            ..withNamedParamInfoAndSameDisplayName('pageSnapping'),
          Parameters.scrollPhysicsParameter,
          Parameters.enableParameter(
            false,
          )
            ..val = false
            ..withNamedParamInfoAndSameDisplayName('reverse'),
        ], childBuilder: [
          'itemBuilder',
        ], childrenBuilder: [], functionMap: {
          'itemBuilder': itemBuilderFunction,
        }) {
    methods([
      FVBFunction('onPageChanged', null,
          [FVBArgument('index', dataType: DataType.fvbInt, nullable: false)],
          returnType: DataType.fvbVoid),
    ]);
    autoHandleKey = false;
    assign('controller', (__, _) => PageController(), 'PageController()');
  }

  @override
  Widget create(BuildContext context) {
    init();
    return PageView.builder(
      key: key(context),
      itemCount: parameters[0].value,
      scrollDirection: parameters[1].value,
      pageSnapping: parameters[2].value,
      physics: parameters[3].value,
      reverse: parameters[4].value,
      controller: values['controller']!,
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', [context, index]);
      },
      onPageChanged: (index) {
        perform(context, arguments: [index]);
      },
    );
  }
}

class ControlValue {
  final dynamic Function(BuildContext, TickerProvider) value;
  final String assignCode;

  ControlValue(this.value, this.assignCode);
}

abstract class ComponentControl {
  final String name;

  ComponentControl(this.name);
}

class SelectionControl extends ComponentControl {
  final List<String> Function() values;
  final String Function() value;
  final void Function(String) onSelection;

  SelectionControl(super.name, this.values, this.onSelection, this.value);
}

class ButtonControl extends ComponentControl {
  final Function(dynamic) onTap;
  final String Function(dynamic) buttonName;
  dynamic value;

  ButtonControl(super.name, this.buttonName, this.onTap);
}

mixin Controller {
  final Map<String, ControlValue> controlMap = {};
  final Map<String, dynamic> values = {};
  final List<ComponentControl> list = [];

  void controls(Iterable<ComponentControl> controls) {
    list.addAll(controls);
  }

  void assign(String key, dynamic Function(BuildContext, TickerProvider) value,
      String assignCode) {
    controlMap[key] = ControlValue(value, assignCode);
  }

  void applyValues(BuildContext context, TickerProvider async) {
    for (final entry in controlMap.entries) {
      values[entry.key] = entry.value.value.call(context, async);
    }
  }
}

class CBuilder extends BuilderComponent {
  CBuilder()
      : super('Builder', [], childBuilder: [
          'builder',
        ], childrenBuilder: [], functionMap: {
          'builder': builderFunction,
        });

  @override
  Widget create(BuildContext context) {
    init();
    return Builder(builder: (context) {
      return builder(context, 'builder', [context]);
    });
  }
}

class CDataLoaderWidget extends BuilderComponent with Controller {
  CDataLoaderWidget()
      : super('DataLoaderWidget', [
          Parameters.futureParameter(),
          ComplexParameter(
              name: 'Test',
              params: [
                Parameters.boolConfigParameter('Show Loading', false),
                Parameters.boolConfigParameter('Show Error', false),
              ],
              evaluate: (params) {},
              generateCode: false),
        ], childBuilder: [
          'onLoad',
          'onLoading',
          'onError',
        ], childrenBuilder: [], functionMap: {
          'onLoad': onLoadFunction,
          'onLoading': onLoadingFunction,
          'onError': onErrorFunction
        }, generics: [
          'T'
        ]) {
    controls([
      ButtonControl('Reload', (p0) => 'Reload', (p0) {
        sl<StateManagementBloc>().add(StateManagementRefreshEvent(
          id,
          RuntimeMode.edit,
        ));
      })
    ]);
    autoHandleKey = false;
  }

  @override
  void searchTappedComponent(Offset offset, Set<Component> components) {
    if (boundary?.contains(offset) ?? false) {
      final loading =
          ((parameters[1] as ComplexParameter).params[0] as BooleanParameter)
              .val;
      final showError =
          ((parameters[1] as ComplexParameter).params[1] as BooleanParameter)
              .val;
      for (final child in childMap.keys) {
        if ((loading == true && child == 'onLoading') ||
            (showError == true && child == 'onError') ||
            (showError != true && loading != true))
          for (final comp in builtList[child] ?? []) {
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
  String? get import => 'data_loader';

  @override
  Widget create(BuildContext context) {
    init();
    final future = parameters[0].value;
    return DataLoaderWidget(
      key: key(context),
      onLoad: (context, data) {
        return builder(context, 'onLoad', [context, data]);
      },
      code: CodeOperations.trim(parameters[0].compiler.code) ?? '',
      future: future,
      showLoading: (parameters[1] as ComplexParameter).params[0].value,
      showError: (parameters[1] as ComplexParameter).params[1].value,
      onLoading: (context) {
        return builder(context, 'onLoading', [context]);
      },
      onError: (BuildContext, String error) {
        return builder(context, 'onError', [context, error]);
      },
    );
  }
}

class CLayoutBuilder extends BuilderComponent {
  CLayoutBuilder()
      : super('LayoutBuilder', [], childBuilder: [
          'builder',
        ], childrenBuilder: [], functionMap: {
          'builder': layoutBuilderFunction,
        });

  @override
  Widget create(BuildContext context) {
    init();
    return LayoutBuilder(builder: (context, constraints) {
      return builder(context, 'builder', [
        context,
        FVBModuleClasses.fvbClasses['BoxConstraints']!
            .createInstance(collection.project!.processor, [constraints])
      ]);
    });
  }
}

class CStatefulBuilder extends BuilderComponent {
  CStatefulBuilder()
      : super('StatefulBuilder', [], childBuilder: [
          'builder',
        ], childrenBuilder: [], functionMap: {
          'builder': stateFulBuilderFunction,
        });

  @override
  Widget create(BuildContext context) {
    init();
    return StatefulBuilder(builder: (context, setState) {
      return builder(context, 'builder', [
        context,
        setStateFunction
          ..dartCall = (arguments, instance) {
            (arguments[0] as FVBFunction).execute(arguments.last, null, []);
            if (Processor.operationType == OperationType.regular) {
              setState(() {});
            }
          }
      ]);
    });
  }
}
