import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:lottie/lottie.dart';

import '../constant/color_assets.dart';
import '../constant/image_asset.dart';
import '../injector.dart';
import '../ui/authentication/auth_navigation.dart';
import '../widgets/image/app_image.dart';
import 'extension_util.dart';
import 'package/custom_textfield_searchable.dart';

enum LoadingMode { defaultMode, projectLoadingMode }

class LoaderProgressIndicatorController extends ChangeNotifier {
  double progress = 0;

  void update(double progress) {
    this.progress = progress;
    notifyListeners();
  }
}

class AppLoaderWidget extends StatefulWidget {
  final LoadingMode loadingMode;
  final LoaderProgressIndicatorController? controller;
  final ValueNotifier<bool> visibility;

  const AppLoaderWidget(
      {super.key,
      required this.loadingMode,
      this.controller,
      required this.visibility});

  @override
  State<AppLoaderWidget> createState() => _AppLoaderWidgetState();
}

class _AppLoaderWidgetState extends State<AppLoaderWidget>
    with SingleTickerProviderStateMixin {
  double progress = 0;
  final Debouncer _debounce = Debouncer(milliseconds: 300);
  late final AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    widget.controller?.addListener(_refresh);
    widget.visibility.addListener(_visibilityChange);
    _visibilityChange();
    super.initState();
  }

  @override
  void dispose() {
    _debounce.cancel();
    widget.visibility.removeListener(_visibilityChange);

    widget.controller?.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Stack(
        children: [
          if (widget.loadingMode == LoadingMode.projectLoadingMode)
            Container(
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, value) {
                          return Container(
                            color: theme.background1.withOpacity(
                                (_animationController.value * 0.8) + 0.2),
                          );
                        }),
                  ),
                  const Positioned.fill(child: BackgroundNetAnimation()),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppImage(
                          Images.logo,
                          width: 100,
                        ),
                        20.hBox,
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          height: 10,
                          width: 150,
                          clipBehavior: Clip.hardEdge,
                          child: TweenAnimationBuilder(
                              key: ValueKey(widget.controller?.progress ?? 0),
                              duration: const Duration(milliseconds: 300),
                              tween: Tween<double>(begin: 0, end: 1),
                              onEnd: () {
                                progress = widget.controller?.progress ?? 0;
                              },
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  color: ColorAssets.darkerTheme,
                                  backgroundColor: ColorAssets.lightGrey,
                                  value: widget.controller?.progress != null
                                      ? (lerpDouble(progress,
                                          widget.controller!.progress, value))
                                      : null,
                                );
                              }),
                        ),
                      ],
                    ).animate().saturate(),
                  ),
                ],
              ),
            )
          else ...[
            TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, _) {
                  return Container(
                    decoration: BoxDecoration(
                        color: theme.background1.withOpacity(0.5 * value)),
                  );
                }),
            Center(
              child: Lottie.asset(
                'assets/lottie/loader.json',
                repeat: true,
                width: 200,
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _refresh() {
    _debounce.run(() {
      if (context.mounted) {
        setState(() {});
      }
    });
  }

  void _visibilityChange() {
    if (widget.visibility.value) {
      _animationController.reset();
      _animationController.forward();
    } else {
      _animationController.reverse().then((value) {
        context.loaderOverlay.hide();
      });
    }
  }
}

class AppLoader {
  static ValueNotifier<bool> visibility = ValueNotifier(false);
  static LoaderProgressIndicatorController controller =
      LoaderProgressIndicatorController();

  static void update(double value) {
    controller.update(value);
  }

  static void show(BuildContext context,
      {LoadingMode loadingMode = LoadingMode.defaultMode}) {
    visibility.value = true;
    controller.progress = 0;
    context.loaderOverlay.show(
      widgetBuilder: (context) => AppLoaderWidget(
        loadingMode: loadingMode,
        controller: controller,
        visibility: visibility,
      ),
    );
  }

  static void hide(BuildContext context) {
    if (visibility.value) {
      visibility.value = false;
    }
  }
}
