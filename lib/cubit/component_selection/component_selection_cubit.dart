import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:get/get.dart';

import '../../injector.dart';
import '../../models/actions/action_model.dart';
import '../../models/component_selection.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/parameter_model.dart';
import '../../ui/paint_tools/paint_tools.dart';
import '../../ui/visual_model.dart';

part 'component_selection_state.dart';

enum AnalysisErrorType { parameter, code, overflow }

class ErrorComponent {
  final Component component;
  final Parameter? parameter;
  final CustomAction? action;
  final String errorMessage;
  final AnalysisErrorType errorType;

  ErrorComponent(this.component, this.parameter, this.action, this.errorMessage,
      this.errorType);
}

class SelectionCubit extends Cubit<SelectionState> {
  ComponentSelectionModel selected = ComponentSelectionModel.empty();
  Component? lastTapped;
  List<ErrorComponent> errorList = [];

  SelectionCubit() : super(ComponentSelectionInitial());

  Component get currentSelectedRoot => selected.root;

  List<Boundary> getErrorBoundaries(BuildContext context) {
    if (errorList.isNotEmpty) {
      return [
        for (final error in errorList)
          Boundary(error.component.boundary ?? Rect.zero, error.component,
              errorMessage: error.errorMessage.isNotEmpty
                  ? error.errorMessage
                  : '${error.component.name}${error.parameter != null ? '-> ${error.parameter!.displayName} = ${error.parameter!.compiler.code}' : ''}',
              onTap: () {
            final ancestor = error.component.ancestor;
            sl<SelectionCubit>().changeComponentSelection(
              ComponentSelectionModel.unique(
                error.component,
                ancestor.component,
                screen: ancestor.screen,
              ),
              parameter: error.parameter,
            );
          })
      ];
    }
    return [];
  }

  bool isErrorEnable(Component other) {
    for (final error in errorList) {
      if (error.component.id == other.id ||
          (error.component is CustomComponent &&
              other is CustomComponent &&
              other.name == error.component.name)) {
        return true;
      }
    }
    return false;
  }

  void init(
    ComponentSelectionModel currentSelected,
  ) {
    this.selected = currentSelected;
  }

  void changeComponentSelection(ComponentSelectionModel component,
      {bool scroll = true, Parameter? parameter}) {
    if (selected != component) {
      final oldModel = selected;
      selected = component;
      // logger('==== ComponentSelectionCubit ** changeComponentSelection == ${component.name} ${root.name}');
      emit(SelectionChangeState(selected, oldModel,
          scroll: scroll, parameter: parameter));
    }
  }

  void refresh() {
    emit(SelectionChangeState(selected, selected));
  }

  void updateError(Component component, String? message, AnalysisErrorType type,
      {Parameter? param,
      PaintParameter? paintParameter,
      CustomAction? action}) {
    if (message == null) {
      hideError(component, param);
    } else {
      showError(component, message, type, param: param, action: action);
    }
  }

  void showError(Component component, String message, AnalysisErrorType type,
      {Parameter? param,
      PaintParameter? paintParameter,
      CustomAction? action}) {
    if (disableError) {
      return;
    }
    final pIndex = param != null ? component.parameters.indexOf(param) : -1;
    if (errorList.firstWhereOrNull((element) =>
            element.component.id == component.id &&
            (param == null ||
                (element.parameter != null &&
                    element.component.parameters.indexOf(element.parameter!) ==
                        pIndex))) ==
        null) {
      errorList.add(ErrorComponent(component, param, action, message, type));
      emit(ComponentSelectionErrorChangeState());
    }
  }

  void hideError(Component component, Parameter? param) {
    final list = errorList
        .where((element) =>
            element.component.id == component.id &&
            (param == null || param == element.parameter))
        .toList(growable: false);
    if (list.isNotEmpty) {
      for (final value in list) errorList.remove(value);
      emit(ComponentSelectionErrorChangeState());
    }
  }

  bool isSelectedInTree(Component component) {
    return selected.treeSelection.contains(component);
  }

  void clearErrors([String? id]) {
    if (id == null) {
      errorList.clear();
    } else {
      errorList.removeWhere((element) => element.component.id == id);
    }
    emit(ComponentSelectionErrorChangeState());
  }
}
