/// For Non-web uncomment this

import 'dart:io' as io;

class Platform {
  static bool get isWindows => io.Platform.isWindows;

  static bool get isMacOS => io.Platform.isMacOS;

  static bool get isLinux => io.Platform.isLinux;

  static bool get isAndroid => io.Platform.isAndroid;

  static bool get isFuchsia => io.Platform.isFuchsia;

  static bool get isIOS => io.Platform.isIOS;
}

/// For web uncomment this

// class Platform {
//   static const bool isWindows = false;
//   static const bool isMacOS = false;
//   static const bool isLinux = false;
//   static const bool isAndroid = false;
//   static const bool isFuchsia = false;
//   static const bool isIOS = false;
// }
