part of 'authentication_cubit.dart';

@immutable
abstract class AuthenticationState {}

class AuthenticationInitial extends AuthenticationState {}

class AuthLoadingState extends AuthenticationState{
  AuthLoadingState();
}

class AuthErrorState extends AuthenticationState{
  AuthErrorState(this.message);
  final String message;
}

class AuthSuccessState extends AuthenticationState{
  final int userId;
  AuthSuccessState(this.userId);
}

class AuthFailedState extends AuthenticationState{
  final String message;
  AuthFailedState(this.message);
}