part of 'component_operation_cubit.dart';

@immutable
abstract class ComponentOperationState {}

class ComponentOperationInitial extends ComponentOperationState {}

class ComponentOperationLoadingState extends ComponentOperationState {

}

class ComponentLoadBytesState extends ComponentOperationState {
  ComponentLoadBytesState(this.bytes);
  final Uint8List? bytes;
}
class ComponentOperationErrorState extends ComponentOperationState{
  ComponentOperationErrorState();
}

class ComponentUpdatedState extends ComponentOperationState {
  ComponentUpdatedState();
}

