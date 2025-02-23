import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/preference_key.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../user_session.dart';
import '../../view_model/auth_viewmodel.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final UserSession _userSession;
  final SharedPreferences _pref;

  AuthenticationCubit(this._pref, this._userSession)
      : super(AuthenticationInitial());

  Future<void> loginWithPreferences() async {
    emit(AuthLoadingState());
    try {
      final response = await dataBridge.tryLoginWithPreference();
      if (response != null) {
        _userSession.user = response;
        _userSession.settingModel =
            await dataBridge.loadUserDetails(_userSession.user.userId!);
        emit(AuthLoginSuccessState(response.userId!));
      }
      emit(AuthenticationInitial());
    } on Exception catch (error) {
      final errorMsg = error.toString();
      emit(AuthErrorState(errorMsg.substring(errorMsg.indexOf(']') + 1)));
    }
  }

  void initial() {
    emit(AuthenticationInitial());
  }

  Future<void> login(String userName, String password) async {
    emit(AuthLoadingState());
    final response = await dataBridge.login(userName, password);
    if (response.user != null) {
      _userSession.user = response.user!;
      await _pref.setString(PrefKey.UID, response.user!.userId!);
      emit(AuthLoginSuccessState(response.user!.userId!));
      emit(AuthenticationInitial());
    } else {
      emit(AuthFailedState(response.error ?? ''));
    }
  }

  Future<void> logout() async {
    emit(AuthLoadingState());
    try {
      await dataBridge.logout();
      await _pref.clear();
      _userSession.user = FVBUser();
      _userSession.settingModel = null;
      emit(AuthLogoutSuccessState());
    } on Exception catch (error) {
      final errorMsg = error.toString();
      emit(AuthErrorState(errorMsg.substring(errorMsg.indexOf(']') + 1)));
    }
  }

  Future<void> resetPassword(final String userName) async {
    emit(AuthLoadingState());

    try {
      final response = await dataBridge.resetPassword(userName);
      if (response == null) {
        emit(AuthResetPasswordSuccessState());
        emit(AuthenticationInitial());
      } else {
        emit(AuthFailedState(response));
      }
    } on Exception catch (error) {
      final errorMsg = error.toString();
      emit(AuthErrorState(errorMsg.substring(errorMsg.indexOf(']') + 1)));
    }
  }

  Future<void> register(FVBUser model) async {
    emit(AuthLoadingState());
    try {
      final response = await dataBridge.registerUser(model);
      if (response.user != null) {
        _userSession.user = response.user!;

        _pref.setString(PrefKey.UID, model.userId!);
        final userData = model.toJson(includePass: true);
        _pref.setString(PrefKey.userData, jsonEncode(userData));
        emit(AuthLoginSuccessState(response.user!.userId!));
        emit(AuthenticationInitial());
      } else {
        emit(AuthFailedState(response.error ?? ''));
      }
    } on Exception catch (error) {
      emit(AuthErrorState(error.toString()));
    }
  }
}
