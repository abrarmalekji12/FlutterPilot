import 'dart:html' as html;
import 'dart:math';

import 'package:flutter/material.dart';
import 'search_textfield.dart';

import '../constant/app_colors.dart';

class CustomPopupMenuButton<T> extends StatefulWidget {
  final List<CustomPopupMenuItem> Function(BuildContext) itemBuilder;
  final void Function(T) onSelected;
  final Widget child;
  final bool animateSuffixIcon;
  final double itemHeight;
  final Widget? suffixIcon;
  final Color? backgroundColor;

  const CustomPopupMenuButton({
    required this.itemBuilder,
    required this.onSelected,
    required this.child,
    Key? key,
    this.itemHeight = 40,
    this.backgroundColor,
    this.animateSuffixIcon = false,
    this.suffixIcon,
  }) : super(key: key);

  @override
  _CustomPopupMenuButtonState createState() => _CustomPopupMenuButtonState<T>();
}

class _CustomPopupMenuButtonState<T> extends State<CustomPopupMenuButton> {
  final GlobalKey globalKey = GlobalKey();
  OverlayEntry? overlayEntry;
  bool expanded = false;
  late List<CustomPopupMenuItem> allItems, filteredItems;

  final TextEditingController _textEditingController = TextEditingController();
  late double minimumBoxHeight;
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = '';
  late double left, top;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    minimumBoxHeight = dh(context, 90);
  }

  @override
  void initState() {
    super.initState();
    overlayEntry = OverlayEntry(builder: (context) {
      allItems = widget.itemBuilder(context);
      filteredItems = allItems
          .where((element) => element.value.toLowerCase().contains(_searchText))
          .toList();

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
                left: left,
                top: top,
                child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.5, end: 1),
                    curve: Curves.bounceOut,
                    duration: const Duration(milliseconds: 100),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Transform.translate(
                          offset: Offset(0, -100 * (1 - value)),
                          child: StatefulBuilder(
                              builder: (context, setStateForMenu) {
                            return SizedBox(
                              width: 220,
                              height: getCalculatedHeight(),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Card(
                                  elevation: 5,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      SearchTextField(
                                        hint: 'Search ..',
                                        onSubmitted: () {
                                          if (filteredItems.isNotEmpty) {
                                            widget.onSelected(
                                                filteredItems.first.value as T);
                                            overlayEntry?.remove();

                                            setState(() {
                                              expanded = false;
                                            });
                                          }
                                        },
                                        focusColor: AppColors.theme,
                                        onTextChange: (text) {
                                          _searchText = text.toLowerCase();
                                          setStateForMenu(() {});
                                        },
                                        focusNode: _searchFocusNode
                                          ..requestFocus(),
                                        controller: _textEditingController,
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: filteredItems.length,
                                          itemBuilder: (_, i) {
                                            return InkWell(
                                              child: Container(
                                                height: widget.itemHeight,
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: filteredItems[i]
                                                    .build(context),
                                              ),
                                              onTap: () {
                                                widget.onSelected(
                                                    filteredItems[i].value
                                                        as T);
                                                overlayEntry?.remove();

                                                setState(() {
                                                  expanded = false;
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              splashColor: Colors.grey,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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
            _searchText = '';
            allItems = widget.itemBuilder(context);
            left = getLeftPosition();
            top = getTopPosition();
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
    final itemsHeight = allItems.length * widget.itemHeight + widget.itemHeight;

    if (itemsHeight > minimumBoxHeight) {
      return minimumBoxHeight;
    }
    // buttonSize = renderBox.size;
    return itemsHeight;
  }

  double getTopPosition() {
    final size = MediaQuery.of(context).size;
    final RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;
    final itemsHeight = allItems.length * widget.itemHeight + widget.itemHeight;

    final translation = renderBox.getTransformTo(null).getTranslation();
    final offset = Offset(translation.x, translation.y);
    final Rect position = renderBox.paintBounds.shift(offset);
    if (position.top + itemsHeight > size.height) {
      return (size.height / 2) - (minimumBoxHeight / 2);
    }
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
