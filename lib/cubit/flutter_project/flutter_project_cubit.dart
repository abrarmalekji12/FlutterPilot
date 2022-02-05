import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_builder/common/logger.dart';
import 'package:flutter_builder/models/other_model.dart';
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
    try {
      final projects = await FireBridge.loadAllFlutterProjects(1);
      emit(FlutterProjectsLoadedState(projects));
    } on Exception {
      emit(FlutterProjectErrorState());
    }
  }

  Future<void> createNewProject(final String name) async {
    emit(FlutterProjectLoadingState());
    final flutterProject = FlutterProject.createNewProject(name);
    await FireBridge.saveFlutterProject(1, flutterProject);
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
          await FireBridge.loadFlutterProject(1, projectName);

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
                await FireBridge.loadImage(1, imageData.imageName!);
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
      await componentOperationCubit.loadFavourites(
          projectName: flutterProject.name);
      emit(FlutterProjectLoadedState(flutterProject));
    } on Exception {
      emit(FlutterProjectErrorState(
          message: 'Something went wrong, Project data can be corrupt'));
    }
  }
}
