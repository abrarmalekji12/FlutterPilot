part of 'api_bloc.dart';

@immutable
abstract class FVBApiState {}

class ApiInitial extends FVBApiState {}

class ApiLoadingState extends FVBApiState {
  final ApiProcessedModel processed;

  ApiLoadingState(this.processed);
}

class ApiErrorState extends FVBApiState {
  final String error;
  ApiErrorState(this.error);
}

class ApiProcessingErrorState extends FVBApiState {
  final List<String> list;
  ApiProcessingErrorState(this.list);
}

class ApiResponseState extends FVBApiState {
  final ApiResponseModel model;
  final ApiProcessedModel processed;
  ApiResponseState(this.model, this.processed);
}
