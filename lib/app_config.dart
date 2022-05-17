final appConfig=DevelopmentConfig();

abstract class AppConfig{
  bool get loggerEnable;
}
class DevelopmentConfig extends AppConfig{
  @override
  bool get loggerEnable => true;
}

class ProductionConfig extends AppConfig {
  @override
  bool get loggerEnable => false;
}