import 'dart:math';

import 'package:flutter/material.dart';

import '../../common/extension_util.dart';
import '../../widgets/overlay/overlay_manager.dart';

class AnimatedSlider {
  final ValueNotifier<bool> _visible = ValueNotifier(false);

  ValueNotifier<bool> get notifier => _visible;

  bool get visible => _visible.value;

  void hide() {
    _visible.value = false;
  }

  void show(
      BuildContext context, OverlayManager manager, Widget child, GlobalKey key,
      {bool dismissible = false,
      double top = 0,
      double left = 0,
      double? height,
      double? width}) {
    _visible.value = true;
    final pos = key.position!;
    final isLeft = pos.dx < (MediaQuery.of(context).size.width / 2);
    final leftPos = pos.dx + (key.size?.width ?? 0) + 10 + left;
    final rightPos = MediaQuery.of(context).size.width - pos.dx + 10 - left;
    manager.showOverlay(
        context,
        'slider',
        (context, offset) => AnimatedSliderProvider(
              slider: this,
              child: Stack(
                children: [
                  if (dismissible)
                    Material(
                      color: Colors.transparent,
                      child: Positioned.fill(
                        child: InkWell(
                          overlayColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                          onTap: hide,
                          child: const Material(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: isLeft
                        ? (width == null
                            ? leftPos
                            : min(leftPos,
                                MediaQuery.of(context).size.width - width - 10))
                        : null,
                    right: !isLeft ? rightPos : null,
                    top: min(
                        pos.dy + top,
                        MediaQuery.of(context).size.height -
                            (height ?? 400) -
                            20),
                    child: AnimatedSliderWrapper(
                      child: child,
                      notifier: _visible,
                      onDismiss: () => manager.removeOverlay('slider'),
                    ),
                  ),
                ],
              ),
            ),
        overlay: Overlay.of(context));
  }
}

class AnimatedSliderWrapper extends StatefulWidget {
  final Widget child;
  final ValueNotifier<bool> notifier;
  final VoidCallback onDismiss;

  const AnimatedSliderWrapper(
      {super.key,
      required this.child,
      required this.notifier,
      required this.onDismiss});

  @override
  State<AnimatedSliderWrapper> createState() => _AnimatedSliderWrapperState();
}

class _AnimatedSliderWrapperState extends State<AnimatedSliderWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    widget.notifier.addListener(_listener);
    _listener();
    super.initState();
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Transform.translate(
          offset: Offset(200 * (1 - _controller.value), 0),
          child: Opacity(
            opacity: _controller.value,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _listener() {
    if (widget.notifier.value) {
      _controller.forward();
    } else {
      _controller.reverse().then((value) {
        widget.onDismiss.call();
      });
    }
  }
}

class AnimatedSliderProvider extends InheritedWidget {
  final AnimatedSlider slider;

  AnimatedSliderProvider({required super.child, required this.slider});

  static AnimatedSlider? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AnimatedSliderProvider>()
      ?.slider;

  @override
  bool updateShouldNotify(AnimatedSliderProvider oldWidget) {
    return oldWidget.slider != slider;
  }
}
