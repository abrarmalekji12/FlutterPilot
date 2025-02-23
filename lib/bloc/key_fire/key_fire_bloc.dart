import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../common/web/io_lib.dart';

part 'key_fire_event.dart';

part 'key_fire_state.dart';

enum FireKeyType {
  enter,
  rtrn,
  ctrl,
  alt,
  shift,
  space,
  backspace,
  delete,
  esc,
  up,
  down,
  left,
  right,
  tab,
  none
}

class FireKey {
  final Map<String, FireKeyType> windowsMap = {
    'ENTER': FireKeyType.enter,
    'LCONTROL': FireKeyType.ctrl,
    'RCONTROL': FireKeyType.ctrl,
    'RETURN': FireKeyType.rtrn,
    'LMENU': FireKeyType.alt,
    'LSHIFT': FireKeyType.shift,
    'RSHIFT': FireKeyType.shift,
    'SPACE': FireKeyType.space,
    'BACK': FireKeyType.backspace,
    'DELETE': FireKeyType.delete,
    'ESCAPE': FireKeyType.esc,
    'UP': FireKeyType.up,
    'DOWN': FireKeyType.down,
    'LEFT': FireKeyType.left,
    'RIGHT': FireKeyType.right,
  };
  final Map<String, FireKeyType> webMap = {
    'Enter': FireKeyType.enter,
    'Ctrl': FireKeyType.ctrl,
    'Alt': FireKeyType.alt,
    'Shift': FireKeyType.shift,
    'Space': FireKeyType.space,
    'Backspace': FireKeyType.backspace,
    'Delete': FireKeyType.delete,
    'Esc': FireKeyType.esc,
    'Up': FireKeyType.up,
    'Down': FireKeyType.down,
    'Left': FireKeyType.left,
    'Right': FireKeyType.right,
  };

  FireKeyType? fromPlatformKey(String key) {
    if (kIsWeb) {
      return webMap[key];
    }
    if (Platform.isWindows) {
      return windowsMap[key];
    }
    return null;
  }
}

class KeyFireBloc extends Bloc<KeyFireEvent, KeyFireState> {
  final FireKey fireKey = FireKey();

  KeyFireBloc() : super(KeyFireInitial()) {
    on<KeyFireEvent>((event, emit) {});
    on<FireKeyDownEvent>((event, emit) {
      // print('== KEY DOWN == ${event.key}');
      emit(DownKeyEventFired(
          fireKey.fromPlatformKey(event.key) ?? FireKeyType.none));
    });
    on<FireKeyDownWithTypeEvent>((event, emit) {
      emit(DownKeyEventFired(event.key));
    });
    on<FireKeyUpEvent>((event, emit) {
      // print('== KEY UP == ${event.key}');
      emit(UpKeyEventFired(
          fireKey.fromPlatformKey(event.key) ?? FireKeyType.none));
    });
  }
}
