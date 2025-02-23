import 'dart:async';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// For web

// import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:uni_links_desktop/uni_links_desktop.dart';

import 'bloc/action_code/action_code_bloc.dart';
import 'bloc/component_drag/component_drag_bloc.dart';
import 'bloc/error/error_bloc.dart';
import 'bloc/key_fire/key_fire_bloc.dart';
import 'bloc/paint_obj/paint_obj_bloc.dart';
import 'bloc/state_management/state_management_bloc.dart';
import 'bloc/theme/theme_bloc.dart';
import 'common/extension_util.dart';
import 'common/responsive/responsive_dimens.dart';
import 'common/web/html_lib.dart' as html;
import 'common/web/io_lib.dart';
import 'constant/color_assets.dart';
import 'constant/font_style.dart';
import 'constant/preference_key.dart';
import 'cubit/authentication/authentication_cubit.dart';
import 'cubit/component_creation/component_creation_cubit.dart';
import 'cubit/component_operation/operation_cubit.dart';
import 'cubit/component_selection/component_selection_cubit.dart';
import 'cubit/screen_config/screen_config_cubit.dart';
import 'cubit/stack_action/stack_action_cubit.dart';
import 'cubit/user_details/user_details_cubit.dart';
import 'injector.dart';
import 'models/actions/action_model.dart';
import 'ui/authentication/auth_navigation.dart';
import 'ui/home/cubit/home_cubit.dart';
import 'ui/home/home_page.dart';
import 'ui/project/project_selection_page.dart';
import 'ui/route_not_found.dart';
import 'user_session.dart';
import 'widgets/common_circular_loading.dart';

GlobalKey<NavigatorState> rootNavigator = GlobalKey();

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // setUrlStrategy(PathUrlStrategy());
  }
  if (Platform.isWindows) {
    registerProtocol('fvb');
  }
  await Future.wait([
    initInjector(),
    dotenv.load(fileName: '.env'),
  ]);
  // await initDB();
  // if (Platform.isWindows) {
  // await KeyboardEvent.init();
  // get<KeyboardEvent>().startListening((keyEvent) {
  //   if (keyEvent.isKeyDown) {
  //     get<KeyFireBloc>().add(FireKeyDownEvent(keyEvent.vkName!));
  //   }
  //   if (keyEvent.isKeyUP) {
  //     get<KeyFireBloc>().add(FireKeyUpEvent(keyEvent.vkName!));
  //   }
  // });
  // } else if (kIsWeb) {
  // initWebKeyEvent();
  // }
  // doCodeTesting();
  if (kDebugMode) {
    runApp(const MyApp());
  } else {
    runZonedGuarded(() => runApp(const MyApp()), (error, stack) {
      print('RUN ZONE CACHED ERROR ${stack.toString()}');
    });
  }
}

void doCodeTesting() {
  final Processor processor = Processor(
    consoleCallback: (message, {List? arguments}) {
      if (message.startsWith('print:')) {
        print(':: => ${message.substring(6)}');
      }
      return null;
    },
    onError: (error, line) {
      print('XX => $error, LINE :: "$line"');
    },
    scopeName: 'test',
  );
  const code = '''
  enum ABC{
 a1,b2,c3
  }
  class Message{
  String text;
  bool my;
  static int abc;
  Message(this.text, this.my);
  void send({bool fast=false}){
  print("fast {{fast}}");
  }
  static void play(){
    print("playing");
    }
}
void waitFor(int milliseconds) async {
}
void main() {
final ab='hello';
final ABC abc=ABC.a1;
print(abc);
}
 ''';
  processor.executeCode(code, declarativeOnly: true);
  processor.functions['main']?.execute(processor, null, []);
  /*
  class Student{
  var roll;
  Student(this.roll);
  }
  var s1=Student(1);
  print(s1.roll);
  var d=Duration(1000);
  var count=0;
  var list=[];
  var t=Timer.periodic(d, (timer) {
    print("Hello {{list.length}}");
    count++;
    list.add(count);
    if(count>5){
      t.cancel();
    }
  });

  var count=0;
class Student {
  var name;
  var roll;
  var percent;
  var guideName;
  Student(this.name,this.roll,this.percent,this.guideName);
  }

  var studentList=[
  Student("Abrar",12,90,"guide 1")
  ];

 addStudent(){
 var name=lookUp("TextField0.2990.454").text;
 var roll=lookUp("TextField0.8520.487").text;
var percent=lookUp("TextField0.3150.119").text;
 var guide=lookUp("TextField0.1950.615").text;
   studentList.add(Student(name,toInt(roll),toInt(percent),guide));

refresh("ListView.builder0.9410.063");
print("hello {{}}");
 }
}

addStudent();

  get("https://api.goal-geek.com/api/v1/fixtures/18220155",(data){
  js=json.decode(data);
  print("{{js["id"]}}");
  },(error){
  });
  * */
  //FVB Language
  // Steps
  // 1. Implement lambda function
  // 2. Static variables & methods
  // 3. Future type variable
  // 4. Stream type variable
  // final FVBEngine engine=FVBEngine();
  // print('DART CODE \n${engine.fvbToDart(code)}');
}

void initWebKeyEvent() {
  html.window.onKeyDown.listen((event) {
    sl<KeyFireBloc>().add(FireKeyDownEvent(event.code!));
  });
  html.window.onKeyUp.listen((event) {
    sl<KeyFireBloc>().add(FireKeyUpEvent(event.code!));
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _userDetailsConfig = sl<UserDetailsCubit>();
  final _pref = sl<SharedPreferences>();

  @override
  void initState() {
    super.initState();

    rootNavigator = GlobalKey();
    _handleIncomingLinks();
  }

  void onLinkReceived(Map<String, String> query) {
    print('LINK GOT $query');
    if (query.containsKey('code')) {
      _userDetailsConfig.onFigmaCodeReceived(query['code']!);
    }
  }

  void _handleIncomingLinks() {
    if (!kIsWeb) {
      if (Platform.isWindows) {
        uriLinkStream.listen((event) {
          if (event != null) {
            onLinkReceived(event.queryParameters);
          }
        });
      } else if (Platform.isMacOS) {
        final _appLinks = AppLinks();
        _appLinks.getInitialLink().then((value) {
          if (value != null) onLinkReceived(value.queryParameters);
        });
        _appLinks.uriLinkStream.listen((value) {
          onLinkReceived(value.queryParameters);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    initScreenUtils(context);

    if (kIsWeb) {
      html.document.addEventListener('contextmenu', (event) => event.preventDefault());
    }
    if (!kDebugMode) {
      FlutterError.onError = (
        FlutterErrorDetails details, {
        bool forceReport = false,
      }) async {
        bool ifIsOverflowError = false;

        final exception = details.exception;
        if (exception is FlutterError) {
          ifIsOverflowError =
              !exception.diagnostics.any((e) => e.value.toString().startsWith('A RenderFlex overflowed by'));
        }

        /// TODO(HandleErrorDialog):
        // if (rootNavigator.currentContext != null) {
        //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        //     showConfirmDialog(
        //         title: 'Error', subtitle: exception.toString(), context: rootNavigator.currentContext!, positive: 'ok');
        //   });
        // }
        // Ignore if is overflow error.
        if (ifIsOverflowError) {
          print('Overflow error.');
        } else {
          FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
        }
      };
    }
    return ProviderScope(
      child: ScreenUtilInit(
        builder: (BuildContext context, Widget? child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => sl<AuthenticationCubit>(),
              ),
              BlocProvider(
                create: (context) => sl<StateManagementBloc>(),
              ),
              BlocProvider(
                create: (context) => sl<StackActionCubit>(),
              ),
              BlocProvider(
                create: (context) => _userDetailsConfig,
              ),
              BlocProvider(
                create: (context) => sl<OperationCubit>(),
              ),
              BlocProvider(
                create: (context) => sl<CreationCubit>(),
              ),
              BlocProvider(
                create: (context) => sl<SelectionCubit>(),
              ),
              BlocProvider(
                create: (context) => sl<EventLogBloc>(),
              ),
              BlocProvider(
                create: (context) => sl<ActionCodeBloc>(),
              ),
              BlocProvider(
                create: (context) => sl<KeyFireBloc>(),
              ),
              BlocProvider(
                create: (context) => sl<HomeCubit>(),
              ),
              BlocProvider(
                create: (context) => sl<ThemeBloc>(),
              ),
              BlocProvider(
                create: (context) => sl<ScreenConfigCubit>(),
              ),
              BlocProvider(
                create: (context) => sl<ComponentDragBloc>(),
              ),
              BlocProvider<PaintObjBloc>(
                create: (context) => PaintObjBloc(
                  sl<StateManagementBloc>(),
                  sl<SelectionCubit>(),
                ),
              ),
            ],
            child: BlocBuilder<ThemeBloc, ThemeState>(
              bloc: theme,
              builder: (context, state) {
                return GetMaterialApp(
                  title: 'FlutterPilot',
                  // scrollBehavior: MyCustomScrollBehavior(),
                  initialRoute: '/login',
                  navigatorKey: rootNavigator,
                  builder: (context, child) {
                    ScreenUtil.init(context,
                        designSize:
                            res(context, const Size(1920, 1000), const Size(764, 1024), MediaQuery.of(context).size));
                    return LoaderOverlay(
                      overlayWidth: 100,
                      overlayHeight: 100,
                      overlayColor: Colors.transparent,
                      useDefaultLoading: false,
                      overlayWidgetBuilder: (_) => Stack(
                        children: [
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                            child: Container(),
                          ),
                          const Align(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: LoadingIndicator(
                                    indicatorType: Indicator.ballSpinFadeLoader,
                                    colors: [ColorAssets.theme],
                                    strokeWidth: 5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // overlayOpacity: 0.5,
                      child: child!,
                    );
                  },
                  // initialRoute: '/run-497aa95cb338b4e1fd95a0f9c26a63d1',
                  onGenerateRoute: _generateRoute,
                  onGenerateInitialRoutes: (route) {
                    return [_generateRoute(RouteSettings(name: route))!];
                  },
                  theme: ThemeData(
                      useMaterial3: false,
                      visualDensity: VisualDensity.standard,
                      primaryColor: ColorAssets.theme,
                      focusColor: ColorAssets.theme.withOpacity(0.2),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                            foregroundColor: ColorAssets.theme, surfaceTintColor: ColorAssets.theme),
                      ),
                      filledButtonTheme: FilledButtonThemeData(
                          style: FilledButton.styleFrom(
                        backgroundColor: ColorAssets.theme,
                      )),
                      checkboxTheme: CheckboxThemeData(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        checkColor: WidgetStateProperty.all(theme.background1),
                        overlayColor: WidgetStatePropertyAll(theme.background1),
                        fillColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected) ? ColorAssets.theme : theme.background1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(
                            color: ColorAssets.theme.withOpacity(0.7),
                            width: 1.5,
                          ),
                        ),
                      ),
                      radioTheme: const RadioThemeData(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                      )),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static const kProjects = '/projects';

  Route? _generateRoute(RouteSettings settings) {
    final link = settings.name?.replaceAll('//', '/').replaceAll('#', '') ?? '';
    print('URL :: $link');
    if (link == '/login') {
      return getRoute((p0) => const AuthNavigation(), '/login');
    }
    if (link.startsWith(kProjects)) {
      if (settings.arguments is List) {
        return getRoute(
            (p0) => HomePage(
                  userId: ((settings.arguments! as List)[0] as String),
                  projectId: (settings.arguments! as List)[1] as String,
                ),
            '$kProjects/${(settings.arguments! as List)[1]}');
      } else if (settings.arguments is String) {
        return getRoute(
            (p0) => ProjectSelectionPage(
                  userId: settings.arguments as String,
                ),
            '$kProjects');
      } else if (link.length > kProjects.length + 5) {
        String projectId = link.substring(kProjects.length + 1);
        if (projectId.endsWith('/')) {
          projectId = projectId.substring(0, projectId.length - 1);
        }
        if (!_pref.containsKey(PrefKey.UID)) {
          _pref.setString(PrefKey.projectId, projectId);
          return getRoute((p0) => const AuthNavigation(), '/login');
        }

        final _userSession = sl<UserSession>();
        _userSession.user.userId = _pref.getString(PrefKey.UID);
        if (projectId.length > 5) {
          return getRoute(
              (p0) => HomePage(
                    projectId: projectId,
                    userId: _pref.getString(PrefKey.UID)!,
                  ),
              '$kProjects/$projectId');
        }
        return getRoute(
            (p0) => ProjectSelectionPage(
                  userId: _pref.getString(PrefKey.UID)!,
                ),
            '$kProjects');
      } else {
        return getRoute((p0) => const AuthNavigation(), '/login');
      }
    } else if (link == '/run' && settings.arguments is List && (settings.arguments as List).length == 2) {
      final args = settings.arguments as List;
      return getRoute(
          (p0) => HomePage(
                userId: args[0] as String,
                projectId: args[1] as String,
                runMode: true,
              ),
          '/run/${args[1]}');
    } else if (link.startsWith('/run')) {
      final projectId = link.substring(5);
      if (projectId.length > 5) {
        return getRoute(
            (p0) => HomePage(
                  projectId: projectId,
                  userId: null,
                  runMode: true,
                ),
            link);
      }
    } else if (link.startsWith('/figma')) {
      final settingsUri = Uri.parse(link);
      final code = settingsUri.queryParameters['code'];
      if (code != null) {
        sl<UserSession>().user.userId = _pref.getString(PrefKey.UID);
        print('USER ${_pref.getString(PrefKey.UID)}');
        return getRoute(
            (p0) => Material(
                  child: FutureBuilder(
                      future: _userDetailsConfig.onFigmaCodeReceived(code),
                      builder: (context, value) {
                        if (value.connectionState == ConnectionState.done && value.data == null) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Figma Connected',
                                      style: AppFontStyle.lato(20),
                                    ),
                                    20.wBox,
                                    const Icon(
                                      Icons.done,
                                      size: 40,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 70,
                                ),
                                Text(
                                  'You can close this window',
                                  style: AppFontStyle.lato(18),
                                ),
                              ],
                            ),
                          );
                        }
                        if (value.hasError || value.data != null) {
                          return Row(
                            children: [
                              Text('Error ${value.data ?? value.error}'),
                              20.wBox,
                              const Icon(Icons.error),
                            ],
                          );
                        }
                        return const Center(
                          child: CommonCircularLoading(),
                        );
                      }),
                ),
            link);
      }
    }
    return getRoute((p0) => const RouteNotFound(), link);
  }
}

getRoute(Widget Function(BuildContext) builder, String? name, {bool anim = true}) {
  if (!anim) {
    return CustomPageRoute(builder: builder, settings: name != null ? RouteSettings(name: name) : null);
  }
  return PageRouteBuilder(
      pageBuilder: (context, _, __) => builder.call(context),
      settings: name != null ? RouteSettings(name: name) : null,
      transitionsBuilder: (context, animation, _, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      });
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        // etc.
      };
}
