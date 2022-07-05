import 'package:flutter/material.dart';

import '../../common/app_button.dart';
import '../../common/app_text_field.dart';
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      width: 500,
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
          SizedBox(
            height: 40,
            child: AppTextField(
              value: _text,
              onChange: (data) {
                _text = data;
              },
            ),
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
    );
  }
}
