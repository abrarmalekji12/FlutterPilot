import 'dart:math';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight_core.dart';

const _MIDDLE_DOT = '·';

class CustomCodeController extends TextEditingController {
  /// A highligh language to parse the text with
  final Mode? language;

  /// The theme to apply to the [language] parsing result
  final Map<String, TextStyle>? theme;

  /// A map of specific regexes to style
  final Map<String, TextStyle>? patternMap;

  /// A map of specific keywords to style
  final Map<String, TextStyle>? stringMap;

  /// Common editor params such as the size of a tab in spaces
  ///
  /// Will be exposed to all [modifiers]
  final EditorParams params;

  /// A list of code modifiers to dynamically update the code upon certain keystrokes
  final List<CodeModifier> modifiers;

  /// On web, replace spaces with invisible dots “·” to fix the current issue with spaces
  ///
  /// https://github.com/flutter/flutter/issues/77929
  final bool webSpaceFix;

  /// onChange callback, called whenever the content is changed
  final void Function(String)? onChange;

  final void Function()? onFormat;

  /* Computed members */
  final String languageId = _genId();
  final styleList = <TextStyle>[];
  final modifierMap = <String, CodeModifier>{};
  RegExp? styleRegExp;

  bool _suggestionEnable = false;
  final void Function(int, int)? onComment;
  final List<(int, int)> errorList = [];
  final KeyEventResult Function(KeyEvent)? onKeyHandle;

  CustomCodeController({
    String? text,
    this.language,
    this.onKeyHandle,
    this.onComment,
    this.theme,
    this.patternMap,
    this.onFormat,
    this.stringMap,
    this.params = const EditorParams(),
    this.modifiers = const <CodeModifier>[
      IndentModifier(),
      CloseBlockModifier(),
      TabModifier(),
    ],
    this.webSpaceFix = true,
    this.onChange,
  }) : super(text: text) {
    // PatternMap
    if (language != null && theme == null) {
      throw Exception('A theme must be provided for language parsing');
    }
    // Register language
    if (language != null) {
      highlight.registerLanguage(languageId, language!);
    }
    // Create modifier map
    modifiers.forEach((el) {
      modifierMap[el.char] = el;
    });
  }

  void enableSuggestion() {
    _suggestionEnable = true;
  }

  bool get suggestionEnable => _suggestionEnable;

  void disableSuggestion() {
    _suggestionEnable = false;
  }

  /// Replaces the current [selection] by [str]
  void insertStr(String str) {
    final sel = selection;
    text = text.replaceRange(selection.start, selection.end, str);
    final len = str.length;
    selection = sel.copyWith(
      baseOffset: sel.start + len,
      extentOffset: sel.start + len,
    );
  }

  /// Remove the char just before the cursor or the selection
  void removeChar() {
    if (selection.start < 1) return;
    final sel = selection;
    text = text.replaceRange(selection.start - 1, selection.start, '');
    selection = sel.copyWith(
      baseOffset: sel.start - 1,
      extentOffset: sel.start - 1,
    );
  }

  /// Remove the selected text
  void removeSelection() {
    final sel = selection;
    text = text.replaceRange(selection.start, selection.end, '');
    selection = sel.copyWith(
      baseOffset: sel.start,
      extentOffset: sel.start,
    );
  }

  /// Remove the selection or last char if the selection is empty
  void backspace() {
    if (selection.start < selection.end) {
      removeSelection();
    } else {
      removeChar();
    }
  }

  static const specialKeys = [
    LogicalKeyboardKey.quote,
    LogicalKeyboardKey.quoteSingle,
    LogicalKeyboardKey.braceLeft,
    LogicalKeyboardKey.bracketLeft,
    LogicalKeyboardKey.parenthesisLeft,
  ];

  KeyEventResult onKey(KeyEvent event) {
    if (onFormat != null &&
        HardwareKeyboard.instance.isControlPressed &&
        HardwareKeyboard.instance.isAltPressed &&
        event.logicalKey == LogicalKeyboardKey.keyL) {
      onFormat!.call();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      text = text.replaceRange(selection.start, selection.end, '\t');
      return KeyEventResult.handled;
    }
    // if (event.isKeyPressed(LogicalKeyboardKey.backspace)&&selection.isCollapsed&&text[selection.start]=='\n') {
    //   final text1=text;
    //   value=TextEditingValue(text: text1.substring(0,selection.start)+(selection.start+1<text1.length?text1.substring(selection.start+1):''),selection: selection.copyWith(baseOffset: selection.start-1,extentOffset: selection.start-1));
    //   return KeyEventResult.handled;
    // }
    if (onComment != null &&
        HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.slash) {
      onComment!(selection.start, selection.end);
      return KeyEventResult.handled;
    }
    for (final key in specialKeys) {
      if (!selection.isCollapsed && event.logicalKey == key) {
        final startIndex = selection.start;
        final length = selection.end - startIndex;
        if (length > 1) {
          final temp = text;
          value = TextEditingValue(
              text: temp.replaceRange(
                startIndex,
                startIndex + length,
                (key.keyLabel) +
                    temp.substring(startIndex, startIndex + length) +
                    getCloseChar(key),
              ),
              selection: TextSelection(
                  baseOffset: selection.baseOffset,
                  extentOffset: selection.extentOffset + 2));
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == key) {
        final close = getCloseChar(key);
        final text2 = text;
        value = TextEditingValue(
            text: text2.substring(0, selection.baseOffset) +
                close +
                (selection.baseOffset <= text2.length
                    ? text2.substring(selection.baseOffset)
                    : ''),
            selection: selection);
        return KeyEventResult.ignored;
      }
    }
    return onKeyHandle?.call(event) ?? KeyEventResult.ignored;
  }

  String getCloseChar(LogicalKeyboardKey key) {
    final String closeChar;
    if (key == LogicalKeyboardKey.bracketLeft) {
      closeChar = LogicalKeyboardKey.bracketRight.keyLabel;
    } else if (key == LogicalKeyboardKey.braceLeft) {
      closeChar = LogicalKeyboardKey.braceRight.keyLabel;
    } else if (key == LogicalKeyboardKey.parenthesisLeft) {
      closeChar = LogicalKeyboardKey.parenthesisRight.keyLabel;
    } else {
      closeChar = key.keyLabel;
    }
    return closeChar;
  }

  /// See webSpaceFix
  static String _spacesToMiddleDots(String str) {
    return str.replaceAll(' ', _MIDDLE_DOT);
  }

  /// See webSpaceFix
  static String _middleDotsToSpaces(String str) {
    return str.replaceAll(_MIDDLE_DOT, ' ');
  }

  /// Get untransformed text
  /// See webSpaceFix
  String get rawText {
    if (!_webSpaceFix) return super.text;
    return _middleDotsToSpaces(super.text);
  }

  // Private methods
  bool get _webSpaceFix => kIsWeb && webSpaceFix;

  static String _genId() {
    const _chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
    final _rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
          10, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))),
    );
  }

  int? _insertedLoc(String a, String b) {
    final sel = selection;
    if (a.length + 1 != b.length || sel.start != sel.end) return null;
    return sel.start;
  }

  @override
  set value(TextEditingValue newValue) {
    final loc = _insertedLoc(text, newValue.text);
    if (loc != null && loc != -1) {
      final char = newValue.text[loc];
      final modifier = modifierMap[char];
      final val = modifier?.updateString(rawText, selection, params);
      if (val != null) {
        // Update newValue
        newValue = newValue.copyWith(
          text: val.text,
          selection: val.selection,
        );
      }
    }
    // Now fix the textfield for web
    if (_webSpaceFix) {
      newValue = newValue.copyWith(text: _spacesToMiddleDots(newValue.text));
    }
    if (onChange != null) {
      onChange!(
          _webSpaceFix ? _middleDotsToSpaces(newValue.text) : newValue.text);
    }
    super.value = newValue;
  }

  TextSpan _processPatterns(String text, TextStyle? style) {
    final children = <TextSpan>[];
    text.splitMapJoin(
      styleRegExp!,
      onMatch: (Match m) {
        if (styleList.isEmpty) return '';
        int idx;
        for (idx = 1;
            idx < m.groupCount &&
                idx <= styleList.length &&
                m.group(idx) == null;
            idx++) {}
        children.add(TextSpan(
          text: m[0],
          style: styleList[idx - 1],
        ));
        return '';
      },
      onNonMatch: (String span) {
        children.add(TextSpan(text: span, style: style));
        return '';
      },
    );
    return TextSpan(style: style, children: children);
  }

  TextSpan _processLanguage(String text, TextStyle? style) {
    final rawText = _webSpaceFix ? _middleDotsToSpaces(text) : text;
    final result = highlight.parse(rawText, language: languageId);

    final nodes = result.nodes;

    final children = <TextSpan>[];
    var currentSpans = children;
    final stack = <List<TextSpan>>[];

    void _traverse(Node node) {
      var val = node.value;
      final nodeChildren = node.children;
      if (val != null) {
        if (_webSpaceFix) val = _spacesToMiddleDots(val);
        var child = TextSpan(text: val, style: theme?[node.className]);
        if (styleRegExp != null) {
          child = _processPatterns(val, theme?[node.className]);
        }
        currentSpans.add(child);
      } else if (nodeChildren != null) {
        List<TextSpan> tmp = [];
        currentSpans.add(TextSpan(
          children: tmp,
          style: theme?[node.className],
        ));
        stack.add(currentSpans);
        currentSpans = tmp;
        nodeChildren.forEach((n) {
          _traverse(n);
          if (n == nodeChildren.last) {
            currentSpans = stack.isEmpty ? children : stack.removeLast();
          }
        });
      }
    }

    if (nodes != null)
      for (var node in nodes) {
        _traverse(node);
      }
    return TextSpan(style: style, children: children);
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context, TextStyle? style, bool? withComposing}) {
    // Retrieve pattern regexp
    final patternList = <String>[];
    if (_webSpaceFix) {
      patternList.add('(' + _MIDDLE_DOT + ')');
      styleList.add(const TextStyle(color: Colors.transparent));
    }
    if (stringMap != null) {
      patternList.addAll(stringMap!.keys.map((e) => r'(\b' + e + r'\b)'));
      styleList.addAll(stringMap!.values);
    }
    if (patternMap != null) {
      patternList.addAll(patternMap!.keys.map((e) => '(' + e + ')'));
      styleList.addAll(patternMap!.values);
    }
    styleRegExp = RegExp(patternList.join('|'), multiLine: true);

    // Return parsing
    if (language != null) {
      return _processLanguage(text, style);
    } else if (styleRegExp != null) {
      return _processPatterns(text, style);
    } else {
      return TextSpan(text: text, style: style);
    }
  }
}
