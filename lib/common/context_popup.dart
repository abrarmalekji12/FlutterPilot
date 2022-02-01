import 'package:flutter/material.dart';

class ContextPopup {
  late Offset offset;
  late Widget child;
  late double width;
  late double height;
  Widget? outRange;
  static OverlayEntry? overlay;

  // ContextPopup(
  //     {required this.child,
  //     required this.widgetKey,
  //     required this.width,
  //     required this.height})
  //     : super();
  void init(
      {required Widget child,
        required Offset offset,
        required double width,
        required double height}) {
    this.child = child;
    this.offset = offset;
    this.width = width;
    this.height = height;
  }

  ContextPopup();

  void show(BuildContext context, {bool animate = true,void Function()? onHide}) {
    if (Overlay.of(context) != null) {
      final BtnLocation location = _getSuitableLocation(context);
      if (!location.isOriginal && outRange != null) {
        overlay = OverlayEntry(builder: (context) {
          return Stack(
            children: [
                Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                      onHide?.call();
                      overlay?.remove();
                    },
                  ),
                ),
              Positioned(
                left: location.offset.dx,
                top: location.offset.dy,
                child: TweenAnimationBuilder(
                  builder: (_, double value, __) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        color: Colors.white,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                            BoxShadow(
                              color: Color(0xffd3d3d3),
                              offset: Offset(2,2),
                              blurRadius: 2
                            )
                          ]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [outRange!, child],
                        ),
                      ),
                    );
                  },
                  tween: Tween<double>(begin: animate ? 0.0 : 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.bounceOut,
                ),
              ),
            ],
          );
        });
      } else {
        overlay = OverlayEntry(builder: (context) {
          return Stack(
            children: [
                Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                      overlay?.remove();
                    },
                  ),
                ),
              Positioned(
                left: location.offset.dx,
                top: location.offset.dy,
                child: TweenAnimationBuilder(
                  builder: (_, double value, __) {
                    return Transform.scale(scale: value, child: Container(
                      padding: const EdgeInsets.all(5),
                        decoration:  BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0xffd3d3d3),
                                  offset: Offset(2,2),
                                  blurRadius: 2
                              )
                            ]
                        ),
                        child: child));
                  },
                  tween: Tween<double>(begin: animate ? 0.0 : 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.bounceOut,
                ),
              ),
            ],
          );
        });
      }
      Overlay.of(context)!.insert(overlay!);
    }
  }

  void showIfInViewPort(BuildContext context, {bool animate = true}) {
    if (Overlay.of(context) != null) {
      BtnLocation location = _getSuitableLocation(context);
      if (!location.isOriginal && outRange != null) {
        return;
      } else {
        overlay = OverlayEntry(builder: (context) {
          return Positioned(
              left: location.offset.dx,
              top: location.offset.dy,
              child: TweenAnimationBuilder(
                builder: (_, double value, __) {
                  return Transform.scale(scale: value, child: child);
                },
                tween: Tween<double>(begin: animate ? 0.0 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.bounceOut,
              ));
        });
      }
      Overlay.of(context)!.insert(overlay!);
    }
  }

  bool isShowing() {
    if (overlay == null) {
      return false;
    }
    return overlay!.mounted;
  }

  void hide() {
    if (overlay != null) {
      if (overlay!.mounted) {
        overlay!.remove();
      }
    }
  }

  BtnLocation _getSuitableLocation(BuildContext context) {
    // buttonSize = renderBox.size;
    final size = MediaQuery.of(context).size;
    double x, y;
    bool isOrigx = false, isOrigy = false;
    if (offset.dx + width > size.width - 20) {
      x = size.width - width - 100;
    } else if (offset.dx < 100) {
      x = 100;
    } else {
      isOrigx = true;
      x = offset.dx;
    }
    if (offset.dy + height > size.height - 20) {
      y = size.height - height - 100;
    } else if (offset.dy < 20) {
      y = 20;
    } else {
      isOrigy = true;
      y = offset.dy;
    }
    return BtnLocation(Offset(x, y), isOrigx && isOrigy);
  }
}

class BtnLocation {
  final Offset offset;
  final bool isOriginal;

  BtnLocation(this.offset, this.isOriginal);
}
