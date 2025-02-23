import 'package:flutter_builder/models/project_model.dart';
import 'package:flutter_builder/common/converter/string_operation.dart';

abstract class AppConfigCode {
  static String generateMaterialCode(FVBProject project) {
    return '''onGenerateRoute: (settings) {
        ${project.screens.map((screen) {
      return '''${screen != project.screens.first ? 'else ' : ''}if (settings.name == App.pages.${StringOperation.toCamelCase(screen.name, startWithLower: true)}) {
          return MaterialPageRoute(
              builder: (context) {
                return const ${screen.getClassName}();
              },
              settings: settings);
        }''';
    }).join('\n')} 
      },
    ''';
  }
}
