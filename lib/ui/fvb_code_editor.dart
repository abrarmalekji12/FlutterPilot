import 'dart:convert';
import 'dart:math';

import 'package:code_text_field/code_text_field.dart';
import 'package:dart_style/dart_style.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_highlight/themes/default.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_highlight/themes/idea.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/monokai.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/constants/processor_constant.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/src/common_modes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/action_code/action_code_bloc.dart';
import '../bloc/suggestion_code/suggestion_code_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../code_operations.dart';
import '../code_snippets/common_snippets.dart';
import '../common/app_button.dart';
import '../common/code_box/custom_code_controller_updated.dart';
import '../common/code_box/custom_code_field_updated.dart';
import '../common/common_methods.dart';
import '../common/custom_extension_tile.dart';
import '../common/extension_util.dart';
import '../common/package/custom_textfield_searchable.dart';
import '../common/responsive/responsive_widget.dart';
import '../common/text_painter.dart';
import '../common/utils/dateformat_utils.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../injector.dart';
import '../models/actions/code_snippets.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/variable_model.dart';
import '../user_session.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/overlay/overlay_manager.dart';
import '../widgets/textfield/appt_search_field.dart';
import 'ide/suggestion.dart';
import 'navigation/animated_dialog.dart';
import 'navigation/animated_slider.dart';
import 'variable_ui.dart';

/// TODO: DECIDE BEST THEME TO MAKE IT DEFAULT
const defaultThemeKey = 'Idea';
const Map<String, Map<String, TextStyle>?> editorThemes = {
  'Default': defaultTheme,
  'Dracula': draculaTheme,
  'Monokai': monokaiTheme,
  'Monokai Sublime': monokaiSublimeTheme,
  'Idea': ideaTheme,
  'VS': vsTheme,
};
final fvbDart = Mode(
    refs: {
      '~contains~0~variants~4~contains~2': Mode(
          className: 'subst',
          variants: [Mode(begin: '\\\${', end: closeInt)],
          keywords: 'true false null this is new super',
          contains: [C_NUMBER_MODE, Mode(ref: '~contains~0')]),
      '~contains~0~variants~4~contains~1': Mode(
          className: 'subst', variants: [Mode(begin: '\\\$[A-Za-z0-9_]+')]),
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
    },
    contains: [
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

class VariableHandler {
  final List<VariableModel> Function() variables;
  final void Function(VariableModel) onVariableAdded;
  final void Function(VariableModel) onDelete;
  final FVBVariable Function(List<VariableModel>)? wrapper;

  VariableHandler(
      {required this.variables,
      this.wrapper,
      required this.onVariableAdded,
      required this.onDelete});
}

class FVBEditorConfig {
  final String? upCode, downCode;
  final List<FVBVariable> Function()? variables;
  final String Function()? onReset;
  final bool string;
  final bool parentProcessorGiven;
  final bool smallBottomBar;
  final bool multiline;
  final DataType? returnType;
  final EdgeInsets? padding;
  final Type? outputType;
  final bool shrink;
  final VariableHandler? variableHandler;
  final bool isJson;
  final bool unmodifiable;

  FVBEditorConfig(
      {this.upCode,
      this.isJson = false,
      this.unmodifiable = false,
      this.shrink = false,
      this.downCode,
      this.onReset,
      this.returnType,
      this.variableHandler,
      this.variables,
      this.outputType,
      this.multiline = true,
      this.smallBottomBar = false,
      this.string = false,
      this.padding,
      this.parentProcessorGiven = false});
}

class FVBCodeEditor extends StatefulWidget {
  final String code;
  final void Function(String, bool) onCodeChange;
  final void Function(String?, bool) onErrorUpdate;
  final FVBEditorConfig config;
  final Processor processor;
  final TextEditingController? controller;
  final String? scopeName;
  final Widget? header;
  final Widget? headerEnd;
  final int? selection;

  const FVBCodeEditor(
      {Key? key,
      this.header,
      this.selection,
      this.headerEnd,
      required this.code,
      required this.onCodeChange,
      required this.onErrorUpdate,
      required this.config,
      required this.processor,
      this.controller,
      this.scopeName})
      : super(key: key);

  @override
  State<FVBCodeEditor> createState() => _FVBCodeEditorState();
}

class _FVBCodeEditorState extends State<FVBCodeEditor> with OverlayManager {
  late final CustomCodeController _codeController;
  late final CodeController _upCodeController;
  late final CodeController _downCodeController;
  late final Processor processor;
  final AnimatedSlider _animatedSlider = AnimatedSlider();
  final _debouncer = Debouncer(
    milliseconds: 100,
  );
  final ValueNotifier<ConsoleMessage?> consoleMessage = ValueNotifier(null);
  final SuggestionCodeBloc _suggestionBloc = SuggestionCodeBloc();
  String? code, oldCode;
  final DartFormatter _formatter = DartFormatter();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  int selectionIndex = 0;
  BoxConstraints? _boxConstraints;
  final ScrollController _scrollController = ScrollController();
  ConsoleMessage? lastMessage;
  final _prefs = sl<SharedPreferences>();
  late Color background;
  late Map<String, TextStyle> codeTheme;

  double get fontSize => widget.config.multiline ? 14 : 13;

  @override
  void dispose() {
    destroyOverlays();
    _animatedSlider.hide();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_boxConstraints != null) {
        rebuild('suggestion');
      }
    });

    final offset = _prefs.getDouble(widget.processor.scopeName);
    if (offset != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (_scrollController.positions.isNotEmpty)
          _scrollController.jumpTo(offset);
      });
    }
    void onError(String error, (int, int)? line) {
      if (error != consoleMessage.value?.message ||
          line != consoleMessage.value?.position)
        consoleMessage.value =
            ConsoleMessage(error, ConsoleMessageType.error, line);
    }

    processor = Processor(
      consoleCallback: Processor.testConsoleCallback,
      onError: onError,
      parentProcessor: widget.processor.parentProcessor
          ?.clone(Processor.testConsoleCallback, onError, false),
      scopeName: widget.scopeName ?? widget.processor.scopeName,
    );
    codeTheme = editorThemes[sl<UserSession>().settingModel!.iDETheme]!.map(
      (key, value) => MapEntry(
        key,
        value.copyWith(fontSize: fontSize),
      ),
    );

    background = codeTheme['root']!.backgroundColor!;
    code = widget.config.string ? '"${widget.code}"' : widget.code;
    if (!widget.config.string && widget.config.multiline) {
      try {
        code = _formatter.format(code!);
        widget.onCodeChange.call(code!, false);
      } on Exception {}
    }
    _codeController = CustomCodeController(
        language: fvbDart,
        text: code ?? '',
        onFormat: widget.config.multiline
            ? () {
                _formatCode();
              }
            : null,
        onKeyHandle: (event) {
          if (_suggestionBloc.suggestion?.suggestions.isNotEmpty ?? false) {
            if (event is KeyDownEvent) {
              if ((event.logicalKey == LogicalKeyboardKey.enter) &&
                  event is! KeyRepeatEvent) {
                _handleEnter();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _suggestionBloc.add(SuggestionSelectionUpdateEvent(-1));
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _suggestionBloc.add(SuggestionSelectionUpdateEvent(1));
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
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
        onChange: (value) {
          if (code != value) {
            final oldCode = code;
            code = value;
            _debouncer.run(() {
              if (widget.config.string) {
                code = CodeOperations.trim(code);
                if (code!.isNotEmpty &&
                    (!code!.startsWith('"') || !code!.endsWith('"'))) {
                  if (code![code!.length - 1] != '"') {
                    code = code! + '"';
                  }
                  if (code![0] != '"') {
                    code = '"' + code!;
                  }
                  _codeController.value = TextEditingValue(
                      text: code!, selection: _codeController.value.selection);
                  return;
                }
              }
              executeAndCheck(code!,
                  suggestion: _focusNode.hasFocus &&
                      (code!.length - (oldCode?.length ?? 0)).abs() == 1);
            });
          } else {
            if (_codeController.selection.baseOffset != selectionIndex) {
              selectionIndex = _codeController.selection.baseOffset;
            }
            _suggestionBloc.clear();
            removeOverlay('suggestion');
          }
        });
    _upCodeController = CodeController(
      language: fvbDart,
    );
    _downCodeController = CodeController(
      language: fvbDart,
    );
    widget.controller?.addListener(() {
      if (widget.controller?.text != null) {
        _codeController.text = widget.controller!.text;
      }
    });
    Processor.operationType = OperationType.checkOnly;
    executeAndCheck(code!, suggestion: false, callOnChange: false);
  }

  List<Rect> getTextPosition(List<int> positions) {
    final AppTextPainter painter = AppTextPainter(
      textDirection: TextDirection.ltr,
      text: _codeController.buildTextSpan(
          context: context, style: TextStyle(fontSize: fontSize)),
    );
    painter.layout(
        maxWidth:
            _boxConstraints!.maxWidth - (widget.config.multiline ? 40 : 32));
    final Rect caretPrototype =
        Rect.fromLTWH(0.0, 0.0, 2, painter.preferredLineHeight);

    /// This will calculate character offset where suggestion needs to be shown.
    return positions.map((position) {
      final rect = painter.getRectForCaret(
          TextPosition(offset: position), caretPrototype);
      return rect;
    }).toList();
  }

  void showSuggestionBox(
      BuildContext context, BoxConstraints constraints) async {
    if (context.mounted)
      showOverlay(context, 'suggestion', (p0, p1) {
        if (!context.mounted) {
          return const Offstage();
        }
        if (_suggestionBloc.suggestion?.suggestions.isEmpty ?? true) {
          return const IgnorePointer();
        }
        if (!isDesktop) {
          return Stack(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    removeOverlay('suggestion');
                    _suggestionBloc.clear();
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    height: double.infinity,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height -
                    _focusNode.size.width -
                    (100),
                child: SuggestionWidget(
                  suggestionCodeBloc: _suggestionBloc,
                ),
              ),
            ],
          );
        }
        final offset = getTextPosition([
          _codeController.selection.baseOffset -
              (_suggestionBloc.suggestion?.code.length ?? 0)
        ])[0];
        final y = _focusNode.offset.dy;
        final top = y + offset.top + (offset.height) + 10;
        final height =
            min(MediaQuery.of(context).size.height - top, kSuggestionBoxHeight);
        final double width = max(_focusNode.size.width, 200);
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _suggestionBloc.clear();
                removeOverlay('suggestion');
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            top: top,
            left: min(
                _focusNode.offset.dx + offset.left - kSuggestionBoxPadding,
                MediaQuery.of(context).size.width -
                    width -
                    kSuggestionBoxPadding),
            width: width,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height),
              child: SuggestionWidget(
                suggestionCodeBloc: _suggestionBloc,
              ),
            ),
          )
        ]);
      });
  }

  void resetProcessor() {
    processor.variables.clear();
    processor.functions.clear();
    processor.localVariables.clear();
    if (!widget.config.parentProcessorGiven) {
      processor.variables.addAll(widget.processor.variables.values
          .where((element) => (element is VariableModel && element.uiAttached))
          .toList(growable: false)
          .asMap()
          .map((key, value) => MapEntry(value.name, value.clone())));
    } else {
      processor.variables.addAll(widget.processor.variables.values
          .toList(growable: false)
          .asMap()
          .map((key, value) => MapEntry(value.name, value.clone())));
    }
    if (widget.config.variableHandler != null) {
      if (widget.config.variableHandler!.wrapper == null) {
        processor.variables.addAll(widget.config.variableHandler!
            .variables()
            .toList(growable: false)
            .asMap()
            .map((key, value) => MapEntry(value.name, value)));
      } else {
        final variable = widget.config.variableHandler!.wrapper!.call(widget
            .config.variableHandler!
            .variables()
            .map((e) => e.clone())
            .toList(growable: false));
        processor.variables[variable.name] = variable;
      }
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
            .map((key, value) => MapEntry(
                value.name, FVBCacheValue(value.value, value.dataType))));
      }
    }
    processor.functions.addAll(
        widget.processor.functions.map((key, value) => MapEntry(key, value)));

    Processor? parent = processor.parentProcessor;
    Processor? originalParent = widget.processor.parentProcessor;
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
  }

  void executeAndCheck(String code,
      {bool suggestion = true,
      bool forceUpdate = false,
      bool callOnChange = true}) {
    if (suggestion) {
      processor.enableSuggestion((suggestions) {
        _suggestionBloc.add(SuggestionUpdatedEvent(suggestions));
      });
    }
    bool isSameCode = true;
    oldCode = processor.executeCode(code,
        type: OperationType.checkOnly,
        oldCode: forceUpdate ? null : oldCode, onExecutionStart: () {
      resetProcessor();
      consoleMessage.value = null;
      isSameCode = false;
      _suggestionBloc.clear();
      rebuild('suggestion');
    },
        declarativeOnly:
            widget.config.upCode == null && widget.config.multiline,
        config: ProcessorConfig(
          unmodifiable: true,
          singleLineProcess: !widget.config.multiline,
        ));
    final hasNotError = consoleMessage.value?.type != ConsoleMessageType.error;
    if (callOnChange) {
      widget.onCodeChange(
          widget.config.string
              ? (code.length > 2 ? code.substring(1, code.length - 1) : '')
              : code,
          !isSameCode && hasNotError);
    }
    processor.destroyProcess(deep: false);

    if (suggestion) {
      processor.disableSuggestion();
    }
    if (!isSameCode && consoleMessage.value == null && context.mounted) {
      consoleMessage.value = null;
      context
          .read<ActionCodeBloc>()
          .add(ActionCodeUpdatedEvent(widget.processor.scopeName));
    }

    widget.onErrorUpdate(
        !hasNotError ? consoleMessage.value?.message : null, !hasNotError);
  }

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: codeTheme),
      child: BlocListener<SuggestionCodeBloc, SuggestionCodeState>(
        bloc: _suggestionBloc,
        listener: (context, state) {
          if (state is SuggestionSelectedState) {
            _handleEnter();
          } else if (state is SuggestionCodeUpdated) {
            final relevantSuggestions = state.suggestions?.suggestions
                .where((element) => element.result != state.suggestions!.code);
            if (relevantSuggestions?.isNotEmpty ?? false) {
              _suggestionBloc.selectionIndex = 0;
              _codeController.enableSuggestion();
              if (_boxConstraints != null) {
                _suggestionBloc.selectionIndex = 0;
                showSuggestionBox(context, _boxConstraints!);
              }
            } else {
              removeOverlay('suggestion');
              _codeController.disableSuggestion();
            }
          }
        },
        child: Builder(builder: (context) {
          if (widget.config.smallBottomBar) {
            return SizedBox(
              height: widget.config.multiline ? null : 40,
              child: Stack(
                children: [
                  _buildEditor(),
                  Positioned(
                    left: 9,
                    top: 4,
                    width: 6.w,
                    height: 6.w,
                    child: ValueListenableBuilder(
                      valueListenable: consoleMessage,
                      builder: (BuildContext context, ConsoleMessage? value,
                          Widget? child) {
                        return TooltipVisibility(
                          visible: value?.message != null,
                          child: Tooltip(
                            message: value?.message ?? '',
                            child: AnimatedContainer(
                              curve: Curves.easeInOutSine,
                              duration: const Duration(milliseconds: 700),
                              width: 6.w,
                              height: 6.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: value?.type == ConsoleMessageType.error
                                    ? ColorAssets.red
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          }
          return Responsive(
            mobile: Column(
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
            desktop: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      if (widget.config.variableHandler != null) ...[
                        _buildHeader(),
                        Builder(builder: (context) {
                          final variables =
                              widget.config.variableHandler!.variables();
                          return CustomExpansionTile(
                            collapsedBackgroundColor: ColorAssets.shimmerColor,
                            backgroundColor: ColorAssets.shimmerColor,
                            tilePadding: const EdgeInsets.only(right: 8),
                            title: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Badge(
                                    label: Text(
                                      '${variables.length}',
                                    ),
                                    backgroundColor: Colors.blueAccent,
                                    isLabelVisible: variables.isNotEmpty,
                                    child: SizedBox(
                                      width: 90,
                                      child: Text(
                                        'Variables',
                                        style: AppFontStyle.titleStyle(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            children: [
                              ColoredBox(
                                color: theme.background1,
                                child: Column(
                                  children: [
                                    8.hBox,
                                    AddVariableWidget(
                                      onAdded: (value) {
                                        widget.config.variableHandler!
                                            .onVariableAdded
                                            .call(value);
                                        setState(() {});
                                        executeAndCheck(_codeController.text,
                                            forceUpdate: true,
                                            suggestion: false);
                                        context
                                            .read<OperationCubit>()
                                            .customComponentVariableUpdated();
                                      },
                                      processor: processor,
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 100,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 15,
                                          children: [
                                            for (final variable in variables)
                                              SizedBox(
                                                width: 200,
                                                child: EditVariable(
                                                  variable,
                                                  onDelete: (value) {
                                                    widget
                                                        .config
                                                        .variableHandler!
                                                        .onDelete
                                                        .call(variable);
                                                    setState(() {});

                                                    executeAndCheck(
                                                        _codeController.text,
                                                        forceUpdate: true,
                                                        suggestion: false);

                                                    context
                                                        .read<OperationCubit>()
                                                        .customComponentVariableUpdated();
                                                  },
                                                  onChanged:
                                                      (FVBVariable model) {
                                                    setState(() {});

                                                    executeAndCheck(
                                                        _codeController.text,
                                                        forceUpdate: true,
                                                        suggestion: false);

                                                    context
                                                        .read<OperationCubit>()
                                                        .customComponentVariableUpdated();
                                                  },
                                                  setState2: setState,
                                                  options: [],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(
                          height: 8,
                        ),
                      ],
                      Expanded(
                        child: _buildEditor(),
                      ),
                    ],
                  ),
                ),
                _buildConsole(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConsole() {
    return ValueListenableBuilder(
        valueListenable: consoleMessage,
        builder: (context, ConsoleMessage? value, child) {
          if (value == null) {
            return const Offstage();
          }
          return Container(
            color: theme.background1,
            padding: const EdgeInsets.all(8),
            alignment: Alignment.topLeft,
            child: Text(
              value.message,
              style: AppFontStyle.lato(14,
                  color: getConsoleMessageColor(value.type),
                  fontWeight: FontWeight.w500),
            ),
          );
        });
  }

  Widget _buildEditor() {
    return Container(
      height: !widget.config.multiline ? 35 : null,
      decoration: widget.config.multiline
          ? BoxDecoration(
              color: background,
              border: Border.all(
                color: ColorAssets.colorD0D5EF,
              ),
              borderRadius: BorderRadius.circular(6),
            )
          : BoxDecoration(
              color: background,
            ),
      child: Stack(
        alignment:
            widget.config.multiline ? Alignment.centerLeft : Alignment.topRight,
        children: [
          Column(
            children: [
              if (widget.config.multiline &&
                  !widget.config.string &&
                  widget.config.variableHandler == null) ...[
                _buildHeader(),
              ],
              if (widget.config.upCode != null)
                Tooltip(
                  message: 'unmodifiable code',
                  child: CodeField(
                    lineNumberBuilder: (context, lineNumber) =>
                        const TextSpan(text: ''),
                    controller: _upCodeController..text = widget.config.upCode!,
                    enabled: false,
                  ),
                ),
              Expanded(
                child: widget.config.multiline
                    ? ColoredBox(
                        color: background,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LayoutBuilder(builder: (context, constraints) {
                            _boxConstraints = constraints;
                            return SingleChildScrollView(
                              padding: EdgeInsets.zero,
                              controller: _scrollController,
                              child: Stack(
                                children: [
                                  CustomCodeField(
                                    lineNumbers: true,
                                    fontSize: fontSize,
                                    enabled: true,
                                    wrap: true,
                                    minLines: widget.config.shrink ? null : 50,
                                    focusNode: _focusNode,
                                    key: _textFieldKey,
                                    padding: EdgeInsets.zero,
                                    lineNumberStyle: const LineNumberStyle(
                                      width: 40,
                                      margin: 4,
                                    ),
                                    outerPadding: widget.config.shrink
                                        ? EdgeInsets.zero
                                        : const EdgeInsets.all(8),
                                    controller: _codeController,
                                  ),
                                  _buildRedUnderlineDrawer()
                                ],
                              ),
                            );
                          }),
                        ),
                      )
                    : LayoutBuilder(builder: (context, constraints) {
                        _boxConstraints = constraints;
                        return Stack(
                          children: [
                            CustomCodeField(
                              fontSize: fontSize,
                              lineNumbers: false,
                              enabled: true,
                              expands: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                      color: ColorAssets.colorD0D5EF)),
                              shrink: widget.config.shrink,
                              focusNode: _focusNode,
                              background: background,
                              key: _textFieldKey,
                              radius: 4,
                              outerPadding: EdgeInsets.zero,
                              controller: _codeController,
                              contextMenuBuilder: (context, state) {
                                final selection =
                                    state.currentTextEditingValue.selection;
                                final string =
                                    state.currentTextEditingValue.text;
                                return AdaptiveTextSelectionToolbar.buttonItems(
                                  anchors: state.contextMenuAnchors,
                                  buttonItems: [
                                    ...state.contextMenuButtonItems,
                                    if (string.isNotEmpty)
                                      ContextMenuButtonItem(
                                        onPressed: () {
                                          if (selection.isValid) {
                                            disableError = true;
                                            final valueCache =
                                                processor.process(
                                              CodeOperations.trim(
                                                  string.substring(
                                                      selection.start,
                                                      selection.end))!,
                                              config: const ProcessorConfig(
                                                unmodifiable: true,
                                              ),
                                            );
                                            final value = valueCache.value;
                                            disableError = false;
                                            if (value != null) {
                                              _addVariableDialog(value);
                                            }
                                          }
                                        },
                                        label: 'Create variable',
                                        type: ContextMenuButtonType.custom,
                                      )
                                  ],
                                );
                              },
                            ),
                            _buildRedUnderlineDrawer()
                          ],
                        );
                      }),
              ),
              if (widget.config.downCode != null)
                Tooltip(
                  message: 'unmodifiable code',
                  child: CodeField(
                    lineNumberBuilder: (context, lineNumber) =>
                        const TextSpan(text: ''),
                    controller: _downCodeController
                      ..text = widget.config.downCode!,
                    enabled: false,
                  ),
                ),
            ],
          ),
          // if (widget.config.multiline && !widget.config.string)
          //   Positioned.fill(
          //       child: CustomDragTarget<FVBCodeSnippet>(
          //     onWillAccept: (obj, _) {
          //       return obj is FVBCodeSnippet;
          //     },
          //     onAccept: (data, _) {
          //      sdf
          //     },
          //     builder:
          //         (BuildContext context, List<Object?> candidateData, List<dynamic> rejectedData, Offset? position) {
          //       if (candidateData.isNotEmpty && candidateData.first is FVBCodeSnippet) {
          //         final snippet = (candidateData.first) as FVBCodeSnippet;
          //         return DottedBorder(
          //           color: ColorAssets.theme,
          //           strokeWidth: 1.2,
          //           dashPattern: [4, 4],
          //           child: Container(
          //             decoration: BoxDecoration(
          //               color: ColorAssets.grey.withOpacity(0.3),
          //             ),
          //             alignment: Alignment.center,
          //             child: Container(
          //               decoration: BoxDecoration(
          //                 color: ColorAssets.theme,
          //                 borderRadius: BorderRadius.circular(6),
          //               ),
          //               padding: const EdgeInsets.all(10),
          //               child: Row(
          //                 mainAxisSize: MainAxisSize.min,
          //                 children: [
          //                   const Icon(
          //                     Icons.add,
          //                     color: ColorAssets.white,
          //                   ),
          //                   const SizedBox(
          //                     width: 10,
          //                   ),
          //                   Flexible(
          //                     child: Text(
          //                       snippet.name,
          //                       style: AppFontStyle.lato(14, color: ColorAssets.white),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ),
          //         );
          //       }
          //       return const Offstage();
          //     },
          //   )),
        ],
      ),
    );
  }

  void _onSelect(FVBCodeSnippet data) {
    final i = _codeController.selection.start;
    if (i >= 0) {
      final code = data.code.call(data.defaultValues);
      final newCode = _codeController.text.substring(0, i) +
          code +
          _codeController.text.substring(i);
      try {
        _codeController.text = _formatter.format(newCode);
      } catch (e) {
        _codeController.text = newCode;
      }
    }
  }

  void _formatCode() {
    try {
      if (widget.config.isJson) {
        _codeController.text = formatJson(_codeController.text);
        return;
      }
      final formatCode = _codeController.text;
      final code1 = (widget.config.downCode != null
          ? _formatter
              .format('temp() {' + formatCode + '}')
              .replaceFirst('temp() {', '')
          : _formatter.format(formatCode));
      final code = widget.config.downCode != null
          ? code1.substring(0, code1.lastIndexOf('}'))
          : code1;
      _codeController.text = code;
      widget.onCodeChange(code, false);
    } on FormatterException catch (error) {
      consoleMessage.value = (ConsoleMessage(
          error.errors.map((e) => e.message).join('\n'),
          ConsoleMessageType.error,
          null));

      return;
    }
  }

  String formatJson(String code) {
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(jsonDecode(code));
  }

  void _handleEnter() {
    if (_suggestionBloc.suggestion == null ||
        _suggestionBloc.suggestion!.suggestions.length <=
            _suggestionBloc.selectionIndex) {
      return;
    }
    final text = _codeController.text;
    final index = _codeController.selection.baseOffset;
    final suggestion =
        _suggestionBloc.suggestion!.suggestions[_suggestionBloc.selectionIndex];
    final offset = index +
        (-_suggestionBloc.suggestion!.code.length + suggestion.result.length);
    if (text.length < index - _suggestionBloc.suggestion!.code.length) {
      return;
    }
    final newText =
        text.substring(0, index - _suggestionBloc.suggestion!.code.length) +
            suggestion.result +
            text.substring(index);
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

    _suggestionBloc.add(SuggestionUpdatedEvent(null));
  }

  _buildHeader() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (widget.header != null) ...[
              widget.header!,
              const SizedBox(
                width: 10,
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppIconButton(
                  size: 16,
                  icon: Icons.explore,
                  onPressed: () {
                    if (_animatedSlider.visible) {
                      _animatedSlider.hide();
                    } else {
                      _animatedSlider.show(
                          context,
                          this,
                          CodeSnippetListingWidget(
                            slider: _animatedSlider,
                            onSelect: (snippet) {
                              if (_codeController.selection.start < 0) {
                                showPopupText(context,
                                    'Please put cursor on the place where you want to insert the snippet');
                                return;
                              }

                              _onSelect(snippet);
                            },
                          ),
                          _textFieldKey,
                          width: 250);
                    }
                  },
                  iconColor: Colors.purpleAccent,
                ),
                const SizedBox(
                  width: 5,
                ),
                if (widget.config.onReset != null) ...[
                  AppIconButton(
                    size: 16,
                    icon: Icons.restart_alt_rounded,
                    onPressed: () {
                      showConfirmDialog(
                          title: 'Alert!',
                          subtitle: 'Are you sure you want to reset code?',
                          context: context,
                          positive: 'Yes',
                          negative: 'No',
                          onPositiveTap: () {
                            _codeController.text = widget.config.onReset!();
                            _formatCode();
                          });
                    },
                    iconColor: ColorAssets.red,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                ],
                AppIconButton(
                    size: 16,
                    icon: Icons.format_align_center,
                    onPressed: () {
                      _formatCode();
                    },
                    iconColor: Colors.blueAccent),
                const SizedBox(
                  width: 5,
                ),
              ],
            ),
            const Spacer(),
            if (widget.headerEnd != null) widget.headerEnd!
          ],
        ),
      );

  Widget _buildRedUnderlineDrawer() {
    return ValueListenableBuilder(
        valueListenable: consoleMessage,
        builder: (context, value, _) {
          if (value != null) {
            if (value.position != null) {
              // print('DETECTED :: "${oldCode?.substring(value.position!.$1, value.position!.$2)}"');
              int start = 0;
              int startTrimmed = value.position!.$1;
              int endTrimmed = value.position!.$2;
              int startIndex = 0, endIndex = -1;
              if (oldCode != null) {
                for (int i = 0; i < value.position!.$2; i++) {
                  if (oldCode![i].codeUnits.first == spaceReplacementCodeUnit) {
                    // print('GOT @ $i ${i <= value.position!.$1}');
                    if (i <= value.position!.$1) {
                      startTrimmed--;
                    }
                    endTrimmed--;
                  } else if (oldCode![i].codeUnits.first == realSpaceCodeUnit) {
                    // print('GOT " " $i ${i <= value.position!.$1}');
                    if (i <= value.position!.$1) {
                      startTrimmed--;
                    }
                    endTrimmed--;
                  }
                }
                final code = _codeController.text;
                // print('SEE TRIM INDEX ${startTrimmed} ${endTrimmed}');

                for (int i = 0; i < code.length; i++) {
                  if (code[i].codeUnits[0] != realSpaceCodeUnit &&
                      code[i].codeUnits[0] != backslashNCodeUnit) {
                    if (start == startTrimmed) {
                      startIndex = i;
                    } else if (start == endTrimmed) {
                      endIndex = i;
                      break;
                    }
                    start++;
                  }
                }
                if (endIndex == -1) {
                  endIndex = code.length;
                }

                // print('CALCULATED :: "${code.substring(startIndex, endIndex)}"');
                final positions = getTextPosition([startIndex, endIndex - 1]);
                final top = positions[0].bottom +
                    (widget.config.multiline
                        ? (widget.config.shrink ? 12 : 20)
                        : 8);
                final left = (widget.config.multiline
                        ? (widget.config.shrink ? 40 : 50)
                        : 15) +
                    positions[0].left;
                return Positioned(
                    left: left,
                    top: top,
                    child: Tooltip(
                      message: value.message,
                      showDuration: const Duration(seconds: 1),
                      child: Container(
                        height: 2,
                        width: max(0, positions[1].right - positions[0].left),
                        decoration: const BoxDecoration(
                          color: ColorAssets.red,
                        ),
                      ),
                    ));
              }
            }
          }
          return const Offstage();
        });
  }

  void _addVariableDialog(dynamic value) {
    final operationCubit = context.read<OperationCubit>();
    final creationCubit = context.read<CreationCubit>();
    AnimatedDialog.show(
        context,
        SizedBox(
          width: 600,
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add variable',
                    style: AppFontStyle.titleStyle(),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  AddVariableWidget(
                    value: value,
                    onAdded: (value) {
                      operationCubit.addVariable(value);
                      creationCubit.changedComponent();
                      AnimatedDialog.hide(context);
                    },
                    processor: collection.project!.processor,
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: true);
  }
}

Color getConsoleMessageColor(ConsoleMessageType type) {
  final dark = (theme.themeType == ThemeType.dark);
  switch (type) {
    case ConsoleMessageType.error:
      return ColorAssets.red;
    case ConsoleMessageType.success:
      return ColorAssets.green;
    case ConsoleMessageType.event:
      return dark ? ColorAssets.lightGrey : ColorAssets.darkGrey;
    default:
      return dark ? Colors.white : Colors.black;
  }
}

enum ConsoleMessageType { validationError, error, info, success, event }

class ConsoleMessage extends Equatable {
  late final String time;
  final String message;
  final (int, int)? position;
  final ConsoleMessageType type;
  final Component? component;

  ConsoleMessage(this.message, this.type, [this.position, this.component]) {
    time = DateFormatUtils.getCurrentTimeForConsole();
  }

  @override
  String toString() {
    return 'ConsoleMessage{time: $time, message: $message, type: $type}';
  }

  @override
  List<Object?> get props => [message, position, type];
}

class CodeBase {
  final String Function() code;
  final Iterable<FVBVariable> Function() variables;
  final String scopeName;

  CodeBase(this.code, this.variables, this.scopeName);
}

class CodeSnippetListingWidget extends StatefulWidget {
  final AnimatedSlider slider;
  final ValueChanged<FVBCodeSnippet> onSelect;

  const CodeSnippetListingWidget({
    super.key,
    required this.slider,
    required this.onSelect,
  });

  @override
  State<CodeSnippetListingWidget> createState() =>
      _CodeSnippetListingWidgetState();
}

class _CodeSnippetListingWidgetState extends State<CodeSnippetListingWidget> {
  final FocusNode _focusNode = FocusNode();
  final CommonSnippets _commonSnippets = sl();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final List<FVBCodeSnippet> list = [
      ...codeSnippets,
      if (collection.project != null)
        ..._commonSnippets.generate(collection.project!)
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: 10.borderRadius,
        boxShadow: kElevationToShadow[4],
      ),
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Snippets',
                style: AppFontStyle.titleStyle(),
              ),
              const Spacer(),
              AppCloseButton(
                onTap: () {
                  widget.slider.hide();
                },
              ),
            ],
          ),
          10.hBox,
          SizedBox(
            height: 35,
            child: AppSearchField(
              onChanged: (value) {},
              focusNode: _focusNode..requestFocus(),
              hint: 'Search..',
              controller: _controller,
            ),
          ),
          10.hBox,
          Container(
            constraints: const BoxConstraints(
              maxHeight: 400,
            ),
            child: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, _, __) {
                  final search = _controller.text.toLowerCase();
                  final codeSnippets = list
                      .where((element) =>
                          element.name.toLowerCase().contains(search))
                      .toList(growable: false);
                  if (codeSnippets.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('No items'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 5),
                    separatorBuilder: (_, __) => const SizedBox(
                      height: 6,
                    ),
                    itemCount: codeSnippets.length,
                    itemBuilder: (context, i) {
                      return _buildTile(codeSnippets[i]);
                    },
                    shrinkWrap: true,
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(FVBCodeSnippet snippet) => TextButton(
        onPressed: () {
          widget.onSelect.call(snippet);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(5),
          backgroundColor: theme.background1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(
              color: ColorAssets.colorD0D5EF,
            ),
          ),
        ),
        child: Text(
          snippet.name,
          style: AppFontStyle.lato(
            13,
            fontWeight: FontWeight.normal,
          ),
        ),
      );
}
