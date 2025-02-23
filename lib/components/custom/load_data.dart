import 'package:flutter/material.dart';

import '../../runtime_provider.dart';

final Map<String, dynamic> _futureCache = {};

class DataLoaderWidget extends StatelessWidget {
  final Future? future;
  final Widget Function(BuildContext) onLoading;
  final Widget Function(BuildContext, String) onError;
  final Widget Function(BuildContext, dynamic) onLoad;
  final bool showLoading;
  final bool showError;
  final String code;

  const DataLoaderWidget(
      {Key? key,
      required this.future,
      required this.onLoading,
      required this.onError,
      required this.onLoad,
      this.showError = false,
      this.showLoading = false,
      required this.code})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (context, data) {
        if (showLoading) {
          return onLoading.call(context);
        } else if (showError) {
          return onError.call(context, 'Test Error');
        }
        if (data.connectionState == ConnectionState.waiting) {
          return onLoading.call(context);
        }
        if (data.hasError) {
          return onError.call(context, data.error?.toString() ?? '');
        }
        if (data.connectionState == ConnectionState.done) {
          _futureCache[code] = data.data;
          return onLoad.call(context, data.data);
        }
        return const Offstage();
      },
      future: _futureCache.containsKey(code) &&
              RuntimeProvider.of(context) == RuntimeMode.edit
          ? Future.value(_futureCache[code])
          : future,
    );
  }
}

const dataLoaderWidgetCode = '''
import 'package:flutter/material.dart';

class DataLoaderWidget extends StatelessWidget {
  final Future? future;
  final Widget Function(BuildContext) onLoading;
  final Widget Function(BuildContext, String) onError;
  final Widget Function(BuildContext, dynamic) onLoad;
  final bool showLoading;
  final bool showError;

  const DataLoaderWidget(
      {Key? key,
        required this.future,
        required this.onLoading,
        required this.onError,
        required this.onLoad,
        this.showError = false,
        this.showLoading = false,})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (context, data) {
        if (showLoading) {
          return onLoading.call(context);
        } else if (showError) {
          return onError.call(context, 'Error');
        }
        if (data.connectionState == ConnectionState.waiting) {
          return onLoading.call(context);
        }
        if (data.hasError) {
          return onError.call(context, data.error?.toString() ?? '');
        }
        if (data.hasData) {
          return onLoad.call(context, data.data);
        }
        return const Offstage();
      },
      future: future,
    );
  }
}
''';

const animatedDialogWidgetCode = '''
import 'dart:ui';

import 'package:flutter/material.dart';


class AnimatedDialog {
  static const String visitDetails = 'visit_details';
  static const String createAppointment = 'create_appointment';
  static final Map<String, ValueNotifier<bool>> _isShowing = {};
  static final Map<String, bool> visibility = {};

  static Future<void> hide([String key = '']) async {
    if (_isShowing[key] != null) {
      _isShowing[key]?.value = false;
      return Future.delayed(const Duration(milliseconds: 230));
    }
    return;
  }

  static void hideNotAnimate(BuildContext context, [String key = '']) {
    _isShowing[key]?.value = false;
    visibility[key] = false;
    Navigator.of(context).pop();
  }

  static Future<dynamic> show(
    BuildContext context,
    Widget child, {
    bool dismissible = false,
    EdgeInsets? margin,
    bool backdrop = false,
    bool rootNavigator = false,
    NavigatorState? navigator,
    String key = '',
  }) async {
    if (_isShowing[key]?.value ?? false) {
      await hide(key);
    }
    if (context.mounted) {
      final notifier = ValueNotifier(true);
      _isShowing[key] = notifier;
      visibility[key] = true;
      await (navigator ??
              Navigator.of(
                context,
                rootNavigator: rootNavigator,
              ))
          .push(DialogRoute(
        useSafeArea: false,
        barrierDismissible: false,
        settings: ModalRoute.of(context)?.settings,
        barrierColor: Colors.transparent,
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                if (backdrop)
                  Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: WidgetAnimator(
                    notifier: notifier,
                    dismissible: dismissible,
                    animateKey: key,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
        context: context,
      ));
    }
  }
  
}

class WidgetAnimator extends StatefulWidget {
  final Widget child;
  final ValueNotifier<bool> notifier;
  final bool dismissible;
  final String animateKey;

  const WidgetAnimator({
    Key? key,
    required this.child,
    required this.notifier,
    required this.dismissible,
    required this.animateKey,
  }) : super(key: key);

  @override
  State<WidgetAnimator> createState() => _WidgetAnimatorState();
}

class _WidgetAnimatorState extends State<WidgetAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 140),
    );
    widget.notifier.addListener(_listener);
    _listener();
  }

  _listener() {
    if (widget.notifier.value) {
      _controller.forward();
    } else {
      _controller.reverse().then((value) {
        if (AnimatedDialog.visibility[widget.animateKey] == true) {
          Navigator.pop(context);
          AnimatedDialog.visibility[widget.animateKey] = false;
        }
      });
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final visible = widget.notifier.value;
          final value = visible ? _controller.value : 1 - _controller.value;
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.dismissible ? () => widget.notifier.value = false : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          Colors.black.withOpacity(visible ? lerpDouble(0, 0.3, value)! : lerpDouble(0.3, 0.2, value)!),
                    ),
                  ),
                ),
              ),
              Align(
                child: Opacity(
                  opacity: visible ? lerpDouble(0.4, 1, value)! : lerpDouble(1, 0.4, value)!,
                  child: Transform.scale(
                    scale: visible ? lerpDouble(1.4, 1, value)! : lerpDouble(1, 0.9, value)!,
                    alignment: const Alignment(0, -0.3),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.transparent,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.child);
  }
}


''';

const materialAlertDialogCode = '''
import 'package:flutter/material.dart';

class MaterialAlertDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? negativeButtonText;
  final String positiveButtonText;
  final VoidCallback? onPositiveTap;
  final VoidCallback? onNegativeTap;

  const MaterialAlertDialog({
    Key? key,
    required this.title,
    this.subtitle,
    this.negativeButtonText,
    required this.positiveButtonText,
    this.onPositiveTap,
    this.onNegativeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(title: Text(title),
     content: subtitle!=null?Text(subtitle!):null,
      actions: [
        TextButton(onPressed: onPositiveTap, child: Text(positiveButtonText)),
        if(negativeButtonText!=null)
        TextButton(onPressed: onNegativeTap, child: Text(negativeButtonText!)),
      ],
    );
  }
}

''';
