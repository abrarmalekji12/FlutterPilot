import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

part 'component_operation_state.dart';

class ComponentOperationCubit extends Cubit<ComponentOperationState> {
  Component rootComponent;
  ComponentOperationCubit(this.rootComponent) : super(ComponentOperationInitial());
  void addedComponent(BuildContext context,Component component){
    Provider.of<ComponentSelectionCubit>(context,listen: false).changeComponentSelection(component);
    emit(ComponentUpdatedState());
  }

  void removedComponent(BuildContext context,Component component){
    Provider.of<ComponentSelectionCubit>(context,listen: false).changeComponentSelection(component.parent!);
    emit(ComponentUpdatedState());
  }
}
