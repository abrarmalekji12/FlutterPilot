import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_builder/main.dart';

import 'services/app_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await AppUpdateService.instance.checkAndPrompt();
  }
  runApp(const MyApp());
}
