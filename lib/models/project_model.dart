import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/app_config_code.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';

import '../bloc/error/error_bloc.dart';
import '../bloc/state_management/state_management_bloc.dart';
import '../collections/project_info_collection.dart';
import '../common/analyzer/package_analyzer.dart';
import '../common/api/api_model.dart';
import '../common/common_methods.dart';
import '../common/converter/code_converter.dart';
import '../common/converter/string_operation.dart';
import '../common/fvb_arch/fvb_refresher.dart';
import '../common/undo/revert_work.dart';
import '../components/component_list.dart';
import '../constant/string_constant.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/stack_action/stack_action_cubit.dart';
import '../data/remote/firestore/firebase_bridge.dart';
import '../injector.dart';
import '../runtime_provider.dart';
import '../screen_model.dart';
import '../ui/action_ui.dart';
import '../ui/boundary_widget.dart';
import '../ui/settings/models/collaborator.dart';
import '../ui/settings/models/project_setting_model.dart';
import '../user_session.dart';
import '../view_model/auth_viewmodel.dart';
import 'fvb_ui_core/component/component_model.dart';
import 'fvb_ui_core/component/custom_component.dart';
import 'other_model.dart';
import 'parameter_model.dart';
import 'variable_model.dart';

final UserProjectCollection _collection = sl<UserProjectCollection>();

class FVBProject with Viewable {
  static const defaultActionCode = '''
    void main(){
    print("Hello World!");
    }
    ''';
  final RevertWork revertWork = RevertWork.init();

  Uint8List? thumbnail;
  late ProjectSettingsModel settings;
  late Processor processor;
  String name;
  String userId;
  final FVBUser? user;
  late String id;
  final String? device;
  @override
  Component? rootComponent;

  String actionCode = '';

  // final List<VariableModel> variables = [];
  // final List<LocalModel> models = [];
  Screen? mainScreen;
  final List<Screen> screens = [];
  final List<CustomComponent> customComponents = [];
  final List<String> imageList;
  final List<CommonParam> commonParams = [];
  late ApiGroupModel apiModel;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<String>? collaboratorIds;

  FVBProject(this.name, this.userId,
      {this.device,
      this.mainScreen,
      this.rootComponent,
      this.createdAt,
      this.updatedAt,
      this.user,
      this.collaboratorIds,
      this.actionCode = defaultActionCode,
      required this.imageList,
      ProjectSettingsModel? settings}) {
    if (settings != null) {
      this.settings = settings;
    } else {
      this.settings = ProjectSettingsModel(
          isPublic: false,
          collaborators: [],
          target: TargetPlatformType.values
              .asMap()
              .map((k, e) => MapEntry(e, true)));
    }
    processor = sl<Processor>();
  }

  String get scopeName => 'MainScope';

  Map<String, FVBVariable> get variables => processor.variables;

  set variables(Map<String, FVBVariable> value) {
    processor.variables.clear();
    processor.variables.addAll(value);
  }

  factory FVBProject.createNewProject(String name, FVBUser user) {
    final FVBProject project = FVBProject(
      name,
      user.userId!,
      actionCode: defaultActionCode,
      device: 'iPhone X',
      user: user,
      imageList: [],
      updatedAt: DateTime.now(),
    );
    _collection.project = project;
    project.createdAt = DateTime.now();
    project.rootComponent = CMaterialApp();
    project.apiModel = ApiGroupModel([], [], project);
    return project;
  }

  String get packageName => StringOperation.toSnakeCase(name);

  List<FVBImage> getAllUsedImages() {
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
        .map((e) => FVBImage(
              bytes: byteCache[e],
              name: e,
            ))
        .toList();
  }

  String code() {
    controllerIds.clear();
    String mainCode = FVBEngine.instance.fvbToDart(actionCode);
    final endBracket = mainCode.lastIndexOf('}');
    if (mainScreen == null) {
      return '';
    }
    final rootComponent = mainScreen!.rootComponent;
    if (endBracket >= 0) {
      mainCode = '''${PackageAnalyzer.getPackages(this, null, actionCode)}    
      import '${mainScreen!.import}';
      ${rootComponent is! CMaterialApp ? screens.map((e) => "import '${e.import}';").join('\n') : ''}
     
      ${systemProcessor.variables.values.map((e) => e.code).join('\n')}
      ${processor.variables.values.where((element) => element is VariableModel && element.uiAttached).map((e) => e.code).join('\n')}
      ''' +
          mainCode.substring(0, endBracket) +
          '\n' +
          (rootComponent is! CMaterialApp
              ? 'runApp(MaterialApp(home:const ${mainScreen!.getClassName}(),${AppConfigCode.generateMaterialCode(this)}),);'
              : 'runApp(const ${mainScreen!.getClassName}(),);') +
          mainCode.substring(endBracket);
    } else {
      showToast('No main method Found');
    }
    return mainCode;
  }

  String dependencyCode() {
    String dynamicVariablesDefinitionCode = '';
    String functionImplementationCode = '';
    for (final function in Processor.predefinedFunctions.values) {
      if (function.functionCode != null) {
        functionImplementationCode += function.functionCode!;
      }
    }
    return '''
    ${PackageAnalyzer.getPackages(this, null, actionCode)}    

    $fvbRefresherCode
    $fvbLookUpCode
    $dynamicVariablesDefinitionCode
   class Pages{
   ${screens.map((screen) => "final ${StringOperation.toCamelCase(screen.name, startWithLower: true)} = '${StringOperation.toSnakeCase(screen.name)}';").join('\n')}
   }
   class CustomWidgets{
   ${customComponents.map((custom) => '''Widget ${StringOperation.toCamelCase(custom.name, startWithLower: true)}(${custom.argumentVariables.isNotEmpty ? '{${custom.argumentVariables.map((e) => e.name).join(',')}}' : ''}){
   return ${custom.name}(${custom.argumentVariables.map((e) => '${e.name}:${e.name}').join(',')});
   }
   ''').join('\n')}
   }
   
   abstract class App
   {
   static final Pages pages=Pages();
   static final CustomWidgets widgets=CustomWidgets();
   
  static void push(BuildContext context, String route, [arguments]) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }
  static void pushReplacement(BuildContext context, String route, [arguments]) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }
  static void pop(BuildContext context) {
    Navigator.pop(context);
  }
  static dynamic arguments(BuildContext context) => ModalRoute.of(context)?.settings.arguments;
  
  static void dialog(BuildContext context, Widget widget) {
    showDialog(
      context: context,
      builder: (context) => widget,
    );
  }
  static void bottomSheet(BuildContext context, Widget widget) {
    showBottomSheet(
      context: context,
      builder: (context) => widget,
    );
  }
  
  static void showSnackbar(BuildContext context,String content,Duration duration){
     ScaffoldMessenger.maybeOf(context)!
      .showSnackBar(SnackBar(
    content: Text(
      content,
      style: const TextStyle(fontSize:14, color: Colors.white),
      textAlign: TextAlign.center,
    ),
    // backgroundColor: Colors.grey,
    duration:duration,
  ));
    }
    

  static Future<void> showAlertDialog(BuildContext context,
      {title,
      subtitle,
      positive,
      negative,
      VoidCallback? positiveCallback,
      VoidCallback? negativeCallback,
      bool dismissible = false}) async {
    await AnimatedDialog.show(
        context,
        MaterialAlertDialog(
          title: title,
          subtitle: subtitle,
          positiveButtonText: positive,
          negativeButtonText: negative,
          onPositiveTap: positiveCallback,
          onNegativeTap: negativeCallback,
        ),
        key: title,
        dismissible: dismissible,
        rootNavigator: true);
  }
  
    static Future<DateTime?> datePicker(BuildContext context,
      {required DateTime initialDate, required DateTime firstDate, required DateTime lastDate}) async {
    return await showDatePicker(context: context, initialDate: initialDate, firstDate: firstDate, lastDate: lastDate);
  }

  static Future<TimeOfDay?> timePicker(BuildContext context, {required TimeOfDay initialTime}) async {
    return await showTimePicker(context: context, initialTime: initialTime);
  }
  
    static Apis get apis => myApis; 
   
    ${settings.firebaseConnect != null ? 'static FirebaseFirestore get firestore => FirebaseFirestore.instance;' : ''}
   
   }
   
    $functionImplementationCode 

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

void openDrawer(BuildContext context) {
  Scaffold.of(context).openDrawer();
}

void closeDrawer(BuildContext context) {
  Scaffold.of(context).closeDrawer();
}
void openEndDrawer(BuildContext context) {
  Scaffold.of(context).openEndDrawer();
}

void closeEndDrawer(BuildContext context) {
  Scaffold.of(context).closeEndDrawer();
}
    ''';
  }

  String extensions() {
    return '''
    import '../main.dart';
extension MyNum on num {
  double get w => dw*toDouble();
  double get h => dh*toDouble();
}
    ''';
  }

  Widget run(final BuildContext context, final BoxConstraints constraints,
      {bool navigator = false, Screen? screen, bool debug = false}) {
    Processor.errorMessage = '';
    if (debug) {
      deviceScaffoldMessenger = null;
      navigationKey = null;
    } else {
      deviceScaffoldMessenger = releaseDeviceScaffoldMessenger;
      navigationKey = releaseNavigatorKey;
    }
    context
        .read<EventLogBloc>()
        .add(ClearMessageEvent(RuntimeProvider.of(context)));
    sl<SelectionCubit>().clearErrors();
    systemProcessor.variables['dw']!.setValue(processor, constraints.maxWidth);
    systemProcessor.variables['dh']!.setValue(processor, constraints.maxHeight);
    processor.destroyProcess(deep: true);
    componentIdCache.clear();
    OperationCubit.paramProcessor = processor;
    processor.executeCode(_collection.project!.actionCode);
    processor.functions['main']?.execute(processor, null, []);
    disableError = false;
    if (!navigator) {
      processor.finished = true;
      return ProcessorProvider(
        processor: sl<Processor>(),
        child: ViewableProvider(
          screen: screen ?? mainScreen!,
          child: Builder(builder: (context) {
            return rootComponent?.build(context) ?? const Offstage();
          }),
        ),
      );
    }
    final _actionCubit = sl<StackActionCubit>();

    return ProcessorProvider(
      processor: sl<Processor>(),
      child: ViewableProvider(
        screen: mainScreen!,
        child: Builder(builder: (context) {
          return Scaffold(
            key: deviceScaffoldMessenger!,
            body: Stack(
              children: [
                rootComponent?.build(context) ?? const Offstage(),
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
      ),
    );
  }

  ProjectPermission userRole(UserSession user) =>
      settings.collaborators
          ?.firstWhereOrNull((e) => e.userId == user.user.userId)
          ?.permission ??
      (user.user.userId == userId
          ? ProjectPermission.owner
          : ProjectPermission.none);

  factory FVBProject.fromJson(json) {
    final project = FVBProject(
      json['name'],
      json['userId'],
      user: json['user'] != null ? FVBUser.fromJson(json['user']) : null,
      device: json['device'],
      collaboratorIds: json['collaboratorIds'] != null
          ? List<String>.from(json['collaboratorIds'])
          : null,
      createdAt: json['createdAt'] != null
          ? FirebaseDataBridge.timestampToDate(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? FirebaseDataBridge.timestampToDate(json['updatedAt'])
          : null,
      imageList:
          json['imageList'] != null ? List<String>.from(json['imageList']) : [],
      actionCode: json['actionCode'] ?? '',
      settings: json['settings'] != null
          ? ProjectSettingsModel.fromJson(json['settings'])
          : null,
    )..id = json['id'];
    if (json['rootComponent'] != null) {
      project.rootComponent =
          Component.fromJson(json['rootComponent'], project);
    } else {
      project.rootComponent = CMaterialApp();
    }
    final variables = List.from(json['variables'] ?? [])
        .map((e) => VariableModel.fromJson(e..['uiAttached'] = true));
    project.variables.clear();
    for (final variable in variables) {
      project.variables[variable.name] = variable;
    }
    return project;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'userId': userId,
        'user': user?.toJson(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'collaboratorIds': collaboratorIds,
        'rootComponent': rootComponent?.toJson(),
        'variables': variables.values
            .where((element) =>
                (element is VariableModel) &&
                element.uiAttached &&
                !element.isDynamic)
            .map((element) => element.toJson())
            .toList(growable: false),
        'device': device,
        'settings': settings.toJson(),
        'imageList': imageList,
        'mainScreen': mainScreen?.id,
        'actionCode': actionCode,
      };
}

class CommonParam {
  final Parameter parameter;
  final String name;
  final Set<Component> connected = {};

  CommonParam(this.parameter, this.name);

  String get fileName =>
      '${StringOperation.toSnakeCase(parameter.displayName?.replaceAll(' ', '') ?? parameter.info.getName() ?? 'other')}';

  String get className => 'Common${StringOperation.toCamelCase(fileName)}';

  String get implCode {
    final nam = (parameter as UsableParam).usableName;
    (parameter as UsableParam).usableName = null;
    final paramCode = parameter.code(true);
    (parameter as UsableParam).usableName = nam;
    String code = parameter.info.getName() != null
        ? paramCode.substring(paramCode.indexOf(':') + 1)
        : paramCode;
    if (code.endsWith(',')) {
      code = code.substring(0, code.length - 1);
    }
    return 'static final $name = $code;';
  }

  @override
  String toString() {
    return '$name : ${parameter.hashCode}';
  }
}

class Screen with Viewable {
  static const defaultActionCode = '''
    void initState(){
    // will execute first time only
    }
    
    void build(context){
    // will execute every time widget rebuild
    }
    ''';
  late final Processor processor;
  String name;
  String actionCode;
  Component? rootComponent;
  late String id;
  final DateTime createdAt;
  FVBProject? project;

  Screen(this.name, this.createdAt,
      {this.actionCode = '',
      this.project,
      String? id,
      List<VariableModel>? parentVars}) {
    this.id = id ?? 'screen_' + name + '_${DateTime.now().toString()}';
    processor = Processor.build(
        parent: parentVars != null
            ? (sl<Processor>().clone((p0, {arguments}) {
                return null;
              }, (p0, p1) {}, true)
              ..variables.removeWhere(
                  (key, value) => value is! VariableModel || value.deletable)
              ..variables.addAll(parentVars
                  .asMap()
                  .map((key, value) => MapEntry(value.name, value))))
            : project?.processor,
        name: name);
    processor.functions['setState'] = FVBFunction('setState', null, [
      FVBArgument('callback', dataType: DataType.fvbFunction)
    ], dartCall: (arguments, instance) {
      if (arguments[0] is FVBTest) {
        return;
      }
      if (arguments[0] is FVBFunction) {
        (arguments[0] as FVBFunction).execute(processor, instance, []);
      }
      (arguments.last as Processor)
          .consoleCallback
          .call('api:refresh|${this.id}');
    });
  }

  String get fileName => StringOperation.toSnakeCase(name);

  String get import =>
      'package:${collection.project!.packageName}/ui/page/${fileName}.dart';

  toJson() => {
        'id': id,
        'name': name,
        'userId': project?.userId,
        'actionCode': actionCode,
        'root': rootComponent?.toJson(),
        'variables': variables.values
            .where((element) => element is VariableModel && element.uiAttached)
            .map((e) => e.toJson())
            .toList(growable: false),
        'createdAt': FirebaseDataBridge.timestamp(createdAt),
        'projectId': project?.id,
      };

  Screen clone({String? name, FVBProject? project}) {
    return Screen(
      name ?? this.name,
      DateTime.now(),
      actionCode: actionCode,
      project: project ?? this.project,
    )
      ..rootComponent =
          rootComponent?.clone(null, deepClone: true, connect: false)
      ..variables
          .addAll(variables.map((key, value) => MapEntry(key, value.clone())));
  }

  Map<String, FVBVariable> get variables => processor.variables;

  factory Screen.mainUI(FVBProject project) {
    final Screen uiScreen = Screen(
      'HomePage',
      DateTime.now(),
      actionCode: defaultActionCode,
      project: project,
    );
    uiScreen.rootComponent = componentList['MaterialApp']!();
    return uiScreen;
  }

  factory Screen.fromJson(Map<String, dynamic> json,
      {List<VariableModel>? parentVars, FVBProject? project}) {
    final screen = Screen(
      json['name'],
      FirebaseDataBridge.timestampToDate(json['createdAt']) ?? DateTime.now(),
      parentVars: parentVars,
      project: project,
      id: json['id'],
    );
    screen.actionCode = json['actionCode'] ?? defaultActionCode;
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

  factory Screen.otherScreen(final String name, FVBProject project,
      {String type = 'screen'}) {
    final Screen uiScreen = Screen(name, DateTime.now(),
        project: project, actionCode: defaultActionCode);
    uiScreen.rootComponent = type == 'screen'
        ? componentList['Scaffold']!()
        : componentList['Container']!();
    return uiScreen;
  }

  Widget? build(BuildContext context) {
    processor.destroyProcess(deep: false);
    processor.executeCode(actionCode);
    processor.variables['context'] =
        FVBVariable('context', DataType.fvbDynamic, value: context);
    final mode = RuntimeProvider.of(context);
    if (mode == RuntimeMode.run) {
      processor.functions['initState']?.execute(processor, null, []);
    }
    return ProcessorProvider(
      processor: processor,
      child: BlocBuilder<StateManagementBloc, StateManagementState>(
          buildWhen: (previous, current) =>
              current.id == id && current.mode == mode,
          builder: (context, state) {
            OperationCubit.paramProcessor = processor;
            if (RuntimeProvider.of(context) == RuntimeMode.run) {
              processor.functions['build']?.execute(processor, null, [context],
                  defaultProcessor: processor);
            }
            processor.variables['context'] =
                FVBVariable('context', DataType.fvbDynamic, value: context);
            return rootComponent?.build(context) ?? const Offstage();
          }),
    );
  }

  String get getClassName {
    return StringOperation.toCamelCase(name);
  }

  String code(final FVBProject flutterProject) {
    final String className = getClassName;
    if (actionCode.isEmpty) {
      actionCode = defaultActionCode;
    }
    print('ACTION $actionCode');
    final uiScreenModifiedCode =
        FVBEngine.instance.getDartCode(processor, actionCode, (p0) {
      if (p0 == 'build') {
        final code = rootComponent!.code();
        return FunctionModifier('Widget ', 'return $code;');
      } else if (p0 == 'initState') {
        return FunctionModifier('void ', 'super.initState();');
      }
      return null;
    });
    processor.destroyProcess(deep: false);
    processor.executeCode(actionCode,
        type: OperationType.checkOnly, config: const ProcessorConfig());
    return '''
    ${PackageAnalyzer.getPackages(flutterProject, rootComponent, actionCode)}
   
    class $className extends StatefulWidget {
    const $className({Key? key}) : super(key: key);

    @override
   State<${className}> createState() => _${className}State();
    }

    class _${className}State extends State<$className> {
    ${variables.values.where((element) => element is VariableModel && element.uiAttached).map((e) => (e as VariableModel).code).join(' ')}
   
     @override
     void didChangeDependencies() {
      super.didChangeDependencies();
      dw=MediaQuery.of(context).size.width;
      dh=MediaQuery.of(context).size.height;
     }
     $uiScreenModifiedCode
     
    }

    ''';
  }
}

class ProjectGroup {
  List<FVBProject> projects = [];
}
