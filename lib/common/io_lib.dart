
/// For Non-web uncomment this

import 'dart:io' as io;

class Platform{
  static get isWindows=> io.Platform.isWindows;
}

/// For web uncomment this

// class Platform {
//   static const bool isWindows = false;
// }
