import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../component_selection/component_selection_cubit.dart';

part 'component_creation_state.dart';

class CreationCubit extends Cubit<CreationState> {
  final SelectionCubit _componentSelectionCubit;

  CreationCubit(this._componentSelectionCubit)
      : super(ComponentCreationInitial());

  void changedComponent({Component? ancestor}) {
    emit(ComponentCreationChangeState(
        ancestor: (ancestor is CustomComponent ? ancestor : null) ??
            (_componentSelectionCubit.currentSelectedRoot is CustomComponent
                ? (_componentSelectionCubit.currentSelectedRoot
                    as CustomComponent)
                : null)));
  }
}
