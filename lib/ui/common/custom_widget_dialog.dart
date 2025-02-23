import 'dart:convert';

// import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';

// import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ollama/ollama.dart';
import 'package:rxdart/rxdart.dart';

// import '../../ai/gemini_integration.dart';
import '../../common/app_loader.dart';
import '../../common/extension_util.dart';
import '../../common/validations.dart';
import '../../components/component_list.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../injector.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/parameter_model.dart';
import '../../runtime_provider.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/button/filled_button.dart';
import '../../widgets/button/outlined_button.dart';
import '../../widgets/textfield/app_textfield.dart';
import '../emulation_view.dart';
import '../navigation/animated_dialog.dart';
import '../paint_tools/paint_tools.dart';

const token =
    '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';

//'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'; //'sk-proj-9VqJqwX8G0mjAaqtFBr4T3BlbkFJKbwme6YxYccIq8vlhG1G';

class CustomWidgetDialog extends StatefulWidget {
  final Function(CustomWidgetType, String, [Map<String, dynamic>]) onSubmit;

  const CustomWidgetDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<CustomWidgetDialog> createState() => _CustomWidgetDialogState();
}

class _CustomWidgetDialogState extends State<CustomWidgetDialog> {
  final TextEditingController _text = TextEditingController();
  final TextEditingController _geminiPrompt = TextEditingController(text: 'Generate simple profile page UI');
  CustomWidgetType _type = CustomWidgetType.stateless;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Component>? generatedOutput;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: AppFontStyle.lato(14, color: theme.text1Color),
      child: Container(
        padding: const EdgeInsets.all(20),
        color: theme.background1,
        width: 500,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Custom Widget',
                    style: AppFontStyle.headerStyle(),
                  ),
                  AppCloseButton(
                    onTap: () {
                      AnimatedDialog.hide(context);
                    },
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              AppTextField(
                hintText: 'Name',
                controller: _text,
                fontSize: 16,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter name';
                  }
                  if (componentList.containsKey(value)) {
                    return 'Widget name already exists';
                  }
                  return Validations.commonNameValidator().call(value);
                },
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Text(
                    'Type: ',
                    style: AppFontStyle.lato(14, color: theme.titleColor),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonHideUnderline(
                      child: DefaultTextStyle(
                        style: AppFontStyle.lato(14, color: theme.text1Color),
                        child: DropdownButton<CustomWidgetType>(
                          value: _type,
                          dropdownColor: theme.background2,
                          style: AppFontStyle.lato(14, color: theme.text1Color),
                          items: [
                            DropdownMenuItem<CustomWidgetType>(
                              value: CustomWidgetType.stateless,
                              child: Text(
                                'StatelessWidget',
                                style: AppFontStyle.lato(14, color: theme.text1Color),
                              ),
                            ),
                            DropdownMenuItem<CustomWidgetType>(
                              value: CustomWidgetType.stateful,
                              child: Text(
                                'StatefulWidget',
                                style: AppFontStyle.lato(14, color: theme.text1Color),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _type = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              AppTextField(
                name: 'Gemini AI prompt (optional)',
                controller: _geminiPrompt,
              ),
              if (generatedOutput?.isNotEmpty ?? false) ...[
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      return SizedBox(
                        width: 150,
                        child: RuntimeProvider(
                          runtimeMode: RuntimeMode.run,
                          child: ProcessorProvider(
                            processor: collection.project!.processor,
                            child: Builder(builder: (context) {
                              return EmulationView(
                                  widget: generatedOutput![i].build(context), screenConfig: defaultScreenConfigs.first);
                            }),
                          ),
                        ),
                      );
                    },
                    itemCount: generatedOutput?.length ?? 0,
                  ),
                ),
              ] else if (generatedOutput != null) ...[
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Couldn\'t generate anything',
                  style: AppFontStyle.lato(16, color: ColorAssets.red, fontWeight: FontWeight.normal),
                )
              ],
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButtonWidget(
                    width: 120,
                    height: 45,
                    text: 'Create',
                    onTap: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // widget.onSubmit.call(_type, _text.text);

                        if (_geminiPrompt.text.isNotEmpty) {
                          AppLoader.show(context);
                          generatedOutput = null;
                          setState(() {});
                          generate(_geminiPrompt.text).then((value) {
                            AppLoader.hide(context);
                            generatedOutput = value;
                            setState(() {});
                          }).onError((error, stackTrace) {
                            AppLoader.hide(context);
                            error.printError();
                          });
                        } else {
                          widget.onSubmit.call(_type, _text.text);
                        }
                      }
                    },
                    fillColor: ColorAssets.theme,
                  ),
                  20.wBox,
                  OutlinedButtonWidget(
                    width: 120,
                    height: 45,
                    text: 'Cancel',
                    onTap: () => AnimatedDialog.hide(context),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  final components = tempComponentList;

  String paramCode(Parameter e) {
    return e.displayName != null
        ? '${e.displayName} ${switch (e) {
            SimpleParameter() => '(${e.type})',
            BoolParameter() => '(bool)',
            ChoiceValueParameter() => '(one of ${e.options.keys.join(', ')})',
            _ => 'N/A'
          }}'
        : 'N/A';
  }

  Future<List<Component>?> generate(String prompt) async {
    // initializeGemini();
    final message = '''Let's say there is a language which contains the below components:
${components.where((element) => element.name != 'MaterialApp').map((e) => 'name: ${e.name}, parameters: [${e.parameters.map(
              (e) => paramCode(e),
            ).join(',')}]').join('\n')}

there will be a prompt, imagine the design and generate component structure in valid JSON format as below example from components given above
Output Format:
- In Clean string serialized JSON Format
- {"name":"Scaffold","parameters":[{"code":"Color(0xffffffff)"},{"code":"1"}],"id":"random_id","body":{"name":"Column","id":"random_id","children":[{"name":"Container","id":"random_id","child":{"name":"CircleAvatar"}}]}}
-- No backslash before quote
-- No newLine (\\n).
Format Note:
- No other fields should be there

Note:
- ID should be unique
- parameter object have "code" field which holds value as a string
- Color parameter should be given as "Color(HEXADECIMAL)"
- parameters should follow sequence.


- Below Components can have single "child" component
${components.where((element) => element is Holder).map((e) => e.name).join(', ')}
i.e
{"name":"SingleChildScrollView","child":{"name":"SizedBox"}}


- Below Components can have "children" components :
${components.where((element) => element is MultiHolder).map((e) => e.name).join(', ')}
i.e
{"name":"Column","children":[{"name":"SizedBox"}]}

- Below can have multiple components but as given below fields,

${components.whereType<CustomNamedHolder>().map((e) => '''
          ${e.name} can't have a "child" or "children".
          
          put component inside "childMap" value of which is always Map<String,dynamic> if it is one of below. 
         ${e.childMap.keys.join(', ')}

          put component inside "childrenMap"  value of which is always List<dynamic>  if it is one of below.
         ${e.childrenMap.keys.join(', ')}
          ''')}
          
Prompt: "$prompt"
''';
    // print("INPUT ::: \n");
    // print(message);
    // print("END ::: ");
    // final content = [
    //   Content(
    //     type: 'text',
    //       text:TextData(annotations: [], value: ))
    // ];
    // final openAI = OpenAI.instance.build(
    //     token: token,
    //     orgId: 'org-6Jt9tkjHwz0pyGbC75mEcIlC',
    //     baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    //     enableLog: true);
    // final response = await openAI.onCompletion(
    //     request: CompleteText(prompt: message, model: Davinci002Model()));

    final ollama = Ollama(
      baseUrl: Uri.http('192.168.0.117:11434')
    );

    final stream = ollama.generate(
      message,
      model: 'deepseek-v2:16b',
      format: 'json',
        chunked: false,
      raw: true
    );

    String finalOutput = '';
    stream.doOnError((_,error){
      print('ERROR STREAM OLLAMA:: ${_}');
      error.printError();
    });
    await for (final chunk in stream) {
      finalOutput += chunk.text ?? '';
    }
    print('FINAL OUTPUT::::: \n$finalOutput\n-----------');

    Component? stringToComponent(String output) {
      if (output.startsWith('```')) {
        output = output.substring(output.indexOf('{'), output.length - 3);
      }

      output = output.replaceAll('""', '"').replaceAll('"\\"', '"').replaceAll('\\"', '"');

      try {
        print('OUT:: $output');
        final Map<String, dynamic> map = jsonDecode(output);
        return Component.fromJson(map, collection.project);
      } on FormatException catch (e) {
        print('FORMAT ERROR ${e.message} in ${e.source}');
      }
      return null;
    }
    final comp=stringToComponent(finalOutput);
    return comp!=null?[comp]:[];
    // return finalOutput
    //     .map((e) => )
    //     .whereType<Component>()
    //     .toList();

    // return response?.choices
    //     .where((element) => element.text.isNotEmpty)
    //     .map((e) => stringToComponent(e.text))
    //     .whereType<Component>()
    //     .toList();
  }
}

//           '''
//       Let's say there is a language which contains the below components:
// MaterialApp
// Scaffold
// AppBar
// Drawer
// Row
// Column
// Stack
// IndexedStack
// Wrap
// ListView
// GridView
// ListTile
// Flex
// SingleChildScrollView
// CustomScrollView
// Padding
// ClipRRect
// ClipOval
// DropdownButtonHideUnderline
// Container
// Offstage
// AnimatedContainer
// AnimatedSwitcher
// AnimatedDefaultTextStyle
// DefaultTextStyle
// ColoredBox
// ColorFiltered
// Visibility
// Material
// Expanded
// IntrinsicWidth
// IntrinsicHeight
// Spacer
// Center
// Align
// Positioned
// AspectRatio
// FractionallySizedBox
// SafeArea
// Flexible
// Card
// SizedBox
// SliverToBoxAdapter
// SliverAppBar
// Shimmer
// SizedBox
// BackdropFilter
// PreferredSize
// FittedBox
// Text
// Icon
// Switch
// CircularProgressIndicator
// LinearProgressIndicator
// LoadingIndicator
// Checkbox
// Radio
// Image
// Image
// Image
// SvgPicture
// SvgPicture
// CircleAvatar
// Divider
// Opacity
// AnimatedOpacity
// Transform
// Transform
// Transform
// VerticalDivider
// DashedLine
// RichText
// CustomPaint
// TextField
// TextFormField
// Form
// InputDecorator
// InkWell
// GestureDetector
// Tooltip
// BackButton
// CloseButton
// TextButton
// OutlinedButton
// ElevatedButton
// FloatingActionButton
// IconButton
// Placeholder
// Builder
// LayoutBuilder
// StatefulBuilder
// GridView
// PageView
// ListView
// ListView
// NotRecognizedWidget
// DataLoaderWidget
// DropdownButton
// DropdownMenuItem
// IfCondition
// ElseIfCondition
// Hero
// TabBar
// Tab
// TabBarView
// BottomNavigationBar
// BottomNavigationBarItem
// NavigationRail
// NavigationRailDestination
// PopupMenuButton
// PopupMenuItem
//
// there will be a prompt, imagine the design and generate component structure in simple JSON format as below example from components given above
// Output Format:
// - Json Format
// {
// "name":"component_name",
// "id":"random_id",
// "child":{
// "name":"component_name",
// "id":"random_id",
// "children":[
// {
// "name":"compoenent_name",
// "id":"random_id",
// }
// ]
// }
// }
//
// Format Note:
// - No "props" should be there
//
// Note:
// - Only Below Components can have single child component
// Scaffold
// AppBar
// Drawer
// Stack
// IndexedStack
// SingleChildScrollView
// CustomScrollView
// Padding
// ClipRRect
// ClipOval
// Container
// Offstage
// AnimatedContainer
// AnimatedSwitcher
// AnimatedDefaultTextStyle
// DefaultTextStyle
// ColoredBox
// ColorFiltered
// Visibility
// Material
// Expanded
// IntrinsicWidth
// IntrinsicHeight
// Center
// Align
// Positioned
// AspectRatio
// FractionallySizedBox
// SafeArea
// Flexible
// Card
// SizedBox
// SliverToBoxAdapter
// SliverAppBar
// Shimmer
// SizedBox
// BackdropFilter
// PreferredSize
// FittedBox
// Image
// SvgPicture
// CircleAvatar
// Opacity
// AnimatedOpacity
// Transform
// VerticalDivider
// RichText
// CustomPaint
// TextField
// TextFormField
// Form
// InputDecorator
// InkWell
// GestureDetector
// Tooltip
// BackButton
// CloseButton
// TextButton
// OutlinedButton
// ElevatedButton
// FloatingActionButton
// IconButton
// Placeholder
// Builder
// LayoutBuilder
// StatefulBuilder
// Hero
// DropdownButton
// DropdownMenuItem
// BottomNavigationBar
// NavigationRail
// PopupMenuButton
// PopupMenuItem
//
// - And Only below widgets can hold multiple children:
// Row
// Column
// Stack
//
// - Scaffold can have multiple components as per Flutter, but not as a child but as,
// Inside "childMap" if it is one of below.
// ${CScaffold().childMap.keys.join('\n')}
//
// Inside "childrenMap" if it is one of below.
// ${CScaffold().childrenMap.keys.join('\n')}
//
// Prompt: "$prompt"
// '''
//
