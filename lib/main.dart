import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'constant/app_colors.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded(() {
    runApp(const MyApp());
  },(Object error, StackTrace stack){

  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
      title: 'Flutter Visual Builder',
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
          visualDensity: VisualDensity.standard, primaryColor: AppColors.theme),
      home: const HomePage(),
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
