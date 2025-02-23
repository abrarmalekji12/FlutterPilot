import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../injector.dart';
import '../widgets/textfield/appt_search_field.dart';
import 'web/html_lib.dart' as html;

const double _kSearchBoxHeight = 50;

class CustomPopupMenuButton<T> extends StatefulWidget {
  final List<CustomPopupMenuItem> Function(BuildContext) itemBuilder;
  final void Function(T) onSelected;
  final Widget child;
  final bool animateSuffixIcon;
  final double itemHeight;
  final Widget? suffixIcon;
  final Color? backgroundColor;
  final bool visible;

  const CustomPopupMenuButton({
    required this.itemBuilder,
    required this.onSelected,
    required this.child,
    Key? key,
    this.visible = true,
    this.itemHeight = 40,
    this.backgroundColor,
    this.animateSuffixIcon = false,
    this.suffixIcon,
  }) : super(key: key);

  @override
  _CustomPopupMenuButtonState createState() => _CustomPopupMenuButtonState<T>();
}

class _CustomPopupMenuButtonState<T> extends State<CustomPopupMenuButton<T>> {
  final GlobalKey globalKey = GlobalKey();
  OverlayEntry? overlayEntry;
  bool expanded = false;
  late List<CustomPopupMenuItem> allItems, filteredItems;

  final TextEditingController _textEditingController = TextEditingController();
  late double maxBoxHeight;
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = '';
  late double left, top;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    maxBoxHeight = dh(context, 90);
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      html.window.onResize.listen((event) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          overlayEntry?.markNeedsBuild();
        });
      });
    }
  }

  void showMenu() {
    if (!(overlayEntry?.mounted ?? false)) {
      overlayEntry = OverlayEntry(builder: (context) {
        allItems = widget.itemBuilder(context);

        return Stack(
          children: [
            Positioned.fill(child: GestureDetector(
              onTap: () {
                overlayEntry?.remove();
                overlayEntry = null;
                expanded = false;
              },
            )),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: FocusTraversalGroup(
                  policy: WidgetOrderTraversalPolicy(),
                  child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.5, end: 1),
                      curve: Curves.bounceOut,
                      duration: const Duration(milliseconds: 200),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Transform.translate(
                            offset: Offset(0, -100 * (1 - value)),
                            child: StatefulBuilder(
                                builder: (context, setStateForMenu) {
                              filteredItems = allItems
                                  .where(
                                    (element) =>
                                        element.value is! String ||
                                        (element.value.toString())
                                            .isCaseInsensitiveContains(
                                                _searchText),
                                  )
                                  .toList();
                              return Container(
                                width: 200,
                                constraints: BoxConstraints(
                                  maxHeight: getCalculatedHeight(),
                                ),
                                decoration: BoxDecoration(
                                    color: theme.background1,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        spreadRadius: 3,
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      )
                                    ]),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: _kSearchBoxHeight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: AppSearchField(
                                          hint: 'Search ..',
                                          onEditingComplete: () {
                                            if (filteredItems.isNotEmpty) {
                                              expanded = false;
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback(
                                                      (timeStamp) {
                                                overlayEntry?.remove();
                                                overlayEntry = null;

                                                widget.onSelected(filteredItems
                                                    .first.value as T);
                                              });
                                            }
                                          },
                                          onChanged: (text) {
                                            _searchText = text.toLowerCase();
                                            setStateForMenu(() {});
                                          },
                                          focusNode: _searchFocusNode
                                            ..requestFocus(),
                                          controller: _textEditingController,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                          height: 0,
                                        ),
                                        padding: const EdgeInsets.all(6)
                                            .copyWith(top: 0),
                                        itemCount: filteredItems.length,
                                        itemBuilder: (_, i) {
                                          return SizedBox(
                                            height: widget.itemHeight,
                                            child: Tooltip(
                                              message: filteredItems[i]
                                                  .value
                                                  .toString(),
                                              child: TextButton(
                                                onPressed: filteredItems[i]
                                                        .enable
                                                    ? () {
                                                        overlayEntry?.remove();
                                                        overlayEntry = null;
                                                        expanded = false;
                                                        Future.delayed(
                                                            Duration.zero, () {
                                                          widget.onSelected(
                                                              filteredItems[i]
                                                                  .value as T);
                                                        });
                                                      }
                                                    : null,
                                                style: TextButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 6),
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  surfaceTintColor: ColorAssets
                                                      .theme
                                                      .withOpacity(0.2),
                                                  backgroundColor:
                                                      !filteredItems[i].enable
                                                          ? ColorAssets
                                                              .lightGrey
                                                          : null,
                                                ),
                                                child: DefaultTextStyle(
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppFontStyle.lato(14,
                                                      color: theme.text1Color,
                                                      fontWeight:
                                                          FontWeight.normal),
                                                  child: filteredItems[i]
                                                      .build(context),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                ),
              ),
            ),
          ],
        );
      });
      _searchText = '';
      allItems = widget.itemBuilder(context);
      left = getLeftPosition();
      top = getTopPosition();
      Overlay.of(context).insert(overlayEntry!);

      setState(() {
        expanded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: globalKey,
      borderRadius: BorderRadius.circular(10),
      splashColor: Colors.grey,
      onTap: () {
        showMenu();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
    final itemsHeight =
        (allItems.length * widget.itemHeight) + _kSearchBoxHeight;

    if (itemsHeight > maxBoxHeight) {
      return maxBoxHeight;
    }
    // buttonSize = renderBox.size;
    return itemsHeight;
  }

  double getTopPosition() {
    final size = MediaQuery.of(context).size;
    final RenderBox renderBox =
        globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;
    final itemsHeight = min(
        maxBoxHeight, allItems.length * widget.itemHeight + _kSearchBoxHeight);

    final translation = renderBox.getTransformTo(null).getTranslation();
    final offset = Offset(translation.x, translation.y);
    final Rect position = renderBox.paintBounds.shift(offset);
    final t = position.top;
    if (t + itemsHeight + 10 > size.height) {
      return size.height - itemsHeight - 10;
    }
    // renderBox.localToGlobal(Offset.zero);
    return t;
  }
}

class CustomPopupMenuItem<T> extends StatelessWidget {
  final T value;
  final Widget child;
  final bool enable;

  const CustomPopupMenuItem({
    required this.value,
    required this.child,
    this.enable = true,
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
