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
    final ui = UIScreen.mainUI();
    flutterProject.uiScreens.add(ui);
    final custom = StatelessComponent(name: 'MainPage')..root = CScaffold();
    flutterProject.customComponents.add(custom);
    (ui.rootComponent as CMaterialApp)
        .addOrUpdateChildWithKey('home', custom.createInstance(null));

    flutterProject.currentScreen = flutterProject.uiScreens.first;
    flutterProject.mainScreen = flutterProject.uiScreens.first;
    return flutterProject;
  }

  Component? get rootComponent => currentScreen.rootComponent;

  set setRootComponent(Component? root) {
    currentScreen.rootComponent = root;
  }

  List<ImageData> getAllUsedImages() {
    final imageList = <ImageData>[];
    for (final screen in uiScreens) {
      screen.rootComponent?.forEach((component) {
        if (component.name == 'Image.asset') {
          if ((component.parameters[0].value as ImageData?) != null) {
            imageList.add((component.parameters[0].value as ImageData));
          }
        }
      });
    }
    return imageList;
  }
  
  Widget run(final BuildContext context, {bool navigator = false}) {
    if (!navigator) {
      return rootComponent?.build(context) ?? Container();
    }

    final _stackCubit = StackActionCubit();
    _stackCubit.stackOperation(StackOperation.push, uiScreen: mainScreen);

    return BlocProvider<StackActionCubit>(
      create: (_) => _stackCubit,
      child: BlocBuilder<StackActionCubit, StackActionState>(
        bloc: _stackCubit,
        builder: (context, state) {
          return Scaffold(
            key: const GlobalObjectKey(deviceScaffoldMessenger),
            body: SafeArea(
              child: Stack(
                children: [
                  Navigator(
                    key: const GlobalObjectKey(navigationKey),
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (_) => mainScreen.build(context) ?? Container(),
                    ),
                  ),
                  for (final model in _stackCubit.models)
                    Center(
                      child: StackActionWidget(
                        actionModel: model,
                      ),
                    )
                ],
              ),
            ),
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
  final List<String> importList=[];
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
        .map((e) => VariableModel.fromJson(e, screen.name)));
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

  String get getClassName {
    final firstLetter = name[0].toUpperCase();
    String name2 = name.substring(1);
    final List<int> underScores = [];
    for (int i = 0; i < name2.length; i++) {
      if (name2[i] == '_') {
        underScores.add(i);
      }
    }
    for (int i in underScores) {
      name2 = name2.substring(0, i + 1) +
          name2[i + 1].toUpperCase() +
          name2.substring(i + 2);
    }
    return firstLetter + name2.replaceAll('_', '');
  }

  String code(final FlutterProject flutterProject) {
    String implementationCode = '';
    if (flutterProject.customComponents.isNotEmpty) {
      for (final customComponent in flutterProject.customComponents) {
        implementationCode += customComponent.implementationCode();
      }
    }
    final List<String> importList=[];
    rootComponent?.forEach((component) {

    if(component is Clickable){
      for (final e in (component as Clickable).actionList) {
        if(e.arguments.isNotEmpty&&(e.arguments[0] is UIScreen?) && e.arguments[0]!= null){
          importList.add((e.arguments[0] as UIScreen).name);
        }
      }
    }
    });
    if(this != flutterProject.mainScreen&&!importList.contains('main')){
      importList.add('main');
    }
    logger('IMPL $implementationCode');
    String staticVariablesCode = '';
    String dynamicVariablesDefinitionCode = '';
    String dynamicVariableAssignmentCode = '';
    for (final variable
        in ComponentOperationCubit.codeProcessor.variables.entries) {
      if (!variable.value.runtimeAssigned) {
        staticVariablesCode +=
            'const ${LocalModel.getDartDataType(variable.value.dataType)} ${variable.key} = ${LocalModel.valueToCode(variable.value.value)};';
      } else {
        dynamicVariablesDefinitionCode +=
            'late ${LocalModel.getDartDataType(variable.value.dataType)} ${variable.key};';
        dynamicVariableAssignmentCode +=
            '${variable.key} = ${variable.value.assignmentCode};';
      }
    }

    String functionImplementationCode = '';
    for (final function
        in ComponentOperationCubit.codeProcessor.functions.values) {
      functionImplementationCode += function.functionCode;
    }

    final String className = getClassName;
    // ${rootComponent!.code()}
    return ''' 
  
    ${this == flutterProject.mainScreen ? '''
     // copy all the images to assets/images/ folder
    // 
    // TODO Dependencies (add into pubspec.yaml)
    // google_fonts: ^2.2.0
    ''' : ''}
    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart';
    import 'dart:math' as math;
    ${importList.map((e) => '''import '$e.dart'; ''').join('\n')}
    ${models.map((e) => e.implementationCode).join(' ')}
    
    ${this == flutterProject.mainScreen ? '''
    
    $staticVariablesCode
    $dynamicVariablesDefinitionCode
     
    void main(){
    ${rootComponent is! MaterialApp ? 'runApp(MaterialApp(home:const $className()));' : 'runApp(const $className());'}
    } 
     $functionImplementationCode 
 
    $implementationCode
    
  Color? hexToColor(String hexString) {
  if (hexString.length < 7) {
    return null;
  }
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  final colorInt = int.tryParse(buffer.toString(), radix: 16);
  if (colorInt == null) {
    return null;
  }
  return Color(colorInt);
}
    ''' : ''}
    class $className extends StatefulWidget {
    const $className({Key? key}) : super(key: key);

    @override
   _${className}State createState() => _${className}State();
    }

    class _${className}State extends State<$className> {
    ${models.map((e) => e.declarationCode).join(' ')}
   
     @override
     void didChangeDependencies() {
      super.didChangeDependencies();
        $dynamicVariableAssignmentCode
     }
     
     @override
     Widget build(BuildContext context) {
       return ${rootComponent!.code()};
      }
     
    }

    ''';
  }
}

class ProjectGroup {
  List<FlutterProject> projects = [];
}
