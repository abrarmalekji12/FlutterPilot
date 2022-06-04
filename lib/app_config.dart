final appConfig = DevelopmentConfig();

abstract class AppConfig {
  bool get loggerEnable;

  String get email;
  String get password;
}

class DevelopmentConfig extends AppConfig {
  @override
  bool get loggerEnable => false;

  @override
  String get email => 'test1@mailinator.com';

  @override
  String get password => 'password';
}

class ProductionConfig extends AppConfig {
  @override
  bool get loggerEnable => false;
  @override
  String get email => '';

  @override
  String get password => '';
}
