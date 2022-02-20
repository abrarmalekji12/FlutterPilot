import 'package:bloc/bloc.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:flutter/foundation.dart';
import '../../models/variable_model.dart';
import '../../common/logger.dart';
import '../../models/other_model.dart';
import '../component_operation/component_operation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';
import '../../firestore/firestore_bridge.dart';
import '../../models/project_model.dart';
import 'package:meta/meta.dart';

part 'flutter_project_state.dart';

class FlutterProjectCubit extends Cubit<FlutterProjectState> {
  final List<FlutterProject> projects = [];
  final int userId;

  FlutterProjectCubit(this.userId) : super(FlutterProjectInitial());

  Future<void> loadFlutterProjectList() async {
    emit(FlutterProjectLoadingState());
    try {
      final projects = await FireBridge.loadAllFlutterProjects(userId);
      emit(FlutterProjectsLoadedState(projects));
    } on Exception {
      emit(FlutterProjectErrorState());
    }
  }

  Future<void> createNewProject(final String name) async {
    emit(FlutterProjectLoadingState());
    final flutterProject = FlutterProject.createNewProject(name,userId);
    flutterProject.variables.addAll([
      VariableModel('tabletWidthLimit', 1200, false, 'maximum width tablet can have',deletable: false),
      VariableModel('phoneWidthLimit', 900, false, 'maximum width phone can have',deletable: false)
    ]);
    await FireBridge.saveFlutterProject(userId, flutterProject);
   projects.add(flutterProject);
    emit(FlutterProjectLoadedState(flutterProject));
  }

  void reloadProject(final ComponentSelectionCubit componentSelectionCubit,
      final ComponentOperationCubit componentOperationCubit) {
    loadFlutterProject(componentSelectionCubit, componentOperationCubit,
        componentOperationCubit.flutterProject!.name);
  }

  void loadFlutterProject(
      final ComponentSelectionCubit componentSelectionCubit,
      final ComponentOperationCubit componentOperationCubit,
      final String projectName) async {
    emit(FlutterProjectLoadingState());
    try {
      final FlutterProject? flutterProject =
          await FireBridge.loadFlutterProject(userId, projectName);

      if (flutterProject == null) {
        emit(FlutterProjectErrorState());
        return;
      }
      logger('ROOT COMPP ${flutterProject.rootComponent != null} ');
      if (flutterProject.rootComponent != null) {
        final List<ImageData> imageDataList = [];
        flutterProject.rootComponent!.forEach((component) async {
          if (component.name == 'Image.asset') {
            imageDataList.add((component.parameters[0].value as ImageData));
          }
        });
        for (final ImageData imageData in imageDataList) {
          if (!componentOperationCubit.byteCache
              .containsKey(imageData.imageName!)) {
            imageData.bytes =
                await FireBridge.loadImage(userId, imageData.imageName!);
            if (imageData.bytes != null) {
              componentOperationCubit.byteCache[imageData.imageName!] =
                  imageData.bytes!;
            }
          } else {
            imageData.bytes =
                componentOperationCubit.byteCache[imageData.imageName!];
          }
        }
      }
      componentSelectionCubit.init(
          flutterProject.rootComponent!, flutterProject.rootComponent!);

      componentOperationCubit.flutterProject = flutterProject;

      if(flutterProject.variables.firstWhereOrNull((e)=>e.name=='tabletWidthLimit')==null){
       componentOperationCubit.addVariable(
           VariableModel('tabletWidthLimit', 1200, false, 'maximum width tablet can have',deletable: false)
       );
       componentOperationCubit.addVariable(
           VariableModel('phoneWidthLimit', 900, false, 'maximum width phone can have',deletable: false)
       );

      }
      await componentOperationCubit.loadFavourites(
          projectName: flutterProject.name);

      componentOperationCubit.extractSameTypeComponents(flutterProject.rootComponent!);
      emit(FlutterProjectLoadedState(flutterProject));
    } on Exception {
      emit(FlutterProjectErrorState(
          message: 'Something went wrong, Project data can be corrupt'));
    }
  }
}
