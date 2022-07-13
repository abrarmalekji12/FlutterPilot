part of 'key_fire_bloc.dart';

@immutable
abstract class KeyFireState {}

class KeyFireInitial extends KeyFireState {}

class DownKeyEventFired extends KeyFireState {
  final String key;

  DownKeyEventFired(this.key);
}

class UpKeyEventFired extends KeyFireState {
  final String key;

  UpKeyEventFired(this.key);
}