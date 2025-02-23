part of 'key_fire_bloc.dart';

@immutable
abstract class KeyFireEvent {}

class FireKeyDownEvent extends KeyFireEvent {
  final String key;

  FireKeyDownEvent(this.key);
}

class FireKeyDownWithTypeEvent extends KeyFireEvent {
  final FireKeyType key;

  FireKeyDownWithTypeEvent(this.key);
}

class FireKeyUpEvent extends KeyFireEvent {
  final String key;

  FireKeyUpEvent(this.key);
}
