import 'package:code_text_field/code_text_field.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/src/common_modes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/action_code/action_code_bloc.dart';
import '../bloc/key_fire/key_fire_bloc.dart';
import '../bloc/suggestion_code/suggestion_code_bloc.dart';
import '../common/code_box/custom_code_controller.dart';
import '../common/code_box/custom_code_field.dart';
import '../common/compiler/code_processor.dart';
import '../common/responsive/responsive_widget.dart';
import '../common/utils/dateformat_utils.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../injector.dart';
import '../models/variable_model.dart';
import 'common/action_code_dialog.dart';
import 'ide/suggestion.dart';
import 'project_selection_page.dart';

final fvbDart = Mode(refs: {
  '~contains~0~variants~4~contains~2': Mode(
      className: 'subst',
      variants: [Mode(begin: '{{', end: '}}')],
      keywords: 'true false null this is new super',
      contains: [C_NUMBER_MODE, Mode(ref: '~contains~0')]),
  '~contains~0~variants~4~contains~1':
      Mode(className: 'subst', variants: [Mode(begin: '\\\$[A-Za-z0-9_]+')]),
  '~contains~0': Mode(className: 'string', variants: [
    Mode(begin: "r'''", end: "'''"),
    Mode(begin: 'r"""', end: '"""'),
    Mode(begin: "r'", end: "'", illegal: '\\n'),
    Mode(begin: 'r"', end: '"', illegal: '\\n'),
    Mode(begin: "'''", end: "'''", contains: [
      BACKSLASH_ESCAPE,
      Mode(ref: '~contains~0~variants~4~contains~1'),
      Mode(ref: '~contains~0~variants~4~contains~2')
    ]),
    Mode(begin: '"""', end: '"""', contains: [
      BACKSLASH_ESCAPE,
      Mode(ref: '~contains~0~variants~4~contains~1'),
      Mode(ref: '~contains~0~variants~4~contains~2')
    ]),
    Mode(begin: "'", end: "'", illegal: '\\n', contains: [
      BACKSLASH_ESCAPE,
      Mode(ref: '~contains~0~variants~4~contains~1'),
      Mode(ref: '~contains~0~variants~4~contains~2')
    ]),
    Mode(begin: '"', end: '"', illegal: '\\n', contains: [
      BACKSLASH_ESCAPE,
      Mode(ref: '~contains~0~variants~4~contains~1'),
      Mode(ref: '~contains~0~variants~4~contains~2')
    ])
  ]),
},

//     keywords: {
//   'keyword':
//       'abstract as assert async await break case catch class const continue covariant default deferred do dynamic else enum export extends extension external factory false final finally for Function get hide if implements import in inferface is library mixin new null on operator part rethrow return set show static super switch sync this throw true try typedef var void while with yield',
//   'built_in':
//       'Comparable DateTime Duration Function Iterable Iterator List Map Match Null Object Pattern RegExp Set Stopwatch String StringBuffer StringSink Symbol Type Uri bool double dynamic int num print Element ElementList document querySelector querySelectorAll window refresh'
// },
    keywords: {
      'keyword':
          'abstract as assert async await break case catch class const continue default do dynamic else enum export extends false final for Function get if implements import in is new null on operator part return set show static super switch this true var void while',
      'built_in':
          'Comparable DateTime Duration Function Iterable Iterator List Map Match Null Object Pattern RegExp Set Stopwatch String StringBuffer StringSink Symbol Type Uri bool double dynamic int num print Element ElementList document querySelector querySelectorAll window refresh'
    }, contains: [
  Mode(ref: '~contains~0'),
  Mode(className: 'comment', begin: '/\\*\\*', end: '\\*/', contains: [
    PHRASAL_WORDS_MODE,
    Mode(
        className: 'doctag',
        begin: '(?:TODO|FIXME|NOTE|BUG|XXX):',
        relevance: 0)
  ], subLanguage: [
    'markdown'
  ]),
  Mode(className: 'comment', begin: '///+\\s*', end: '\$', contains: [
    Mode(subLanguage: ['markdown'], begin: '.', end: '\$'),
    PHRASAL_WORDS_MODE,
    Mode(
        className: 'doctag',
        begin: '(?:TODO|FIXME|NOTE|BUG|XXX):',
        relevance: 0)
  ]),
  C_LINE_COMMENT_MODE,
  C_BLOCK_COMMENT_MODE,
  Mode(
      className: 'class',
      beginKeywords: 'class interface',
      end: '{',
      excludeEnd: true,
      contains: [
        Mode(beginKeywords: 'extends implements'),
        UNDERSCORE_TITLE_MODE
      ]),
  C_NUMBER_MODE,
  Mode(className: 'meta', begin: '@[A-Za-z]+'),
  Mode(begin: '=>')
]);

class FVBCodeEditor extends StatefulWidget {
  final String code;
  final void Function(String) onCodeChange;
  final void Function(bool) onError;
  final ActionCodeEditorConfig config;
  final CodeProcessor processor;
  final String scopeName;

  const FVBCodeEditor(
      {Key? key,
      required this.code,
      required this.scopeName,
      required this.onCodeChange,
      required this.onError,
      required this.config,
      required this.processor})
      : super(key: key);

  @override
  State<FVBCodeEditor> createState() => _FVBCodeEditorState();
}

class _FVBCodeEditorState extends State<FVBCodeEditor> {
  late final CustomCodeController _codeController;
  late final CodeProcessor processor;
  final List<ConsoleMessage> consoleMessages = [];
  final SuggestionCodeBloc _suggestionCodeBloc = SuggestionCodeBloc();
  final ValueNotifier<int> _consoleChangeNotifier = ValueNotifier<int>(0);
  String? code, oldCode;
  final DartFormatter _formatter = DartFormatter();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  late double _topBox, _bottomBox;
  int selectionIndex = 0;
  OverlayEntry? suggestionOverlayEntry;
  BoxConstraints? _boxConstraints;
  final ScrollController _scrollController = ScrollController();
  final upStaticCodeController = CodeController(
    language: fvbDart,
    theme: monokaiSublimeTheme
        .map((key, value) => MapEntry(key, value.copyWith(fontSize: 15))),
  );
  final downStaticCodeController = CodeController(
    language: fvbDart,
    theme: monokaiSublimeTheme
        .map((key, value) => MapEntry(key, value.copyWith(fontSize: 15))),
  );
  final _prefs = get<SharedPreferences>();

  @override
  void dispose() {
    if (suggestionOverlayEntry?.mounted ?? false) {
      suggestionOverlayEntry?.remove();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _prefs.setDouble(widget.processor.scopeName, _scrollController.offset);
      if (Responsive.isLargeScreen(context) && _boxConstraints != null) {
        showSuggestionBox(context, _boxConstraints!);
      }
    });

    final offset = _prefs.getDouble(widget.processor.scopeName);
    if (offset != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _scrollController.jumpTo(offset);
      });
    }
    final onError = (error, line) {
      consoleMessages.add(
          ConsoleMessage('$error at Line $line', ConsoleMessageType.error));
      _consoleChangeNotifier.value++;
    };
    processor = CodeProcessor(
      consoleCallback: CodeProcessor.testConsoleCallback,
      onError: onError,
      parentProcessor: widget.processor.parentProcessor
          ?.clone(CodeProcessor.testConsoleCallback, onError),
      scopeName: widget.scopeName,
    );

    _codeController = CustomCodeController(
        language: fvbDart,
        onComment: (start, end) {
          if (start == end) {
            /// Single line comment
            final code = _codeController.text;
            int index = -1;
            for (int i = start - 1; i >= 0; i--) {
              if (code[i] == '\n') {
                index = i;
                break;
              }
            }
            if (index == -1) {
              return;
            }
            if (code.length > index + 2 &&
                code[index + 1] == '/' &&
                code[index + 2] == '/') {
              _codeController.value = TextEditingValue(
                  text:
                      code.substring(0, index + 1) + code.substring(index + 3),
                  selection: TextSelection.collapsed(
                      offset: _codeController.selection.baseOffset));
            } else {
              _codeController.value = TextEditingValue(
                  text: code.substring(0, index + 1) +
                      '//' +
                      code.substring(index + 1),
                  selection: TextSelection.collapsed(
                      offset: _codeController.selection.baseOffset));
            }
          } else {
            /// Multi line comment
            final code = _codeController.text;
            _codeController.text = code.substring(0, start) +
                '/*\n' +
                code.substring(start, end + 1) +
                '*/' +
                code.substring(end + 1);
          }
        },
        theme: monokaiSublimeTheme
            .map((key, value) => MapEntry(key, value.copyWith(fontSize: 15))),
        onChange: (value) {
          if (code != value) {
            final oldCode = code;
            code = value;
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              if (widget.config.string) {
                if (code!.startsWith('"') && code!.endsWith('"')) {
                  widget.onCodeChange(code!.substring(1, code!.length - 1));
                } else {
                  if (code![code!.length - 1] != '"') {
                    code = code! + '"';
                  }
                  if (code![0] != '"') {
                    code = '"' + code!;
                  }
                  _codeController.value = TextEditingValue(text: code!,selection: _codeController.value.selection);
                  return;
                }
              } else {
                widget.onCodeChange(code!);
              }
              executeAndCheck(code!,
                  suggestion:
                      (code!.length - (oldCode?.length ?? 0)).abs() == 1);
            });
          } else {
            if (_codeController.selection.baseOffset != selectionIndex) {
              _suggestionCodeBloc.add(SuggestionUpdatedEvent(null));
              selectionIndex = _codeController.selection.baseOffset;
            }
          }
        });

    code = widget.config.string ? '"${widget.code}"' : widget.code;
    _codeController.text = code!;
    executeAndCheck(code!, suggestion: false);
  }

  void showSuggestionBox(
      BuildContext context, BoxConstraints constraints) async {
    if (_suggestionCodeBloc.suggestion == null || !mounted) {
      return;
    }
    if (suggestionOverlayEntry?.mounted ?? false) {
      suggestionOverlayEntry?.remove();
    }
    suggestionOverlayEntry = OverlayEntry(builder: (context) {
      if (!mounted) {
        return Container();
      }
      if (!Responsive.isLargeScreen(context)) {
        return Positioned(
          top: MediaQuery.of(context).size.height - 380 - (100),
          child: SuggestionWidget(
            suggestionCodeBloc: _suggestionCodeBloc,
          ),
        );
      }
      final TextPainter painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: _codeController.buildTextSpan(
            context: context, style: const TextStyle(fontSize: 16)),
      );
      painter.layout(maxWidth: constraints.maxWidth - 40);
      final Rect caretPrototype =
          Rect.fromLTWH(0.0, 0.0, 2, painter.preferredLineHeight);
      final offset = painter.getOffsetForCaret(
          TextPosition(
              offset: _codeController.selection.baseOffset -
                  (_suggestionCodeBloc.suggestion?.code.length ?? 0)),
          caretPrototype);
      final top = Responsive.isLargeScreen(context)
          ? _focusNode.offset.dy + offset.dy + painter.preferredLineHeight
          : MediaQuery.of(context).size.height - 400;

      if (top > _topBox && top < _bottomBox) {
        return Positioned(
          top: top,
          left: _focusNode.offset.dx + offset.dx,
          child: SuggestionWidget(
            suggestionCodeBloc: _suggestionCodeBloc,
          ),
        );
      }
      return const Offstage();
    });

    Overlay.of(context)!.insert(suggestionOverlayEntry!);
  }

  void executeAndCheck(String code, {bool suggestion = true}) {
    processor.variables.clear();
    processor.functions.clear();
    processor.localVariables.clear();
    if (!widget.config.parentProcessorGiven) {
      processor.variables.addAll(widget.processor.variables.values
          .where((element) =>
              element.runtimeType == FVBVariable ||
              (element is VariableModel && element.uiAttached))
          .toList(growable: false)
          .asMap()
          .map((key, value) => MapEntry(value.name, value.clone())));
    } else {
      processor.variables.addAll(widget.processor.variables.values
          .toList(growable: false)
          .asMap()
          .map((key, value) => MapEntry(value.name, value.clone())));
    }
    processor.localVariables.addAll(widget.processor.localVariables);
    if (widget.config.variables != null) {
      if (widget.config.parentProcessorGiven) {
        processor.variables.addAll(widget.config.variables!
            .call()
            .asMap()
            .map((key, value) => MapEntry(value.name, value)));
      } else {
        processor.localVariables.addAll(widget.config.variables!
            .call()
            .asMap()
            .map((key, value) => MapEntry(value.name, value.value)));
      }
    }
    processor.functions.addAll(
        widget.processor.functions.map((key, value) => MapEntry(key, value)));
    CodeProcessor? parent = processor.parentProcessor;
    CodeProcessor? originalParent = widget.processor.parentProcessor;
    while (parent != null) {
      parent.variables.clear();
      parent.functions.clear();
      parent.localVariables.clear();
      parent.variables.addAll(originalParent!.variables
          .map((key, value) => MapEntry(value.name, value.clone())));
      parent.functions.addAll(
          originalParent.functions.map((key, value) => MapEntry(key, value)));

      parent.localVariables.addAll(originalParent.localVariables);
      parent = parent.parentProcessor;
      originalParent = originalParent.parentProcessor;
    }
    if (suggestion) {
      processor.enableSuggestion((suggestions) {
        _suggestionCodeBloc.add(SuggestionUpdatedEvent(suggestions));
      });
    }
    oldCode = processor.executeCode(code,
        type: OperationType.checkOnly, oldCode: oldCode, onExecutionStart: () {
      consoleMessages.clear();
      _consoleChangeNotifier.value = 0;
      _suggestionCodeBloc.add(SuggestionUpdatedEvent(null));
    },
        declarativeOnly:
            widget.config.upCode == null && !widget.config.singleLine);
    processor.destroyProcess(deep: false);
    if (suggestion) {
      processor.disableSuggestion();
    }
    if (_consoleChangeNotifier.value == 0) {
      consoleMessages.add(
          ConsoleMessage('Compiled. No Errors.', ConsoleMessageType.success));
      context
          .read<ActionCodeBloc>()
          .add(ActionCodeUpdatedEvent(widget.processor.scopeName));

      _consoleChangeNotifier.value++;
    }
    widget.onError(consoleMessages
        .where((element) => element.type == ConsoleMessageType.error)
        .isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (_boxConstraints == null) {
        _boxConstraints = constraints;
        final size = MediaQuery.of(context).size;
        _topBox = (size.height / 2) - (constraints.maxHeight / 2);
        _bottomBox = (size.height / 2) + (constraints.maxHeight / 2);
      }
      return BlocListener<KeyFireBloc, KeyFireState>(
        listener: (context, state) {
          if (state is DownKeyEventFired) {
            if (_suggestionCodeBloc.suggestion != null) {
              if ((state.key == FireKeyType.enter ||
                  state.key == FireKeyType.rtrn)) {
                _handleEnter();
              } else if (state.key == FireKeyType.up) {
                _suggestionCodeBloc.add(SuggestionSelectionChangeEvent(-1));
              } else if (state.key == FireKeyType.down) {
                _suggestionCodeBloc.add(SuggestionSelectionChangeEvent(1));
              }
            }
          }
        },
        child: BlocListener<SuggestionCodeBloc, SuggestionCodeState>(
          bloc: _suggestionCodeBloc,
          listener: (context, state) {
            if (state is SuggestionCodeUpdated) {
              if (state.suggestions != null) {
                _codeController.enableSuggestion();
                if (state.suggestions != null && _boxConstraints != null) {
                  showSuggestionBox(context, _boxConstraints!);
                }
              } else {
                if (suggestionOverlayEntry != null &&
                    _codeController.suggestionEnable) {
                  suggestionOverlayEntry?.remove();
                  _codeController.disableSuggestion();
                }
              }
            }
          },
          child: Responsive(
            smallScreen: Column(
              children: [
                SizedBox(
                  height: 50,
                  child: _buildConsole(),
                ),
                Expanded(
                  child: _buildEditor(),
                ),
              ],
            ),
            largeScreen: Column(
              children: [Expanded(child: _buildEditor()), _buildConsole()],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildConsole() {
    return Container(
      color: const Color(0xff494949),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.topLeft,
      child: ValueListenableBuilder(
          valueListenable: _consoleChangeNotifier,
          builder: (context, value, child) {
            return printConsoleMessage();
          }),
    );
  }

  Widget _buildEditor() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Column(
          children: [
            if (widget.config.upCode != null)
              Tooltip(
                message: 'unmodifiable code',
                child: CodeField(
                  lineNumberBuilder: (context, lineNumber) =>
                      const TextSpan(text: ''),
                  controller: upStaticCodeController
                    ..text = widget.config.upCode!,
                  enabled: false,
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: CustomCodeField(
                  minLines: 50,
                  enabled: true,
                  focusNode: _focusNode,
                  key: _textFieldKey,
                  wrap: true,
                  controller: _codeController,
                ),
              ),
            ),
            if (widget.config.downCode != null)
              Tooltip(
                message: 'unmodifiable code',
                child: CodeField(
                  lineNumberBuilder: (context, lineNumber) =>
                      const TextSpan(text: ''),
                  controller: downStaticCodeController
                    ..text = widget.config.downCode!,
                  enabled: false,
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconButton(
                    icon: Icons.format_align_center,
                    onPressed: () {
                      try {
                        final formatCode = _codeController.text
                            .replaceAll('{{', '__\${')
                            .replaceAll('}}', '}__');
                        final code1 = (widget.config.downCode != null
                                ? _formatter
                                    .format('temp() {' + formatCode + '}')
                                    .replaceFirst('temp() {', '')
                                : _formatter.format(formatCode))
                            .replaceAll('__\${', '{{')
                            .replaceAll('}__', '}}');
                        final code = widget.config.downCode != null
                            ? code1.substring(0, code1.lastIndexOf('}'))
                            : code1;
                        final cursor = _codeController.selection.extentOffset;
                        _codeController.value = TextEditingValue(
                            text: code,
                            selection: TextSelection.collapsed(
                                offset: code.length > cursor
                                    ? cursor
                                    : code.length - 1));
                        widget.onCodeChange(code);
                      } on FormatterException catch (error) {
                        for (final error in error.errors) {
                          consoleMessages.add(ConsoleMessage(
                              error.message, ConsoleMessageType.error));
                          _consoleChangeNotifier.value++;
                        }
                        return;
                      }
                    },
                    color: Colors.blueAccent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget printConsoleMessage() {
    final List<TextSpan> list = [];
    for (final consoleMessage in consoleMessages) {
      list.add(TextSpan(
        text: '-> ' + consoleMessage.message + '\n',
        style: AppFontStyle.roboto(14,
            color: getConsoleMessageColor(consoleMessage.type, darkTheme: true),
            fontWeight: FontWeight.w800),
      ));
    }
    return RichText(
      text: TextSpan(children: list),
    );
  }

  void _handleEnter() {
    if (_suggestionCodeBloc.suggestion!.suggestions.length <=
        _suggestionCodeBloc.selectionIndex) {
      return;
    }
    final text = _codeController.text;
    final index = _codeController.selection.baseOffset;
    final suggestion = _suggestionCodeBloc
        .suggestion!.suggestions[_suggestionCodeBloc.selectionIndex];
    final offset = index +
        (-_suggestionCodeBloc.suggestion!.code.length +
            suggestion.result.length);
    final newText =
        text.substring(0, index - _suggestionCodeBloc.suggestion!.code.length) +
            suggestion.result +
            text.substring(index);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _codeController.value = TextEditingValue(
          text: newText,
          selection: suggestion.resultCursorStart != null
              ? TextSelection(
                  baseOffset: offset -
                      suggestion.result.length +
                      suggestion.resultCursorStart! -
                      1,
                  extentOffset: offset - suggestion.resultCursorEnd)
              : TextSelection.collapsed(
                  offset: offset - suggestion.resultCursorEnd));

      _suggestionCodeBloc.add(SuggestionUpdatedEvent(null));
    });
  }
}

Color getConsoleMessageColor(ConsoleMessageType type,
    {bool darkTheme = false}) {
  switch (type) {
    case ConsoleMessageType.error:
      return AppColors.red;
    case ConsoleMessageType.success:
      return AppColors.green;
    case ConsoleMessageType.event:
      return darkTheme ? AppColors.lightGrey : AppColors.darkGrey;
    case ConsoleMessageType.info:
      return darkTheme ? Colors.white : Colors.black;
    default:
      return darkTheme ? Colors.white : Colors.black;
  }
}

enum ConsoleMessageType { error, info, success, event }

class ConsoleMessage {
  late final String time;
  final String message;
  final ConsoleMessageType type;

  ConsoleMessage(this.message, this.type) {
    time = DateFormatUtils.getCurrentTimeForConsole();
  }

  @override
  String toString() {
    return 'ConsoleMessage{time: $time, message: $message, type: $type}';
  }
}

class CodeBase {
  final String Function() code;
  final Iterable<FVBVariable> Function() variables;
  final String scopeName;

  CodeBase(this.code, this.variables, this.scopeName);
}
