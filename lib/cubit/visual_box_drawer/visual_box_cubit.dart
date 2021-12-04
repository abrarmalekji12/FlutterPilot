import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'visual_box_state.dart';

class VisualBoxCubit extends Cubit<VisualBoxState> {
  String? errorMessage;
  VisualBoxCubit() : super(VisualBoxInitial());

  void visualUpdated(){
    emit(VisualBoxUpdatedState());
  }

  void enableError(String message){
    errorMessage=message;
    emit(VisualBoxUpdatedState());
  }
}
