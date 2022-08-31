part of 'api_bloc.dart';

@immutable
abstract class ApiState {}

class ApiInitial extends ApiState {}

class ApiLoadingState extends ApiState{

}
class ApiErrorState extends ApiState{
  final String error;
  ApiErrorState(this.error);
}
class ApiResponseState extends ApiState{
  final  ApiResponseModel model;
  ApiResponseState(this.model);
}