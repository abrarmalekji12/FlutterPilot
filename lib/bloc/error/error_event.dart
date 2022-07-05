part of 'error_bloc.dart';

@immutable
abstract class ErrorEvent {}

// Error updated event
class ConsoleUpdatedEvent extends ErrorEvent {
  final ConsoleMessage consoleMessage;
  ConsoleUpdatedEvent(this.consoleMessage);
}

class ClearMessageEvent extends ErrorEvent {
  ClearMessageEvent();
}
