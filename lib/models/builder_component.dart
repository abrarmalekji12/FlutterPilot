import 'package:flutter/material.dart';

import '../component_list.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import 'component_model.dart';
import 'local_model.dart';
import 'parameter_model.dart';
import 'variable_model.dart';

abstract class BuilderComponent extends Holder {
  LocalModel? model;
  final List<Component> builtList = [];

  BuilderComponent(String name, List<Parameter> parameters)
      : super(name, parameters);

  Widget builder(BuildContext context, int index) {

    for (int i = 0; i < (model?.variables.length ?? 0); i++) {
      ComponentOperationCubit.codeProcessor
          .modelVariables[model!.variables[i].name] = model!.values[index][i];
    }
    ComponentOperationCubit.codeProcessor.modelVariables['index'] = index;
    ComponentOperationCubit.codeProcessor.modelVariables['count'] =
        model!.values.length;
    final component = child!.clone(this);
    final widget = (component.create(context));
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
    // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
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
    String itemCode =
        child?.code(clean: clean) ?? CContainer().code(clean: clean);
    String name = this.name;
    if (!clean) {
      name += '[id=$id|model=${model?.name}]';
    }
    // final List<DynamicVariableModel> usedVariables = [];

    String itemCount = '';
    if (clean) {
      itemCount = '\n, itemCount:${model?.listVariableName}.length,';
      int start = 0;
      int gotIndex = -1;
      while (start < itemCode.length) {
        if (gotIndex == -1) {
          start = itemCode.indexOf('{{', start);
          if (start == -1) {
            break;
          }
          start += 2;
          gotIndex = start;
        } else {
          start = itemCode.indexOf('}}', start);
          if (start == -1) {
            break;
          }
          String innerArea = itemCode.substring(gotIndex, start);
          if (model != null && model!.variables.isNotEmpty) {
            for (final variable in model!.variables) {
              innerArea=innerArea.replaceAll(
                  variable.name, '${model!.listVariableName}[index].${variable.name}');
              // if (!usedVariables.contains(variable)) {
              //   usedVariables.add(variable);
              // }
            }
            itemCode = itemCode.replaceRange(
                gotIndex - 2, start + 2, '\${$innerArea}');
            gotIndex = -1;
            start += 2;
            continue;
          }
        }
      }
    }
    return '''$name($middle\nbuilder:(_,index){\nreturn $itemCode;\n}''' +
        itemCount +
        '\n),';
    // return '$name(\n${middle}child:${child!.code(clean: clean)}\n)';
  }

  int get count => model?.values.length ?? 0;
}

class CListViewBuilder extends BuilderComponent {
  CListViewBuilder() : super('ListView.Builder', []);

  @override
  Widget create(BuildContext context) {
    init();
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
