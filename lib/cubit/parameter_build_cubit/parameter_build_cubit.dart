import 'package:bloc/bloc.dart';
import 'package:flutter_builder/parameter_model.dart';
import 'package:meta/meta.dart';

import '../../component_model.dart';

part 'parameter_build_state.dart';

class ParameterBuildCubit extends Cubit<ParameterBuildState> {
  ParameterBuildCubit() : super(ParameterBuildInitial());

  void parameterChanged(Parameter parameter){
    emit(ParameterChangeState(parameter));
  }
}
