import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/extension_util.dart';
import '../../common/validations.dart';
import '../../components/component_list.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../injector.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/button/filled_button.dart';
import '../../widgets/button/outlined_button.dart';
import '../../widgets/textfield/app_textfield.dart';
import '../navigation/animated_dialog.dart';
import 'ai_generation_section.dart';

class CustomWidgetDialog extends StatefulWidget {
  final Function(CustomWidgetType, String, [Map<String, dynamic>]) onSubmit;

  const CustomWidgetDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<CustomWidgetDialog> createState() => _CustomWidgetDialogState();
}

class _CustomWidgetDialogState extends State<CustomWidgetDialog> {
  final TextEditingController _text = TextEditingController(text: kDebugMode?'GenAITestPage':''); //'ProfilePage'
  CustomWidgetType _type = CustomWidgetType.stateless;
  final ValueNotifier<Component?> generatedComponent = ValueNotifier(null);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
              AIGenerationSection(
                selectedComponent: generatedComponent,
              ),
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
                        if (generatedComponent.value != null) {
                          final operationCubit = sl<OperationCubit>();
                          final component = generatedComponent.value!;
                          operationCubit.addCustomComponent(_text.text, _type, root: component);
                          AnimatedDialog.hide(context);
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
}
