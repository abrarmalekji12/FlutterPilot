import 'package:flutter/material.dart';
import 'search_textfield.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';

class DialogSelection extends StatefulWidget {
  final List<dynamic> data;
  final void Function(dynamic) onSelection;
  final void Function()? onDismiss;
  final Widget Function(dynamic)? getChild;

  const DialogSelection({
    required this.onSelection,
    required this.title,
    required this.data,
    this.getChild,
    this.onDismiss,
    this.isSingleSelect = false,
    Key? key,
  }) : super(key: key);

  final String title;
  final bool isSingleSelect;

  @override
  _DialogSelectionState createState() {
    return _DialogSelectionState();
  }
}

class _DialogSelectionState extends State<DialogSelection> {
  late List<dynamic> data;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    data = widget.data;
    //data = Provider.of<AddUserDialogNotifier>(context, listen: false).dataSearch;
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // data = Provider.of<AddUserDialogNotifier>(context, listen: false).dataSearch;

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
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  /*boxShadow: [
                    BoxShadow(blurRadius: 4, color: Colors.grey.shade400, spreadRadius: 0.5,),
                  ]*/
                ),
                child: _buildBody(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select ${widget.title}',
          style: AppFontStyle.roboto(16,
              fontWeight: FontWeight.w500, color: Colors.black),
          //style: AppFontStyle.dashboardDialogTitle(),
        ),
        const SizedBox(
          height: 20,
        ),
        Expanded(
          child: _buildDataList(),
        ),
      ],
    );
  }

  Widget _buildDataList() {
    return Column(
      children: <Widget>[
        SearchTextField(
          focusNode: focusNode,
          onTextChange: (String valueRaw) {
            String value = valueRaw.toLowerCase();
            data = widget.data
                .where((element) => element.toLowerCase().startsWith(value))
                .toList();
            setState(() {});
            //Provider.of<AddUserDialogNotifier>(context, listen: false).onSearch(value);
          },
          hint: 'Search ${widget.title}',
          focusColor: AppColors.theme,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: widget.getChild == null
                ? FixChildListView(
                    data: data,
                    onSelection: widget.onSelection,
                  )
                : DynamicChildListview(
                    data: data,
                    onSelection: widget.onSelection,
                    getChild: widget.getChild!,
                  ),
          ),
        )
      ],
    );
  }
}

class DynamicChildListview extends StatelessWidget {
  final List<dynamic> data;
  final void Function(dynamic) onSelection;
  final Widget Function(dynamic) getChild;

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
            contentPadding: const EdgeInsets.all(5),
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
  final List<dynamic> data;
  final void Function(dynamic) onSelection;
  const FixChildListView(
      {Key? key, required this.data, required this.onSelection})
      : super(key: key);

//widget.getChild?.call(data[index])
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          onTap: () {
            onSelection(data[index]);
            Navigator.pop(context);
          },
          contentPadding: const EdgeInsets.all(5),
          title: Text(
            data[index],
            style: AppFontStyle.roboto(14,
                color: Colors.black, fontWeight: FontWeight.w500),
          ),
        );
      },
    );
  }
}
