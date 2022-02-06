import 'package:bloc/bloc.dart';
import '../../firestore/firestore_bridge.dart';
import 'package:meta/meta.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit() : super(AuthenticationInitial());

  Future<void> login(String userName, String password) async {
    emit(AuthLoadingState());
    try {
      final id = await FireBridge.login(userName, password);
      if (id != null) {
        emit(AuthSuccessState(id));
      } else {
        emit(AuthFailedState('Wrong Username and/or Password'));
      }
    } on Exception {
      emit(AuthErrorState('Something went wrong'));
    }
  }
}
