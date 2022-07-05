part of 'flutter_project_cubit.dart';

@immutable
abstract class FlutterProjectState {}

class FlutterProjectInitial extends FlutterProjectState {}

class FlutterProjectLoadingState extends FlutterProjectState {}

class FlutterProjectLoadedState extends FlutterProjectState {
  FlutterProjectLoadedState(this.flutterProject);
  final FlutterProject flutterProject;
}

class FlutterProjectsLoadedState extends FlutterProjectState {
  FlutterProjectsLoadedState(this.flutterProjectList);
  final List<FlutterProject> flutterProjectList;
}

class FlutterProjectErrorState extends FlutterProjectState {
  final String? message;
  FlutterProjectErrorState({this.message});
}

class FlutterProjectLoadingErrorState extends FlutterProjectState {
  final ProjectLoadErrorModel model;
  FlutterProjectLoadingErrorState({required this.model});
}
