part of 'firebase_connect_cubit.dart';

@immutable
abstract class FirebaseConnectState {}

class FirebaseConnectInitial extends FirebaseConnectState {}

class FirebaseConnectingState extends FirebaseConnectState {}

class FirebaseConnectedSuccessState extends FirebaseConnectState {}

class FirebaseConnectErrorState extends FirebaseConnectState {
  final String message;

  FirebaseConnectErrorState(this.message);
}
