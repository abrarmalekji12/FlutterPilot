import 'package:bloc/bloc.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:flutter/foundation.dart';
import '../../models/component_selection.dart';
import '../../models/variable_model.dart';
import '../../models/other_model.dart';
import '../../ui/models_view.dart';
import '../component_operation/component_operation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';
import '../../firestore/firestore_bridge.dart';
import '../../models/project_model.dart';
import 'package:meta/meta.dart';

part 'flutter_project_state.dart';

class FlutterProjectCubit extends Cubit<FlutterProjectState> {
  List<FlutterProject> projects = [];
  int? _userId;

  FlutterProjectCubit() : super(FlutterProjectInitial());


  // set userId
  set setUserId(int userId) {
    _userId = userId;
  }

  int get userId => _userId??-1;
  Future<void> loadFlutterProjectList() async {
    emit(FlutterProjectLoadingState());
    try {
      projects = await FireBridge.loadAllFlutterProjects(userId);
      emit(FlutterProjectsLoadedState(projects));
    } on Exception {
      emit(FlutterProjectErrorState());
    }
  }

  Future<void> deleteProject(final FlutterProject project) async {
    emit(FlutterProjectLoadingState());
    await FireBridge.deleteProject(userId, project);
    projects.remove(project);
    emit(FlutterProjectsLoadedState(projects));
  }

  Future<void> createNewProject(final String name) async {
    emit(FlutterProjectLoadingState());
    final flutterProject = FlutterProject.createNewProject(name, userId);
    ComponentOperationCubit.currentFlutterProject = flutterProject;
    flutterProject.currentScreen.variables.addAll([
      VariableModel(
          'tabletWidthLimit',
          1200,
          false,
          'maximum width tablet can have',
          DataType.double,
          flutterProject.currentScreen.name,
          deletable: false),
      VariableModel(
          'phoneWidthLimit',
          900,
          false,
          'maximum width phone can have',
          DataType.double,
          flutterProject.currentScreen.name,
          deletable: false)
    ]);
    await FireBridge.saveFlutterProject(userId, flutterProject);
    projects.add(flutterProject);
    emit(FlutterProjectLoadedState(flutterProject));
  }

  void reloadProject(final ComponentSelectionCubit componentSelectionCubit,
      final ComponentOperationCubit componentOperationCubit) {
    loadFlutterProject(componentSelectionCubit, componentOperationCubit,
        componentOperationCubit.flutterProject!.name, false);
  }

  void loadFlutterProject(
      final ComponentSelectionCubit componentSelectionCubit,
      final ComponentOperationCubit componentOperationCubit,
      final String projectName,
      final bool notLoggedIn,{int? user}) async {
    emit(FlutterProjectLoadingState());
    try {
      if (notLoggedIn) {
        final authResponse= await FireBridge.login('test_fvb@mailinator.com', 'test123');
        setUserId=authResponse.userId!;
        print('Auth response: ${authResponse.userId}');
      }
      ComponentOperationCubit.codeProcessor.variables
          .removeWhere((key, value) => value.deletable);
      ComponentOperationCubit.codeProcessor.localVariables.clear();

      final FlutterProject? flutterProject =
          await FireBridge.loadFlutterProject(userId, projectName);

      if (flutterProject == null) {
        print('Project not found $projectName $userId');
        emit(FlutterProjectErrorState());
        return;
      }

      if (flutterProject.rootComponent != null) {
        final List<ImageData> imageDataList = [];
        componentOperationCubit.setFlutterProject = flutterProject;
        await componentOperationCubit.loadFavourites();
        final idList = componentOperationCubit.flutterProject!.favouriteList
            .map((e) => e.component.id)
            .toList();

        for (final uiScreen in flutterProject.uiScreens) {
          ComponentOperationCubit.changeVariables(uiScreen);
          uiScreen.rootComponent?.forEach((component) async {
            final index = idList.indexOf(component.id);
            if (index >= 0) {
              flutterProject.favouriteList[index] =
                  FavouriteModel(component, projectName);
            }
            if (component.name == 'Image.asset') {
              imageDataList.add((component.parameters[0].value as ImageData));
            }
          });
        }
        await componentOperationCubit.loadAllImages();

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
          print('IMAGE DATA ${imageData.imageName} ${imageData.bytes?.length}');
        }
      }
      ComponentOperationCubit.changeVariables(flutterProject.currentScreen);
      componentSelectionCubit.init(
          ComponentSelectionModel.unique(flutterProject.rootComponent!),
          flutterProject.rootComponent!);

      if (flutterProject.currentScreen.variables
              .firstWhereOrNull((e) => e.name == 'tabletWidthLimit') ==
          null) {
        componentOperationCubit.addVariable(VariableModel(
            'tabletWidthLimit',
            1200,
            false,
            'maximum width tablet can have',
            DataType.double,
            flutterProject.currentScreen.name,
            deletable: false));
        componentOperationCubit.addVariable(VariableModel(
            'phoneWidthLimit',
            900,
            false,
            'maximum width phone can have',
            DataType.double,
            flutterProject.currentScreen.name,
            deletable: false));
      }

      componentOperationCubit
          .extractSameTypeComponents(flutterProject.rootComponent!);

      emit(FlutterProjectLoadedState(flutterProject));
    } on Exception catch (error) {
      print('ERROR $error');
      emit(FlutterProjectErrorState(
          message: 'Something went wrong, Project data can be corrupt $error'));
    }
  }
}
