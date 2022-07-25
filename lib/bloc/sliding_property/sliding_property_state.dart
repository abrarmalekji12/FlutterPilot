part of 'sliding_property_bloc.dart';

@immutable
abstract class SlidingPropertyState {}

class SlidingPropertyInitial extends SlidingPropertyState {}

class SlidingPropertyChangeState extends SlidingPropertyState {
  final double value;

  SlidingPropertyChangeState({required this.value});
}