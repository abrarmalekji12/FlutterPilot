part of 'authentication_cubit.dart';

@immutable
abstract class AuthenticationState {}

class AuthenticationInitial extends AuthenticationState {}

class AuthLoadingState extends AuthenticationState {
  AuthLoadingState();
}

class AuthErrorState extends AuthenticationState {
  AuthErrorState(this.message);

  final String message;
}

class AuthLoginSuccessState extends AuthenticationState {
  final String userId;

  AuthLoginSuccessState(this.userId);
}

class AuthLogoutSuccessState extends AuthenticationState {
  AuthLogoutSuccessState();
}

class AuthResetPasswordSuccessState extends AuthenticationState {
  AuthResetPasswordSuccessState();
}

class AuthFailedState extends AuthenticationState {
  final String message;

  AuthFailedState(this.message);
}
