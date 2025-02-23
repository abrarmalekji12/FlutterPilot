part of 'parameter_build_cubit.dart';

@immutable
abstract class ParameterBuildState {}

class ParameterBuildInitial extends ParameterBuildState {}

class ParameterChangeState extends ParameterBuildState {
  ParameterChangeState(this.parameter, {this.refresh = true, this.component});
  final Parameter parameter;
  final Component? component;
  final bool refresh;
}

class ParameterAlteredState extends ParameterBuildState {
  ParameterAlteredState(this.parameter);
  final Parameter parameter;
}
