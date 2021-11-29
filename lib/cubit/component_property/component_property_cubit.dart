import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import '../../component_model.dart';

part 'component_property_state.dart';

class ComponentCreationCubit extends Cubit<ComponentCreationState> {
  ComponentCreationCubit() : super(ComponentPropertyInitial());

  void changedProperty(BuildContext context,{Component? addedComp}){
    final component=addedComp??Provider.of<ComponentSelectionCubit>(context,
        listen: false).currentSelected;
    if(component.parent is CustomNamedHolder) {
      emit(ComponentPropertyChangeState(component.parent!));
    }
    else{
      emit(ComponentPropertyChangeState(component));
    }
  }
}
