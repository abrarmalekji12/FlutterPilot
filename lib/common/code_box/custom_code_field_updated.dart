import 'dart:async';
import 'dart:math';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import 'custom_code_controller_updated.dart';

class CustomCodeField extends StatefulWidget {
  /// {@macro flutter.widgets.textField.smartQuotesType}
  final SmartQuotesType? smartQuotesType;

  /// {@macro flutter.widgets.textField.keyboardType}
  final TextInputType? keyboardType;

  /// {@macro flutter.widgets.textField.minLines}
  final int? minLines;

  /// {@macro flutter.widgets.textField.maxLInes}
  final int? maxLines;

  /// {@macro flutter.widgets.textField.expands}
  final bool expands;

  /// Whether overflowing lines should wrap around or make the field scrollable horizontally
  final bool wrap;

  /// A CodeController instance to apply language highlight, theming and modifiers
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

  /// {@macro flutter.widgets.editableText.onChanged}
  final void Function(String)? onChanged;

  /// {@macro flutter.widgets.editableText.readOnly}
  final bool readOnly;

  /// {@macro flutter.widgets.textField.isDense}
  final bool isDense;

  /// {@macro flutter.widgets.textField.selectionControls}
  final TextSelectionControls? selectionControls;

  final Color? background;
  final EdgeInsets padding;
  final EdgeInsets? outerPadding;
  final double? fontSize;
  final Decoration? decoration;
  final TextSelectionThemeData? textSelectionTheme;
  final FocusNode? focusNode;
  final void Function()? onTap;
  final bool lineNumbers;
  final bool horizontalScroll;
  final InputBorder? border;
  final bool shrink;
  final double? radius;
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  const CustomCodeField({
    Key? key,
    required this.controller,
    this.minLines,
    this.maxLines,
    this.radius,
    this.border,
    this.shrink = false,
    this.expands = false,
    this.outerPadding,
    this.wrap = false,
    this.background,
    this.decoration,
    this.textStyle,
    this.fontSize,
    this.padding = EdgeInsets.zero,
    this.lineNumberStyle = const LineNumberStyle(),
    this.enabled,
    this.contextMenuBuilder,
    this.onTap,
    this.readOnly = false,
    this.cursorColor,
    this.textSelectionTheme,
    this.lineNumberBuilder,
    this.focusNode,
    this.onChanged,
    this.isDense = false,
    this.smartQuotesType,
    this.keyboardType,
    this.lineNumbers = true,
    this.horizontalScroll = true,
    this.selectionControls,
  }) : super(key: key);

  @override
  State<CustomCodeField> createState() => _CustomCodeFieldState();
}

class _CustomCodeFieldState extends State<CustomCodeField> {
  // Add a controller
  LinkedScrollControllerGroup? _controllers;
  ScrollController? _numberScroll;
  ScrollController? _codeScroll;
  LineNumberController? _numberController;

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
    _focusNode!.onKeyEvent = _onKey;
    _focusNode!.attach(context, onKeyEvent: _onKey);

    _onTextChanged();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.readOnly) {
      return KeyEventResult.ignored;
    }

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
    Widget codeField,
    TextStyle textStyle,
    double minWidth,
  ) {
    final leftPad = widget.lineNumberStyle.margin / 2;
    final intrinsic = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 0,
              minWidth: max(minWidth - leftPad, 0),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(longestLine, style: textStyle),
            ), // Add extra padding
          ),
          widget.expands ? Expanded(child: codeField) : codeField,
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: leftPad,
        right: widget.padding.right,
      ),
      scrollDirection: Axis.horizontal,

      /// Prevents the horizontal scroll if horizontalScroll is false
      physics:
          widget.horizontalScroll ? null : const NeverScrollableScrollPhysics(),
      child: intrinsic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Default color scheme
    const rootKey = 'root';
    final defaultBg = Colors.grey.shade900;
    final defaultText = Colors.grey.shade200;

    final styles = CodeTheme.of(context)?.styles;
    Color? backgroundCol =
        widget.background ?? styles?[rootKey]?.backgroundColor ?? defaultBg;

    if (widget.decoration != null) {
      backgroundCol = null;
    }

    TextStyle textStyle = widget.textStyle ?? const TextStyle();
    textStyle = textStyle.copyWith(
      color: textStyle.color ?? styles?[rootKey]?.color ?? defaultText,
      fontSize: widget.fontSize,
    );

    TextStyle numberTextStyle =
        widget.lineNumberStyle.textStyle ?? const TextStyle();
    final numberColor =
        (styles?[rootKey]?.color ?? defaultText).withOpacity(0.7);

    // Copy important attributes
    numberTextStyle = numberTextStyle.copyWith(
      color: numberTextStyle.color ?? numberColor,
      fontSize: textStyle.fontSize,
      fontFamily: textStyle.fontFamily,
    );

    final cursorColor =
        widget.cursorColor ?? styles?[rootKey]?.color ?? defaultText;

    TextField? lineNumberCol;
    Container? numberCol;
    if (widget.lineNumbers) {
      lineNumberCol = TextField(
        smartQuotesType: widget.smartQuotesType,
        scrollPadding: widget.padding,
        style: numberTextStyle,
        controller: _numberController,
        enabled: false,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        selectionControls: widget.selectionControls,
        expands: widget.expands,
        scrollController: _numberScroll,
        decoration: InputDecoration(
          disabledBorder: InputBorder.none,
          contentPadding:
              widget.shrink ? const EdgeInsets.symmetric(horizontal: 10) : null,
          isDense: widget.isDense,
        ),
        textAlign: widget.lineNumberStyle.textAlign,
      );

      numberCol = Container(
        width: widget.lineNumberStyle.width,
        padding: EdgeInsets.only(
          left: widget.padding.left,
          right: widget.lineNumberStyle.margin / 2,
        ),
        color: widget.lineNumberStyle.background,
        child: lineNumberCol,
      );
    }

    final codeField = TextField(
      keyboardType: widget.keyboardType,
      smartQuotesType: widget.smartQuotesType,
      focusNode: _focusNode,
      onTap: widget.onTap,
      scrollPadding: widget.padding,
      style: textStyle,
      controller: widget.controller,
      minLines: widget.minLines,
      selectionControls: widget.selectionControls,
      maxLines: widget.maxLines,
      expands: widget.expands,
      scrollController: _codeScroll,
      decoration: InputDecoration(
        disabledBorder: widget.border ?? InputBorder.none,
        border: widget.border ?? InputBorder.none,
        enabledBorder: widget.border ?? InputBorder.none,
        focusedBorder: widget.border ?? InputBorder.none,
        isDense: widget.isDense,
        contentPadding:
            widget.shrink ? const EdgeInsets.symmetric(horizontal: 10) : null,
      ),
      cursorColor: cursorColor,
      autocorrect: false,
      enableSuggestions: false,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
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
          if (widget.lineNumbers && numberCol != null) numberCol,
          Expanded(child: codeCol),
        ],
      ),
    );
  }
}
