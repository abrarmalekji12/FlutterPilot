import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update_flutter/in_app_update_flutter.dart';

// Replace with the numeric App Store ID from your App Store URL.
// e.g. https://apps.apple.com/app/id1234567890 → '1234567890'
const String _kAppStoreId = '6759552936';

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  final _plugin = InAppUpdateFlutter();

  /// Call once on app start (after WidgetsFlutterBinding.ensureInitialized).
  /// Silently swallows all errors so a failed update check never crashes the app.
  Future<void> checkAndPrompt() async {
    if (kIsWeb) return;
    try {
      if (Platform.isIOS) {
        await _checkIos();
      } else if (Platform.isAndroid) {
        await _checkAndroid();
      }
    } catch (_) {
      // Update check must not crash the app.
    }
  }

  Future<void> _checkIos() async {
    // Shows the App Store product page inside the app via SKStoreProductViewController.
    // No-ops on simulator and TestFlight builds (plugin handles this gracefully).
    await _plugin.showUpdateForIos(appStoreId: _kAppStoreId);
  }

  Future<void> _checkAndroid() async {
    final info = await _plugin.checkUpdateAndroid();
    if (info.updateAvailability != UpdateAvailabilityAndroid.updateAvailable) {
      return;
    }

    if (info.isImmediateUpdateAllowed) {
      await _plugin.startImmediateUpdateAndroid();
    } else if (info.isFlexibleUpdateAllowed) {
      await _plugin.startFlexibleUpdateAndroid();
      _plugin.installStateStreamAndroid.listen((state) {
        if (state.installStatus == InstallStatusAndroid.downloaded) {
          _plugin.completeUpdateAndroid();
        }
      });
    }
  }
}
