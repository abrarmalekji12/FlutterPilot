import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'component_drag_event.dart';
part 'component_drag_state.dart';

enum DragArea { tree, center, all }

class ComponentDragBloc extends Bloc<ComponentDragEvent, ComponentDragState> {
  DragArea? _area;
  ComponentDragBloc() : super(ComponentDragInitial(DragArea.all)) {
    on<ComponentDragEvent>((event, emit) {});
    on<ComponentInitialEvent>((event, emit) {
      emit(ComponentDragInitial(_area ?? DragArea.all));
    });
    on<ComponentDraggingEvent>(_componentDragging);
  }

  FutureOr<void> _componentDragging(
      ComponentDraggingEvent event, Emitter<ComponentDragState> emit) {
    _area = event.area;
    emit(ComponentDraggingState(event.area));
  }
}
