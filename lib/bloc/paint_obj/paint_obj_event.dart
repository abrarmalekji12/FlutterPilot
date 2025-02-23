part of 'paint_obj_bloc.dart';

@immutable
abstract class PaintObjEvent {}

class UpdatePaintObjEvent extends PaintObjEvent {
  final FVBPaintObj obj;
  final bool refreshField;
  final bool save;

  UpdatePaintObjEvent(this.obj, {this.refreshField = true, this.save = false});
}

class RemovePaintObjEvent extends PaintObjEvent {}

class UpdatePaintObjSelectionEvent extends PaintObjEvent {
  final FVBPaintObj? obj;

  UpdatePaintObjSelectionEvent(this.obj);
}
