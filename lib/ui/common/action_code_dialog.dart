import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/compiler/code_processor.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../models/variable_model.dart';
import '../action_code_editor.dart';
class ActionCodeEditorConfig{
  final String? upCode,downCode;

  ActionCodeEditorConfig({this.upCode, this.downCode});
}
class ActionCodeDialog {
  final BuildContext context;
  final List<FVBFunction> functions;
  final void Function(String) onChanged;
  late OverlayEntry _overlayEntry;
  final void Function(bool) onError;
  final void Function() onDismiss;
  final String title;
  final ActionCodeEditorConfig? config;
  ActionCodeDialog({
    required this.onError,
    required this.title,
    required this.functions,
    required this.context,
    required this.onChanged,
    required this.onDismiss,
    this.config
  });

  void show(final BuildContext context,
      {required final String code,
      required final List<FVBVariable> Function()? variables,
      final List<CodeBase>? prerequisites}) {
    _overlayEntry = OverlayEntry(
      builder: (_) {
        return GestureDetector(
          onTap: () {
            hide();
          },
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: kElevationToShadow[10],
                ),
                width: 500,
                height: 600,
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppFontStyle.roboto(14,
                              fontWeight: FontWeight.w500),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (_overlayEntry.mounted) {
                              _overlayEntry.remove();
                              onDismiss.call();
                            }
                          },
                          child: const Icon(
                            Icons.close,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: (){

                        },
                        child: ActionCodeEditor(
                          prerequisites: prerequisites ?? [],
                          onCodeChange: onChanged,
                          onError: onError,
                          code: code,
                          variables: variables,
                          scopeName: title,
                          functions: functions,
                          config: config??ActionCodeEditorConfig(),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context)!.insert(_overlayEntry);
  }

  void hide() {
    _overlayEntry.remove();
    context.read<ComponentCreationCubit>().changedComponent();
  }
}
