import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_classes.dart';

import '../bloc/state_management/state_management_bloc.dart';
import '../common/package/custom_textfield_searchable.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../injector.dart';
import '../models/fvb_ui_core/component/custom_component.dart';
import '../models/local_model.dart';
import '../runtime_provider.dart';
import 'fvb_code_editor.dart';
import 'parameter_ui.dart';

class CustomComponentProperty extends StatefulWidget {
  final CustomComponent component;

  const CustomComponentProperty({Key? key, required this.component})
      : super(key: key);

  @override
  State<CustomComponentProperty> createState() =>
      _CustomComponentPropertyState();
}

class _CustomComponentPropertyState extends State<CustomComponentProperty>
    with GetProcessor {
  final Debouncer _debouncer = Debouncer(milliseconds: 120);
  final controller = TextEditingController();
  final ValueNotifier<String> colorChangedNotifier = ValueNotifier(' ');
  late Processor processor;

  @override
  void initState() {
    super.initState();
    processor = needfulProcessor(context.read<SelectionCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OperationCubit, OperationState>(
      buildWhen: (old, state) {
        return state is CustomComponentVariableUpdatedState;
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            Text(
              'Export Values',
              style: AppFontStyle.titleStyle(),
            ),
            const SizedBox(
              height: 15,
            ),
            ListView.builder(
              itemBuilder: (_, index) {
                final variable = widget.component.argumentVariables[index];
                if (widget.component.arguments.length <= index) {
                  widget.component.arguments.add('');
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${variable.name} :',
                            style: AppFontStyle.lato(13,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            DataType.dataTypeToCode(variable.dataType) +
                                (variable.nullable ? '?' : ''),
                            style: AppFontStyle.lato(13,
                                fontWeight: FontWeight.w600,
                                color: ColorAssets.theme),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          if (widget.component.parent != null) ...[
                            if (variable.dataType.equals(fvbColor)) ...[
                              ValueListenableBuilder(
                                builder: (context, value, _) {
                                  final val = processor
                                      .process(
                                          widget.component.arguments[index],
                                          config: const ProcessorConfig())
                                      .value;
                                  Color? color;
                                  if (val is FVBInstance) {
                                    color = val.toDart();
                                  }
                                  if (color == null) {
                                    color = (variable.value as FVBInstance?)
                                        ?.toDart();
                                  }
                                  return SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: ColorButton(
                                      color: color ?? Colors.black,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        color: color ?? Colors.black,
                                        border: Border.all(
                                            color: Colors.black, width: 1),
                                      ),
                                      onColorChanged: (color) {
                                        setState(() {
                                          widget.component.arguments[index] =
                                              'Color(0x${color.value.toRadixString(16)})';
                                          controller.text =
                                              widget.component.arguments[index];
                                        });
                                      },
                                    ),
                                  );
                                },
                                valueListenable: colorChangedNotifier,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                            ],
                            Expanded(
                              child: FVBCodeEditor(
                                  controller: controller,
                                  code: widget.component.arguments[index],
                                  onCodeChange: (value, refresh) {
                                    _debouncer.run(() {
                                      widget.component.arguments[index] = value;
                                      if (variable.dataType.equals(fvbColor)) {
                                        colorChangedNotifier.value = value;
                                      }
                                      context.read<StateManagementBloc>().add(
                                          StateManagementRefreshEvent(
                                              widget.component.id,
                                              RuntimeMode.edit));

                                      context
                                          .read<OperationCubit>()
                                          .updateRootOnFirestore();

                                      // if (refresh) {
                                      //   context
                                      //       .read<OperationCubit>()
                                      //       .refreshPropertyChanges(context.read<SelectionCubit>());
                                      //   context.read<CreationCubit>().changedComponent();
                                      // }
                                    });
                                  },
                                  onErrorUpdate: (message, error) {
                                    context.read<SelectionCubit>().updateError(
                                          widget.component,
                                          message,
                                          AnalysisErrorType.parameter,
                                        );
                                  },
                                  config: FVBEditorConfig(
                                      parentProcessorGiven: true,
                                      smallBottomBar: true,
                                      multiline: false,
                                      shrink: true),
                                  processor: processor),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Text(
                            'Default',
                            style: AppFontStyle.lato(13,
                                fontWeight: FontWeight.w500,
                                color: theme.text3Color),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          if (variable.dataType.equals(fvbColor)) ...[
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: variable.value?.toDart(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                          Text(
                            LocalModel.valueToCode(variable.value),
                            style: AppFontStyle.lato(14,
                                fontWeight: FontWeight.normal,
                                color: theme.text1Color),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              itemCount: widget.component.argumentVariables.length,
              shrinkWrap: true,
            )
          ],
        );
      },
    );
  }
}
