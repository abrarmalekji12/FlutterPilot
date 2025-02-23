import 'package:flutter_builder/models/project_model.dart';

class PubManager {
  static String code(FVBProject project) => '''name: ${project.packageName}
description: A new Flutter project.
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.2
  google_fonts: ^5.0.0
  intl: ^0.17.0
  ionicons: ^0.2.2
  dio: ^4.0.6
  flutter_animate: 4.2.0
  loading_indicator: ^3.1.1
  ${project.settings.firebaseConnect != null ? '''firebase_core: ^2.15.1
  firebase_auth: ^4.7.3
  cloud_firestore: ^4.8.5
  firebase_storage: ^11.2.6''' : ''}
  
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:

  uses-material-design: true

  ${project.imageList.isNotEmpty ? 'assets:\n  - assets/images/' : ''}
    ''';
}
