import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'key_fire_event.dart';
part 'key_fire_state.dart';

class KeyFireBloc extends Bloc<KeyFireEvent, KeyFireState> {
  KeyFireBloc() : super(KeyFireInitial()) {
    on<KeyFireEvent>((event, emit) {
    });
    on<FireKeyDownEvent>((event, emit) {
      // print('== KEY DOWN == ${event.key}');
      emit(DownKeyEventFired(event.key));
    });
    on<FireKeyUpEvent>((event, emit) {
      // print('== KEY UP == ${event.key}');
      emit(UpKeyEventFired(event.key));
    });
  }
}
