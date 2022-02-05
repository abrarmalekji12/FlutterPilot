import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../constant/font_style.dart';
import '../component_selection/component_selection_cubit.dart';
import '../../models/parameter_model.dart';


part 'parameter_build_state.dart';

class ParameterBuildCubit extends Cubit<ParameterBuildState> {
  ParameterBuildCubit() : super(ParameterBuildInitial());

  void parameterChanged(BuildContext context, Parameter parameter) {
    final selectedComponent =
        BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
            .currentSelected;
    final paramRule=selectedComponent.validateParameters(parameter);
    if(paramRule!=null){
      emit(ParameterChangeState(paramRule.changedParameter));
      emit(ParameterChangeState(paramRule.anotherParameter));
      if(paramRule.errorText!=null) {
        Fluttertoast.showToast(msg: paramRule.errorText!,toastLength: Toast.LENGTH_LONG,timeInSecForIosWeb: 3);
      }
    }
    else {
      emit(ParameterChangeState(parameter));
    }
  }
}
