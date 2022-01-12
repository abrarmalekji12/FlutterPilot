import 'package:bloc/bloc.dart';
import '../../models/project_model.dart';
import 'package:meta/meta.dart';

part 'flutter_project_state.dart';

class FlutterProjectCubit extends Cubit<FlutterProjectState> {
  final List<FlutterProject> projects = [];
  FlutterProjectCubit() : super(FlutterProjectInitial());

  Future<void> loadFlutterProjectList() async {
    emit(FlutterProjectLoadingState());
    emit(FlutterProjectLoadedState());
  }


  Future<void> loadFlutterProject() async {
    emit(FlutterProjectLoadingState());

    emit(FlutterProjectLoadedState());
  }
}
