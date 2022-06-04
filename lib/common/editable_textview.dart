import 'package:flutter/material.dart';

import '../constant/font_style.dart';
import 'border_text_field.dart';

class EditableTextView extends StatefulWidget {
  final String text;
  final void Function(String) onChange;

  EditableTextView({Key? key, required this.text, required this.onChange})
      : super(key: key);

  @override
  _EditableTextViewState createState() => _EditableTextViewState();
}

class _EditableTextViewState extends State<EditableTextView> {
  bool editMode = false;
  bool touchMode = false;
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    _controller.text = widget.text;
  }

  @override
  Widget build(BuildContext context) {
    if (editMode) {
      return Container(
        width: 20.0 * _controller.text.length,
        padding: const EdgeInsets.all(5),
        child: BorderTextField(
          focusNode: FocusNode()..requestFocus(),
          controller: _controller,
          onSubmitted: (data) {
            widget.onChange.call(data);
            setState(() {
              editMode = false;
            });
          },
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          touchMode = true;
        });
      },
      onExit: (_) {
        setState(() {
          touchMode = false;
        });
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            editMode = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.text,
                style: AppFontStyle.roboto(14,
                    color: Colors.black, fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                width: 10,
              ),
              Icon(
                Icons.edit,
                size: 16,
                color: touchMode ? Colors.black : Colors.grey,
              )
            ],
          ),
        ),
      ),
    );
  }
}
