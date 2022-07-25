import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../models/component_model.dart';
import '../component_selection/component_selection_cubit.dart';

part 'component_creation_state.dart';

class ComponentCreationCubit extends Cubit<ComponentCreationState> {
  final ComponentSelectionCubit _componentSelectionCubit;

  ComponentCreationCubit(this._componentSelectionCubit)
      : super(ComponentCreationInitial());

  void changedComponent({CustomComponent? ancestor}) {
    emit(ComponentCreationChangeState(
        ancestor: ancestor ??
            (_componentSelectionCubit.currentSelectedRoot is CustomComponent
                ?( _componentSelectionCubit.currentSelectedRoot
                    as CustomComponent)
                : null)));
  }
}
