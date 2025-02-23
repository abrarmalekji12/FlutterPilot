import 'package:device_preview/device_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:resizable_widget/resizable_widget.dart';

import '../../collections/project_info_collection.dart';
import '../../common/app_button.dart';
import '../../common/device_preview/custom_device_preview.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/app_dim.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
import '../../injector.dart';
import '../../runtime_provider.dart';
import '../../screen_model.dart';
import '../../widgets/button/app_close_button.dart';
import '../error_widget.dart';
import '../navigation/animated_dialog.dart';

final UserProjectCollection _collection = sl<UserProjectCollection>();

class BuildView extends StatefulWidget {
  final ScreenConfigCubit screenConfigCubit;
  final OperationCubit operationCubit;
  final CreationCubit creationCubit;

  const BuildView(
      {Key? key,
      required this.screenConfigCubit,
      required this.operationCubit,
      required this.creationCubit})
      : super(key: key);

  @override
  State<BuildView> createState() => _BuildViewState();
}

final ValueNotifier<bool> fullScreenView = ValueNotifier(false);

class _BuildViewState extends State<BuildView> {
  final stackCubit = sl<StackActionCubit>();

  @override
  void initState() {
    super.initState();
    stackCubit.stackOperation(StackOperation.push,
        screen: _collection.project!.mainScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.background1,
      child: BlocProvider.value(
        value: stackCubit,
        child: BlocListener<StackActionCubit, StackActionState>(
          listener: (_, state) {
            if (state is StackClearState) {
              _onDismiss(context);
            }
          },
          child: Responsive(
            desktop: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        Text(
                          'Run',
                          style: AppFontStyle.headerStyle(),
                        ),
                        20.wBox,
                        AppIconButton(
                            icon: Icons.refresh,
                            iconColor: theme.iconColor1,
                            background: theme.background1,
                            onPressed: () {
                              stackCubit.reset();
                            }),
                        20.wBox,
                        ValueListenableBuilder(
                            valueListenable: fullScreenView,
                            builder: (context, value, _) {
                              return CupertinoSlidingSegmentedControl<bool>(
                                  key: ValueKey(value),
                                  children: {
                                    true: Text(
                                      'App & Console',
                                      style: AppFontStyle.lato(14,
                                          color: Colors.black),
                                    ),
                                    false: Text('App Only',
                                        style: AppFontStyle.lato(14,
                                            color: Colors.black)),
                                  },
                                  groupValue: !value,
                                  onValueChanged: (value) {
                                    if (value != null) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((timeStamp) {
                                        fullScreenView.value = !value;
                                      });
                                    }
                                  });
                            }),
                        const Spacer(),
                        AppCloseButton(
                          onTap: () {
                            _onDismiss(context);
                          },
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: ValueListenableBuilder(
                        valueListenable: fullScreenView,
                        builder: (context, value, _) {
                          if (value) {
                            return RuntimeProvider(
                              runtimeMode: RuntimeMode.run,
                              child: LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  return collection.project!.run(
                                      context, constraints,
                                      navigator: true);
                                },
                              ),
                            );
                          }
                          return ResizableWidget(
                            separatorSize: Dimen.separator,
                            separatorColor: ColorAssets.separator,
                            percentages: const [0.8, 0.2],
                            children: [
                              RunView(
                                  componentOperationCubit:
                                      widget.operationCubit),
                              const ConsoleWidget(
                                mode: RuntimeMode.run,
                              ),
                            ],
                          );
                        }),
                  ),
                ],
              ),
            ),
            mobile: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child:
                      RunView(componentOperationCubit: widget.operationCubit),
                ),
                // SlidingUpPanel(
                //   minHeight: 100,
                //   maxHeight: 500,
                //   panel: const ConsoleWidget(
                //     mode: RuntimeMode.run,
                //   ),
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDismiss(BuildContext context) {
    _collection.project!.processor.destroyProcess(deep: true);
    RuntimeProvider.global = RuntimeMode.edit;
    AnimatedDialog.hide(context);
  }
}

class RunView extends StatefulWidget {
  final OperationCubit componentOperationCubit;

  const RunView({Key? key, required this.componentOperationCubit})
      : super(key: key);

  @override
  State<RunView> createState() => _RunViewState();
}

DeviceInfo? defaultDeviceInfo;

class _RunViewState extends State<RunView> {
  late StackActionCubit _stackActionCubit;

  @override
  void initState() {
    _stackActionCubit = context.read<StackActionCubit>();
    if (defaultDeviceInfo == null) {
      final values = collection.project!.settings.target.entries
          .where((element) => element.value);
      if (values.isNotEmpty) {
        final target = values.first.key;
        switch (target) {
          case TargetPlatformType.mobile:
            // TODO: Handle this case.
            break;
          case TargetPlatformType.tablet:
            // TODO: Handle this case.
            break;
          case TargetPlatformType.desktop:
            // TODO: Handle this case.
            break;
        }
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RuntimeProvider(
      runtimeMode: RuntimeMode.run,
      child: CustomDevicePreview(
        tools: const [DeviceSection()],
        backgroundColor: theme.backgroundLightGrey,
        defaultDevice: defaultDeviceInfo,
        builder: (_) {
          return LayoutBuilder(builder: (devicePreviewContext, constraints) {
            if (defaultDeviceInfo == null) {
              defaultDeviceInfo =
                  devicePreviewContext.read<DevicePreviewStore>().defaultDevice;
              return const CircularProgressIndicator();
            }
            return BlocBuilder(
                bloc: _stackActionCubit,
                buildWhen: (_, state) => state is StackResetState,
                builder: (context, state) {
                  return widget.componentOperationCubit.project!
                      .run(context, constraints, navigator: true);
                });
          });
        },
        enabled: true,
      ),
    );
  }
}

class CacheMemory {
  final Map<String, dynamic> variables = {};
  final Map<String, dynamic> localVariables = {};

  CacheMemory(final Processor processor) {
    // for (final variable in processor.variables.entries) {
    //   variables[variable.key] = variable.value.value;
    // }
    for (final variable in processor.localVariables.entries) {
      localVariables[variable.key] = variable.value;
    }
  }

  void restore(final Processor processor) {
    final List<String> removeList = [];
    // for (final variable in processor.variables.entries) {
    //   if (variables.containsKey(variable.key)) {
    //     variable.value.value = variables[variable.key];
    //   } else {
    //     removeList.add(variable.key);
    //   }
    // }
    // for (final key in removeList) {
    //   processor.variables.remove(key);
    // }
    removeList.clear();
    for (final variable in processor.localVariables.keys) {
      if (localVariables.containsKey(variable)) {
        processor.localVariables[variable] = localVariables[variable];
      } else {
        removeList.add(variable);
      }
    }
    for (final key in removeList) {
      processor.localVariables.remove(key);
    }
  }
}
