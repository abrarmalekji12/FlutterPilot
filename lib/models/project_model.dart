import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../code_to_component.dart';
import '../common/compiler/code_processor.dart';
import '../common/compiler/processor_component.dart';
import '../common/converter/code_converter.dart';
import '../common/logger.dart';
import '../common/undo/revert_work.dart';
import '../component_list.dart';
import '../constant/string_constant.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/stack_action/stack_action_cubit.dart';
import '../injector.dart';
import '../main.dart';
import '../runtime_provider.dart';
import '../ui/action_ui.dart';
import '../ui/models_view.dart';
import '../ui/project_setting_page.dart';
import 'component_model.dart';
import 'local_model.dart';
import 'other_model.dart';
import 'variable_model.dart';

class FlutterProject {
  late ProjectSettingsModel settings;
  String name;
  final int userId;
  String? docId;
  final String? device;
  String actionCode = '';

  // final List<VariableModel> variables = [];
  // final List<LocalModel> models = [];
  late UIScreen currentScreen;
  late UIScreen mainScreen;
  final List<UIScreen> uiScreens = [];
  final List<CustomComponent> customComponents = [];
  final List<FavouriteModel> favouriteList = [];

  FlutterProject(this.name, this.userId, this.docId,
      {this.device, this.actionCode = '', ProjectSettingsModel? settings}) {
    if (settings != null) {
      this.settings = settings;
    } else {
      this.settings = ProjectSettingsModel(isPublic: false, collaborators: []);
    }
  }

  Map<String, VariableModel> get variables => ComponentOperationCubit.codeProcessor.variables;

  set variables(Map<String, VariableModel> value) {
    ComponentOperationCubit.codeProcessor.variables.clear();
    ComponentOperationCubit.codeProcessor.variables.addAll(value);
  }

  String get getPath {
    return RunKey.encrypt(userId, name);
  }

  factory FlutterProject.createNewProject(String name, int userId) {
    final FlutterProject flutterProject = FlutterProject(name, userId, null);
    final ui = UIScreen.mainUI();
    flutterProject.uiScreens.add(ui);
    final custom = StatelessComponent(name: 'MainPage')..root = CScaffold();
    flutterProject.customComponents.add(custom);
    (ui.rootComponent as CMaterialApp).addOrUpdateChildWithKey('home', custom.createInstance(null));

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
      return ProcessorProvider(
        get<CodeProcessor>(),
        Builder(
          builder: (context) {
            return rootComponent?.build(context) ?? Container();
          }
        ),
      );
    }
    final _actionCubit = get<StackActionCubit>();
    return ProcessorProvider(
      get<CodeProcessor>(),
      Builder(builder: (context) {
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
                BlocBuilder<StackActionCubit, StackActionState>(
                  bloc: _actionCubit,
                  builder: (context, state) {
                    return Stack(
                      children: [
                        for (final model in _actionCubit.models)
                          Center(
                            child: StackActionWidget(
                              actionModel: model,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void setRoot(Component component) {
    currentScreen.rootComponent = component;
    component.setParent(null);
  }
}

class UIScreen {
  late final CodeProcessor processor;
  String name;
  String actionCode = '';
  Component? rootComponent;
  final List<String> importList = [];
  final List<LocalModel> models = [];
  final RevertWork revertWork = RevertWork.init();

  UIScreen(this.name){
    processor = CodeProcessor.build(processor: ComponentOperationCubit.codeProcessor,name: name);
  }

  toJson() => {
        'name': name,
        'actionCode': actionCode,
        'root': CodeOperations.trim(rootComponent?.code(clean: false)),
        'models': models.map((e) => e.toJson()).toList(growable: false),
        'variables':
            variables.values.where((element) => element.uiAttached).map((e) => e.toJson()).toList(growable: false)
      };

  Map<String, VariableModel> get variables => processor.variables;

  set variables(Map<String, VariableModel> value) {
    processor.variables.clear();
    processor.variables.addAll(value);
  }

  factory UIScreen.mainUI() {
    final UIScreen uiScreen = UIScreen('HomePage');
    uiScreen.rootComponent = componentList['MaterialApp']!();
    return uiScreen;
  }

  factory UIScreen.fromJson(Map<String, dynamic> json, final FlutterProject flutterProject) {
    final screen = UIScreen(json['name']);
    screen.actionCode = json['actionCode'] ?? '';
    screen.models.addAll(List.from(json['models'] ?? []).map((e) => LocalModel.fromJson(e)));
    screen.variables.addAll(List.from(json['variables'] ?? [])
        .asMap()
        .map((key, value) => MapEntry(value['name'], VariableModel.fromJson(value, screen.name))));
    return screen;
  }

  factory UIScreen.otherScreen(final String name, {String type = 'screen'}) {
    final UIScreen uiScreen = UIScreen(name);
    uiScreen.rootComponent = type == 'screen' ? componentList['Scaffold']!() : componentList['Container']!();
    return uiScreen;
  }

  Widget? build(BuildContext context) {
    if (RuntimeProvider.of(context) == RuntimeMode.run) {
      processor.executeCode(actionCode);
      processor.functions['build']?.execute(processor, []);
      print('CALLED BUILD');
    }
    return ProcessorProvider(
      processor,
      rootComponent?.build(context) ?? Container(),
    );
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
      name2 = name2.substring(0, i + 1) + name2[i + 1].toUpperCase() + name2.substring(i + 2);
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
    final List<String> importList = [];
    rootComponent?.forEach((component) {
      if (component is Clickable) {
        for (final e in (component as Clickable).actionList) {
          if (e.arguments.isNotEmpty && (e.arguments[0] is UIScreen?) && e.arguments[0] != null) {
            importList.add((e.arguments[0] as UIScreen).name);
          }
        }
      }
    });
    if (this != flutterProject.mainScreen && !importList.contains('main')) {
      importList.add('main');
    }
    logger('IMPL $implementationCode');
    String staticVariablesCode = '';
    String dynamicVariablesDefinitionCode = '';
    String dynamicVariableAssignmentCode = '';
    for (final variable in ComponentOperationCubit.codeProcessor.variables.entries) {
      if ([DataType.string, DataType.int, DataType.double, DataType.double].contains(variable.value.dataType)) {
        if (!variable.value.isFinal) {
          staticVariablesCode +=
              'final ${LocalModel.dataTypeToCode(variable.value.dataType)} ${variable.key} = ${LocalModel.valueToCode(variable.value.value)};';
        } else {
          dynamicVariablesDefinitionCode +=
              'late ${LocalModel.dataTypeToCode(variable.value.dataType)} ${variable.key};';
          dynamicVariableAssignmentCode += '${variable.key} = ${variable.value.assignmentCode};';
        }
      }
    }

    String functionImplementationCode = '';
    for (final function in ComponentOperationCubit.codeProcessor.predefinedFunctions.values) {
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
    import 'dart:math';
    ${importList.map((e) => '''import '$e.dart'; ''').join('\n')}
    ${models.map((e) => e.implementationCode).join(' ')}
    
    ${this == flutterProject.mainScreen ? '''
    
    $staticVariablesCode
    $dynamicVariablesDefinitionCode
     
    void main(){
    ${FVBEngine().fvbToDart(flutterProject.actionCode)}
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
