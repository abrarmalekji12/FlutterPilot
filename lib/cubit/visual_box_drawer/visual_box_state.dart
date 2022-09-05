part of 'visual_box_cubit.dart';

@immutable
abstract class VisualBoxState {}

class VisualBoxInitial extends VisualBoxState {}

class VisualBoxUpdatedState extends VisualBoxState {}
class VisualBoxHoverUpdatedState extends VisualBoxState {
  final List<Boundary> boundaries;

  VisualBoxHoverUpdatedState(this.boundaries);
}