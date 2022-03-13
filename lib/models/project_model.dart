import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../code_to_component.dart';
import '../common/undo/revert_work.dart';
import '../constant/string_constant.dart';
import '../cubit/stack_action/stack_action_cubit.dart';
import '../ui/action_ui.dart';
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

  String code(final UIScreen screen) {
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
    final className = screen.name[0].toUpperCase() + screen.name.substring(1);
    // ${rootComponent!.code()}
    return ''' 
   
    ${screen==mainScreen?'''
     // copy all the images to assets/images/ folder
    // 
    // TODO Dependencies (add into pubspec.yaml)
    // google_fonts: ^2.2.0
    ''':''}
    import 'package:flutter/material.dart';
    cimport 'package:google_fonts/google_fonts.dart';
    
    ${screen.models.map((e) => e.implementationCode).join('\n')}
    
    ${screen==mainScreen?'''
    void main(){
    runApp(const $className());
    } 
    ''':''}
    class $className extends StatefulWidget {
    const $className({Key? key}) : super(key: key);

    @override
   _${className}State createState() => _${className}State();
    }

    class _${className}State extends State<$className> {
    ${screen.models.map((e) => e.declarationCode).join('\n')}
     $staticVariablesCode
     $dynamicVariablesDefinitionCode
     @override
     Widget build(BuildContext context) {
         $dynamicVariableAssignmentCode
          return ${screen.rootComponent!.code()};
      }
      $functionImplementationCode 
    }

    $implementationCode
    ''';
  }

  Widget run(final BuildContext context, {bool navigator = false}) {
    if (!navigator) {
      return rootComponent?.build(context);
    }

    final _stackCubit = StackActionCubit();
    return BlocProvider<StackActionCubit>(
      create: (_) => _stackCubit,
      child: BlocBuilder<StackActionCubit, StackActionState>(
        bloc: _stackCubit,
        builder: (context, state) {
          return Stack(
            children: [
              Navigator(
                key: const GlobalObjectKey(navigationKey),
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (_) => mainScreen.build(context) ?? Container() ,
                ),
              ),
              for (final model in _stackCubit.models)
                Center(
                  child: StackActionWidget(
                    actionModel: model,
                  ),
                )
            ],
          );
        },
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
  final RevertWork revertWork = RevertWork.init();

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

    screen.models.addAll(
        List.from(json['models'] ?? []).map((e) => LocalModel.fromJson(e)));
    screen.variables.addAll(List.from(json['variables'] ?? [])
        .map((e) => VariableModel.fromJson(e)));
    return screen;
  }

  factory UIScreen.otherScreen(final String name, {String type = 'screen'}) {
    final UIScreen uiScreen = UIScreen(name);
    uiScreen.rootComponent = type == 'screen'
        ? componentList['Scaffold']!()
        : componentList['Container']!();
    return uiScreen;
  }

  Widget? build(BuildContext context) {
    return rootComponent?.build(context);
  }
}

class ProjectGroup {
  List<FlutterProject> projects = [];
}
