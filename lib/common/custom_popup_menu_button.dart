import 'dart:html' as html;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomPopupMenuButton<T> extends StatefulWidget {
  final List<CustomPopupMenuItem> Function(BuildContext) itemBuilder;
  final void Function(T) onSelected;
  final Widget child;
  final bool animateSuffixIcon;
  final Widget? suffixIcon;
  final Color? backgroundColor;

  const CustomPopupMenuButton(
      {required this.itemBuilder,
      required this.onSelected,
      required this.child,
      Key? key,
      this.backgroundColor,
      this.animateSuffixIcon = false,
      this.suffixIcon,})
      : super(key: key);

  @override
  _CustomPopupMenuButtonState createState() => _CustomPopupMenuButtonState();
}

class _CustomPopupMenuButtonState extends State<CustomPopupMenuButton> {
  GlobalKey globalKey = GlobalKey();
  OverlayEntry? overlayEntry;
  bool expanded = false;
  late int _itemCount;
@override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    _itemCount=widget.itemBuilder(context).length;
}
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    overlayEntry = OverlayEntry(builder: (context) {
      return GestureDetector(
        onTap: () {
          overlayEntry?.remove();
          setState(() {
            expanded = false;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: getLeftPosition(),
                top: getTopPosition(),
                child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.5, end: 1),
                    curve: Curves.bounceOut,
                    duration: const Duration(milliseconds: 100),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Transform.translate(
                          offset: Offset(0, -100 * (1 - value)),
                          child: SizedBox(
                            width: 180,
                            height: getCalculatedHeight(),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Card(
                                elevation: 5,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: widget
                                        .itemBuilder(context)
                                        .map((e) => InkWell(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: e,
                                              ),
                                              onTap: () {
                                                widget.onSelected(e.value);
                                                overlayEntry?.remove();

                                                setState(() {
                                                  expanded = false;
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              splashColor: Colors.grey,
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            ],
          ),
        ),
      );
    });
    html.window.onResize.listen((event) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        overlayEntry?.markNeedsBuild();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: widget.backgroundColor,
      child: InkWell(
        key: globalKey,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.grey,
        onTap: () {
          if (!(overlayEntry?.mounted ?? false)) {
            Overlay.of(context)?.insert(overlayEntry!);
            setState(() {
              expanded = true;
            });
          }
        },
        child: Row(
          children: [
            widget.child,
            if (widget.suffixIcon != null) ...[
              const SizedBox(
                width: 15,
              ),
              TweenAnimationBuilder(
                key: ValueKey(expanded),
                curve: Curves.bounceInOut,
                builder: (context, double value, child) {
                  return Transform.rotate(
                    angle: (expanded ? pi * value : pi * (value - 1)),
                    child: widget.suffixIcon!,
                  );
                },
                tween: Tween<double>(begin: 0, end: 1),
                duration: widget.animateSuffixIcon
                    ? const Duration(milliseconds: 150)
                    : Duration.zero,
              ),
            ]
          ],
        ),
      ),
    );
  }

  double getLeftPosition() {
    RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    final translation = renderBox.getTransformTo(null).getTranslation();
    final offset = Offset(translation.x, translation.y);
    Rect position = renderBox.paintBounds.shift(offset);
    if (position.left + 180 > dw(context, 100)) {
      return dw(context, 100) - 200;
    } else {
      return position.left;
    }
  }
  double getCalculatedHeight() {
    final size=MediaQuery.of(context).size;
    final itemsHeight=_itemCount*40.0;
    final topPosition=getTopPosition();
    if(topPosition+itemsHeight>size.height){
      return size.height-(topPosition);
    }
    // buttonSize = renderBox.size;
    return itemsHeight;
  }
  double getTopPosition() {
    RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;
    final translation = renderBox.getTransformTo(null).getTranslation();
    final offset = Offset(translation.x, translation.y);
    Rect position = renderBox.paintBounds.shift(offset);

    // renderBox.localToGlobal(Offset.zero);
    return position.top + renderBox.size.height;
  }
}

class CustomPopupMenuItem<T> extends StatelessWidget {
  final T value;
  final Widget child;

  const CustomPopupMenuItem({
    required this.value,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: child,
    );
  }
}
double dw(BuildContext context, double pt) =>
    pt * MediaQuery.of(context).size.width / 100.0;

double dh(BuildContext context, double pt) =>
    pt * MediaQuery.of(context).size.height / 100.0;

