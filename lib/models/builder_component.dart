import 'package:flutter/material.dart';

import '../component_list.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../parameters_list.dart';
import 'component_model.dart';
import 'local_model.dart';
import 'parameter_model.dart';
import 'variable_model.dart';

abstract class BuilderComponent extends Holder {
  LocalModel? model;

  BuilderComponent(String name, List<Parameter> parameters)
      : super(name, parameters);

  Widget builder(BuildContext context, int index) {
    ComponentOperationCubit.codeProcessor.modelVariables.clear();
    for (int i = 0; i < (model?.variables.length ?? 0); i++) {
      ComponentOperationCubit.codeProcessor
          .modelVariables[model!.variables[i].name] = model!.values[index][i];
    }
    ComponentOperationCubit.codeProcessor.modelVariables['index'] = index;
    ComponentOperationCubit.codeProcessor.modelVariables['count'] =
        model!.values.length;
    final widget = (child?.clone(this).create(context) ?? Container());
    return widget;
  }

  int get count => model?.values.length ?? 0;
}

class CListViewBuilder extends BuilderComponent {
  CListViewBuilder() : super('ListView.Builder', []);

  @override
  Widget create(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return builder(context, index);
      },
      itemCount: count,
    );
  }

  // @override
  // String code({bool clean = true}) {
  //   return '''$name(
  //       builder: (context,index){
  //       return ${child?.code() ?? CContainer().code(clean: clean)};
  //       }
  //       ),''';
  // }
}
