import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';

import '../../common/app_button.dart';
import '../../common/common_methods.dart';
import '../../common/custom_popup_menu_button.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../injector.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/overlay/overlay_manager.dart';
import '../fvb_code_editor.dart';
import '../navigation/animated_slider.dart';

class FVBCodeEditorDialog {
  final BuildContext context;
  final void Function(String, bool) onChanged;
  final void Function(String?, bool) onError;
  final void Function() onDismiss;
  final String title;
  bool fullScreen = false;
  final FVBEditorConfig? config;
  final Processor processor;
  final AnimatedSlider _slider = AnimatedSlider();

  FVBCodeEditorDialog(
      {required this.onError,
      required this.title,
      required this.processor,
      required this.context,
      required this.onChanged,
      required this.onDismiss,
      this.config});

  void show(
    final BuildContext context,
    OverlayManager manager,
    GlobalKey key, {
    required final String code,
  }) {
    if (_slider.visible) {
      return;
    }
    Processor.lastCodes.clear();
    Processor.lastCodeCount = 0;
    _slider.show(context, manager, SafeArea(
      child: StatefulBuilder(builder: (context, setState2) {
        return Align(
          alignment: Responsive.isDesktop(context)
              ? Alignment.center
              : Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: AnimatedSize(
              alignment: Alignment.centerLeft,
              reverseDuration: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(6),
                ),
                width: fullScreen ? dw(context, 100) - 200 : 500,
                height: !(config?.multiline ?? true) ? 200 : dh(context, 90),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Column(
                  children: [
                    Expanded(
                      child: FVBCodeEditor(
                        onCodeChange: onChanged,
                        onErrorUpdate: onError,
                        code: code,
                        config: config ?? FVBEditorConfig(),
                        processor: processor,
                        headerEnd: Row(
                          children: [
                            AppCloseButton(
                              onTap: () {
                                AnimatedSliderProvider.of(context)?.hide();
                                onDismiss.call();
                              },
                            ),
                          ],
                        ),
                        header: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.code,
                                  color: Colors.green.shade600,
                                ),
                                10.wBox,
                                Text(
                                  title,
                                  style: AppFontStyle.lato(
                                    16,
                                    color: theme.text1Color,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            AppIconButton(
                              icon: Icons.refresh,
                              onPressed: () {
                                context
                                    .read<CreationCubit>()
                                    .changedComponent();
                              },
                              background: Colors.white,
                              iconColor: ColorAssets.darkerTheme,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            if (Responsive.isDesktop(context)) ...[
                              AppIconButton(
                                icon: fullScreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                onPressed: () {
                                  setState2(() {
                                    fullScreen = !fullScreen;
                                  });
                                },
                                iconColor: ColorAssets.darkerTheme,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (isKeyboardOpen(context) && (config?.multiline ?? true))
                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom,
                      )
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    ), key, height: dh(context, 90));
  }

  void hide() {
    _slider.hide();
    context.read<CreationCubit>().changedComponent();
  }
}
