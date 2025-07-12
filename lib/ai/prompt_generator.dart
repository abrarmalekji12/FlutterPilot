import 'dart:convert';

import 'package:collection/collection.dart';

import '../components/component_impl.dart';
import '../components/component_list.dart';
import '../components/holder_impl.dart';
import '../components/scrollable_impl.dart';
import '../cubit/screen_config/screen_config_cubit.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/parameter_model.dart';
import '../parameter/parameters_list.dart';
import 'llm_integration/output_schema.dart';

class PromptGenerator {
  final maxPromptComponents = [
    CScaffold(),
    CContainer(),
    CStack(),
    CColumn(),
    CRow(),
    CAlign(),
    CCenter(),
    CPositioned(),
    CAppBar(),
    CText(),
    CImageNetwork(),
    CExpanded(),
    CFlexible(),
    CIcon(),
    CCard(),
    CTextField(),
    CCheckbox(),
    CSwitch(),
    CRadio(),
    CListTile(),
    CCircleAvatar(),
    CInkWell(),
    CIconButton(),
    CListView(),
    CSingleChildScrollView(),
    CTextButton(),
    CElevatedButton(),
    CBottomNavigationBar(),
    CBottomNavigationBarItem(),
    CCircularProgressIndicator(),
  ];

  final Map<String, Component> litePromptComponents = {
    'Scaffold': CScaffold(),
    'Column/Row/Stack/Flex/Wrap': CColumn(),
    'Container': CContainer(),
    'Text': CText(),
    'TextField': CTextField(),
    'Card': CCard(),
    'ElevatedButton': CElevatedButton(),
    'ListView': CListView()
  };

  String paramCode(Parameter e) {
    if (e case ComplexParameter(params: var params)) {
      final parentName = e.info.getName();
      return params
          .map((e) => paramCode(e))
          .where((e) => e.isNotEmpty)
          .map((param) => parentName != null ? '${parentName}.$param' : param)
          .join(',');
    }
    final parentName = e.info.getName();
    final info = switch (e) {
      SimpleParameter() => '(${e.type})',
      BooleanParameter() => '(bool)',
      ChoiceParameter(options: var options) =>
        'One of (JSON): [${options.mapIndexed((i, e) => '$parentName.$i:{${paramCode(e)}}').join(',')}]',
      ChoiceValueParameter() => '(${e.options.keys.take(20).join('|')} ${e.options.length > 20 ? 'etc...' : ''})',
      NullParameter() => '',
      _ => null
    };
    return e.info.isNamed() || e.displayName != null ? '${e.info.getName() ?? e.displayName}:${info}' : '';
  }

  String generatePrompt() {
    final List<Parameter> defaultParameters = [
      Parameters.widthParameter(initial: null),
      Parameters.heightParameter(initial: null),
      Parameters.paddingParameter(),
      Parameters.alignmentParameter()
        ..defaultValue = null
        ..withRequired(false)
    ];

    final message = '''You are Flutter UI generator following below Rules:
Components (Same as Flutter Widgets):

[${maxPromptComponents.where((element) => element.name != 'MaterialApp').map(_componentPromptMapper).join(',\n')}]

Every components can have below props:
[${defaultParameters.map((e) => paramCode(e)).join(',')}]

Rules:
- Color prop should be provided as "Color(0xffffffff)"

Example:
{"name":"Scaffold","props":{"backgroundColor":"Color(0xfff5f5f5)"},"slots":{"appBar":{"name":"AppBar","props":{"backgroundColor":"Color(0xff6200ea)","centerTitle":true},"slots":{"title":{"name":"Text","props":{"Text":"TestApp","textStyle.fontSize":20,"textStyle.color":"Color(0xffffffff)"}}}},"body":{"name":"Center","child":{"name":"Column","props":{"mainAxisAlignment":"center","crossAxisAlignment":"center","padding":{"All":10}},"children":[{"name":"Text","props":{"padding":{"bottom":50},"Text":"HelloWorld!","textStyle.fontSize":"20","textStyle.color":"Color(0xff000000)"}},{"name":"Text","props":{"Text":"HelloWorld!","textStyle.fontSize":"20","textStyle.color":"Color(0xff000000)"}}]}}}}

Output should be PROPER JSON of type Map<String,(String or List or String)> only.
Design clean, modern, and beautiful UIs for ${selectedConfig?.type.name ?? 'mobile'} using Material Design principles. Ensure proper spacing, alignment, colors, and responsiveness.

Prompt will be given call "generateFlutterUI" function
''';

    return message;
  }

  String generatePromptLite({String? model}) {
    final List<Parameter> defaultParameters = [
      Parameters.widthParameter(initial: null),
      Parameters.heightParameter(initial: null),
      Parameters.paddingParameter(),
      Parameters.alignmentParameter()
        ..defaultValue = null
        ..withRequired(false)
    ];

    final message = '''You are Flutter UI generator following below Rules:
All supported Flutter components (exact names):
[${componentList.keys.where((element) => !['MaterialApp', 'Image', 'ListView.builder'].contains(element)).join(',')}]

Component hierarchy should follow this structure:

[${litePromptComponents.entries.map(_componentPromptMapperLite).join(', ')}]

Above Mentioned Props:
[${litePromptComponents.values.map((e) => e.parameters).expand((e) => e).toList().asMap().map((k, v) => MapEntry(parameterName(v), v)).values.map(
              (e) => paramCode(e),
            ).where((e) => e.isNotEmpty).join(',')}]

Every components can have below props:
[${defaultParameters.map((e) => paramCode(e)).join(',')}]

Example:
{"name":"Scaffold","props":{"backgroundColor":"Color(0xfff5f5f5)"},"slots":{"appBar":{"name":"AppBar","props":{"backgroundColor":"Color(0xff6200ea)","centerTitle":true},"slots":{"title":{"name":"Text","props":{"Text":"TestApp","textStyle.fontSize":20,"textStyle.color":"Color(0xffffffff)"}}}},"body":{"name":"Center","child":{"name":"Column","props":{"mainAxisAlignment":"center","crossAxisAlignment":"center","padding":{"All":10}},"children":[{"name":"Text","props":{"padding":{"bottom":50},"Text":"HelloWorld!","textStyle.fontSize":"20","textStyle.color":"Color(0xff000000)"}},{"name":"Text","props":{"Text":"HelloWorld!","textStyle.fontSize":"20","textStyle.color":"Color(0xff000000)"}}]}}}}

- Color prop should be provided as "Color(0xffffffff)"
- Generate beautiful Material Design UIs with consistent margins, padding, spacing, and alignment. Ensure clear visual hierarchy, balanced white space, and harmonious colors for a clean, modern layout.
- Ensure output is valid JSON (Map<String, dynamic>), with no extra curly braces, no trailing commas, and no wrapping parentheses. JSON must be directly parsable.

${model == 'chatgpt' ? 'Prompt will be given, call "generateFlutterUI" function' : 'Prompt will be given, generate output JSON which will be in below Schema:\n ${jsonEncode(widgetTreeSchema)}'}
''';

    return message;
  }

  final defaultParameterNames = ['width', 'height', 'padding', 'alignment'];

  String _componentPromptMapperLite(MapEntry<String, Component> entry) {
    // if (e is CImage) {
    //   return '{name: ${e.name}, props: {${e.parameters.mapIndexed(
    //         (i, e) => paramCode(e),
    //   ).where((e) => e.isNotEmpty).join(',')}}';
    // }
    var (name, Component e) = (entry.key, entry.value);
    return '{name: ${name}, props: {${e.parameters.map(
          (e) => parameterName(e),
        ).where((e) => e.isNotEmpty).join(',')}}, ${switch (e) {
      Holder() => 'child: {...}',
      MultiHolder() => 'children: [...]',
      CustomNamedHolder(childMap: var childMap, childrenMap: var childrenMap)
          when childMap.isNotEmpty || childrenMap.isNotEmpty =>
        'slots: {...} (${e.childMap.isNotEmpty ? " (Single) <${e.childMap.keys.join(',')}>" : ''} ${e.childrenMap.isNotEmpty ? " (Multiple) ${e.childrenMap.keys.join(',')}" : ""}',
      _ => ''
    }}}';
  }

  String parameterName(Parameter e) =>
      e.info.isNamed() || e.displayName != null ? '${e.info.getName() ?? e.displayName}' : '';

  String _componentPromptMapper(Component e) {
    // if (e is CImage) {
    //   return '{name: ${e.name}, props: {${e.parameters.mapIndexed(
    //         (i, e) => paramCode(e),
    //   ).where((e) => e.isNotEmpty).join(',')}}';
    // }
    return '{name: ${e.name}, props: {${e.parameters.whereNot((e) => defaultParameterNames.contains(e.info.getName())).map(
          (e) => paramCode(e),
        ).where((e) => e.isNotEmpty).join(',')}}, ${switch (e) {
      Holder() => 'child: {...}',
      MultiHolder() => 'children: [...]',
      CustomNamedHolder(childMap: var childMap, childrenMap: var childrenMap)
          when childMap.isNotEmpty || childrenMap.isNotEmpty =>
        'slots: {...} (inside map one of ${e.childMap.isNotEmpty ? " (Single) <${e.childMap.keys.join(',')}>" : ''} ${e.childrenMap.isNotEmpty ? " (Multiple) ${e.childrenMap.keys.join(',')}" : ""}',
      _ => ''
    }}}';
  }
}
