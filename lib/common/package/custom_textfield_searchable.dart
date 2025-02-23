import 'dart:async';

import 'package:flutter/material.dart';

import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../constant/other_constant.dart';
import '../../injector.dart';

class TileModel {
  final String label;
  final String value;
  final bool sticky;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  TileModel(
    this.label,
    this.value, {
    this.sticky = false,
    this.onTap,
    this.onDelete,
  });
}

class CustomTextFieldSearch extends StatefulWidget {
  /// A default list of values that can be used for an initial list of elements to select from
  final List<TileModel>? initialList;

  /// A string used for display of the selectable elements
  final String label;

  /// A controller for an editable text field
  final TextEditingController controller;

  /// An optional future or async function that should return a list of selectable elements
  final Future<List<TileModel>> Function(String)? future;

  /// The value selected on tap of an element within the list
  final Function? getSelectedValue;

  /// Used for customizing the display of the TextField
  final InputDecoration? decoration;

  /// Used for customizing the style of the text within the TextField
  final TextStyle? textStyle;

  /// Used for customizing the scrollbar for the scrollable results
  final ScrollbarDecoration? scrollbarDecoration;

  /// The minimum length of characters to be entered into the TextField before executing a search
  final int minStringLength;

  /// The number of matched items that are viewable in results
  final int itemsInView;

  final void Function(TileModel)? onSelected;

  /// Creates a TextFieldSearch for displaying selected elements and retrieving a selected element
  const CustomTextFieldSearch(
      {Key? key,
      this.initialList,
      required this.label,
      required this.controller,
      this.textStyle,
      this.future,
      this.getSelectedValue,
      this.decoration,
      this.scrollbarDecoration,
      this.itemsInView = 3,
      this.minStringLength = 2,
      required this.onSelected})
      : super(key: key);

  @override
  _CustomTextFieldSearchState createState() => _CustomTextFieldSearchState();
}

class _CustomTextFieldSearchState extends State<CustomTextFieldSearch> {
  final FocusNode _focusNode = FocusNode();
  late OverlayEntry _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<TileModel>? filteredList = [];
  bool hasFuture = false;
  bool loading = false;
  final _debouncer = Debouncer(milliseconds: debounceTimeInMillis);
  static const itemHeight = 55;
  ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.controller.text.isNotEmpty) {
        this._overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(this._overlayEntry);
      }
    });
    super.didChangeDependencies();
  }

  void resetList() {
    List<TileModel> tempList = <TileModel>[];
    setState(() {
      // after loop is done, set the filteredList state from the tempList
      this.filteredList = tempList;
      this.loading = false;
    });
    // mark that the overlay widget needs to be rebuilt
    this._overlayEntry.markNeedsBuild();
  }

  void setLoading() {
    if (!this.loading) {
      setState(() {
        this.loading = true;
      });
    }
  }

  void resetState(List<TileModel> tempList) {
    setState(() {
      // after loop is done, set the filteredList state from the tempList
      this.filteredList = tempList;
      this.loading = false;
      // if no items are found, add message none found
    });
    // mark that the overlay widget needs to be rebuilt so results can show
    this._overlayEntry.markNeedsBuild();
  }

  void updateGetItems() {
    // mark that the overlay widget needs to be rebuilt
    // so loader can show
    this._overlayEntry.markNeedsBuild();
    if (widget.controller.text.length > widget.minStringLength) {
      this.setLoading();
      widget.future!(widget.controller.text).then((value) {
        this.filteredList = value;
        // create an empty temp list
        List<TileModel> tempList = <TileModel>[];
        bool notShowSticky = false;
        // loop through each item in filtered items
        for (int i = 0; i < filteredList!.length; i++) {
          // lowercase the item and see if the item contains the string of text from the lowercase search

          if (!filteredList![i].sticky &&
              filteredList![i]
                  .label
                  .toLowerCase()
                  .contains(widget.controller.text.toLowerCase())) {
            if (filteredList![i].label == widget.controller.text) {
              notShowSticky = true;
            }
            // if there is a match, add to the temp list
            tempList.add(this.filteredList![i]);
          }
        }
        if (!notShowSticky) {
          tempList.addAll(filteredList!.where((element) => element.sticky));
        }
        // helper function to set tempList and other state props
        this.resetState(tempList);
      });
    } else {
      // reset the list if we ever have less than 2 characters
      resetList();
    }
  }

  void updateList() {
    this.setLoading();
    // set the filtered list using the initial list
    this.filteredList = widget.initialList;

    // create an empty temp list
    List<TileModel> tempList = [];
    // loop through each item in filtered items
    bool showSticky = true;
    for (int i = 0; i < filteredList!.length; i++) {
      // lowercase the item and see if the item contains the string of text from the lowercase search
      if (!filteredList![i].sticky &
          this
              .filteredList![i]
              .label
              .toLowerCase()
              .contains(widget.controller.text.toLowerCase())) {
        if (filteredList![i].label == widget.controller.text) {
          showSticky = false;
        }
        // if there is a match, add to the temp list
        tempList.add(this.filteredList![i]);
      }
    }
    if (showSticky) {
      tempList.addAll(filteredList!.where((element) => element.sticky));
    }
    // helper function to set tempList and other state props
    this.resetState(tempList);
  }

  void initState() {
    super.initState();

    if (widget.scrollbarDecoration?.controller != null) {
      _scrollController = widget.scrollbarDecoration!.controller;
    }

    // throw error if we don't have an initial list or a future
    if (widget.initialList == null && widget.future == null) {
      throw ('Error: Missing required initial list or future that returns list');
    }
    if (widget.future != null) {
      setState(() {
        hasFuture = true;
      });
    }
    // add event listener to the focus node and only give an overlay if an entry
    // has focus and insert the overlay into Overlay context otherwise remove it

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.controller.text.isNotEmpty) {
        this._overlayEntry = this._createOverlayEntry();
        Overlay.of(context).insert(this._overlayEntry);
      }
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        this._overlayEntry = this._createOverlayEntry();
        Overlay.of(context).insert(this._overlayEntry);
      } else {
        Debouncer(milliseconds: 700).run(() {
          this._overlayEntry.remove();
          // check to see if itemsFound is false, if it is clear the input
          // check to see if we are currently loading items when keyboard exists, and clear the input
          if (loading == true) {
            // reset the list so it's empty and not visible
            resetList();
            widget.controller.clear();
          }
        });
        // if we have a list of items, make sure the text input matches one of them
        // if not, clear the input
      }
    });
  }

  ListView _listViewBuilder(context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredList!.length,
      itemBuilder: (context, i) {
        return InkWell(
          onTap: () {
            // set the controller value to what was selected
            if (filteredList![i].onTap != null) {
              filteredList![i].onTap!.call();
            } else {
              widget.controller.text = filteredList![i].value;
            }

            widget.onSelected?.call(filteredList![i]);
            // reset the list so it's empty and not visible
            resetList();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                filteredList![i].label,
                style: AppFontStyle.lato(14,
                    color: filteredList![i].sticky
                        ? ColorAssets.theme
                        : Colors.black),
              ),
              if (filteredList![i].onDelete != null) ...[
                const Spacer(),
                InkWell(
                  onTap: () {
                    filteredList![i].onDelete!.call();
                    filteredList!.removeAt(i);
                    this._overlayEntry = _createOverlayEntry();
                    Overlay.of(context).insert(this._overlayEntry);
                  },
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: ColorAssets.black,
                  ),
                ),
              ],
            ]),
          ),
        );
      },
      padding: EdgeInsets.zero,
      shrinkWrap: true,
    );
  }

  /// A default loading indicator to display when executing a Future
  Widget _loadingIndicator() {
    return Container(
      width: 50,
      height: 50,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary),
        ),
      ),
    );
  }

  Widget decoratedScrollbar(child) {
    if (widget.scrollbarDecoration is ScrollbarDecoration) {
      return Theme(
        data: Theme.of(context)
            .copyWith(scrollbarTheme: widget.scrollbarDecoration!.theme),
        child: Scrollbar(child: child, controller: _scrollController),
      );
    }

    return Scrollbar(child: child);
  }

  Widget? _listViewContainer(context) {
    if (filteredList!.length > 0) {
      return decoratedScrollbar(Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: theme.background1),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _listViewBuilder(context)));
    }
    return null;
  }

  num heightByLength(int length) {
    return itemHeight * length;
  }

  num calculateHeight() {
    if (filteredList!.length > 1) {
      if (widget.itemsInView <= filteredList!.length) {
        return heightByLength(widget.itemsInView);
      }

      return heightByLength(filteredList!.length);
    }

    return itemHeight;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size overlaySize = renderBox.size;
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    return OverlayEntry(
        builder: (context) => Positioned(
              width: overlaySize.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, overlaySize.height + 5.0),
                child: Material(
                  color: Colors.transparent,
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: screenWidth,
                        maxWidth: screenWidth,
                      ),
                      child: loading
                          ? _loadingIndicator()
                          : _listViewContainer(context)),
                ),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: this._layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: this._focusNode,
        decoration: widget.decoration != null
            ? widget.decoration
            : InputDecoration(labelText: widget.label),
        style: widget.textStyle,
        onChanged: (String value) {
          // every time we make a change to the input, update the list
          _debouncer.run(() {
            setState(() {
              if (hasFuture) {
                updateGetItems();
              } else {
                updateList();
              }
            });
          });
        },
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;

  /// A callback function to execute
  VoidCallback? action;

  /// A count-down timer that can be configured to fire once or repeatedly.
  Timer? _timer;

  /// Creates a Debouncer that executes a function after a certain length of time in milliseconds
  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

class ScrollbarDecoration {
  const ScrollbarDecoration({
    required this.controller,
    required this.theme,
  });

  /// {@macro flutter.widgets.Scrollbar.controller}
  final ScrollController controller;

  /// {@macro flutter.widgets.ScrollbarThemeData}
  final ScrollbarThemeData theme;
}
