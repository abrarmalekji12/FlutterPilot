part of 'parameter_build_cubit.dart';

@immutable
abstract class ParameterBuildState {}

class ParameterBuildInitial extends ParameterBuildState {}

class ParameterChangeState extends ParameterBuildState {
  ParameterChangeState(this.parameter);
  final Parameter parameter;
}
