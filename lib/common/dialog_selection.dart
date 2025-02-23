import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import 'search_textfield.dart';

class DialogSelection extends StatefulWidget {
  final List<MapEntry<String, String>> data;
  final void Function(MapEntry<String, String>) onSelection;
  final void Function()? onDismiss;
  final Widget Function(String, int)? getClue;

  // final Widget Function(dynamic)? getChild;

  const DialogSelection({
    required this.onSelection,
    required this.title,
    required this.data,
    // this.getChild,
    this.onDismiss,
    this.isSingleSelect = false,
    Key? key,
    this.getClue,
  }) : super(key: key);

  final String title;
  final bool isSingleSelect;

  @override
  _DialogSelectionState createState() {
    return _DialogSelectionState();
  }
}

class _DialogSelectionState extends State<DialogSelection> {
  late List<MapEntry<String, String>> data;
  final TextEditingController _textEditingController = TextEditingController();
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    data = widget.data;
    //data = Provider.of<AddUserDialogNotifier>(context).dataSearch;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onDismiss != null) {
          widget.onDismiss!();
        }
        Navigator.pop(context);
      },
      child: ClipRRect(
        child: Container(
          color: Colors.black.withOpacity(0.2),
          //color: Colors.grey.shade800.withOpacity(0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 500,
                height: 600,
                padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  /*boxShadow: [
                    BoxShadow(blurRadius: 4, color: Colors.grey.shade400, spreadRadius: 0.5,),
                  ]*/
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select ${widget.title}',
                      style: AppFontStyle.lato(16,
                          fontWeight: FontWeight.w500, color: Colors.black),
                      //style: AppFontStyle.dashboardDialogTitle(),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SearchTextField(
                      focusNode: focusNode,
                      onTextChange: (String valueRaw) {
                        final List<String> value = valueRaw
                            .toLowerCase()
                            .split(' ')
                            .where((element) => element.isNotEmpty)
                            .toList(growable: false);
                        data = widget.data
                            .where(
                              (element) => value.any(
                                (v) =>
                                    element.value.isCaseInsensitiveContains(v),
                              ),
                            )
                            .toList();
                        setState(() {});
                      },
                      hint: 'Search ${widget.title}',
                      focusColor: ColorAssets.theme,
                      controller: _textEditingController,
                    ),
                    Expanded(
                      child: FixChildListView(
                        data: data,
                        getClue: widget.getClue,
                        onSelection: widget.onSelection,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DynamicChildListview extends StatelessWidget {
  final List<MapEntry<String, String>> data;
  final void Function(MapEntry<String, String>) onSelection;
  final Widget Function(MapEntry<String, String>) getChild;

  const DynamicChildListview(
      {Key? key,
      required this.data,
      required this.onSelection,
      required this.getChild})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, int index) {
          return ListTile(
            onTap: () {
              onSelection(data[index]);
              Navigator.pop(context);
            },
            title: getChild(data[index]),
          );
        });
  }
}

class FixChildListView extends StatelessWidget {
  final List<MapEntry<String, String>> data;
  final Widget Function(String, int)? getClue;
  final void Function(MapEntry<String, String>) onSelection;

  const FixChildListView(
      {Key? key, required this.data, this.getClue, required this.onSelection})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (BuildContext context, int index) {
        final clue = getClue?.call(data[index].value, index);
        return InkWell(
          onTap: () {
            onSelection(data[index]);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (clue != null) ...[
                  Flexible(child: clue),
                  const SizedBox(
                    width: 10,
                  ),
                ],
                SizedBox(
                  height: 30,
                  child: Text(
                    data[index].key,
                    style: AppFontStyle.lato(14,
                        color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
