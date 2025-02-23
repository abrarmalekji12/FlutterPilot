part of 'paint_obj_bloc.dart';

@immutable
abstract class PaintObjState {}

class PaintObjInitial extends PaintObjState {}

class PaintObjUpdateState extends PaintObjState {
  final FVBPaintObj obj;
  final bool refreshField;

  PaintObjUpdateState(this.obj, {this.refreshField = true});
}

class PaintObjRemoveState extends PaintObjState {
  PaintObjRemoveState();
}

class PaintObjSelectionUpdatedState extends PaintObjState {
  final FVBPaintObj? obj;
  PaintObjSelectionUpdatedState(this.obj);
}
