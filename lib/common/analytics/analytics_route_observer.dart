import 'package:flutter/widgets.dart';

import 'analytics_keys.dart';
import 'analytics_service.dart';

/// Tracks screen views and page-load time for every navigation.
///
/// "Page load time" here is measured from the moment a route is pushed until
/// its first frame is rendered — a practical proxy for how long the user waited
/// for the screen to appear.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _track(previousRoute);
  }

  void _track(Route<dynamic> route) {
    if (route is! PageRoute) return;
    final rawName = route.settings.name;
    if (rawName == null || rawName.isEmpty) return;

    final screenName = _normalize(rawName);
    final stopwatch = Stopwatch()..start();
    _analytics.logScreenView(screenName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stopwatch.stop();
      _analytics.logPageLoadTime(screenName, stopwatch.elapsed);
    });
  }

  /// Reduces dynamic route names (e.g. `/projects/<id>`, `/run-<hash>`) to a
  /// stable, low-cardinality screen name suitable for analytics.
  String _normalize(String name) {
    final path = name.replaceAll('//', '/').replaceAll('#', '');
    if (path.startsWith('/login')) return AnalyticsKeys.screenLogin;
    if (path.startsWith('/projects')) return AnalyticsKeys.screenProjects;
    if (path.startsWith('/run')) return AnalyticsKeys.screenHome;
    final segment = path.split('/').firstWhere(
          (s) => s.isNotEmpty,
          orElse: () => 'root',
        );
    return segment.split('-').first;
  }
}
