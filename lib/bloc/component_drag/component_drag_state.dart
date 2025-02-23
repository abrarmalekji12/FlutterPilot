part of 'component_drag_bloc.dart';

@immutable
abstract class ComponentDragState {}

class ComponentDragInitial extends ComponentDragState {
  final DragArea area;
  ComponentDragInitial(this.area);
}

class ComponentDraggingState extends ComponentDragState {
  final DragArea area;

  ComponentDraggingState(this.area);
}
