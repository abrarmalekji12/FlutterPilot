import 'package:flutter/material.dart';
import 'parameter_info_model.dart';
import '../common/logger.dart';
import '../component_list.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../parameters_list.dart';
import 'component_model.dart';
import 'local_model.dart';
import 'parameter_model.dart';

abstract class BuilderComponent extends Holder {
  LocalModel? model;
  final List<Component> builtList = [];
  SimpleParameter<int> itemLengthParameter =
      SimpleParameter<int>(name: 'count', defaultValue: 5, required: true);
  final String builderName;

  BuilderComponent(String name, List<Parameter> parameters,
      {this.builderName = 'itemBuilder'})
      : super(name, parameters) {
    itemLengthParameter;
  }

  @override
  Component clone(Component? parent, {bool deepClone = false}) {
    return (super.clone(parent, deepClone: deepClone) as BuilderComponent)
      ..model = model
      ..itemLengthParameter = itemLengthParameter;
  }

  Widget builder(BuildContext context, int index) {
    if (child == null) {
      return Container();
    }
    if (model != null) {
      for (int i = 0; i < (model?.variables.length ?? 0); i++) {
        ComponentOperationCubit.codeProcessor
            .localVariables[model!.variables[i].name] = model!.values[index][i];
      }
    }
    ComponentOperationCubit.codeProcessor.localVariables['index'] = index;
    ComponentOperationCubit.codeProcessor.localVariables['count'] =
        model?.values.length ?? itemLengthParameter.value;
    final component = child!.clone(this);
    final widget = (component.build(context));
    if (index < builtList.length) {
      builtList.removeAt(index);
      builtList.insert(index, component);
    } else {
      builtList.add(component);
    }

    return widget;
  }

  void init() {
    builtList.clear();
    child?.forEach((p0) {
      p0.cloneElements.clear();
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
    String itemCode =
        child?.code(clean: clean) ?? CContainer().code(clean: clean);
    String name = this.name;
    if (!clean) {
      name +=
          '[id=$id|model=${model?.name}|len=${itemLengthParameter.code(false)}]';
    }
    // final List<DynamicVariableModel> usedVariables = [];

    String itemCount = '';
    if (clean && model != null) {
      itemCount = ', itemCount:${model?.listVariableName}.length,';
      int start = 0;
      int gotIndex = -1;
      logger('ITEM CODE $itemCode');
      while (start != -1 && start < itemCode.length) {
        if (gotIndex == -1) {
          start = itemCode.indexOf('\${', start);
          logger('START ++ $start');
          if (start == -1) {
            break;
          }
          start += 2;
          gotIndex = start;
        } else {
          start = itemCode.indexOf('}', start);
          logger('START 2 ++ $start');
          if (start == -1) {
            break;
          }
          String innerArea = itemCode.substring(gotIndex, start);
          if (model != null && model!.variables.isNotEmpty) {
            for (final variable in model!.variables) {
              innerArea = innerArea.replaceAll(variable.name,
                  '${model!.listVariableName}[index].${variable.name}');
              // if (!usedVariables.contains(variable)) {
              //   usedVariables.add(variable);
              // }
            }
            logger('MODEL + ++ ++ $innerArea');
            itemCode = itemCode.replaceRange(
                gotIndex - 2, start + 1, '\${$innerArea}');
            gotIndex = -1;
            start += 2;
            continue;
          }
        }
      }
    }
    return '''$name($middle $builderName:(_,index){ return $itemCode; }''' +
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

class CListViewBuilder extends BuilderComponent {
  CListViewBuilder()
      : super('ListView.builder', [
          Parameters.axisParameter()
            ..withInfo(NamedParameterInfo('scrollDirection'))
        ]);

  @override
  Widget create(BuildContext context) {
    init();
    return ListView.builder(
      scrollDirection: parameters[0].value,
      itemBuilder: (context, index) {
        return builder(context, index);
      },
      itemCount: count,
    );
  }
}

class CGridViewBuilder extends BuilderComponent {
  CGridViewBuilder()
      : super('GridView.builder', [
          Parameters.sliverDelegate(),
        ]);

  @override
  Widget create(BuildContext context) {
    init();
    return GridView.builder(
      itemBuilder: (context, index) {
        return builder(context, index);
      },
      itemCount: count,
      gridDelegate: parameters[0].value,
    );
  }
}
