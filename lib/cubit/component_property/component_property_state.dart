part of 'component_property_cubit.dart';

@immutable
abstract class ComponentCreationState {}

class ComponentPropertyInitial extends ComponentCreationState {}

class ComponentPropertyChangeState extends ComponentCreationState {
  final Component rebuildComponent;
  ComponentPropertyChangeState(this.rebuildComponent);
}
