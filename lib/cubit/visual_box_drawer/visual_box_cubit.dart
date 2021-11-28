import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'visual_box_state.dart';

class VisualBoxCubit extends Cubit<VisualBoxState> {
  VisualBoxCubit() : super(VisualBoxInitial());

  void visualUpdated(){
    emit(VisualBoxUpdatedState());
  }
}
