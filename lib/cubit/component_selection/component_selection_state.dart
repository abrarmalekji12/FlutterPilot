part of 'component_selection_cubit.dart';

@immutable
abstract class ComponentSelectionState {}

class ComponentSelectionInitial extends ComponentSelectionState {}

class ComponentSelectionChange extends ComponentSelectionState {
  ComponentSelectionChange();
}
