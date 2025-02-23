part of 'component_creation_cubit.dart';

@immutable
abstract class CreationState {}

class ComponentCreationInitial extends CreationState {}

class ComponentCreationLoadingState extends CreationState {}

class ComponentCreationChangeState extends CreationState {
  ComponentCreationChangeState({this.ancestor});
  final CustomComponent? ancestor;
}

// class ComponentSavedState extends ComponentCreationState {
//   ComponentSavedState();
// }
class CustomComponentCreationChangeState extends CreationState {
  final Component rebuildComponent;
  final Component? ancestor;
  CustomComponentCreationChangeState(this.rebuildComponent, this.ancestor);
}
