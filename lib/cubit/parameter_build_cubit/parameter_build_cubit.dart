import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/constant/app_colors.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(paramRule.errorText!,style: AppFontStyle.roboto(15,color: Colors.black,fontWeight: FontWeight.w500,),textAlign: TextAlign.center,),
          backgroundColor: AppColors.DADADA,
      ));
      }
    }
    else {
      emit(ParameterChangeState(parameter));
    }
  }
}
