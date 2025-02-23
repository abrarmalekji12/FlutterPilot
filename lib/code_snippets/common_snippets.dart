import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/fvb_functions.dart';

import '../common/converter/string_operation.dart';
import '../models/actions/code_snippets.dart';
import '../models/project_model.dart';

class CommonSnippets {
  List<FVBCodeSnippet> generate(FVBProject project) {
    final List<FVBCodeSnippet> list = [];
    if (project.screens.isNotEmpty) {
      list.addAll(project.screens.map((e) => FVBCodeSnippet(
              name: 'Navigate to ${e.name} screen',
              fields: fvbFunPush.arguments,
              code: (fields) {
                return 'App.${fvbFunPush.generate(fields)};';
              },
              defaultValues: {
                'context': FVBCode('context'),
                'arguments': FVBCode('[]'),
                'screen': FVBCode(
                    'App.pages.${StringOperation.toCamelCase(e.name, startWithLower: true)}')
              })));
    }
    if (project.customComponents.isNotEmpty) {
      list.addAll(project.customComponents.map((e) => FVBCodeSnippet(
              name: 'Show dialog ${e.name}',
              fields: fvbFunShowDialog.arguments,
              code: (fields) {
                return 'App.${fvbFunShowDialog.generate(fields)};';
              },
              defaultValues: {
                'context': FVBCode('context'),
                'component': FVBCode(
                    'App.widgets.${StringOperation.toSnakeCase(e.name)}()')
              })));
    }
    if (project.customComponents.isNotEmpty) {
      list.addAll(project.customComponents.map((e) => FVBCodeSnippet(
              name: 'Show Bottom-Sheet ${e.name}',
              fields: fvbFunShowBottomSheet.arguments,
              code: (fields) {
                return 'App.${fvbFunShowBottomSheet.generate(fields)};';
              },
              defaultValues: {
                'context': FVBCode('context'),
                'component': FVBCode(
                    'App.widgets.${StringOperation.toSnakeCase(e.name)}()')
              })));
    }

    if (project.apiModel.apis.isNotEmpty) {
      list.addAll(project.apiModel.apis.map((e) => FVBCodeSnippet(
          name: 'Call Api ${e.name}',
          fields: fvbFunShowBottomSheet.arguments,
          code: (fields) {
            return 'App.apis.${StringOperation.toSnakeCase(e.name)}.fetch().then((ApiResponse data){'
                '});';
          },
          defaultValues: {})));
    }
    return list;
  }
}
