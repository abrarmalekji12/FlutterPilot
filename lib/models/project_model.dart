import 'package:flutter/material.dart';
import '../code_to_component.dart';
import '../constant/string_constant.dart';
import 'local_model.dart';
import 'variable_model.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import 'other_model.dart';
import '../common/logger.dart';
import '../component_list.dart';

import 'component_model.dart';

class FlutterProject {
  String name;
  final int userId;
  String? docId;
  final String? device;

  // final List<VariableModel> variables = [];
  // final List<LocalModel> models = [];
  late UIScreen currentScreen;
  late UIScreen mainScreen;
  final List<UIScreen> uiScreens = [];
  final List<CustomComponent> customComponents = [];
  final List<FavouriteModel> favouriteList = [];

  FlutterProject(this.name, this.userId, this.docId, {this.device});

  factory FlutterProject.createNewProject(String name, int userId) {
    final FlutterProject flutterProject = FlutterProject(name, userId, null);
    flutterProject.uiScreens.add(UIScreen.mainUI());
    flutterProject.currentScreen = flutterProject.uiScreens.first;
    flutterProject.mainScreen = flutterProject.uiScreens.first;
    return flutterProject;
  }

  get rootComponent => currentScreen.rootComponent;

  set setRootComponent(Component? root) {
    currentScreen.rootComponent = root;
  }

  String code() {
    String implementationCode = '';
    if (customComponents.isNotEmpty) {
      for (final customComponent in customComponents) {
        implementationCode += '${customComponent.implementationCode()}\n';
      }
    }
    logger('IMPL $implementationCode');
    String staticVariablesCode = '';
    String dynamicVariablesDefinitionCode = '';
    String dynamicVariableAssignmentCode = '';
    for (final variable
        in ComponentOperationCubit.codeProcessor.variables.entries) {
      if (!variable.value.runtimeAssigned) {
        staticVariablesCode +=
            'static const double ${variable.key} = ${variable.value.value};\n';
      } else {
        dynamicVariablesDefinitionCode += 'late double ${variable.key};\n';
        dynamicVariableAssignmentCode +=
            '${variable.key} = ${variable.value.assignmentCode};\n';
      }
    }

    String functionImplementationCode = '';
    for (final function
        in ComponentOperationCubit.codeProcessor.functions.values) {
      functionImplementationCode += '${function.functionCode}\n';
    }
    final className = name[0].toUpperCase() + name.substring(1);
    // ${rootComponent!.code()}
    return ''' 
    // copy all the images to assets/images/ folder
    // 
    // TODO Dependencies (add into pubspec.yaml)
    // google_fonts: ^2.2.0
    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart';
    ${currentScreen.models.map((e) => e.implementationCode).join('\n')}
    void main(){
    runApp(const $className());
    } 
    class $className extends StatefulWidget {
    const $className({Key? key}) : super(key: key);

    @override
   _${className}State createState() => _${className}State();
    }

    class _${className}State extends State<$className> {
    ${currentScreen.models.map((e) => e.declarationCode).join('\n')}
     $staticVariablesCode
     $dynamicVariablesDefinitionCode
     @override
     Widget build(BuildContext context) {
         $dynamicVariableAssignmentCode
          return ${rootComponent!.code()};
      }
      $functionImplementationCode 
    }

    $implementationCode
    ''';
  }

  Widget run(BuildContext context, {bool navigator = false}) {
    if (!navigator) {
      return rootComponent?.build(context);
    }
    return Navigator(
      key: const GlobalObjectKey(navigationKey),
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => mainScreen.build(context) ?? Container(),
      ),
    );
  }

  void setRoot(Component component) {
    currentScreen.rootComponent = component;
    component.setParent(null);
  }
}

class UIScreen {
  String name;
  Component? rootComponent;
  final List<LocalModel> models = [];
  final List<VariableModel> variables = [];

  UIScreen(this.name);

  toJson() => {
        'name': name,
        'root': CodeOperations.trim(rootComponent?.code(clean: false)),
        'models': models.map((e) => e.toJson()).toList(growable: false),
        'variables': variables.map((e) => e.toJson()).toList(growable: false)
      };

  factory UIScreen.mainUI() {
    final UIScreen uiScreen = UIScreen('HomePage');
    uiScreen.rootComponent = componentList['MaterialApp']!();
    return uiScreen;
  }

  factory UIScreen.fromJson(
      Map<String, dynamic> json, final FlutterProject flutterProject) {
    final screen = UIScreen(json['name']);
    screen.rootComponent = Component.fromCode(json['root'], flutterProject);
    screen.models.addAll(
        List.from(json['models'] ?? []).map((e) => LocalModel.fromJson(e)));
    screen.variables.addAll(List.from(json['variables'] ?? [])
        .map((e) => VariableModel.fromJson(e)));
    return screen;
  }

  factory UIScreen.otherScreen(final String name) {
    final UIScreen uiScreen = UIScreen(name);
    uiScreen.rootComponent = componentList['Scaffold']!();
    return uiScreen;
  }

  Widget? build(BuildContext context) {
    return rootComponent?.build(context);
  }
}

class ProjectGroup {
  List<FlutterProject> projects = [];
}
