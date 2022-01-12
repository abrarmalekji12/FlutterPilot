part of 'component_operation_cubit.dart';

@immutable
abstract class ComponentOperationState {}

class ComponentOperationInitial extends ComponentOperationState {}

class ComponentOperationLoadingState extends ComponentOperationState {

}
class GlobalComponentLoadedState extends ComponentOperationState {
  GlobalComponentLoadedState();
}
class ComponentUpdatedState extends ComponentOperationState {}

