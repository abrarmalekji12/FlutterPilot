import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/compiler/code_processor.dart';
import '../common/dynamic_value_filed.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../models/component_model.dart';

class CustomComponentProperty extends StatefulWidget {
  final CustomComponent component;

  const CustomComponentProperty({Key? key, required this.component})
      : super(key: key);

  @override
  State<CustomComponentProperty> createState() =>
      _CustomComponentPropertyState();
}

class _CustomComponentPropertyState extends State<CustomComponentProperty> {
  final TextEditingController _controller = TextEditingController();
  late FVBFunction? constructor;

  @override
  void initState() {
    widget.component.processor.destroyProcess(deep: false);
    widget.component.processor.executeCode(widget.component.actionCode);
    constructor = widget.component.processor.functions[widget.component.name];
    if (constructor != null && widget.component.arguments == null) {
      widget.component.arguments =
          List.filled(constructor!.arguments.length, '');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (constructor != null && constructor!.arguments.isNotEmpty) ...[
          const SizedBox(
            height: 10,
          ),
          Text(
            'Constructor Arguments',
            style: AppFontStyle.roboto(14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 15,
          ),
          ListView.builder(
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      constructor!.arguments[index].name,
                      style:
                          AppFontStyle.roboto(14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      DataType.dataTypeToCode(
                              constructor!.arguments[index].dataType) +
                          (constructor!.arguments[index].nullable ? '?' : ''),
                      style: AppFontStyle.roboto(14,
                          fontWeight: FontWeight.w600, color: AppColors.theme),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: DynamicValueField(
                          onProcessedResult: (code, value) {
                            widget.component.arguments![index] = code;
                            context.read<ComponentOperationCubit>().refreshPropertyChanges(context.read<ComponentSelectionCubit>());
                            context.read<ComponentCreationCubit>().changedComponent();
                            return true;
                          },
                          processor: widget.component.processor,
                          textEditingController: _controller),
                    )
                  ],
                ),
              );
            },
            itemCount: constructor!.arguments.length,
            shrinkWrap: true,
          )
        ]
      ],
    );
  }
}
