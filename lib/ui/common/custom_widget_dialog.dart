import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_button.dart';
import '../../common/app_text_field.dart';
import '../../component_list.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';

class CustomWidgetDialog extends StatefulWidget {
  final Function(CustomWidgetType, String) onSubmit;

  const CustomWidgetDialog({Key? key, required this.onSubmit})
      : super(key: key);

  @override
  State<CustomWidgetDialog> createState() => _CustomWidgetDialogState();
}

class _CustomWidgetDialogState extends State<CustomWidgetDialog> {
  String _text = '';
  CustomWidgetType _type = CustomWidgetType.stateless;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      width: 500,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter Custom Widget Details',
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 10,
            ),
            AppTextField(
              value: _text,
              onValidate: (value) {
                if (value == null) {
                  return 'Please enter name';
                }
                if (componentList.containsKey(value)) {
                  return 'Widget name already exists';
                }
                if (ComponentOperationCubit.currentProject!.customComponents
                        .firstWhereOrNull((element) => element.name == value) !=
                    null) {
                  return 'Custom Widget name already exists';
                }
                _text = value;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Text(
                  'Type',
                  style: AppFontStyle.roboto(14, color: Colors.black),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: DropdownButton<CustomWidgetType>(
                    value: _type,
                    items: const [
                      DropdownMenuItem<CustomWidgetType>(
                        value: CustomWidgetType.stateless,
                        child: Text('StatelessWidget'),
                      ),
                      DropdownMenuItem<CustomWidgetType>(
                        value: CustomWidgetType.stateful,
                        child: Text('StatefulWidget'),
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
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            AppButton(
              height: 45,
              title: 'ok',
              onPressed: () {
                if (AppTextField.changedValue.length > 1 &&
                    !AppTextField.changedValue.contains(' ') &&
                    !AppTextField.changedValue.contains('.')) {
                  widget.onSubmit.call(_type, _text);
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
