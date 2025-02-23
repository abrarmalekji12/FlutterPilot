import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/common_methods.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/parameter_model.dart';
import '../component_selection/component_selection_cubit.dart';

part 'parameter_build_state.dart';

class ParameterBuildCubit extends Cubit<ParameterBuildState> {
  final SelectionCubit _selectionCubit;
  ParameterBuildCubit(this._selectionCubit) : super(ParameterBuildInitial());

  void parameterChanged(Parameter parameter,
      {bool refresh = true, Component? component}) {
    final selectedComponent = _selectionCubit.selected;
    final paramRule =
        selectedComponent.propertySelection.validateParameters(parameter);
    if (paramRule != null) {
      emit(ParameterChangeState(paramRule.changedParameter,
          refresh: refresh, component: component));
      emit(ParameterChangeState(paramRule.anotherParameter,
          refresh: refresh, component: component));
      if (paramRule.errorText != null) {
        showToast(paramRule.errorText!, error: true);
      }
    } else {
      emit(ParameterChangeState(parameter,
          refresh: refresh, component: component));
    }
  }

  void paramAltered(List<Parameter> parameters) {
    for (final param in parameters) {
      emit(ParameterAlteredState(param));
    }
  }
}
