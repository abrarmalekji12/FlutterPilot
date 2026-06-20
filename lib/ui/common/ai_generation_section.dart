import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/fvb_file.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:json_view/json_view.dart';

import '../../common/app_button.dart';
import '../../common/app_loader.dart';
import '../../common/extension_util.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../injector.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../runtime_provider.dart';
import '../../user_session.dart';
import '../../widgets/button/filled_button.dart';
import '../../widgets/textfield/app_textfield.dart';
import '../code_view_widget.dart';
import '../emulation_view.dart';
import '../navigation/animated_dialog.dart';

class AIGenerationSection extends StatefulWidget {
  final ValueNotifier<Component?> selectedComponent;

  const AIGenerationSection({super.key, required this.selectedComponent});

  @override
  State<AIGenerationSection> createState() => _AIGenerationSectionState();
}

class _AIGenerationSectionState extends State<AIGenerationSection> {
  final _userSession = sl<UserSession>();
  final TextEditingController _prompt = TextEditingController(text: kDebugMode ? 'Simple profile page UI' : ''); //

  (List<Component>, List<Map<String, dynamic>>)? generatedOutput;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_userSession.settingModel!.openAISecretToken != null) ...[
          AppTextField(
            name: 'AI prompt (optional)',
            hintText: 'Describe what you want.....',
            maxLines: 8,
            fontSize: 14,
            controller: _prompt,
          ),
          const SizedBox(
            height: 10,
          ),
          FilledButtonWidget(
              width: 230,
              height: 45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome,color: Colors.white,),
                  15.wBox,
                  const Text('Generate using AI'),
                ],
              ),
              onTap: () {
                if (_prompt.text.isNotEmpty) {
                  AppLoader.show(context);
                  generatedOutput = null;
                  setState(() {});
                  componentGenerator.generate(_prompt.text).then((value) {
                    AppLoader.hide(context);
                    generatedOutput = value;

                    setState(() {});
                  }).onError((error, stackTrace) {
                    AppLoader.hide(context);
                    print('ERROR: ${error}');
                    print('TRACE: ${stackTrace}');
                  });
                }
              }),
        ] else
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                ),
                10.wBox,
                Expanded(
                  child: Text(
                    'Configure OpenAI Secret key from Settings to use AI Generation',
                    style: AppFontStyle.lato(14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        if (generatedOutput?.$1.isNotEmpty ?? false) ...[
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: generatedOutput?.$1.length ?? 0,
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: (360) / defaultScreenConfigs.first.scale,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 2,
                                        color: widget.selectedComponent.value == generatedOutput!.$1[i]
                                            ? ColorAssets.theme
                                            : ColorAssets.grey),
                                    borderRadius: BorderRadius.circular(10)),
                                child: InkWell(
                                  onTap: () {
                                    widget.selectedComponent.value = generatedOutput!.$1[i];
                                    setState(() {});
                                  },
                                  child: RuntimeProvider(
                                    runtimeMode: RuntimeMode.run,
                                    child: ProcessorProvider(
                                      processor: collection.project!.processor,
                                      child: Theme(
                                        data: ThemeData.light(useMaterial3: false),

                                        child: Builder(builder: (context) {
                                          return EmulationView(
                                              widget: generatedOutput!.$1[i].build(context),
                                              screenConfig: defaultScreenConfigs.first);
                                        }),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.selectedComponent.value == generatedOutput!.$1[i])
                              const Positioned(
                                left: 20,
                                top: 20,
                                child: CircleAvatar(
                                  radius: 12,
                                  child: Icon(
                                    Icons.done,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  backgroundColor: ColorAssets.theme,
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 30,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIconButton(
                              icon: Icons.account_tree_rounded,
                              onPressed: () {
                                AnimatedDialog.show(
                                    context,
                                    Material(
                                      color: Colors.white,
                                      child: SizedBox(
                                        width: 400,
                                        height: 500,
                                        child: JsonView(
                                          json: generatedOutput!.$1[i].toJson(),
                                        ),
                                      ),
                                    ),
                                    barrierDismissible: true,
                                    backPressDismissible: true);
                              }),
                          30.wBox,
                          AppIconButton(
                              icon: Icons.code_rounded,
                              onPressed: () {
                                AnimatedDialog.show(
                                  context,
                                  CodeViewerWidget(
                                    code: FVBFile(
                                        'generated_code.dart',
                                        StatelessComponent(
                                                root: generatedOutput!.$1[i],
                                                name: 'GeneratedComp',
                                                project: collection.project!,
                                                userId: _userSession.user.userId!,
                                                id: randomId)
                                            .implementationCode(collection.project!)),
                                  ),
                                );
                              }),
                        ],
                      ),
                    )
                  ],
                );
              },
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
      ],
    );
  }
}
