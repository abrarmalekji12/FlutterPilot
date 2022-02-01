part of 'flutter_project_cubit.dart';

@immutable
abstract class FlutterProjectState {}

class FlutterProjectInitial extends FlutterProjectState {}

class FlutterProjectLoadingState extends FlutterProjectState{
}
class FlutterProjectLoadedState extends FlutterProjectState{
  FlutterProjectLoadedState(this.flutterProject);
  final FlutterProject flutterProject;
}
class FlutterProjectErrorState extends FlutterProjectState{
}

