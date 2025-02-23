part of 'api_bloc.dart';

@immutable
abstract class ApiEvent {}

class ApiFireEvent extends ApiEvent {
  final ApiViewModel apiViewModel;
  ApiFireEvent(this.apiViewModel);
}

class ApiTestEvent extends ApiEvent {
  final ApiProcessedModel apiViewModel;
  ApiTestEvent(this.apiViewModel);
}

class ApiProcessingErrorEvent extends ApiEvent {
  final List<String> errorList;
  ApiProcessingErrorEvent(this.errorList);
}
