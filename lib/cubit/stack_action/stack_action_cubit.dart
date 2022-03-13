import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../models/actions/action_model.dart';

part 'stack_action_state.dart';

class StackActionCubit extends Cubit<StackActionState> {
  final List<ActionModel> models=[];
  StackActionCubit() : super(StackActionInitial());

  void showSimpleDialog(final ShowDialogInStackAction model){
    models.add(model);
    emit(StackUpdatedState());
  }
  void showCustomSimpleDialog(final ShowCustomDialogInStackAction model){
    models.add(model);
    emit(StackUpdatedState());
  }

  void back(){
    if(models.isNotEmpty) {
      models.removeAt(models.length-1);
      emit(StackUpdatedState());
    }
  }
}
