import 'package:bloc/bloc.dart';
import 'package:flutter_builder/common/logger.dart';
import '../component_operation/component_operation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';
import '../../firestore/firestore_bridge.dart';
import '../../models/project_model.dart';
import 'package:meta/meta.dart';

part 'flutter_project_state.dart';

class FlutterProjectCubit extends Cubit<FlutterProjectState> {
  final List<FlutterProject> projects = [];
  FlutterProjectCubit() : super(FlutterProjectInitial());

  Future<void> loadFlutterProjectList() async {
    emit(FlutterProjectLoadingState());
  }
  void loadFlutterProject(final ComponentSelectionCubit componentSelectionCubit,final ComponentOperationCubit componentOperationCubit) async {
    emit(FlutterProjectLoadingState());
    FlutterProject? flutterProject = await FireBridge.loadFlutterProject(1, 'untitled1');
    if(flutterProject == null){
      flutterProject=FlutterProject.createNewProject();
      FireBridge.saveFlutterProject(1, flutterProject);
    }
    logger('ROOT COMPP ${flutterProject.rootComponent!=null}');
    componentSelectionCubit.init(
        flutterProject.rootComponent!,
        flutterProject.rootComponent!);
    componentOperationCubit.flutterProject =
        flutterProject;
    logger('ABOUT TO FIRE');
    emit(FlutterProjectLoadedState(flutterProject));
  }

}
