part of 'user_details_cubit.dart';

@immutable
abstract class UserDetailsState {}

class FlutterProjectInitial extends UserDetailsState {}

class ProjectLoadingState extends UserDetailsState {}

class ProjectListLoadingState extends UserDetailsState {}

class ProjectUploadAsTemplateLoadingState extends UserDetailsState {}

class ProjectUploadAsTemplateSuccessState extends UserDetailsState {}

class ProjectTemplatesLoadingState extends UserDetailsState {}

class ProjectTemplatesLoadedState extends UserDetailsState {
  final String? userId;
  final List<FVBTemplate> templates;

  ProjectTemplatesLoadedState(this.userId, this.templates);
}

class ProjectUpdateLoadingState extends UserDetailsState {}

class ProjectUpdateSuccessState extends UserDetailsState {
  final bool deleted;

  ProjectUpdateSuccessState({this.deleted = false});
}

class ProjectCreationLoadingState extends UserDetailsState {}

class UserDetailsFigmaTokenGeneratingState extends UserDetailsState {}

class UserDetailsFigmaTokenUpdatedState extends UserDetailsState {}

class FlutterProjectLoadedState extends UserDetailsState {
  FlutterProjectLoadedState(this.project, {this.created = false});
  final FVBProject project;
  final bool created;
}

class FlutterProjectScreenUpdatedState extends UserDetailsState {
  FlutterProjectScreenUpdatedState();
}

class UserDetailsLoadedState extends UserDetailsState {
  UserDetailsLoadedState(this.userSettingModel);
  final UserSettingModel userSettingModel;
}

class UserDetailsErrorState extends UserDetailsState {
  final String message;
  UserDetailsErrorState({required this.message});
}

class FlutterProjectLoadingErrorState extends UserDetailsState {
  final ProjectLoadErrorModel model;
  FlutterProjectLoadingErrorState({required this.model});
}
