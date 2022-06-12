import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';

import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

import '../constant/font_style.dart';

class ActionCodeEditor extends StatefulWidget {
  final String code;
  final void Function(String) onCodeChange;

  const ActionCodeEditor(
      {Key? key, required this.code, required this.onCodeChange})
      : super(key: key);

  @override
  State<ActionCodeEditor> createState() => _ActionCodeEditorState();
}

class _ActionCodeEditorState extends State<ActionCodeEditor> {
  late final CodeController _codeController;

  @override
  initState() {
    super.initState();
    _codeController = CodeController(language: dart,
        theme: monokaiSublimeTheme,
        onChange: widget.onCodeChange);
    _codeController.text = widget.code;
  }

  @override
  Widget build(BuildContext context) {
    return CodeField(
      // expands: true,
      enabled: true,
      lineNumberStyle: const LineNumberStyle(
        margin: 5,
        textStyle: TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontFamily: 'arial'),
      ),

      controller: _codeController,
    );
  }
}
