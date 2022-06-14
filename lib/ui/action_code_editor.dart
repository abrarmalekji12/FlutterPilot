import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';

import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/src/common_modes.dart';

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
  'Comparable DateTime Duration Function Iterable Iterator List Map Match Null Object Pattern RegExp Set Stopwatch String StringBuffer StringSink Symbol Type Uri bool double dynamic int num print Element ElementList document querySelector querySelectorAll window'
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
