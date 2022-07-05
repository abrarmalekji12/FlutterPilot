import 'package:intl/intl.dart';

class DateFormatUtils {
  static String getCurrentTimeForConsole() {
    return DateFormat('hh:mm:ss a').format(DateTime.now());
  }
}
