import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../models/actions/action_model.dart';
import '../../models/project_model.dart';
import '../component_operation/component_operation_cubit.dart';

part 'stack_action_state.dart';

enum StackOperation {
 push,
 replace,
 addOverlay,
 pop
}
class Route{
  final UIScreen uiScreen;
  final bool overlay;

  Route(this.uiScreen, {this.overlay=false});
}
class StackActionCubit extends Cubit<StackActionState> {
  final List<ActionModel> models=[];
  final List<Route> navigationStack=[];
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

  void stackOperation(final StackOperation operation,{UIScreen? uiScreen}) {
    switch(operation){
      case StackOperation.push:
        navigationStack.add(Route(uiScreen!));
        ComponentOperationCubit.changeVariables(uiScreen);
        break;
      case StackOperation.replace:
        final last=navigationStack.removeLast();
        navigationStack.add(Route(uiScreen!));
        ComponentOperationCubit.removeVariables(last.uiScreen);
        ComponentOperationCubit.addVariables(uiScreen);
        break;
      case StackOperation.addOverlay:
        navigationStack.add(Route(uiScreen!,overlay: true));
        ComponentOperationCubit.addVariables(uiScreen);
        break;
      case StackOperation.pop:
        if(navigationStack.isEmpty){
          throw Exception('Navigation Stack is Empty !! ');
        }
        final last=navigationStack.removeLast();
        ComponentOperationCubit.removeVariables(last.uiScreen);
        int index=navigationStack.length;
        do{
          index--;
          ComponentOperationCubit.addVariables(navigationStack[index].uiScreen);
        }while(navigationStack[index].overlay);
        break;
    }
  }

}
