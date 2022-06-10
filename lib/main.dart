import 'dart:html' as html;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_strategy/url_strategy.dart';
import 'bloc/state_management/state_management_bloc.dart';
import 'common/compiler/code_processor.dart';
import 'common/shared_preferences.dart';
import 'cubit/authentication/authentication_cubit.dart';
import 'injector.dart';
import 'ui/authentication/login.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'constant/app_colors.dart';

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
  final CodeProcessor processor = CodeProcessor(consoleCallback: (message) {
    print(':: => $message');
  }, onError: (error) {
    print('XX => $error ');
  });
  const code = '''
  class Student {
  name:String;
  age:int;
  fun1:Function;
  Student(this.name,this.age,this.fun1);
  
  toJson(){
  return {
  'name': name,
  'age': age
  };
  }
  }
  list=[3,5,45];  
  fun1=(a,b){
  return a+b;
  };
  print(fun1(3,5));
 ''';
  /*
  get("https://api.goal-geek.com/api/v1/fixtures/18220155",(data){
  js=json.decode(data);
  print("{{js["id"]}}");
  },(error){
  });
  * */
  processor.executeCode(code);
  // final FVBEngine engine=FVBEngine();
  // print('DART CODE \n${engine.fvbToDart(code)}');
  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    html.document
        .addEventListener('contextmenu', (event) => event.preventDefault());
    if (!kDebugMode) {
      FlutterError.onError = (FlutterErrorDetails details, {
        bool forceReport = false,
      }) async {
        bool ifIsOverflowError = false;

        final exception = details.exception;
        if (exception is FlutterError) {
          ifIsOverflowError = !exception.diagnostics.any((e) =>
              e.value.toString().startsWith('A RenderFlex overflowed by'));
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
          create: (context) => AuthenticationCubit(),
        ),
        BlocProvider(
          create: (context) => get<StateManagementBloc>(),
          lazy:true,
        ),
      ],
      child: GetMaterialApp(
        title: 'Flutter Visual Builder',
        scrollBehavior: MyCustomScrollBehavior(),
        theme: ThemeData(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            primaryColor: AppColors.theme),
        home: const LoginPage(),
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices =>
      {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
