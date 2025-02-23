import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../collections/project_info_collection.dart';
import '../../../data/remote/firestore/firebase_bridge.dart';
import '../model.dart';

part 'firebase_connect_state.dart';

class FirebaseConnectCubit extends Cubit<FirebaseConnectState> {
  final UserProjectCollection _collection;

  FirebaseConnectCubit(this._collection) : super(FirebaseConnectInitial());

  Future<bool> connect(String text) async {
    try {
      emit(FirebaseConnectingState());
      final Map<String, dynamic> map = jsonDecode(text);
      final essentialKeys = [
        'apiKey',
        'appId',
        'messagingSenderId',
        'projectId',
        'authDomain',
        'storageBucket',
      ];
      for (final key in essentialKeys) {
        if (!map.containsKey(key)) {
          emit(FirebaseConnectErrorState('Missing "$key" in Json'));
          return false;
        }
      }
      final value = await dataBridge.connect(_collection.project!.id, map);
      if (value) {
        _collection.project?.settings.firebaseConnect = FVBFirebaseConnect(map);
        await dataBridge.updateProjectSettings(
          _collection.project!,
        );
        emit(FirebaseConnectedSuccessState());
      } else {
        emit(FirebaseConnectErrorState('Couldn\'t found Firebase account!'));
      }
      return value;
    } on FormatException catch (e) {
      emit(FirebaseConnectErrorState('Invalid Json: ${e.message}'));
    } on Exception catch (e) {
      emit(FirebaseConnectErrorState(e.toString()));
    }
    return false;
  }

  Future<bool> disconnect() async {
    try {
      emit(FirebaseConnectingState());
      final value = await dataBridge.disconnect();
      _collection.project?.settings.firebaseConnect = null;
      await dataBridge.updateProjectSettings(
        _collection.project!,
      );
      emit(FirebaseConnectInitial());
      return value;
    } on Exception catch (e) {
      emit(FirebaseConnectErrorState(e.toString()));
    }
    return false;
  }
}
