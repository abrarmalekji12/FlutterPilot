import 'package:flutter/material.dart';
import 'package:flutter_builder/common/search_textfield.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:flutter_builder/constant/font_style.dart';

class DialogSelection extends StatefulWidget {
  final List<dynamic> data;
  final void Function(dynamic) onSelection;
  final void Function()? onDismiss;

  const DialogSelection({
    required this.onSelection,
    required this.title,
    required this.data,
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
          style: AppFontStyle.roboto(16, fontWeight: FontWeight.w500, color: Colors.black),
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
            data = widget.data.where((element) => element.toLowerCase().startsWith(value)).toList();
            setState(() {});
            //Provider.of<AddUserDialogNotifier>(context, listen: false).onSearch(value);
          },
          hint: 'Search ${widget.title}',
          focusColor: AppColors.theme,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: ListView.builder(
              //shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: _singleSelectItemBuilder,
            ),
          ),
        )
      ],
    );
  }

  Widget _singleSelectItemBuilder(BuildContext itemBuilder, int index) {
    //final item = data[index];
    return InkWell(
      onTap: () {
        widget.onSelection(data[index]);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        child: Text(
          data[index],
          style: AppFontStyle.roboto(14, color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
