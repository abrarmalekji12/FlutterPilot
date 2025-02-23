import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'click_action_state.dart';

class ClickActionCubit extends Cubit<ClickActionState> {
  ClickActionCubit() : super(ClickActionInitial());

  void changedState() {
    emit(ClickActionListChangeState());
  }
}
