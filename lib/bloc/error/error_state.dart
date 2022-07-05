part of 'error_bloc.dart';

@immutable
abstract class ErrorState {}

class ErrorInitial extends ErrorState {}

class ErrorUpdatedState extends ErrorState {
  ErrorUpdatedState();
}
