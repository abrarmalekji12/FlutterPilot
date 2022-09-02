import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/error/error_bloc.dart';
import '../bloc/state_management/state_management_bloc.dart';
import '../code_to_component.dart';
import '../common/common_methods.dart';
import '../common/compiler/code_processor.dart';
import '../common/compiler/fvb_function_variables.dart';
import '../common/compiler/processor_component.dart';
import '../common/converter/code_converter.dart';
import '../common/converter/string_operation.dart';
import '../common/fvb_arch/fvb_refresher.dart';
import '../common/undo/revert_work.dart';
import '../component_list.dart';
import '../constant/string_constant.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/stack_action/stack_action_cubit.dart';
import '../injector.dart';
import '../main.dart';
import '../runtime_provider.dart';
import '../ui/action_ui.dart';
import '../ui/project_setting_page.dart';
import 'component_model.dart';
import 'component_selection.dart';
import 'local_model.dart';
import 'other_model.dart';
import 'variable_model.dart';

class FlutterProject {
  static const defaultActionCode = '''
    void main(){
    print("Hello World!");
    }
    ''';
  late ProjectSettingsModel settings;
  late CodeProcessor processor;
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
  final List<String> imageList;

  FlutterProject(this.name, this.userId, this.docId,
      {this.device,
      this.actionCode = defaultActionCode,
      required this.imageList,
      ProjectSettingsModel? settings}) {
    if (settings != null) {
      this.settings = settings;
    } else {
      this.settings = ProjectSettingsModel(isPublic: false, collaborators: []);
    }
    processor = get<CodeProcessor>();
  }

  Map<String, FVBVariable> get variables => processor.variables;

  set variables(Map<String, FVBVariable> value) {
    processor.variables.clear();
    processor.variables.addAll(value);
  }

  String get getPath {
    return RunKey.encrypt(userId, name);
  }

  factory FlutterProject.createNewProject(String name, int userId) {
    final FlutterProject flutterProject =
        FlutterProject(name, userId, null, actionCode: defaultActionCode, imageList: []);
    ComponentOperationCubit.currentProject = flutterProject;
    final ui = UIScreen.mainUI();
    flutterProject.uiScreens.add(ui);
    final custom = StatefulComponent(name: 'MainPage')..root = CScaffold();
    flutterProject.customComponents.add(custom);
    flutterProject.currentScreen = ui;
    flutterProject.mainScreen = ui;
    (ui.rootComponent as CMaterialApp)
        .addOrUpdateChildWithKey('home', custom.createInstance(null));
    get<ComponentSelectionCubit>().init(ComponentSelectionModel.unique(
        CNotRecognizedWidget(), ui.rootComponent!));

    return flutterProject;
  }

  Component? get rootComponent => currentScreen.rootComponent;

  set setRootComponent(Component? root) {
    currentScreen.rootComponent = root;
  }

  List<ImageData> getAllUsedImages() {
    // for (final screen in uiScreens) {
    //   screen.rootComponent?.forEach((component) {
    //     if (component.name == 'Image.asset') {
    //       if ((component.parameters[0].value as ImageData?) != null) {
    //         imageList.add((component.parameters[0].value as ImageData));
    //       }
    //     }
    //   });
    // }
    return imageList
        .map((e) => ImageData(ComponentOperationCubit.bytesCache[e], e))
        .toList();
  }

  Widget run(final BuildContext context, final BoxConstraints constraints,
      {bool navigator = false}) {
    context.read<ErrorBloc>().add(ClearMessageEvent());
    processor.destroyProcess(deep: true);
    processor.variables['dw']!.value = constraints.maxWidth;
    processor.variables['dh']!.value = constraints.maxHeight;
    // refresherUsed.clear();
    ComponentOperationCubit.processor = processor;
    processor.executeCode(ComponentOperationCubit.currentProject!.actionCode);
    processor.functions['main']?.execute(processor, null, []);
    if (!navigator) {
      processor.finished = true;
      return ProcessorProvider(
        get<CodeProcessor>(),
        Builder(builder: (context) {
          return currentScreen.build(context) ?? Container();
        }),
      );
    }
    final _actionCubit = get<StackActionCubit>();
    return ProcessorProvider(
      get<CodeProcessor>(),
      Builder(builder: (context) {
        return Scaffold(
          key: const GlobalObjectKey(deviceScaffoldMessenger),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Navigator(
                  key: const GlobalObjectKey(navigationKey),
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (_) => mainScreen.build(context) ?? Container(),
                  ),
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
  static const defaultActionCode = '''
    void initState(){
    // will execute first time only
    }
    
    void build(context){
    // will execute every time widget rebuild
    }
    ''';
  late final CodeProcessor processor;
  String name;
  String actionCode;
  Component? rootComponent;
  late final String id;
  final List<String> importList = [];
  final List<LocalModel> models = [];
  final RevertWork revertWork = RevertWork.init();

  UIScreen(this.name, {this.actionCode = ''}) {
    id = 'screen_' + name;
    processor = CodeProcessor.build(
        processor: ComponentOperationCubit.currentProject!.processor,
        name: name);
    processor.functions['setState'] = FVBFunction('setState', null, [
      FVBArgument('callback', dataType: DataType.fvbFunction)
    ], dartCall: (arguments, instance) {
      (arguments[0] as FVBFunction).execute(processor, instance, []);
      (arguments[1] as CodeProcessor).consoleCallback.call('api:refresh|$id');
    });
  }

  String get importFile =>
      ComponentOperationCubit.currentProject!.mainScreen == this
          ? 'main'
          : StringOperation.toSnakeCase(name);

  toJson() => {
        'name': name,
        'action_code': actionCode,
        'root': CodeOperations.trim(rootComponent?.code(clean: false)),
        'models': models.map((e) => e.toJson()).toList(growable: false),
        'variables': variables.values
            .where((element) => element is VariableModel && element.uiAttached)
            .map((e) => e.toJson())
            .toList(growable: false)
      };

  Map<String, FVBVariable> get variables => processor.variables;

  factory UIScreen.mainUI() {
    final UIScreen uiScreen =
        UIScreen('HomePage', actionCode: defaultActionCode);
    uiScreen.rootComponent = componentList['MaterialApp']!();
    return uiScreen;
  }

  factory UIScreen.fromJson(
      Map<String, dynamic> json, final FlutterProject flutterProject) {
    final screen = UIScreen(json['name']);
    screen.actionCode = json['action_code'] ?? defaultActionCode;
    screen.models.addAll(
        List.from(json['models'] ?? []).map((e) => LocalModel.fromJson(e)));
    screen.variables.addAll(
      List.from(json['variables'] ?? []).asMap().map(
            (key, value) => MapEntry(
              value['name'],
              VariableModel.fromJson(value..['uiAttached'] = true),
            ),
          ),
    );
    return screen;
  }

  factory UIScreen.otherScreen(final String name, {String type = 'screen'}) {
    final UIScreen uiScreen = UIScreen(name, actionCode: defaultActionCode);
    uiScreen.rootComponent = type == 'screen'
        ? componentList['Scaffold']!()
        : componentList['Container']!();
    return uiScreen;
  }

  Widget? build(BuildContext context) {
    processor.destroyProcess(deep: false);
    processor.executeCode(actionCode);
    if (RuntimeProvider.of(context) == RuntimeMode.run) {
      processor.functions['initState']?.execute(processor, null, []);
    }

    return ProcessorProvider(
      processor,
      BlocBuilder<StateManagementBloc, StateManagementState>(
          buildWhen: (previous, current) => current.id == id,
          builder: (context, state) {
            ComponentOperationCubit.processor = processor;

            if (RuntimeProvider.of(context) == RuntimeMode.run) {
              processor.functions['build']?.execute(processor, null, [context]);
            }
            variables['context'] =
                FVBVariable('context', DataType.dynamic, value: context);

            return rootComponent?.build(context) ?? Container();
          }),
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
      name2 = name2.substring(0, i + 1) +
          name2[i + 1].toUpperCase() +
          name2.substring(i + 2);
    }
    return firstLetter + name2.replaceAll('_', '');
  }

  String code(final FlutterProject flutterProject) {
    String implementationCode = '';

    final List<String> importList = [];
    // rootComponent?.forEach((component) {
    //   if (component is Clickable) {
    //     for (final e in (component as Clickable).actionList) {
    //       if (e.arguments.isNotEmpty &&
    //           (e.arguments[0] is UIScreen?) &&
    //           e.arguments[0] != null) {
    //         importList.add((e.arguments[0] as UIScreen).importFile);
    //       }
    //     }
    //   } else if (component is CCustomPaint) {
    //     implementationCode += component.implCode;
    //   }
    // });
    if (this != flutterProject.mainScreen && !importList.contains('main')) {
      importList.add('main');

    }
    String staticVariablesCode = '';
    String dynamicVariablesDefinitionCode = '';
    String dynamicVariableAssignmentCode = '';

    String functionImplementationCode = '';
    if (this == flutterProject.mainScreen) {
      for (final function in CodeProcessor.predefinedFunctions.values) {
        if (function.functionCode != null) {
          functionImplementationCode += function.functionCode!;
        }
      }
      if (flutterProject.customComponents.isNotEmpty) {
        for (final customComponent in flutterProject.customComponents) {
          implementationCode += customComponent.implementationCode();
        }
      }
      for (final variable in ComponentOperationCubit
          .currentProject!.processor.variables.entries) {
        if ([
              DataType.string,
              DataType.fvbInt,
              DataType.fvbDouble,
              DataType.fvbBool
            ].contains(variable.value.dataType) &&
            (variable.value is VariableModel &&
                (variable.value as VariableModel).uiAttached)) {
          if (!(variable.value as VariableModel).isDynamic) {
            staticVariablesCode +=
            'const ${DataType.dataTypeToCode(variable.value.dataType)} ${variable.key} = ${LocalModel.valueToCode(variable.value.value)};';
          } else {
            dynamicVariablesDefinitionCode +=
                'late ${DataType.dataTypeToCode(variable.value.dataType)} ${variable.key};';
            // dynamicVariableAssignmentCode +=
            //     '${variable.key} = ${variable.value.};';
          }
        }
      }
    }



    final String className = getClassName;
    // ${rootComponent!.code()}
    String mainCode = this == flutterProject.mainScreen
        ? FVBEngine.instance.fvbToDart(flutterProject.actionCode)
        : '';
    final endBracket = mainCode.lastIndexOf('}');
    final uiScreenModifiedCode =
        FVBEngine.instance.getDartCode(processor, actionCode, (p0) {
      if (p0 == 'build') {
        return 'return ${rootComponent!.code()};';
      } else if (p0 == 'initState') {
        return 'super.initState();';
      }
    });
    if (this == flutterProject.mainScreen) {
      if (endBracket >= 0) {
        mainCode = mainCode.substring(0, endBracket) +
            '\n' +
            (rootComponent is! MaterialApp
                ? 'runApp(MaterialApp(home:const $className()));'
                : 'runApp(const $className());') +
            mainCode.substring(endBracket);
      } else {
        showToast('No main method Found');
      }
    }
    processor.destroyProcess(deep: false);
    processor.executeCode(actionCode, type: OperationType.checkOnly);
    return ''' 
    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart';
    import 'package:intl/intl.dart';
    import 'dart:math';
    
    ${importList.map((e) => '''import '$e.dart'; ''').join('\n')}
    ${models.map((e) => e.implementationCode).join(' ')}
    
    ${this == flutterProject.mainScreen ? '''
    $fvbRefresherCode
    $fvbLookUpCode
    $staticVariablesCode
    $dynamicVariablesDefinitionCode
    $mainCode
    ${(importFiles['showSnackbar'] ?? false) ? snackbarCode : ''}
    $functionImplementationCode 
 
    $implementationCode

Color hexToColor(String hexString) {
  if (hexString.length < 7) {
    return Colors.black;
  }
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  final colorInt = int.parse(buffer.toString(), radix: 16);
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
    ${variables.values.where((element) => element is VariableModel && element.uiAttached).map((e) => (e as VariableModel).code).join(' ')}
   
     @override
     void didChangeDependencies() {
      super.didChangeDependencies();
      dw=MediaQuery.of(context).size.width;
      dh=MediaQuery.of(context).size.height;
      $dynamicVariableAssignmentCode
     }
     $uiScreenModifiedCode
     
    }

    ''';
  }
}

class ProjectGroup {
  List<FlutterProject> projects = [];
}
