import Cocoa
import FlutterMacOS
import FirebaseCore

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
   if FirebaseApp.app() == nil {
       FirebaseApp.configure()
   }
    return true
  }
}
