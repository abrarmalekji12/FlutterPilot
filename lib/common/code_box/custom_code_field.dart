import 'dart:async';
import 'dart:math';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import 'custom_code_controller.dart';

class LineNumberController extends TextEditingController {
  final TextSpan Function(int, TextStyle?)? lineNumberBuilder;

  LineNumberController(this.lineNumberBuilder);

  @override
  TextSpan buildTextSpan(
      {required BuildContext context, TextStyle? style, bool? withComposing}) {
    final children = <TextSpan>[];
    final list = text.split('\n');
    for (int k = 0; k < list.length; k++) {
      final el = list[k];
      final number = int.parse(el);
      var textSpan = TextSpan(text: el, style: style);
      if (lineNumberBuilder != null) {
        textSpan = lineNumberBuilder!(number, style);
      }
      children.add(textSpan);
      if (k < list.length - 1) children.add(const TextSpan(text: '\n'));
    }
    return TextSpan(children: children, style: style);
  }
}

class CustomCodeField extends StatefulWidget {
  /// {@macro flutter.widgets.textField.minLines}
  final int? minLines;

  /// {@macro flutter.widgets.textField.maxLInes}
  final int? maxLines;

  /// {@macro flutter.widgets.textField.expands}
  final bool expands;

  /// Whether overflowing lines should wrap around or make the field scrollable horizontally
  final bool wrap;

  /// A CodeController instance to apply language highlight, themeing and modifiers
  final CustomCodeController controller;

  /// A LineNumberStyle instance to tweak the line number column styling
  final LineNumberStyle lineNumberStyle;

  /// {@macro flutter.widgets.textField.cursorColor}
  final Color? cursorColor;

  /// {@macro flutter.widgets.textField.textStyle}
  final TextStyle? textStyle;

  /// A way to replace specific line numbers by a custom TextSpan
  final TextSpan Function(int, TextStyle?)? lineNumberBuilder;

  /// {@macro flutter.widgets.textField.enabled}
  final bool? enabled;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final Color? background;
  final EdgeInsets padding;
  final Decoration? decoration;
  final EdgeInsets? outerPadding;
  final TextSelectionThemeData? textSelectionTheme;
  final FocusNode? focusNode;
  final double? radius;
  final bool showLineNumber;
  final bool shrink;
  final bool readOnly;
  final double fontSize;
  final InputBorder? border;

  const CustomCodeField({
    Key? key,
    required this.controller,
    this.minLines,
    this.shrink = false,
    this.readOnly = false,
    this.showLineNumber = true,
    this.maxLines,
    this.expands = false,
    this.wrap = false,
    this.background,
    this.decoration,
    this.outerPadding,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(),
    this.lineNumberStyle = const LineNumberStyle(),
    this.enabled,
    this.cursorColor,
    this.textSelectionTheme,
    this.lineNumberBuilder,
    this.focusNode,
    this.radius,
    this.contextMenuBuilder,
    required this.fontSize,
    this.border,
  }) : super(key: key);

  @override
  CustomCodeFieldState createState() => CustomCodeFieldState();
}

class CustomCodeFieldState extends State<CustomCodeField> {
// Add a controller
  LinkedScrollControllerGroup? _controllers;
  ScrollController? _numberScroll;
  ScrollController? _codeScroll;
  LineNumberController? _numberController;

  //
  StreamSubscription<bool>? _keyboardVisibilitySubscription;
  FocusNode? _focusNode;
  String? lines;
  String longestLine = '';

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    _numberScroll = _controllers?.addAndGet();
    _codeScroll = _controllers?.addAndGet();
    _numberController = LineNumberController(widget.lineNumberBuilder);
    widget.controller.addListener(_onTextChanged);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode!.attach(context, onKeyEvent: _onKey);

    _onTextChanged();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    return widget.controller.onKey(event);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _numberScroll?.dispose();
    _codeScroll?.dispose();
    _numberController?.dispose();
    _keyboardVisibilitySubscription?.cancel();
    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  void _onTextChanged() {
    // Rebuild line number
    final str = widget.controller.text.split('\n');
    final buf = <String>[];
    for (var k = 0; k < str.length; k++) {
      buf.add((k + 1).toString());
    }
    _numberController?.text = buf.join('\n');
    // Find longest line
    longestLine = '';
    widget.controller.text.split('\n').forEach((line) {
      if (line.length > longestLine.length) longestLine = line;
    });
    setState(() {});
  }

  // Wrap the codeField in a horizontal scrollView
  Widget _wrapInScrollView(
      Widget codeField, TextStyle textStyle, double minWidth) {
    final leftPad = widget.lineNumberStyle.margin / 2;
    final intrinsic = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 0.0,
              minWidth: max(minWidth - leftPad, 0.0),
            ),
            child: Padding(
              child: Text(longestLine, style: textStyle),
              padding: const EdgeInsets.only(right: 16.0),
            ), // Add extra padding
          ),
          widget.expands ? Expanded(child: codeField) : codeField,
        ],
      ),
    );

    return SingleChildScrollView(
      padding: widget.shrink
          ? EdgeInsets.zero
          : EdgeInsets.only(
              left: leftPad,
              right: widget.padding.right,
            ),
      scrollDirection: Axis.horizontal,
      child: intrinsic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Default color scheme
    const ROOT_KEY = 'root';
    final defaultBg = Colors.grey.shade900;
    final defaultText = Colors.grey.shade200;

    final theme = widget.controller.theme;
    Color? backgroundCol =
        widget.background ?? theme?[ROOT_KEY]?.backgroundColor ?? defaultBg;
    if (widget.decoration != null) {
      backgroundCol = null;
    }
    TextStyle textStyle = widget.textStyle ?? const TextStyle();
    textStyle = textStyle.copyWith(
      color: textStyle.color ?? theme?[ROOT_KEY]?.color ?? defaultText,
      fontSize: widget.fontSize,
    );
    final TextStyle numberTextStyle = AppFontStyle.lato(12,
            fontWeight: FontWeight.w400,
            color: ColorAssets.darkerGrey.withOpacity(0.7))
        .copyWith(height: 1.33 * textStyle.fontSize! / 12);
    final cursorColor =
        widget.cursorColor ?? theme?[ROOT_KEY]?.color ?? defaultText;

    final lineNumberCol = TextField(
      scrollPadding: widget.padding.copyWith(left: 0, right: 5),
      style: numberTextStyle,
      controller: _numberController,
      enabled: false,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      expands: widget.expands,
      scrollController: _numberScroll,
      decoration: const InputDecoration(
        disabledBorder: InputBorder.none,
        filled: true,
        contentPadding: EdgeInsets.symmetric(vertical: 10),
      ),
      textAlign: widget.lineNumberStyle.textAlign,
    );

    final numberCol = Container(
      width: widget.lineNumberStyle.width,
      padding: EdgeInsets.only(
        left: widget.padding.left,
        right: widget.lineNumberStyle.margin / 2,
      ),
      color: backgroundCol?.withOpacity(0.5),
      child: lineNumberCol,
    );

    final codeField = TextField(
      focusNode: _focusNode,
      scrollPadding: widget.padding,
      style: textStyle,
      controller: widget.controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      expands: widget.expands,
      scrollController: _codeScroll,
      decoration: InputDecoration(
        disabledBorder: widget.border ?? InputBorder.none,
        border: widget.border ?? InputBorder.none,
        enabledBorder: widget.border ?? InputBorder.none,
        focusedBorder: widget.border ?? InputBorder.none,
        contentPadding: widget.shrink
            ? const EdgeInsets.symmetric(horizontal: 10)
            : const EdgeInsets.all(10),
      ),
      textAlignVertical: widget.shrink ? TextAlignVertical.center : null,
      readOnly: widget.readOnly,
      cursorColor: cursorColor,
      autocorrect: false,
      enableSuggestions: false,
      enabled: widget.enabled,
      contextMenuBuilder: widget.contextMenuBuilder,
    );

    final codeCol = Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: widget.textSelectionTheme,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Control horizontal scrolling
          return widget.wrap
              ? codeField
              : _wrapInScrollView(codeField, textStyle, constraints.maxWidth);
        },
      ),
    );
    return Container(
      decoration: (widget.decoration as BoxDecoration?)?.copyWith(
              borderRadius: BorderRadius.circular(widget.radius ?? 0)) ??
          BoxDecoration(
            color: backgroundCol,
            borderRadius: BorderRadius.circular(widget.radius ?? 0),
          ),
      padding: widget.outerPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLineNumber) numberCol,
          Expanded(child: codeCol),
        ],
      ),
    );
  }
}
