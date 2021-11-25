import 'package:bloc/bloc.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:meta/meta.dart';

part 'component_operation_state.dart';

class ComponentOperationCubit extends Cubit<ComponentOperationState> {
  Component rootComponent;
  ComponentOperationCubit(this.rootComponent) : super(ComponentOperationInitial());
  void changedComponent(){
    emit(ComponentUpdatedState());
  }
}
