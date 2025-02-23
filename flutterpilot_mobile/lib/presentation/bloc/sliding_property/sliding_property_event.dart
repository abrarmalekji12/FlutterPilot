part of 'sliding_property_bloc.dart';

@immutable
abstract class SlidingPropertyEvent {}

class SlidingPropertyChange extends SlidingPropertyEvent {
  final double value;

  SlidingPropertyChange({required this.value});
}
