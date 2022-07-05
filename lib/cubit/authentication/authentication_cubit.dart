import 'package:bloc/bloc.dart';
import '../../common/shared_preferences.dart';
import '../../constant/preference_key.dart';
import '../../firestore/firestore_bridge.dart';
import 'package:meta/meta.dart';

import '../../view_model/auth_viewmodel.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final AuthViewModel authViewModel = AuthViewModel();
  AuthenticationCubit() : super(AuthenticationInitial());

  Future<void> loginWithPreferences() async {
    // emit(AuthLoadingState());
    try {
      final response = await FireBridge.tryLoginWithPreference();
      if (response != null) {
        authViewModel.userId = response;
        emit(AuthSuccessState(response));
      } else {
        emit(AuthenticationInitial());
      }
    } on Exception catch (error) {
      final errorMsg = error.toString();
      Preferences.remove(PrefKey.UID);
      emit(AuthErrorState(errorMsg.substring(errorMsg.indexOf(']') + 1)));
    }
  }

  Future<void> login(String userName, String password) async {
    emit(AuthLoadingState());
    try {
      final response = await FireBridge.login(userName, password);
      if (response.userId != null) {
        authViewModel.userId = response.userId;
        emit(AuthSuccessState(response.userId!));
      } else {
        emit(AuthFailedState(response.error ?? ''));
      }
    } on Exception catch (error) {
      final errorMsg = error.toString();
      emit(AuthErrorState(errorMsg.substring(errorMsg.indexOf(']') + 1)));
    }
  }

  Future<void> logout() async {
    emit(AuthLoadingState());
    try {
      await FireBridge.logout();
      emit(AuthSuccessState(-1));
    } on Exception catch (error) {
      final errorMsg = error.toString();
      emit(AuthErrorState(errorMsg.substring(errorMsg.indexOf(']') + 1)));
    }
  }

  Future<void> resetPassword(final String userName) async {
    emit(AuthLoadingState());

    try {
      final response = await FireBridge.resetPassword(userName);
      if (response == null) {
        emit(AuthResetPasswordSuccessState());
      } else {
        emit(AuthFailedState(response));
      }
    } on Exception catch (error) {
      final errorMsg = error.toString();
      emit(AuthErrorState(errorMsg.substring(errorMsg.indexOf(']') + 1)));
    }
  }

  Future<void> register(String userName, String password) async {
    emit(AuthLoadingState());
    try {
      final response = await FireBridge.registerUser(userName, password);
      if (response.userId != null) {
        authViewModel.userId = response.userId;
        emit(AuthSuccessState(response.userId!));
      } else {
        emit(AuthFailedState(response.error ?? ''));
      }
    } on Exception catch (error) {
      emit(AuthErrorState(error.toString()));
    }
  }
}
