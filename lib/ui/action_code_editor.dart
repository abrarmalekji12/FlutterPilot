import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';

import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/src/common_modes.dart';
import 'package:resizable_widget/resizable_widget.dart';

import '../common/compiler/code_processor.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import 'build_view/build_view.dart';

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
    Mode(begin: 'r\"\"\"', end: '\"\"\"'),
    Mode(begin: "r'", end: "'", illegal: '\\n'),
    Mode(begin: 'r\"', end: '\"', illegal: '\\n'),
    Mode(begin: "'''", end: "'''", contains: [
      BACKSLASH_ESCAPE,
      Mode(ref: '~contains~0~variants~4~contains~1'),
      Mode(ref: '~contains~0~variants~4~contains~2')
    ]),
    Mode(begin: '\"\"\"', end: '\"\"\"', contains: [
      BACKSLASH_ESCAPE,
      Mode(ref: '~contains~0~variants~4~contains~1'),
      Mode(ref: '~contains~0~variants~4~contains~2')
    ]),
    Mode(begin: "'", end: "'", illegal: '\\n', contains: [
      BACKSLASH_ESCAPE,
      Mode(ref: '~contains~0~variants~4~contains~1'),
      Mode(ref: '~contains~0~variants~4~contains~2')
    ]),
    Mode(begin: '\"', end: '\"', illegal: '\\n', contains: [
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
  final void Function(String) onCodeChange;
  final List<String> prerequisites;

  const ActionCodeEditor(
      {Key? key, required this.code, required this.onCodeChange, required this.prerequisites})
      : super(key: key);

  @override
  State<ActionCodeEditor> createState() => _ActionCodeEditorState();
}

class _ActionCodeEditorState extends State<ActionCodeEditor> {
  late final CodeController _codeController;
  late final CodeProcessor processor;
  final List<ConsoleMessage> consoleMessages = [];
  final ValueNotifier<int> _consoleChangeNotifier = ValueNotifier<int>(0);
  String? code;
  late CacheMemory memory;

  @override
  initState() {
    super.initState();
    processor = CodeProcessor(
      consoleCallback: (message) {
        print('CONSOLE: $message');
      },
      onError: (error, line) {
        consoleMessages.add(
            ConsoleMessage('$error at Line $line', ConsoleMessageType.error));
        _consoleChangeNotifier.value++;
      },
    );
    for(final prerequisite in widget.prerequisites) {
      processor.executeCode(prerequisite, operationType: OperationType.checkOnly,);
    }
    memory=CacheMemory(processor);
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

  void executeAndCheck(String code){
    consoleMessages.clear();
    _consoleChangeNotifier.value = 0;
    final output=processor.executeCode(code, operationType: OperationType.checkOnly,);
    processor.destroyProcess(memory: memory);
    if(output is FVBUndefined){
      consoleMessages.add(ConsoleMessage(output.toString(), ConsoleMessageType.error));
      _consoleChangeNotifier.value++;
    }
    else if(_consoleChangeNotifier.value==0){
      consoleMessages.add(ConsoleMessage('Compiled without errors :)', ConsoleMessageType.success));
      _consoleChangeNotifier.value++;
    }
  }
  @override
  Widget build(BuildContext context) {
    return ResizableWidget(
      isHorizontalSeparator: true,
      percentages: const [
        0.9,0.1
      ],
      separatorColor: Colors.black,separatorSize: 2,
      children: [
        Container(
          child: SingleChildScrollView(
            child: CodeField(
              // expands: true,
              minLines: 50,
              enabled: true,
              wrap: true,
              lineNumberStyle: LineNumberStyle(
                margin: 5,
                textStyle: AppFontStyle.roboto(14, color: Colors.white)
                    .copyWith(height: 1.31),
              ),

              controller: _codeController,
            ),
          ),
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
    );
  }

  Widget printConsoleMessage() {
    final List<TextSpan> list = [];
    for (final consoleMessage in consoleMessages) {
      list.add(TextSpan(
        text: '-> '+consoleMessage.message + '\n',
        style: AppFontStyle.roboto(14,
          color: getColor(consoleMessage.type),
          fontWeight: FontWeight.w800
        ),
      ));
    }
    return RichText(
      text: TextSpan(children: list),
    );
  }
}
Color getColor(ConsoleMessageType type) {
  switch (type) {
    case ConsoleMessageType.error:
      return AppColors.red;
    case ConsoleMessageType.success:
      return AppColors.green;
    case ConsoleMessageType.info:
      return Colors.white;
    default:
      return Colors.white;
  }
}

enum ConsoleMessageType {
  error,
  info,
  success
}

class ConsoleMessage {
  final String message;
  final ConsoleMessageType type;

  ConsoleMessage(this.message, this.type);
}
