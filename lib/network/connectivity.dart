import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class AppConnectivity {
  static StreamSubscription<ConnectivityResult>? subscription;
  static Future<bool> available() async {
    return (await Connectivity().checkConnectivity()) !=
        ConnectivityResult.none;
  }

  static Stream<List<ConnectivityResult>> listen() {
    return Connectivity().onConnectivityChanged;
  }
}
