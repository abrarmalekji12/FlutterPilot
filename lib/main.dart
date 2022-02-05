import 'dart:html' as html;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/common/compiler/code_processor.dart';
import 'package:flutter_builder/ui/project_selection_page.dart';
import 'common/logger.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'constant/app_colors.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    html.document
        .addEventListener('contextmenu', (event) => event.preventDefault());
    // if(!kDebugMode) {
    //   FlutterError.onError = (
    //     FlutterErrorDetails details, {
    //     bool forceReport = false,
    //   }) async {
    //     bool ifIsOverflowError = false;
    //
    //     final exception = details.exception;
    //     if (exception is FlutterError) {
    //       ifIsOverflowError = !exception.diagnostics.any((e) =>
    //           e.value.toString().startsWith('A RenderFlex overflowed by'));
    //     }
    //
    //     // Ignore if is overflow error.
    //     if (ifIsOverflowError) {
    //       print('Overflow error.');
    //     } else {
    //       FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
    //     }
    //   };
    // }
    return GetMaterialApp(
      title: 'Flutter Visual Builder',
      scrollBehavior: MyCustomScrollBehavior(),
      onGenerateRoute: onGenerateRoute,
      theme: ThemeData(
          visualDensity: VisualDensity.standard, primaryColor: AppColors.theme),
      home: const ProjectSelectionPage(),
    );
  }

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    logger('generate route ${settings.name} ${settings.arguments}');
    // if (settings.name!.startsWith('/projects')) {
    //   return PageRouteBuilder(
    //     pageBuilder: (context, animation1, animation2) {
    //       return HomePage(
    //         projectName: settings.name!.split('/')[2],
    //       );
    //     },
    //     settings: settings,
    //     maintainState: true,
    //     opaque: true,
    //   );
    // }
    // If no match is found, [WidgetsApp.onUnknownRoute] handles it.
    return PageRouteBuilder(pageBuilder: (context, animation1, animation2) {
      return const ProjectSelectionPage();
    });
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
