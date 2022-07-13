import 'package:code_text_field/code_text_field.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/src/common_modes.dart';
import 'package:resizable_widget/resizable_widget.dart';

import '../bloc/action_code/action_code_bloc.dart';
import '../bloc/key_fire/key_fire_bloc.dart';
import '../bloc/suggestion_code/suggestion_code_bloc.dart';
import '../common/compiler/code_processor.dart';
import '../common/utils/dateformat_utils.dart';
import '../constant/app_colors.dart';
import '../constant/app_dim.dart';
import '../constant/font_style.dart';
import '../models/variable_model.dart';
import 'build_view/build_view.dart';
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
}, keywords: {
  'keyword':
      'abstract as assert async await break case catch class const continue covariant default deferred do dynamic else enum export extends extension external factory false final finally for Function get hide if implements import in inferface is library mixin new null on operator part rethrow return set show static super switch sync this throw true try typedef var void while with yield',
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

class ActionCodeEditor extends StatefulWidget {
  final String code;
  final String scopeName;
  final void Function(String) onCodeChange;
  final List<CodeBase> prerequisites;
  final void Function(bool) onError;
  final Iterable<FVBFunction> functions;
  final Iterable<FVBVariable> Function()? variables;
  final Iterable<FVBClass>? classes;

  const ActionCodeEditor(
      {Key? key,
      required this.code,
      required this.onCodeChange,
      required this.prerequisites,
      required this.variables,
      required this.onError,
      required this.scopeName,
      required this.functions,
      this.classes})
      : super(key: key);

  @override
  State<ActionCodeEditor> createState() => _ActionCodeEditorState();
}

class _ActionCodeEditorState extends State<ActionCodeEditor> {
  late final CodeController _codeController;
  late final CodeProcessor processor;
  final List<ConsoleMessage> consoleMessages = [];
  final SuggestionCodeBloc _suggestionCodeBloc = SuggestionCodeBloc();
  final ValueNotifier<int> _consoleChangeNotifier = ValueNotifier<int>(0);
  String? code;
  final DartFormatter formatter = DartFormatter();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  late double _topBox, _bottomBox;
  OverlayEntry? suggestionOverlayEntry;
  BoxConstraints? _boxConstraints;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    suggestionOverlayEntry?.remove();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_boxConstraints != null) {
        showOverlaidTag(context, _boxConstraints!);
      }
    });
    processor = CodeProcessor(
      consoleCallback: (message, {List? arguments}) {
        return null;
      },
      onError: (error, line) {
        consoleMessages.add(
            ConsoleMessage('$error at Line $line', ConsoleMessageType.error));
        _consoleChangeNotifier.value++;
      },
      scopeName: widget.scopeName,
    );

    processor.functions.addAll(
      widget.functions.toList(growable: false).asMap().map(
            (key, value) => MapEntry(value.name, value),
          ),
    );

    _codeController = CodeController(
        language: fvbDart,
        theme: monokaiSublimeTheme
            .map((key, value) => MapEntry(key, value.copyWith(fontSize: 14))),
        onChange: (value) {
          if (code != value) {
            code = value;
            widget.onCodeChange(value);
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              executeAndCheck(code!);
            });
          }
        });
    code = widget.code;
    _codeController.text = widget.code;
    executeAndCheck(code!);
  }

  void showOverlaidTag(BuildContext context, BoxConstraints constraints) async {
    if (mounted) {
      suggestionOverlayEntry?.remove();
      suggestionOverlayEntry = OverlayEntry(builder: (context) {
        if (!mounted) {
          suggestionOverlayEntry?.remove();
          return const Offstage();
        }
        final TextPainter painter = TextPainter(
          textScaleFactor: 1.15,
          textDirection: TextDirection.ltr,
          text: _codeController.buildTextSpan(context: context),
        );
        painter.layout(maxWidth: constraints.maxWidth - 20);
        final Rect caretPrototype =
            Rect.fromLTWH(0.0, 0.0, 2, painter.preferredLineHeight);
        final offset = painter.getOffsetForCaret(
            TextPosition(
                offset: _codeController.selection.baseOffset -
                    (_suggestionCodeBloc.suggestion?.code.length ?? 0)),
            caretPrototype);
        final top =
            _focusNode.offset.dy + offset.dy + painter.preferredLineHeight;
        if (top > _topBox && top < _bottomBox) {
          return Positioned(
            // Decides where to place the tag on the screen.
            top: top,
            left: _focusNode.offset.dx + offset.dx,
            // Tag code.
            child: SuggestionWidget(
              suggestionCodeBloc: _suggestionCodeBloc,
            ),
          );
        }
        return const Offstage();
      });

      Overlay.of(context)!.insert(suggestionOverlayEntry!);
    }
  }

  void executeAndCheck(String code) {
    consoleMessages.clear();
    _consoleChangeNotifier.value = 0;
    if (widget.variables != null) {
      processor.variables.addAll(widget.variables!
          .call()
          .where((element) => element is VariableModel && element.uiAttached)
          .where((element) => element is VariableModel && element.uiAttached)
          .toList(growable: false)
          .asMap()
          .map((key, value) => MapEntry(value.name, value.clone())));
    }
    final cache = CacheMemory(processor);
    for (final prerequisite in widget.prerequisites) {
      processor.variables.addAll(prerequisite.variables
          .call()
          .where((element) => element is VariableModel && element.uiAttached)
          .toList(growable: false)
          .asMap()
          .map((key, value) => MapEntry(value.name, value.clone())));
      processor.executeCode(
        prerequisite.code(),
        type: OperationType.checkOnly,
      );
    }
    processor.enableSuggestion((suggestions) {
      _suggestionCodeBloc.add(SuggestionUpdatedEvent(suggestions));
      if (suggestions != null && _boxConstraints != null) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          showOverlaidTag(context, _boxConstraints!);
        });
      }
    });
    final output = processor.executeCode(
      code,
      type: OperationType.checkOnly,
    );
    processor.destroyProcess(cacheMemory: cache, deep: true);
    processor.disableSuggestion();
    if (output is FVBUndefined) {
      consoleMessages
          .add(ConsoleMessage(output.toString(), ConsoleMessageType.error));
      _consoleChangeNotifier.value++;
    } else if (_consoleChangeNotifier.value == 0) {
      consoleMessages.add(
          ConsoleMessage('Compiled. No Errors.', ConsoleMessageType.success));
      context
          .read<ActionCodeBloc>()
          .add(ActionCodeUpdatedEvent(widget.scopeName));

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
      if (suggestionOverlayEntry == null) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          showOverlaidTag(context, constraints);
        });
      }
      return BlocListener<KeyFireBloc, KeyFireState>(
        listener: (context, state) {
          if (state is DownKeyEventFired) {
            if (_suggestionCodeBloc.suggestion != null) {
              if ((state.key == 'RETURN' || state.key == 'ENTER')) {
                _handleEnter();
              } else if (state.key == 'UP') {
                final offset = _codeController.selection.baseOffset;
                _suggestionCodeBloc.add(SuggestionSelectionChangeEvent(-1));
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  _codeController.selection =
                      TextSelection.collapsed(offset: offset);
                });
              } else if (state.key == 'DOWN') {
                final offset = _codeController.selection.baseOffset;
                _suggestionCodeBloc.add(SuggestionSelectionChangeEvent(1));
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  _codeController.selection =
                      TextSelection.collapsed(offset: offset);
                });
              }
            }
          }
        },
        child: ResizableWidget(
          separatorSize: Dimen.separator,
          separatorColor: AppColors.separator,
          isHorizontalSeparator: true,
          percentages: const [0.9, 0.1],
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: CodeField(
                    minLines: 50,
                    enabled: true,
                    focusNode: _focusNode,
                    key: _textFieldKey,
                    wrap: true,
                    controller: _codeController,
                  ),
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
                                final code =
                                    formatter.format(_codeController.text);
                                final cursor =
                                    _codeController.selection.extentOffset;
                                _codeController.value = TextEditingValue(
                                    text: code,
                                    selection: TextSelection.collapsed(
                                        offset: cursor));
                                widget.onCodeChange(code);
                              } on FormatterException {
                                return;
                              }
                            },
                            color: Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: const Color(0xff494949),
              padding: const EdgeInsets.all(8),
              alignment: Alignment.topLeft,
              child: ValueListenableBuilder(
                  valueListenable: _consoleChangeNotifier,
                  builder: (context, value, child) {
                    return printConsoleMessage();
                  }),
            )
          ],
        ),
      );
    });
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
    _suggestionCodeBloc.suggestion = null;
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
}

class CodeBase {
  final String Function() code;
  final Iterable<FVBVariable> Function() variables;
  final String scopeName;

  CodeBase(this.code, this.variables, this.scopeName);
}
