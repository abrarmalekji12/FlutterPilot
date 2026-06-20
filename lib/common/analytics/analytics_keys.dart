import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for Google Analytics (GA4) configuration and event/screen
/// naming. Firebase Analytics is used on Web/Android/iOS. On desktop
/// (Windows/macOS/Linux) Firebase Analytics has no implementation, so events
/// are sent through the GA4 Measurement Protocol using the values below.
class AnalyticsKeys {
  AnalyticsKeys._();

  // ---------------------------------------------------------------------------
  // GA4 Measurement Protocol config (used only on desktop platforms).
  //
  // Provide these through the project `.env` file:
  //   GA4_MEASUREMENT_ID=G-XXXXXXXXXX
  //   GA4_API_SECRET=xxxxxxxxxxxxxxxxxxxxxx
  // The API secret is created in GA4 Admin > Data Streams > Measurement
  // Protocol API secrets. Until both are set, desktop events are skipped.
  // ---------------------------------------------------------------------------
  static const String _placeholderMeasurementId = 'G-XXXXXXXXXX';

  static String get measurementId =>
      dotenv.maybeGet('GA4_MEASUREMENT_ID') ?? _placeholderMeasurementId;

  static String get apiSecret => dotenv.maybeGet('GA4_API_SECRET') ?? '';

  static bool get isMeasurementProtocolConfigured =>
      measurementId.isNotEmpty &&
      measurementId != _placeholderMeasurementId &&
      apiSecret.isNotEmpty;

  /// SharedPreferences key for the persistent GA4 client id (desktop only).
  static const String clientIdPref = 'ga4_client_id';

  // ---------------------------------------------------------------------------
  // Event names (snake_case, <= 40 chars, GA4 compatible).
  // ---------------------------------------------------------------------------
  static const String pageLoadTime = 'page_load_time';
  static const String screenTime = 'screen_time';
  static const String apkExport = 'apk_export';
  static const String projectCreated = 'project_created';
  static const String aiGeneration = 'ai_generation';

  // ---------------------------------------------------------------------------
  // Screen names.
  // ---------------------------------------------------------------------------
  static const String screenHome = 'home_editor';
  static const String screenAiAssistant = 'ai_assistant';
  static const String screenProjects = 'projects';
  static const String screenLogin = 'login';
}
