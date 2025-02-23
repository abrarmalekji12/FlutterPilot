import 'package:flutter/material.dart';

import '../constant/font_style.dart';

class EditableTextView extends StatefulWidget {
  final String text;
  final void Function(String) onChange;
  final TextStyle? style;

  EditableTextView(this.text, {Key? key, this.style, required this.onChange})
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
      return SizedBox(
        height: 45,
        width: 20.0 * _controller.text.length,
        child: TextField(
          focusNode: FocusNode()..requestFocus(),
          controller: _controller,
          style: widget.style ??
              AppFontStyle.lato(14,
                  color: Colors.black, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(contentPadding: EdgeInsets.zero),
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
        child: SizedBox(
          height: 45,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.text,
                style: widget.style ??
                    AppFontStyle.lato(14,
                        color: Colors.black, fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                width: 10,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.edit,
                  size: touchMode ? 16 : 14,
                  color: touchMode ? Colors.black : Colors.grey,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
