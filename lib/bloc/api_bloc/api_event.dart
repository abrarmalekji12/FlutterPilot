part of 'api_bloc.dart';

@immutable
abstract class ApiEvent {}

class ApiFireEvent extends ApiEvent {
  final ApiViewModel apiViewModel;
  ApiFireEvent(this.apiViewModel);
}
