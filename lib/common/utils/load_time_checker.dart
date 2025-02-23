abstract class LoadTimeChecker {
  static Future<void> checkTime(
      String name, Future<void> Function() task) async {
    final time = DateTime.now();
    await task();
    final taken = (DateTime.now().difference(time)).inSeconds;
    print('TIME NOTE :: $name :: TOOK $taken SECONDS');
  }
}
