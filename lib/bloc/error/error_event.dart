part of 'error_bloc.dart';

@immutable
abstract class ErrorEvent {}

// Error updated event
class ConsoleUpdatedEvent extends ErrorEvent {
  final ConsoleMessage consoleMessage;
  ConsoleUpdatedEvent(this.consoleMessage);
}

class ClearMessageEvent extends ErrorEvent {
  final RuntimeMode mode;
  ClearMessageEvent(this.mode);
}

class ClearComponentMessageEvent extends ErrorEvent {
  final String componentId;
  ClearComponentMessageEvent(this.componentId);
}

class HandleBugReportEvent extends ErrorEvent {
  final String error;

  HandleBugReportEvent(this.error);
}
