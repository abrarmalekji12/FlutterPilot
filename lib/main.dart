import 'dart:html' as html;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:url_strategy/url_strategy.dart';

import 'bloc/state_management/state_management_bloc.dart';
import 'common/compiler/code_processor.dart';
import 'common/converter/code_converter.dart';
import 'common/shared_preferences.dart';
import 'constant/app_colors.dart';
import 'cubit/authentication/authentication_cubit.dart';
import 'injector.dart';
import 'ui/authentication/login.dart';

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
    if (message.startsWith('print:')) {
      print(':: => ${message.substring(6)}');
    }
    return null;
  }, onError: (error,line) {
    print('XX => $error, LINE :: "$line"');
  });
  const code = '''
  // class Student{
  // var roll;
  // Student(this.roll);
  // }
  // var s1=Student(1);
  // print(s1.roll);
  // var d=Duration(1000);
  // var count=0;
  // var list=[];
  // var t=Timer.periodic(d, (timer) {
  //   print("Hello {{list.length}}");
  //   count++;
  //   list.add(count);
  //   if(count>5){
  //     t.cancel();
  //   }
  // });
  
  class ABC{

 
  }
  var name;
  var roll;
  setName(roll2,{nm="LMN"}){
  name=nm;
  roll=roll2;
  }
  
  
  
  setName(100,nm:"CDE");
  var d=Duration(milliseconds: 1000);
  print("{{name}} {{roll}}");
}
 ''';
  processor.executeCode(code);
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
    html.document
        .addEventListener('contextmenu', (event) => event.preventDefault());
    if (!kDebugMode) {
      FlutterError.onError = (
        FlutterErrorDetails details, {
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
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
