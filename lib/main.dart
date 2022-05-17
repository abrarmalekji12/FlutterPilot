import 'dart:html' as html;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_strategy/url_strategy.dart';
import 'common/compiler/code_processor.dart';
import 'common/logger.dart';
import 'common/shared_preferences.dart';
import 'cubit/authentication/authentication_cubit.dart';
import 'ui/authentication/login.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'constant/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await Preferences.load();
  final CodeProcessor processor=CodeProcessor();
   processor.executeCode('''
   b=math.sin(pi/2);
   r=randInt(100);
   print("hello {{b}} {{ifElse(r%2==0,"{{r}} is Even","{{r}} is Odd")}}");
  ''',(message)
   {
     logger('console out :: $message');
   },(error)
   {
     logger('Error :: $error ');
   });
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
    return BlocProvider(

      create: (context) => AuthenticationCubit(),
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
