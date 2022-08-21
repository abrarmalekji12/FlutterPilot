import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/compiler/code_processor.dart';
import '../../common/custom_popup_menu_button.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../models/variable_model.dart';
import '../action_code_editor.dart';

class ActionCodeEditorConfig {
  final String? upCode, downCode;
  final List<FVBVariable> Function()? variables;
  final bool singleLine;
  final bool string;
  final bool parentProcessorGiven;

  ActionCodeEditorConfig(
      {this.upCode,
      this.downCode,
      this.variables,
      this.singleLine = false,
      this.string = false,
      this.parentProcessorGiven = false});
}

class ActionCodeDialog {
  final BuildContext context;
  final void Function(String) onChanged;
  late OverlayEntry _overlayEntry;
  final void Function(bool) onError;
  final void Function() onDismiss;
  final String title;
  bool fullScreen = false;
  final ActionCodeEditorConfig? config;
  final CodeProcessor processor;

  ActionCodeDialog(
      {required this.onError,
      required this.title,
      required this.processor,
      required this.context,
      required this.onChanged,
      required this.onDismiss,
      this.config});

  void show(
    final BuildContext context, {
    required final String code,
  }) {
    CodeProcessor.lastCodes.clear();
    CodeProcessor.lastCodeCount = 0;
    _overlayEntry = OverlayEntry(
      builder: (_) {
        return SafeArea(
          child: StatefulBuilder(builder: (context, setState2) {
            return GestureDetector(
              onTap: () {
                hide();
              },
              child: Align(
                alignment: Responsive.isLargeScreen(context)
                    ? Alignment.center
                    : Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: kElevationToShadow[10],
                      ),
                      width: fullScreen ? dw(context, 100) : 500,
                      height: (config?.singleLine ?? false)
                          ? 200
                          : (fullScreen
                              ? null
                              : (Responsive.isLargeScreen(context)
                                  ? 600
                                  : (MediaQuery.of(context).size.height -
                                      400))),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () {
                                      context
                                          .read<ComponentCreationCubit>()
                                          .changedComponent();
                                    },
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  if (Responsive.isLargeScreen(context)) ...[
                                    IconButton(
                                      icon: Icon(fullScreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen),
                                      onPressed: () {
                                        setState2(() {
                                          fullScreen = !fullScreen;
                                        });
                                      },
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                  ],
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
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: FVBCodeEditor(
                                onCodeChange: onChanged,
                                scopeName: title,
                                onError: onError,
                                code: code,
                                config: config ?? ActionCodeEditorConfig(),
                                processor: processor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );

    Overlay.of(context)!.insert(_overlayEntry);
  }

  void hide() {
    if (_overlayEntry.mounted) {
      _overlayEntry.remove();
      context.read<ComponentCreationCubit>().changedComponent();
    }
  }
}
