part of 'home_cubit.dart';

@immutable
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeCustomComponentPreviewUpdatedState extends HomeState {
  final int index;

  HomeCustomComponentPreviewUpdatedState(this.index);
}
