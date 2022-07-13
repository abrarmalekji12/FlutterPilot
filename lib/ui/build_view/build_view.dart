import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:resizable_widget/resizable_widget.dart';

import '../../common/compiler/code_processor.dart';
import '../../constant/app_colors.dart';
import '../../constant/app_dim.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
import '../../injector.dart';
import '../../runtime_provider.dart';
import '../error_widget.dart';

class BuildView extends StatefulWidget {
  final ScreenConfigCubit screenConfigCubit;
  final ComponentOperationCubit componentOperationCubit;

  const BuildView(
      {Key? key,
      required this.screenConfigCubit,
      required this.componentOperationCubit})
      : super(key: key);

  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView> {
  @override
  void initState() {
    super.initState();
    get<StackActionCubit>().stackOperation(StackOperation.push,
        uiScreen: ComponentOperationCubit.currentProject!.mainScreen);
  }

  @override
  Widget build(BuildContext context) {
    widget.componentOperationCubit.runtimeMode = RuntimeMode.run;
    return Material(
      color: Colors.white,
      child: BlocListener<StackActionCubit, StackActionState>(
        listener: (_, state) {
          if (state is StackClearState) {
            _onDismiss(context);
          }
        },
        child: ResizableWidget(
          separatorSize: Dimen.separator,
          separatorColor: AppColors.separator,
          percentages: const [0.2, 0.8],
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _onDismiss(context);
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
                const Expanded(
                  child: ConsoleWidget(),
                ),
              ],
            ),
            RuntimeProvider(
              runtimeMode: RuntimeMode.run,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: DevicePreview(
                  tools: const [DeviceSection()],
                  builder: (_) {
                    return LayoutBuilder(builder: (_, constraints) {
                      return Container(
                        color: Colors.white,
                        child: widget.componentOperationCubit.project!
                            .run(context, constraints, navigator: true),
                      );
                    });
                  },
                  enabled: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDismiss(BuildContext context) {
    ComponentOperationCubit.currentProject!.processor
        .destroyProcess(deep: true);
    widget.componentOperationCubit.runtimeMode = RuntimeMode.edit;

    Navigator.pop(context);
  }
}

class CacheMemory {
  final Map<String, dynamic> variables = {};
  final Map<String, dynamic> localVariables = {};

  CacheMemory(final CodeProcessor processor) {
    // for (final variable in processor.variables.entries) {
    //   variables[variable.key] = variable.value.value;
    // }
    for (final variable in processor.localVariables.entries) {
      localVariables[variable.key] = variable.value;
    }
  }

  void restore(final CodeProcessor processor) {
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
