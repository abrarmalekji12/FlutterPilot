import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../common/web/io_lib.dart';

class PushNotificationService {
  // On iOS, getToken() returns null unless:
  //   1. requestPermission() was called and the user granted it
  //   2. The aps-environment entitlement is present in Runner.entitlements
  // This method handles both by requesting permission before fetching the token.
  static Future<String?> initialize() async {
    if (kIsWeb) return null;
    if (!Platform.isIOS && !Platform.isAndroid) return null;

    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
    }

    try {
      final token = await messaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }
}
