import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/compiler/code_processor.dart';
import '../../common/compiler/fvb_function_variables.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../models/variable_model.dart';
import '../variable_ui.dart';

class VariableDialogOption {
  final String name;
  final void Function(VariableModel) callback;

  VariableDialogOption(this.name, this.callback);
}

class VariableDialog {
  final String title;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentCreationCubit componentCreationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final void Function(VariableModel) onAdded;
  final void Function(VariableModel) onEdited;
  final void Function(VariableModel) onDeleted;
  final Map<String, FVBVariable> variables;
  late final OverlayEntry _overlayEntry;
  final List<VariableDialogOption> options;

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
  }) {
    _overlayEntry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.transparent,
        child: Center(
          child: SizedBox(
            width: 500,
            child: VariableBox(
              componentCreationCubit: componentCreationCubit,
              componentOperationCubit: componentOperationCubit,
              componentSelectionCubit: componentSelectionCubit,
              overlayEntry: _overlayEntry,
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
    );
  }

  void show(BuildContext context) {
    Overlay.of(context)!.insert(_overlayEntry);
  }

  void hide() {
    _overlayEntry.remove();
  }
}
