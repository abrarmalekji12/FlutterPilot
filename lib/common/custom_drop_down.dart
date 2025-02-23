import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constant/color_assets.dart';
import '../injector.dart';
import 'web/html_lib.dart' as html;

class CustomDropdownButton<T> extends StatefulWidget {
  final TextStyle style;
  final Icon? icon;
  final T? value;
  final Widget? hint;
  final bool enable;
  final Widget Function(BuildContext, T) selectedItemBuilder;
  final List<CustomDropdownMenuItem<T>> items;
  final void Function(T) onChanged;
  final double itemHeight;

  const CustomDropdownButton({
    required this.style,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.selectedItemBuilder,
    this.icon,
    Key? key,
    this.enable = true,
    this.itemHeight = 40,
  }) : super(key: key);

  @override
  _CustomDropdownButtonState<T> createState() => _CustomDropdownButtonState();
}

const double dropDownWidth = 340;

class _CustomDropdownButtonState<T> extends State<CustomDropdownButton<T>> {
  // T? selected;
  final GlobalKey globalKey = GlobalKey();
  late double maxHeight;
  OverlayEntry? overlayEntry;
  int state = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    // selected = widget.value;

    if (kIsWeb) {
      html.window.onResize.listen((event) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          overlayEntry?.markNeedsBuild();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: globalKey,
      borderRadius: BorderRadius.circular(10),
      splashColor: Colors.grey,
      onTap: widget.enable
          ? () {
              if (!(overlayEntry?.mounted ?? false)) {
                overlayEntry = OverlayEntry(builder: (context) {
                  maxHeight = MediaQuery.of(context).size.height * 0.7;
                  return GestureDetector(
                    onTap: () {
                      overlayEntry?.remove();
                      overlayEntry = null;

                      setState(() {
                        state = 2;
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
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.background1,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: kElevationToShadow[4],
                                        ),
                                        constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.6),
                                        width: getWidth(),
                                        // height: calculatedHeight + 16,
                                        child: ListView.separated(
                                          separatorBuilder: (context, _) =>
                                              const Divider(
                                            height: 1,
                                          ),
                                          itemCount: widget.items.length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, i) {
                                            return InkWell(
                                              child: Container(
                                                alignment: Alignment.centerLeft,
                                                child: widget.items[i].child,
                                                color: widget.items[i].value ==
                                                        widget.value
                                                    ? theme.background2
                                                    : null,
                                                height: widget.itemHeight,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                              ),
                                              onTap: () {
                                                widget.onChanged(
                                                    widget.items[i].value);
                                                if (overlayEntry != null) {
                                                  overlayEntry?.remove();
                                                  overlayEntry = null;
                                                }
                                                setState(() {
                                                  state = 2;
                                                });
                                              },
                                              splashColor: Colors.grey,
                                            );
                                          },
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
                Overlay.of(context).insert(overlayEntry!);
                setState(() {
                  state = 1;
                });
              }
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: theme.background1,
          border: Border.all(color: ColorAssets.border),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: widget.value != null
                  ? widget.selectedItemBuilder(context, widget.value!)
                  : widget.hint ?? Container(),
            ),
            TweenAnimationBuilder(
              key: ValueKey(state),
              curve: Curves.bounceInOut,
              builder: (context, double value, child) {
                return Transform.rotate(
                  angle: ((state == 1) ? pi * value : pi * (value - 1)),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xffb3b3b3),
                    size: 24,
                  ),
                );
              },
              tween: Tween<double>(begin: 0, end: 1),
              duration: state == 0
                  ? const Duration(milliseconds: 0)
                  : const Duration(milliseconds: 150),
            ),
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

  double get calculatedHeight {
    final height = widget.items.length * widget.itemHeight;
    // buttonSize = renderBox.size;
    return height < maxHeight ? height : maxHeight;
  }

  double getTopPosition() {
    final RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;
    final size = MediaQuery.of(context).size;

    final Offset position = renderBox.localToGlobal(Offset.zero);

    if (position.dy +
            renderBox.size.height +
            (widget.itemHeight * widget.items.length) >
        size.height) {
      return size.height - (widget.itemHeight * widget.items.length) > 0
          ? size.height - (widget.itemHeight * widget.items.length)
          : position.dy;
    }
    return position.dy + renderBox.size.height;
  }
}

class CustomDropdownMenuItem<T> extends StatelessWidget {
  final T value;
  final Widget child;

  const CustomDropdownMenuItem({
    required this.value,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
