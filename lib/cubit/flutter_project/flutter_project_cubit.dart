import 'package:bloc/bloc.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:flutter/foundation.dart';
import '../../common/compiler/code_processor.dart';
import '../../injector.dart';
import '../../models/component_selection.dart';
import '../../models/variable_model.dart';
import '../../models/other_model.dart';
import '../authentication/authentication_cubit.dart';
import '../component_operation/component_operation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';
import '../../firestore/firestore_bridge.dart';
import '../../models/project_model.dart';

part 'flutter_project_state.dart';

class FlutterProjectCubit extends Cubit<FlutterProjectState> {
  List<FlutterProject> projects = [];
  int? _userId;

  FlutterProjectCubit() : super(FlutterProjectInitial());

  // set userId
  set setUserId(int userId) {
    _userId = userId;
  }

  int get userId => _userId ?? -1;

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
    await FireBridge.deleteProject(userId, project,projects);
    projects.remove(project);
    emit(FlutterProjectsLoadedState(projects));
  }

  Future<void> createNewProject(final String name) async {
    emit(FlutterProjectLoadingState());
    final flutterProject = FlutterProject.createNewProject(name, userId);
    ComponentOperationCubit.currentProject = flutterProject;
    flutterProject.variables.addAll({
      'tabletWidthLimit': VariableModel('tabletWidthLimit', DataType.fvbDouble,
          description: 'maximum width tablet can have',
          value: 1200,
          deletable: false,
          uiAttached: true),
      'phoneWidthLimit': VariableModel('phoneWidthLimit', DataType.fvbDouble,
          deletable: false,
          value: 900,
          uiAttached: true,
          description: 'maximum width phone can have')
    });
    await FireBridge.saveFlutterProject(userId, flutterProject);
    projects.add(flutterProject);
    emit(FlutterProjectLoadedState(flutterProject));
  }

  void reloadProject(final ComponentSelectionCubit componentSelectionCubit,
      final ComponentOperationCubit componentOperationCubit,
      {required int userId}) {
    loadFlutterProject(componentSelectionCubit, componentOperationCubit,
        componentOperationCubit.project!.name, false,
        userId: userId);
  }

  void loadFlutterProject(
      final ComponentSelectionCubit componentSelectionCubit,
      final ComponentOperationCubit componentOperationCubit,
      final String projectName,
      final bool notLoggedIn,
      {required int userId}) async {
    emit(FlutterProjectLoadingState());
    try {
      if (notLoggedIn) {
        final authResponse =
            await FireBridge.login('test_fvb@mailinator.com', 'test123');
        get<AuthenticationCubit>().authViewModel.userId = authResponse.userId;
        if (kDebugMode) {
          print('Auth response: ${authResponse.userId}');
        }
      }
      setUserId = userId;
      if (kDebugMode) {
        print(
            'CHECKING $userId & ${get<AuthenticationCubit>().authViewModel.userId}');
      }
      final response = await FireBridge.loadFlutterProject(userId, projectName,
          ifPublic: userId != get<AuthenticationCubit>().authViewModel.userId);
      if (response.isRight) {
        switch (response.right.projectLoadError) {
          case ProjectLoadError.notPermission:
            if (kDebugMode) {
              print('Not permission');
            }
            break;
          case ProjectLoadError.networkError:
            if (kDebugMode) {
              print('Network error');
            }
            break;

          case ProjectLoadError.otherError:
            if (kDebugMode) {
              print('Project not found $projectName $userId');
            }
            break;
          case ProjectLoadError.notFound:
            if (kDebugMode) {
              print('Project not found $projectName $userId');
            }
            break;
        }
        emit(FlutterProjectLoadingErrorState(model: response.right));
        return;
      }
      final flutterProject = response.left;
      if (flutterProject.rootComponent != null) {
        final List<ImageData> imageDataList = [];
        componentOperationCubit.setFlutterProject = flutterProject;
        await componentOperationCubit.loadFavourites();
        final idList = componentOperationCubit.project!.favouriteList
            .map((e) => e.component.id)
            .toList();

        for (final uiScreen in flutterProject.uiScreens) {
          // ComponentOperationCubit.changeVariables(uiScreen);
          uiScreen.rootComponent?.forEach((component) async {
            final index = idList.indexOf(component.id);
            if (index >= 0) {
              flutterProject.favouriteList[index] =
                  FavouriteModel(component, projectName);
            }
            if (component.name == 'Image.asset') {
              final imageData = component.parameters[0].value as ImageData?;
              if (imageData != null) {
                imageDataList.add(imageData);
              }
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
      // ComponentOperationCubit.changeVariables(flutterProject.currentScreen);
      componentSelectionCubit.init(
          ComponentSelectionModel.unique(flutterProject.rootComponent!),
          flutterProject.rootComponent!);

      if (flutterProject.variables.entries
              .firstWhereOrNull((e) => e.key == 'tabletWidthLimit') ==
          null) {
        componentOperationCubit.addVariable(VariableModel(
            'tabletWidthLimit', DataType.fvbDouble,
            deletable: false,
            description: 'maximum width tablet can have',
            value: 1200,uiAttached: true));
        componentOperationCubit.addVariable(VariableModel(
          'phoneWidthLimit',
          DataType.fvbDouble,
          deletable: false,
          description: 'maximum width tablet can have',
          value: 900,uiAttached: true
        ));
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
