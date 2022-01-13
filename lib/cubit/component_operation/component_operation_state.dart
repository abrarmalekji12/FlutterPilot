part of 'component_operation_cubit.dart';

@immutable
abstract class ComponentOperationState {}

class ComponentOperationInitial extends ComponentOperationState {}

class ComponentOperationLoadingState extends ComponentOperationState {

}

class ProjectLoadedState extends ComponentOperationState {
  ProjectLoadedState();
}
class ComponentUpdatedState extends ComponentOperationState {}

