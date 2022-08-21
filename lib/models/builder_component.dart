import 'package:flutter/material.dart';
import '../common/compiler/code_processor.dart';
import '../common/compiler/processor_component.dart';
import 'parameter_info_model.dart';
import '../common/logger.dart';
import '../component_list.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../parameters_list.dart';
import 'component_model.dart';
import 'local_model.dart';
import 'parameter_model.dart';

abstract class BuilderComponent extends CustomNamedHolder {
  LocalModel? model;
  final Map<String, List<Component>> builtList = {};
  final Map<String, FVBFunction> functionMap;
  late SimpleParameter<int> itemLengthParameter;
  final String countName;

  BuilderComponent(String name, List<Parameter> parameters,
      {required List<String> childBuilder,
      required List<String> childrenBuilder,
      required this.functionMap,
      this.countName = 'itemCount'})
      : super(name, parameters, childBuilder, childrenBuilder) {
    itemLengthParameter =
        SimpleParameter<int>(name: countName, defaultValue: 5, required: true);
  }

  @override
  Component clone(Component? parent, {bool deepClone = false}) {
    final clone =
        (super.clone(parent, deepClone: deepClone) as BuilderComponent);
    clone.model = model;
    clone.itemLengthParameter = deepClone
        ? (SimpleParameter<int>()..cloneOf(itemLengthParameter))
        : itemLengthParameter;
    clone.parent = parent;
    clone.childMap =
        childMap.map((key, value) => MapEntry(key, value?.clone(clone)));
    clone.childrenMap = childrenMap.map((key, value) => MapEntry(
        key, value.map((e) => e.clone(clone)).toList(growable: false)));
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

  Widget builder(BuildContext context, String name, int index,
      {Component? Function()? defaultComp}) {
    final Component child = childMap[name] ??
        childrenMap[name]?[0] ??
        defaultComp?.call() ??
        CContainer();
    if (model != null) {
      for (int i = 0; i < (model?.variables.length ?? 0); i++) {
        ComponentOperationCubit.processor
            .localVariables[model!.variables[i].name] = model!.values[index][i];
      }
    }
    final parent = ProcessorProvider.maybeOf(context) ??
        ComponentOperationCubit.currentProject!.processor;
    final processor = CodeProcessor.build(name: name, processor: parent);
    final function = functionMap[name];
    final component = child.clone(this);
    if (index < builtList[name]!.length) {
      builtList[name]!.removeAt(index);
      builtList[name]!.insert(index, component);
    } else {
      builtList[name]!.add(component);
    }
    return ProcessorProvider(
      processor,
      Builder(builder: (context) {
        if (CodeProcessor.error) {
          return Container();
        }
        if (function != null) {
          function.execute(parent, null, [index],
              defaultProcessor: processor,
              filtered:
                  CodeProcessor.cleanCode(function.code ?? '', processor));
        }
        return component.build(context);
      }),
    );
  }

  void init() {
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
    final middle = parametersCode(clean);
    final String defaultCode = CContainer().code(clean: clean);
    final Map<String, String> itemsCode = childMap.map((key, value) =>
        MapEntry(key, (value?.code(clean: clean) ?? defaultCode)));
    String name = this.name;
    if (!clean) {
      name = metaCode(name);
    }
    // final List<DynamicVariableModel> usedVariables = [];

    String itemCount = '';
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
      final countCode = itemLengthParameter.code(clean);
      itemCount = countCode.isNotEmpty ? ', itemCount:$countCode,' : '';
      return withState(
          '''$name($middle 
        ${itemsCode.entries.map((entry) => '${entry.key}:(context,index){${functionMap[entry.key]?.code ?? ''} return ${entry.value};}').join(',')}''' +
              itemCount +
              '),',
          clean);
    }
    return '''$name($middle 
        ${itemsCode.entries.map((entry) => '${entry.key}:(){`${functionMap[entry.key]?.code ?? ''}`return${entry.value};}').join(',')}''' +
        itemCount +
        '),';
    // return '$name(\n${middle}child:${child!.code(clean: clean)}\n)';
  }

  int get count {
    final length = itemLengthParameter.value;
    if (model == null || length < model!.values.length) {
      return length;
    }
    return model!.values.length;
  }
}

get itemBuilderFunction => FVBFunction(
      'itemBuilder',
      '',
      [
        FVBArgument('index', dataType: DataType.fvbInt, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

get separatorBuilderFunction => FVBFunction(
      'separatorBuilder',
      '',
      [
        FVBArgument('index', dataType: DataType.fvbInt, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );

class CPageViewBuilder extends BuilderComponent with Controller, Clickable {
  CPageViewBuilder()
      : super('PageView.builder', [
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
          Parameters.enableParameter()
            ..val = true
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('pageSnapping'),
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
  }

  @override
  Widget create(BuildContext context) {
    assign('controller', PageController(), 'PageController()');
    init();
    return PageView.builder(
      scrollDirection: parameters[0].value,
      pageSnapping: parameters[1].value,
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', index);
      },
      controller: controlMap['controller']!.value,
      onPageChanged: (index) {
        perform(context, arguments: [index]);
      },
      itemCount: count,
    );
  }
}

class ControlValue {
  final dynamic value;
  final String assignCode;
  ControlValue(this.value, this.assignCode);
}

class Controller {
  final Map<String, ControlValue> controlMap = {};
  void assign(String key, dynamic value, String assignCode) {
    controlMap[key] = ControlValue(value, assignCode);
  }
}

class CListViewBuilder extends BuilderComponent with FVBScrollable {
  CListViewBuilder()
      : super('ListView.builder', [
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
    Parameters.paddingParameter(),
          Parameters.enableParameter()
            ..val = false
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
          Parameters.enableParameter()..val=false..withNamedParamInfoAndSameDisplayName('reverse')
        ], childBuilder: [
          'itemBuilder',
        ], childrenBuilder: [], functionMap: {
          'itemBuilder': itemBuilderFunction,
        });

  @override
  Widget create(BuildContext context) {
    init();
    return ListView.builder(
      controller: initScrollController(context),
      scrollDirection: parameters[0].value,
      padding: parameters[1].value,
      shrinkWrap: parameters[2].value,
      reverse: parameters[3].value,
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', index);
      },
      itemCount: count,
    );
  }
}

class CListViewSeparated extends BuilderComponent with FVBScrollable {
  CListViewSeparated()
      : super('ListView.separated', [
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
          Parameters.enableParameter()
            ..val = false
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
        ], childBuilder: [
          'itemBuilder',
          'separatorBuilder'
        ], childrenBuilder: [], functionMap: {
          'itemBuilder': itemBuilderFunction,
          'separatorBuilder': separatorBuilderFunction
        });

  @override
  Widget create(BuildContext context) {
    init();
    return ListView.separated(
      controller: initScrollController(context),
      scrollDirection: parameters[0].value,
      shrinkWrap: parameters[1].value,
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', index);
      },
      itemCount: count,
      separatorBuilder: (BuildContext context, int index) {
        return builder(context, 'separatorBuilder', index,
            defaultComp: () => CDivider());
      },
    );
  }
}

class CGridViewBuilder extends BuilderComponent with FVBScrollable {
  CGridViewBuilder()
      : super('GridView.builder', [
          Parameters.sliverDelegate(),
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
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', index);
      },
      itemCount: count,
      gridDelegate: parameters[0].value,
    );
  }
}
