import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';

import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../models/variable_model.dart';
import '../../widgets/overlay/overlay_manager.dart';
import '../navigation/animated_slider.dart';
import '../variable_ui.dart';

class VariableDialogOption {
  final String name;
  final void Function(VariableModel) callback;

  VariableDialogOption(this.name, this.callback);
}

class VariableDialog {
  final String title;
  final OperationCubit componentOperationCubit;
  final CreationCubit componentCreationCubit;
  final SelectionCubit componentSelectionCubit;
  final void Function(FVBVariable) onAdded;
  final void Function(FVBVariable) onEdited;
  final void Function(FVBVariable) onDeleted;
  final Map<String, FVBVariable> variables;
  final List<VariableDialogOption> options;
  final AnimatedSlider _slider = AnimatedSlider();

  VariableDialog({
    required this.componentOperationCubit,
    required this.componentCreationCubit,
    required this.title,
    required this.onAdded,
    required this.onEdited,
    required this.onDeleted,
    required this.componentSelectionCubit,
    required this.variables,
    this.options = const [],
  });

  void show(BuildContext context, OverlayManager manager, GlobalKey key) {
    if (_slider.visible) {
      return;
    }
    _slider.show(
      context,
      manager,
      Material(
        color: Colors.transparent,
        child: Center(
          child: SizedBox(
            width: 340,
            child: VariableBox(
              componentCreationCubit: componentCreationCubit,
              componentOperationCubit: componentOperationCubit,
              componentSelectionCubit: componentSelectionCubit,
              onAdded: onAdded,
              title: title,
              onChanged: onEdited,
              variables: variables,
              onDeleted: onDeleted,
              options: options,
            ),
          ),
        ),
      ),
      key,
      height: 600,
    );
  }

  void hide() {
    _slider.hide();
  }
}
