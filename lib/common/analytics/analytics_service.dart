import 'dart:convert';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../web/io_lib.dart';
import 'analytics_keys.dart';
import 'analytics_route_observer.dart';

/// Single entry point for all analytics in FlutterPilot.
///
/// On Web/Android/iOS it forwards to Firebase Analytics (GA4). On desktop
/// platforms, where Firebase Analytics has no plugin implementation, it sends
/// the same events through the GA4 Measurement Protocol over HTTP.
///
/// Every call is fire-and-forget and wrapped so analytics failures can never
/// crash or block the app.
class AnalyticsService {
  AnalyticsService(this._prefs);

  final SharedPreferences _prefs;

  /// Firebase Analytics is available on web and mobile, but not on desktop.
  /// `kIsWeb` is checked first so `Platform` (dart:io) is never touched on web.
  static final bool _useFirebase =
      kIsWeb || Platform.isAndroid || Platform.isIOS;

  FirebaseAnalytics? _firebase;
  String? _clientId;
  String? _userId;
  bool _enabled = false;

  late final AnalyticsRouteObserver routeObserver =
      AnalyticsRouteObserver(this);

  Future<void> init() async {
    try {
      if (_useFirebase) {
        _firebase = FirebaseAnalytics.instance;
        await _firebase!.setAnalyticsCollectionEnabled(true);
      } else {
        _clientId = _ensureClientId();
      }
      _enabled = true;
      await logEvent('app_open');
    } catch (e) {
      _enabled = false;
      debugPrint('AnalyticsService init failed: $e');
    }
  }

  String _ensureClientId() {
    var id = _prefs.getString(AnalyticsKeys.clientIdPref);
    if (id == null || id.isEmpty) {
      final rand = Random().nextInt(1 << 31);
      id = '$rand.${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      _prefs.setString(AnalyticsKeys.clientIdPref, id);
    }
    return id;
  }

  /// Associates a user id with subsequent events (after login).
  Future<void> setUser(String? userId) async {
    _userId = userId;
    if (!_enabled) return;
    try {
      if (_useFirebase) {
        await _firebase?.setUserId(id: userId);
      }
    } catch (e) {
      debugPrint('AnalyticsService setUser error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Generic logging.
  // ---------------------------------------------------------------------------
  Future<void> logEvent(String name,
      [Map<String, Object?> params = const {}]) async {
    if (!_enabled) return;
    final clean = _sanitize(params);
    try {
      if (_useFirebase) {
        await _firebase?.logEvent(
            name: name, parameters: clean.isEmpty ? null : clean);
      } else {
        await _sendMeasurementProtocol(name, clean);
      }
    } catch (e) {
      debugPrint('AnalyticsService logEvent($name) error: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    if (!_enabled) return;
    try {
      if (_useFirebase) {
        await _firebase?.logScreenView(screenName: screenName);
      } else {
        await _sendMeasurementProtocol(
            'screen_view', {'screen_name': screenName});
      }
    } catch (e) {
      debugPrint('AnalyticsService logScreenView error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Domain-specific helpers.
  // ---------------------------------------------------------------------------

  /// Time taken for a page/screen to become interactive (first frame).
  Future<void> logPageLoadTime(String screenName, Duration duration) =>
      logEvent(AnalyticsKeys.pageLoadTime, {
        'screen_name': screenName,
        'load_time_ms': duration.inMilliseconds,
      });

  /// Total time a user spent on a screen before leaving it.
  Future<void> logScreenTime(String screenName, Duration duration) =>
      logEvent(AnalyticsKeys.screenTime, {
        'screen_name': screenName,
        'duration_ms': duration.inMilliseconds,
        'duration_sec': duration.inSeconds,
      });

  /// A user exported/built an APK.
  Future<void> logApkExport({
    required String buildPlatform,
    required bool success,
    String? projectName,
  }) =>
      logEvent(AnalyticsKeys.apkExport, {
        'build_platform': buildPlatform,
        'success': success,
        if (projectName != null) 'project_name': projectName,
      });

  /// A user created a new project.
  Future<void> logProjectCreated({
    String? projectName,
    String? templateId,
    String? templateName,
  }) =>
      logEvent(AnalyticsKeys.projectCreated, {
        if (projectName != null) 'project_name': projectName,
        'from_template': templateId != null,
        if (templateId != null) 'template_id': templateId,
        if (templateName != null) 'template_name': templateName,
      });

  /// A user started a project from a specific template. Logged separately from
  /// [logProjectCreated] so per-template usage counts are unambiguous: in GA4,
  /// break the `template_used` event down by the `template_name` (or
  /// `template_id`) parameter to see how many times each template was used.
  Future<void> logTemplateUsed({
    required String templateId,
    required String templateName,
  }) =>
      logEvent(AnalyticsKeys.templateUsed, {
        'template_id': templateId,
        'template_name': templateName,
      });

  /// A user generated UI through the AI assistant. The prompt text itself is
  /// not sent (privacy) — only its length and the outcome.
  Future<void> logAiGeneration({
    required int promptLength,
    required bool success,
    int? componentCount,
    int? durationMs,
  }) =>
      logEvent(AnalyticsKeys.aiGeneration, {
        'prompt_length': promptLength,
        'success': success,
        if (componentCount != null) 'component_count': componentCount,
        if (durationMs != null) 'duration_ms': durationMs,
      });

  // ---------------------------------------------------------------------------
  // GA4 Measurement Protocol (desktop fallback).
  // ---------------------------------------------------------------------------
  Future<void> _sendMeasurementProtocol(
      String name, Map<String, Object> params) async {
    if (!AnalyticsKeys.isMeasurementProtocolConfigured || _clientId == null) {
      return;
    }
    final uri = Uri.parse(
        'https://www.google-analytics.com/mp/collect?measurement_id=${AnalyticsKeys.measurementId}&api_secret=${AnalyticsKeys.apiSecret}');
    final body = jsonEncode({
      'client_id': _clientId,
      if (_userId != null) 'user_id': _userId,
      'events': [
        {
          'name': name,
          'params': {
            ...params,
            // Required for events to count toward active-user/engagement.
            'engagement_time_msec': 100,
          },
        }
      ],
    });
    await http.post(uri, body: body);
  }

  /// GA4 parameter values must be String or num (no bool/null/objects).
  Map<String, Object> _sanitize(Map<String, Object?> params) {
    final out = <String, Object>{};
    params.forEach((key, value) {
      if (value == null) return;
      out[key] = value is num ? value : value.toString();
    });
    return out;
  }
}
