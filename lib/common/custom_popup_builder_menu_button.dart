import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constant/font_style.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import 'custom_popup_menu_button.dart';
import 'web/html_lib.dart' as html;

class CustomPopupMenuBuilderButton extends StatefulWidget {
  final CustomPopupMenuItem Function(BuildContext, int) itemBuilder;
  final void Function(Component) onSelected;
  final Widget child;
  final bool animateSuffixIcon;
  final Widget? suffixIcon;
  final Color? backgroundColor;
  final int itemCount;
  final String title;

  const CustomPopupMenuBuilderButton({
    required this.itemBuilder,
    required this.onSelected,
    required this.child,
    required this.title,
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
  late double maxHeight;
  bool expanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    maxHeight = MediaQuery.of(context).size.height;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    overlayEntry = OverlayEntry(builder: (context) {
      return GestureDetector(
        onTap: () {
          overlayEntry?.remove();
          overlayEntry = null;
          setState(() {
            expanded = false;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.5, end: 1),
                curve: Curves.bounceOut,
                duration: const Duration(milliseconds: 100),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.translate(
                      offset: Offset(0, -100 * (1 - value)),
                      child: SingleChildScrollView(
                        child: Container(
                          width: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: kElevationToShadow[2],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  widget.title,
                                  style: AppFontStyle.lato(16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: maxHeight,
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  separatorBuilder: (_, __) => const Divider(
                                    thickness: 1,
                                  ),
                                  itemBuilder: (context, i) {
                                    final CustomPopupMenuItem child =
                                        widget.itemBuilder.call(context, i);
                                    return InkWell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: IgnorePointer(child: child),
                                      ),
                                      onTap: () {
                                        widget.onSelected(child.value);
                                        overlayEntry?.remove();
                                        overlayEntry = null;
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ),
      );
    });
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
    return Card(
      elevation: 0,
      color: widget.backgroundColor,
      child: InkWell(
        key: globalKey,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.grey,
        onTap: () {
          if (!(overlayEntry?.mounted ?? false)) {
            Overlay.of(context).insert(overlayEntry!);
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
    return 0;
  }
}
