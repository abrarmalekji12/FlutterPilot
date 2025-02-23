part of 'settings_bloc.dart';

@immutable
abstract class SettingsEvent {}

class SettingsAddCollaboratorEvent extends SettingsEvent {
  final FVBCollaborator collaborator;

  SettingsAddCollaboratorEvent(this.collaborator);
}

class SettingsUpdateCollaboratorsEvent extends SettingsEvent {
  SettingsUpdateCollaboratorsEvent();
}
