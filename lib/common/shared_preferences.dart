import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static late final SharedPreferences sharedPreferences;
  static load() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }
}
