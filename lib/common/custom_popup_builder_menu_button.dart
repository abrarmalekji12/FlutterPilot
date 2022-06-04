import 'dart:html' as html;
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/component_model.dart';
import 'custom_popup_menu_button.dart';

class CustomPopupMenuBuilderButton extends StatefulWidget {
  final CustomPopupMenuItem Function(BuildContext, int) itemBuilder;
  final void Function(Component) onSelected;
  final Widget child;
  final bool animateSuffixIcon;
  final Widget? suffixIcon;
  final Color? backgroundColor;
  final int itemCount;

  const CustomPopupMenuBuilderButton({
    required this.itemBuilder,
    required this.onSelected,
    required this.child,
    required this.itemCount,
    Key? key,
    this.backgroundColor,
    this.animateSuffixIcon = false,
    this.suffixIcon,
  }) : super(key: key);

  @override
  _CustomPopupMenuBuilderButtonState createState() =>
      _CustomPopupMenuBuilderButtonState();
}

class _CustomPopupMenuBuilderButtonState
    extends State<CustomPopupMenuBuilderButton> {
  final GlobalKey globalKey = GlobalKey();
  OverlayEntry? overlayEntry;
  bool expanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
                            width: 300,
                            height: getCalculatedHeight(),
                            child: Card(
                              elevation: 5,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.builder(
                                itemBuilder: (context, i) {
                                  final CustomPopupMenuItem child =
                                      widget.itemBuilder.call(context, i);
                                  return InkWell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: child,
                                    ),
                                    onTap: () {
                                      debugPrint(
                                          'TYPE ${child.value.runtimeType} ');
                                      widget.onSelected(child.value);
                                      overlayEntry?.remove();
                                      setState(() {
                                        expanded = false;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    splashColor: Colors.grey,
                                  );
                                },
                                itemCount: widget.itemCount,
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
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
    final RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final size = MediaQuery.of(context).size;
    if (position.dx + 200 > size.width) {
      return size.width - 230;
    }
    return position.dx;
  }

  double getWidth() {
    final RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;
    return renderBox.size.width;
  }

  double getCalculatedHeight() {
    final size = MediaQuery.of(context).size;
    final itemsHeight = widget.itemCount * 170.0;
    final topPosition = getTopPosition();
    if (topPosition + itemsHeight > size.height) {
      return size.height - (topPosition);
    }
    // buttonSize = renderBox.size;
    return itemsHeight;
  }

  double getTopPosition() {
    final RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;
    final size = MediaQuery.of(context).size;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    if (position.dy + renderBox.size.height + (170 * widget.itemCount) >
        size.height) {
      return size.height - (170 * widget.itemCount) > 0
          ? size.height - (170 * widget.itemCount)
          : position.dy;
    }
    return position.dy + renderBox.size.height;
  }
}
