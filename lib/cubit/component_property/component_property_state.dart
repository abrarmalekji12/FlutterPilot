part of 'component_property_cubit.dart';

@immutable
abstract class ComponentPropertyState {}

class ComponentPropertyInitial extends ComponentPropertyState {}

class ComponentPropertyChangeState extends ComponentPropertyState {
  final Component rebuildComponent;
  ComponentPropertyChangeState(this.rebuildComponent);
}
