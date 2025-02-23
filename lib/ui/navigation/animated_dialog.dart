import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../common/extension_util.dart';

class DialogKeyProvider extends InheritedWidget {
  final String dialogKey;

  const DialogKeyProvider(
      {super.key, required super.child, required this.dialogKey});

  @override
  bool updateShouldNotify(DialogKeyProvider oldWidget) =>
      dialogKey != oldWidget.dialogKey;

  static String? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DialogKeyProvider>()
      ?.dialogKey;
}

class AnimatedDialog {
  static final Map<String, ValueNotifier<bool>> isShowing = {};
  static final List<String> stack = [];
  static dynamic lastResult;

  static Future<void> hide(BuildContext context,
      {String key = '', dynamic result}) async {
    if (key.isEmpty && stack.isNotEmpty) {
      key = DialogKeyProvider.of(context) ?? stack.last;
    }
    lastResult = result;

    if (isShowing[key] != null) {
      isShowing[key]?.value = false;
      await Future.delayed(const Duration(milliseconds: 270));
    }
    return;
  }

  static bool visibleInStack(String key) => stack.contains(key);

  static bool removeFromStack(String key) => stack.remove(key);

  static bool isVisible([String key = '']) {
    return isShowing.entries.where((p0) => p0.value.value == true).isNotEmpty;
  }

  static void hideNotAnimate(BuildContext context,
      {String key = '', dynamic result}) {
    if (key.isEmpty && stack.isNotEmpty) {
      key = stack.last;
    }
    lastResult = result;
    if (stack.contains(key)) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
      }
      stack.remove(key);
      isShowing[key]?.value = false;
    }
  }

  static Future<dynamic> show(
    BuildContext context,
    Widget child, {
    bool barrierDismissible = false,
    bool backPressDismissible = true,
    EdgeInsets? margin,
    bool topAlign = false,
    bool popOutAnimation = true,
    bool fullPage = false,
    bool backdrop = false,
    bool replace = true,
    bool rootNavigator = false,
    NavigatorState? navigator,
    String key = '',
  }) async {
    if (replace && (isShowing[key]?.value ?? false)) {
      hideNotAnimate(context, key: key);
      await Future.delayed(const Duration(milliseconds: 100));
    } else {
      key = DateTime.now().millisecondsSinceEpoch.toString();
    }
    if (context.mounted) {
      final notifier = ValueNotifier(true);
      isShowing[key] = notifier;
      final dialogNavigator =
          navigator ?? Navigator.of(context, rootNavigator: rootNavigator);
      stack.add(key);
      return await dialogNavigator.push(DialogRoute(
        useSafeArea: false,
        barrierDismissible: false,
        settings: RouteSettings(
          name: key,
        ),
        barrierColor: Colors.transparent,
        builder: (BuildContext context) {
          return DialogKeyProvider(
            dialogKey: key,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  if (backdrop)
                    Positioned.fill(
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(),
                        ),
                      ),
                    ),
                  if (fullPage)
                    Positioned.fill(
                      child: WidgetAnimator(
                        notifier: notifier,
                        backPressDismissible: backPressDismissible,
                        animate: popOutAnimation,
                        topAlign: topAlign,
                        backdrop: backdrop,
                        dialogKey: key,
                        fullPage: fullPage,
                        navigator: dialogNavigator,
                        barrierDismissible: barrierDismissible,
                        child: child,
                      ),
                    )
                  else
                    Align(
                      child: WidgetAnimator(
                        navigator: dialogNavigator,
                        notifier: notifier,
                        backPressDismissible: backPressDismissible,
                        animate: popOutAnimation,
                        topAlign: topAlign,
                        backdrop: backdrop,
                        dialogKey: key,
                        fullPage: fullPage,
                        barrierDismissible: barrierDismissible,
                        child: child,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        context: context,
      ));
    }
  }

  static Future<dynamic> showTraced(
    BuildContext context,
    Widget child,
    GlobalKey globalKey, {
    bool dismissible = false,
    EdgeInsets? margin,
    bool backdrop = false,
    String key = '',
  }) async {
    if (isShowing[key]?.value ?? false) {
      hide(context, key: key);
    }
    final notifier = ValueNotifier(true);
    isShowing[key] = notifier;
    final oldPosition = globalKey.position!;
    await showDialog(
        useRootNavigator: false,
        useSafeArea: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                if (backdrop)
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(),
                    ),
                  ),
                Center(
                  child: ValueListenableBuilder<bool>(
                      valueListenable: notifier,
                      child: child,
                      builder: (context, bool visible, child) {
                        return (child ?? const Offstage()).animate(
                            onComplete: (controller) {
                          if (!visible) {
                            Navigator.pop(context);
                          }
                        }).move(begin: oldPosition, end: Offset.zero);
                      }),
                ),
              ],
            ),
          );
        });
  }
}

class WidgetAnimator extends StatefulWidget {
  final Widget child;
  final ValueNotifier<bool> notifier;
  final bool backPressDismissible;
  final bool barrierDismissible;
  final bool animate;
  final bool topAlign;
  final bool fullPage;
  final bool backdrop;
  final String dialogKey;
  final NavigatorState navigator;

  const WidgetAnimator({
    super.key,
    required this.topAlign,
    required this.child,
    required this.notifier,
    required this.backPressDismissible,
    required this.animate,
    required this.backdrop,
    required this.dialogKey,
    required this.fullPage,
    required this.navigator,
    required this.barrierDismissible,
  });

  @override
  State<WidgetAnimator> createState() => _WidgetAnimatorState();
}

class _WidgetAnimatorState extends State<WidgetAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    widget.notifier.addListener(_listener);
    _listener();
  }

  _listener() {
    if (widget.notifier.value) {
      _controller.forward(from: 0);
    } else if (AnimatedDialog.stack.contains(widget.dialogKey)) {
      _controller.reverse().then((value) {
        if (AnimatedDialog.visibleInStack(widget.dialogKey)) {
          widget.navigator.pop(AnimatedDialog.lastResult);
          // AnimatedDialog.removeFromStack(widget.dialogKey);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    AnimatedDialog.removeFromStack(widget.dialogKey);
    widget.notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context).size.width;
    return OrientationBuilder(builder: (context, _) {
      return Stack(
        children: [
          if (!widget.backdrop)
            GestureDetector(
              onTap: widget.barrierDismissible
                  ? () => widget.notifier.value = false
                  : null,
              child: Container(
                color: Colors.black.withOpacity(0.1),
                alignment: Alignment.center,
              ),
            ),
          Align(
            alignment: widget.topAlign ? Alignment.topCenter : Alignment.center,
            child: SafeArea(
              left: false,
              right: false,
              top: !widget.fullPage,
              bottom: !widget.fullPage,
              child: Padding(
                padding: widget.topAlign
                    ? const EdgeInsets.only(top: 80)
                    : EdgeInsets.zero,
                child: AnimatedBuilder(
                    animation: _controller,
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        color: Colors.transparent,
                      ),
                      child: widget.child,
                    ),
                    builder: (context, child) {
                      final visible = widget.notifier.value;
                      final value =
                          visible ? _animation.value : 1 - _animation.value;

                      return Transform.scale(
                        scale: !widget.animate
                            ? 1
                            : (visible
                                ? lerpDouble(2, 1, value)!
                                : lerpDouble(1, 0.8, value)!),
                        alignment: Alignment.topCenter,
                        child: Opacity(
                          alwaysIncludeSemantics: true,
                          opacity: !widget.animate
                              ? 1
                              : visible
                                  ? lerpDouble(0, 1, value)!
                                  : lerpDouble(1, 0, value)!,
                          child: Transform.translate(
                            offset: !widget.animate
                                ? Offset(
                                    visible
                                        ? (MediaQuery.of(context).size.width *
                                            (1 - value))
                                        : MediaQuery.of(context).size.width *
                                            value,
                                    0)
                                : Offset.zero,
                            child: child,
                          ),
                        ),
                      );
                    }),
              ),
            ),
          ),
        ],
      );
    });
  }
}
