import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static late final SharedPreferences sharedPreferences;

  static load() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static put(String key, dynamic value) {
    switch (value.runtimeType) {
      case int:
        sharedPreferences.setInt(key, value);
        break;
      case String:
        sharedPreferences.setString(key, value);
        break;
      case bool:
        sharedPreferences.setBool(key, value);
        break;
      case double:
        sharedPreferences.setDouble(key, value);
        break;
      case List:
        sharedPreferences.setStringList(key, value);
        break;
      default:
        throw Exception('Not supported type');
    }
  }

  static remove(String key) async {
    await sharedPreferences.remove(key);
  }

  static dynamic get(String key) {
    return sharedPreferences.get(key);
  }
}
