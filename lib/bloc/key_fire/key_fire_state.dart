part of 'key_fire_bloc.dart';

@immutable
abstract class KeyFireState {}

class KeyFireInitial extends KeyFireState {}

class DownKeyEventFired extends KeyFireState {
  final key;

  DownKeyEventFired(this.key);
}

class UpKeyEventFired extends KeyFireState {
  final FireKeyType key;

  UpKeyEventFired(this.key);
}
