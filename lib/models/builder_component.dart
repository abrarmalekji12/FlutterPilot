import 'package:flutter/material.dart';
import '../common/compiler/code_processor.dart';
import '../common/compiler/fvb_function_variables.dart';
import '../common/compiler/processor_component.dart';
import 'parameter_info_model.dart';
import '../component_list.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../parameters_list.dart';
import 'component_model.dart';
import 'parameter_model.dart';

abstract class BuilderComponent extends CustomNamedHolder {
  // LocalModel? model;
  final Map<String, List<Component>> builtList = {};
  final Map<String, FVBFunction> functionMap;

  // late SimpleParameter<int> itemLengthParameter;

  BuilderComponent(
    String name,
    List<Parameter> parameters, {
    required List<String> childBuilder,
    required List<String> childrenBuilder,
    required this.functionMap,
  }) : super(name, parameters, childBuilder, childrenBuilder) {
    // itemLengthParameter =
    //     SimpleParameter<int>(name: countName, defaultValue: 5, required: true);
  }

  @override
  Component clone(Component? parent, {bool deepClone = false}) {
    final clone =
        (super.clone(parent, deepClone: deepClone) as BuilderComponent);
    // clone.model = model;
    // clone.itemLengthParameter = deepClone
    //     ? (SimpleParameter<int>()..cloneOf(itemLengthParameter))
    //     : itemLengthParameter;
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

  Widget builder(BuildContext context, String name,List<dynamic> args,
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
        ComponentOperationCubit.currentProject!.processor;
    final processor = CodeProcessor.build(name: name, processor: parent);
    final function = functionMap[name];
    final component = child.clone(this);
    final index=args.isNotEmpty?(args.last is int?args.last:0):0;
    if (index< builtList[name]!.length) {
      builtList[name]!.removeAt(index);
      builtList[name]!.insert(index, component);
    } else {
      builtList[name]!.add(component);
    }
    if (CodeProcessor.error) {
      return Container();
    }
    if (function != null) {
      function.execute(parent, null, args,
          defaultProcessor: processor,
          filtered:
          CodeProcessor.cleanCode(function.code ?? '', processor));
    }
    return ProcessorProvider(
      processor,
      Builder(builder: (context) {
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
    try{
    final middle = parametersCode(clean);
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
        ${itemsCode.entries.map((entry) => '${entry.key}:(context,index){${functionMap[entry.key]?.code ?? ''} return ${entry.value};}').join(',')}),''',
          clean);
    }
    return '''$name($middle 
        ${itemsCode.entries.map((entry) => '${entry.key}:(){`${functionMap[entry.key]?.code ?? ''}`return${entry.value};}').join(',')}),''';
    // return '$name(\n${middle}child:${child!.code(clean: clean)}\n)';
    }
    catch(e){
      print('$name ${e.toString()}');
    }
    return '';
    }

}

FVBFunction get itemBuilderFunction => FVBFunction(
      'itemBuilder',
      '',
      [
        FVBArgument('context', dataType: DataType.dynamic, nullable: false),
        FVBArgument('index', dataType: DataType.fvbInt, nullable: false),
      ],
      returnType: DataType.fvbVoid,
      canReturnNull: false,
    );
FVBFunction get builderFunction => FVBFunction(
  'builder',
  '',
  [
    FVBArgument('context', dataType: DataType.dynamic, nullable: false),
  ],
  returnType: DataType.fvbVoid,
  canReturnNull: false,
);
FVBFunction get stateFulBuilderFunction => FVBFunction(
  'builder',
  '',
  [
    FVBArgument('context', dataType: DataType.dynamic, nullable: false),
    FVBArgument('setState2', dataType: DataType.fvbInstance('setState'), nullable: false),
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
          Parameters.itemLengthParameter,
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
          Parameters.enableParameter
            ..val = true
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('pageSnapping'),
          Parameters.scrollablePhysicsParameter
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
      itemCount: parameters[0].value,
      scrollDirection: parameters[1].value,
      pageSnapping: parameters[2].value,
      physics: parameters[3].value,
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', [context,index]);
      },
      controller: controlMap['controller']!.value,
      onPageChanged: (index) {
        perform(context, arguments: [index]);
      },
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
class CBuilder extends BuilderComponent{
  CBuilder(): super('Builder', [], childBuilder: [
    'builder',
  ], childrenBuilder: [], functionMap: {
    'builder': builderFunction,
  });

  @override
  Widget create(BuildContext context) {
    init();
    return Builder(builder: (context){
      return builder(context, 'builder', [context]);
    });
  }
}
class CStatefulBuilder extends BuilderComponent{
  CStatefulBuilder(): super('StatefulBuilder', [], childBuilder: [
    'builder',
  ], childrenBuilder: [], functionMap: {
    'builder': stateFulBuilderFunction,
  });

  @override
  Widget create(BuildContext context) {
    init();
    return StatefulBuilder(builder: (context,setState){
      return builder(context, 'builder', [context,setStateFunction..dartCall=(arguments,instance){
        (arguments[0] as FVBFunction).execute(arguments.last, null, []);
        setState((){

        });
      }]);
    });
  }
}
class CListViewBuilder extends BuilderComponent with FVBScrollable {
  CListViewBuilder()
      : super('ListView.builder', [
          Parameters.itemLengthParameter,
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
          Parameters.paddingParameter(),
          Parameters.enableParameter
            ..val = false
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
          Parameters.enableParameter
            ..val = false
            ..withNamedParamInfoAndSameDisplayName('reverse'),
    Parameters.scrollablePhysicsParameter
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
      scrollDirection: parameters[1].value,
      padding: parameters[2].value,
      shrinkWrap: parameters[3].value,
      reverse: parameters[4].value,
      physics: parameters[5].value,
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', [context,index]);
      },
      itemCount: parameters[0].value,
    );
  }
}

class CListViewSeparated extends BuilderComponent with FVBScrollable {
  CListViewSeparated()
      : super('ListView.separated', [
          Parameters.itemLengthParameter,
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection')),
    Parameters.paddingParameter(),
          Parameters.enableParameter
            ..val = false
            ..withRequired(true)
            ..withNamedParamInfoAndSameDisplayName('shrinkWrap'),
    Parameters.scrollablePhysicsParameter,
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
      scrollDirection: parameters[1].value,
      padding: parameters[2].value,
      shrinkWrap: parameters[3].value,
      physics: parameters[4].value,
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', [context,index]);
      },
      itemCount: parameters[0].value,
      separatorBuilder: (BuildContext context, int index) {
        return builder(context, 'separatorBuilder', [context,index],
            defaultComp: () => CDivider());
      },
    );
  }
}

class CGridViewBuilder extends BuilderComponent with FVBScrollable {
  CGridViewBuilder()
      : super('GridView.builder', [
          Parameters.itemLengthParameter,
          Parameters.sliverDelegate(),
    Parameters.scrollablePhysicsParameter,
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
      itemBuilder: (context, index) {
        return builder(context, 'itemBuilder', [context,index]);
      },
      itemCount: parameters[0].value,
      gridDelegate: parameters[1].value,
      physics: parameters[2].value,
      padding:parameters[3].value ,
    );
  }
}
