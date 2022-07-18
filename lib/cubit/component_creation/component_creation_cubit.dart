import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../models/component_model.dart';

part 'component_creation_state.dart';

class ComponentCreationCubit extends Cubit<ComponentCreationState> {
  ComponentCreationCubit() : super(ComponentCreationInitial());

  void changedComponent({CustomComponent? ancestor}) {
    emit(ComponentCreationChangeState(ancestor: ancestor));
  }
}
