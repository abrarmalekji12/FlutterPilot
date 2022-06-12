import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../common/compiler/code_processor.dart';
import '../../constant/string_constant.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
import '../../injector.dart';
import '../../models/variable_model.dart';
import '../../runtime_provider.dart';

class BuildView extends StatefulWidget {
  final Function onDismiss;
  final ScreenConfigCubit screenConfigCubit;
  final ComponentOperationCubit componentOperationCubit;

  const BuildView(
      {Key? key,
      required this.onDismiss,
      required this.screenConfigCubit,
      required this.componentOperationCubit})
      : super(key: key);

  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView> {
  late final CacheMemory _cacheMemory;

  @override
  void initState() {
    super.initState();
    _cacheMemory = CacheMemory(ComponentOperationCubit.codeProcessor);
    get<StackActionCubit>().stackOperation(StackOperation.push,
        uiScreen: ComponentOperationCubit.currentFlutterProject!.mainScreen);
    ComponentOperationCubit.codeProcessor
        .executeCode(ComponentOperationCubit.currentFlutterProject!.actionCode);
  }

  @override
  Widget build(BuildContext context) {
    widget.componentOperationCubit.runtimeMode = RuntimeMode.run;
    return GestureDetector(
      onTap: () {
        _onDismiss(context);
      },
      child: Material(
        color: Colors.white,
        child: Stack(
          children: [
            Center(
              child: RuntimeProvider(
                runtimeMode: RuntimeMode.run,
                child: BlocBuilder<ComponentOperationCubit,
                    ComponentOperationState>(
                  bloc: widget.componentOperationCubit,
                  builder: (_, state) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: GestureDetector(
                        onTap: () {},
                        child: DevicePreview(
                          tools: const [DeviceSection()],
                          builder: (_) {
                            return LayoutBuilder(builder: (_, constraints) {
                              if (Get.isDialogOpen ?? false) {
                                ComponentOperationCubit
                                    .codeProcessor
                                    .variables['dw']!
                                    .value = constraints.maxWidth;

                                ComponentOperationCubit
                                    .codeProcessor
                                    .variables['dh']!
                                    .value = constraints.maxHeight;
                              }
                              return Container(
                                color: Colors.white,
                                child: widget
                                    .componentOperationCubit.flutterProject!
                                    .run(context, navigator: true),
                              );
                            });
                          },
                          enabled: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _onDismiss(context);
                  },
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onDismiss(BuildContext context) {
    _cacheMemory.restore(ComponentOperationCubit.codeProcessor);
    ComponentOperationCubit.codeProcessor.destroyProcess();
    widget.componentOperationCubit.runtimeMode = RuntimeMode.edit;
    Get.back(
      closeOverlays: false,
    );

    ComponentOperationCubit.changeVariables(
        widget.componentOperationCubit.flutterProject!.currentScreen);
    widget.onDismiss.call();
  }
}

class CacheMemory {
  final Map<String, dynamic> variables = {};
  final Map<String, dynamic> localVariables = {};

  CacheMemory(final CodeProcessor processor) {
    for (final variable in processor.variables.entries) {
      variables[variable.key] = variable.value.value;
    }
    for (final variable in processor.localVariables.entries) {
      localVariables[variable.key] = variable.value;
    }
  }

  void restore(final CodeProcessor processor) {
    for (final variable in processor.variables.entries) {
      variable.value.value = variables[variable.key];
    }
    for (final variable in processor.localVariables.keys) {
      processor.localVariables[variable] = localVariables[variable];
    }
  }
}
