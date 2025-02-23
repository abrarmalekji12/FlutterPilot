part of 'component_drag_bloc.dart';

@immutable
abstract class ComponentDragEvent {}

class ComponentDraggingEvent extends ComponentDragEvent {
  final DragArea area;

  ComponentDraggingEvent(this.area);
}

class ComponentInitialEvent extends ComponentDragEvent {}
