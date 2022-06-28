
/// For Non-web uncomment this

import 'dart:io' as io;

class Platform{
  static get isWindows=> io.Platform.isWindows;
  static get isMacOS=> io.Platform.isMacOS;
  static get isLinux=> io.Platform.isLinux;
  static get isAndroid=> io.Platform.isAndroid;
  static get isFuchsia=> io.Platform.isFuchsia;
  static get isIOS=> io.Platform.isIOS;
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
