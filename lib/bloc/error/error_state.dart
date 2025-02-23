part of 'error_bloc.dart';

@immutable
abstract class ErrorState {}

class ErrorInitial extends ErrorState {}

class ErrorUpdatedState extends ErrorState {
  ErrorUpdatedState();
}

class BugReportState extends ErrorState {
  final String error;

  BugReportState(this.error);
}
