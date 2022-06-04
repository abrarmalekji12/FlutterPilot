part of 'component_creation_cubit.dart';

@immutable
abstract class ComponentCreationState {}

class ComponentCreationInitial extends ComponentCreationState {}

class ComponentCreationLoadingState extends ComponentCreationState {}

class ComponentCreationChangeState extends ComponentCreationState {
  ComponentCreationChangeState();
}

// class ComponentSavedState extends ComponentCreationState {
//   ComponentSavedState();
// }
class CustomComponentCreationChangeState extends ComponentCreationState {
  final Component rebuildComponent;
  final Component? ancestor;
  CustomComponentCreationChangeState(this.rebuildComponent, this.ancestor);
}
