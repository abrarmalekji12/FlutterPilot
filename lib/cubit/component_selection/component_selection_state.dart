part of 'component_selection_cubit.dart';

@immutable
abstract class SelectionState {}

class ComponentSelectionInitial extends SelectionState {}

class SelectionChangeState extends SelectionState {
  final ComponentSelectionModel model;
  final ComponentSelectionModel oldModel;
  SelectionChangeState(this.model, this.oldModel,
      {this.scroll = true, this.parameter, this.paintParameter});
  final bool scroll;
  final PaintParameter? paintParameter;
  final Parameter? parameter;
}

class ComponentSelectionErrorChangeState extends SelectionState {
  ComponentSelectionErrorChangeState();
}
