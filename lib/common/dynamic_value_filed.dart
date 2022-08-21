import 'package:flutter/material.dart';

import '../code_to_component.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/other_model.dart';
import 'compiler/code_processor.dart';

enum InputOption { defaultConfig, doubleZeroToOne }

class DynamicValueField<T> extends StatefulWidget {
  late TextEditingController? textEditingController;
  final CodeProcessor processor;
  final bool Function(String, dynamic) onProcessedResult;
  final GlobalKey<FormState> formKey;
  final InputOption inputOption;
  final String? initialCode;

  DynamicValueField(
      {Key? key,
      required this.onProcessedResult,
      required this.processor,
      this.textEditingController,
      this.initialCode,
      this.inputOption = InputOption.defaultConfig,
      required this.formKey})
      : super(key: key) {
    textEditingController ??= TextEditingController();
  }

  @override
  State<DynamicValueField<T>> createState() => _DynamicValueFieldState<T>();
}

class _DynamicValueFieldState<T> extends State<DynamicValueField<T>> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialCode != null) {
      widget.textEditingController!.text = widget.initialCode!;
    }
    return Form(
      key: widget.formKey,
      child: TextFormField(
        onChanged: (value) {
          widget.formKey.currentState?.validate();
        },
        style: AppFontStyle.roboto(13,
            color: Colors.black, fontWeight: FontWeight.w600),
        controller: widget.textEditingController,
        maxLines: null,
        decoration: const InputDecoration(
          hintText: '',
          errorText: null,
          enabled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.theme, width: 1.5),
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Colors.grey, width: 1.5)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.theme, width: 1.5),
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
        ),
        validator: (data) {
          if (data != null) {
            CodeProcessor.error = false;
            if (T == String || T == ImageData) {
              data = CodeOperations.trim(data);
            }
            final result = widget.processor.process<T>(data ?? '');
            if (!widget.onProcessedResult(data ?? '', result)) {
              return '';
            }
            return CodeProcessor.error ? '' : null;
          }
        },
      ),
    );
  }
}
