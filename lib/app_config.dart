import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'common/app_secrets.dart';

final appConfig = ProductionConfig();

abstract class AppConfig {
  bool get loggerEnable;

  String get email;

  String get password;

  String get figmaClientId => 'crQr2ZRYFkKiMFuC4fElaf';

  String get figmaClientSecret => dotenv.env[AppSecrets.figmaSecretKey] ?? '';

  static bool get isAdmin => kDebugMode;

  String get storageBucket;
}

class DevelopmentConfig extends AppConfig {
  @override
  bool get loggerEnable => false;

  @override
  String get email => 'test1@mailinator.com';

  @override
  String get password => 'password';

  @override
  String get storageBucket => 'gs://flutter-visual-builder-staging.appspot.com';
}

class ProductionConfig extends AppConfig {
  @override
  bool get loggerEnable => false;

  @override
  String get email => '';

  @override
  String get password => '';

  @override
  String get storageBucket => 'gs://flutter-visual-builder-staging.appspot.com';
}
