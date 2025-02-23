import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../collections/project_info_collection.dart';
import '../../../data/remote/data_bridge.dart';
import '../models/collaborator.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final DataBridge _dataBridge;
  final UserProjectCollection _collection;

  SettingsBloc(this._collection, this._dataBridge) : super(SettingsInitial()) {
    on<SettingsEvent>((event, emit) {});
    on<SettingsAddCollaboratorEvent>(_addCollaborator);
    on<SettingsUpdateCollaboratorsEvent>(_updateCollaborator);
  }

  FutureOr<void> _addCollaborator(
      SettingsAddCollaboratorEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsCollaboratorAddingState());
    final user =
        await _dataBridge.loadUserDetailsFromEmail(event.collaborator.email);
    if (user?.userId != null) {
      event.collaborator.userId = user!.userId!;
      if (_collection.project!.settings.collaborators == null) {
        _collection.project!.settings.collaborators = [event.collaborator];
      } else {
        _collection.project!.settings.collaborators?.add(event.collaborator);
      }
      _collection.project!.collaboratorIds = _collection
          .project!.settings.collaborators
          ?.map((e) => e.userId!)
          .toList();
      await Future.wait([
        _dataBridge.updateProjectValue(
          _collection.project!,
          'settings',
          _collection.project!.settings.toJson(),
        ),
        _dataBridge.updateProjectValue(
          _collection.project!,
          'collaboratorIds',
          _collection.project!.collaboratorIds,
        ),
      ]);
      emit(SettingsCollaboratorAddedState());
    } else {
      emit(SettingsCollaboratorErrorState(
          'User "${event.collaborator.email}" not found'));
    }
  }

  FutureOr<void> _updateCollaborator(SettingsUpdateCollaboratorsEvent event,
      Emitter<SettingsState> emit) async {
    try {
      emit(SettingsCollaboratorAddingState());
      _collection.project!.collaboratorIds = _collection
          .project!.settings.collaborators
          ?.map((e) => e.userId!)
          .toList();
      await Future.wait([
        _dataBridge.updateProjectValue(
          _collection.project!,
          'settings',
          _collection.project!.settings.toJson(),
        ),
        _dataBridge.updateProjectValue(
          _collection.project!,
          'collaboratorIds',
          _collection.project!.collaboratorIds,
        ),
      ]);
      emit(SettingsCollaboratorAddedState());
    } on Exception catch (e) {
      emit(SettingsCollaboratorErrorState(e.toString()));
    }
  }
}
