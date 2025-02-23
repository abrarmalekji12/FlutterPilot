part of 'settings_bloc.dart';

@immutable
abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsCollaboratorAddingState extends SettingsState {}

class SettingsCollaboratorAddedState extends SettingsState {}

class SettingsCollaboratorErrorState extends SettingsState {
  final String message;

  SettingsCollaboratorErrorState(this.message);
}
