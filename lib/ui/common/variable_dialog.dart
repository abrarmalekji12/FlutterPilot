import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/compiler/code_processor.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../models/variable_model.dart';
import '../variable_ui.dart';

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

  VariableDialog({
    required this.componentOperationCubit,
    required this.componentCreationCubit,
    required this.title,
    required this.onAdded,
    required this.onEdited,
    required this.onDeleted,
    required this.componentSelectionCubit,
    required this.variables,
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
