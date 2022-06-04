import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'action_edit_state.dart';

class ActionEditCubit extends Cubit<ActionEditState> {
  ActionEditCubit() : super(ActionEditInitial());

  void change() {
    emit(ActionChangeState());
  }
}
