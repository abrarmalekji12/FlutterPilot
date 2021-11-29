part of 'component_creation_cubit.dart';

@immutable
abstract class ComponentCreationState {}

class ComponentCreationInitial extends ComponentCreationState {}

class ComponentCreationChangeState extends ComponentCreationState {
  final Component rebuildComponent;
  ComponentCreationChangeState(this.rebuildComponent);
}
