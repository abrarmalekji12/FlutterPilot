import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/ui/route_not_found.dart';
import 'package:url_strategy/url_strategy.dart';

import 'bloc/action_code/action_code_bloc.dart';
import 'bloc/error/error_bloc.dart';
import 'bloc/state_management/state_management_bloc.dart';
import 'common/compiler/code_processor.dart';
import 'common/html_lib.dart' as html;
import 'common/shared_preferences.dart';
import 'constant/app_colors.dart';
import 'cubit/authentication/authentication_cubit.dart';
import 'cubit/component_creation/component_creation_cubit.dart';
import 'cubit/component_operation/component_operation_cubit.dart';
import 'cubit/flutter_project/flutter_project_cubit.dart';
import 'cubit/stack_action/stack_action_cubit.dart';
import 'injector.dart';
import 'models/actions/action_model.dart';
import 'ui/home/landing_page.dart';
import 'ui/home_page.dart';
import 'ui/project_selection_page.dart';

/// Bubble sort algo
// sort(arr){
//   i=0;
//   while(i<7){
//     j=i+1;
//     while(j<7){
//       if(arr[i]>arr[j]){
//         t=arr[i];
//         arr[i]=arr[j];
//         arr[j]=t;
//       }
//       j=j+1;
//     }
//     i=i+1;
//   }
// }
// arr=[4,2,1,6,1,10,3];
// sort(arr);
// print("{{arr}}");
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  initInjector();
  await Preferences.load();
  final CodeProcessor processor = CodeProcessor(
      consoleCallback: (message) {
        if (message.startsWith('print:')) {
          print(':: => ${message.substring(6)}');
        }
        return null;
      },
      onError: (error, line) {
        print('XX => $error, LINE :: "$line"');
      },
      scopeName: 'test');
  const code = '''
bool getVal()=>false;
final i=0;
String str=getVal()?"Hello World":"No World";
print(str);

 ''';

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

  */
  processor.executeCode(code, declarativeOnly: false);
  /*
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
  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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

        // Ignore if is overflow error.
        if (ifIsOverflowError) {
          print('Overflow error.');
        } else {
          FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
        }
      };
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => get<AuthenticationCubit>(),
        ),
        BlocProvider(
          create: (context) => get<StateManagementBloc>(),
        ),
        BlocProvider(
          create: (context) => get<StackActionCubit>(),
        ),
        BlocProvider(
          create: (context) => get<FlutterProjectCubit>(),
        ),
        BlocProvider(
          create: (context) => get<ComponentOperationCubit>(),
        ),
        BlocProvider(
          create: (context) => get<ComponentCreationCubit>(),
        ),
        BlocProvider(
          create: (context) => get<ErrorBloc>(),
        ),
        BlocProvider(
          create: (context) => get<ActionCodeBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Visual Builder',
        scrollBehavior: MyCustomScrollBehavior(),
        initialRoute: '',
        routes: {
          '': (context) => const LandingPage(),
        },
        // initialRoute: '/run-497aa95cb338b4e1fd95a0f9c26a63d1',
        onGenerateRoute: (settings) {
          final link = settings.name ?? '';
          if (link.startsWith('/projects')) {
            if (settings.arguments is List) {
              return getRoute(
                  (p0) => HomePage(
                        userId: ((settings.arguments! as List)[0] as int),
                        projectName: (settings.arguments! as List)[1] as String,
                      ),
                  '/projects/${(settings.arguments! as List)[1]}');
            } else if (get<FlutterProjectCubit>().userId != -1) {
              return getRoute(
                  (p0) => ProjectSelectionPage(
                        userId: get<FlutterProjectCubit>().userId,
                      ),
                  '/projects');
            } else {
              return getRoute((p0) => const LandingPage(), '');
            }
          } else if (link == '/run' && settings.arguments is List) {
            final args = settings.arguments as List;
            return getRoute(
                (p0) => HomePage(
                      userId: args[0] as int,
                      projectName: args[1] as String,
                      runMode: true,
                    ),
                '/run');
          } else if (link.startsWith('/run')) {
            final list = RunKey.decrypt(link.substring(5));
            if (list != null) {
              return getRoute(
                  (p0) => HomePage(
                        projectName: list[1],
                        userId: list[0],
                        runMode: true,
                      ),
                  link);
            }
          }
          return getRoute((p0) => const RouteNotFound(), link);
        },
        theme: ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity, primaryColor: AppColors.theme),
      ),
    );
  }
}

getRoute(Widget Function(BuildContext) builder, String? name, {bool anim = true}) {
  if (!anim) {
    return CustomPageRoute(builder: builder, settings: name != null ? RouteSettings(name: name) : null);
  }
  return MaterialPageRoute(builder: builder, settings: name != null ? RouteSettings(name: name) : null);
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}

class RunKey {
  static String encrypt(int userId, String project) {
    return '${userId}_$project';
  }

  static List<dynamic>? decrypt(String input) {
    if (input.contains('_')) {
      final split = input.split('_');
      final id = int.tryParse(split[0]);
      if (id == null) {
        return null;
      }
      return [id, split[1]];
    }
    return null;
  }
}
