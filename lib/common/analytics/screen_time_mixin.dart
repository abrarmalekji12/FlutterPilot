import 'package:flutter/widgets.dart';

import '../../injector.dart';
import 'analytics_service.dart';

/// Mixin for a [State] that should report how long the user spent on it.
///
/// It logs a screen view when the widget is inserted and a `screen_time` event
/// (with the elapsed duration) when it is disposed. App background/foreground
/// transitions are tracked via an [AppLifecycleListener] so only foreground
/// time is counted.
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage>
///     with ScreenTimeTracker<MyPage> {
///   @override
///   String get screenName => 'my_page';
/// }
/// ```
mixin ScreenTimeTracker<T extends StatefulWidget> on State<T> {
  final Stopwatch _stopwatch = Stopwatch();
  AppLifecycleListener? _lifecycleListener;

  AnalyticsService get _analytics => sl<AnalyticsService>();

  /// Name reported for this screen.
  String get screenName;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) {
          _stopwatch.start();
        } else {
          _stopwatch.stop();
        }
      },
    );
    _analytics.logScreenView(screenName);
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _analytics.logScreenTime(screenName, _stopwatch.elapsed);
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
