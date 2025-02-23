part of 'visual_box_cubit.dart';

@immutable
abstract class VisualBoxState {}

class VisualBoxInitial extends VisualBoxState {}

class VisualBoxUpdatedState extends VisualBoxState {
  final Viewable? screen;

  VisualBoxUpdatedState(this.screen);
}

class VisualBoxHoverUpdatedState extends VisualBoxState {
  final List<Boundary> boundaries;
  final Viewable? screen;

  VisualBoxHoverUpdatedState(this.boundaries, this.screen);
}
