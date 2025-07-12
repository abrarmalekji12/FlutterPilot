import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_config.dart';
import '../../bloc/error/error_bloc.dart';
import '../../common/app_loader.dart';
import '../../common/utils/load_time_checker.dart';
import '../../common/web/html_lib.dart' as html;
import '../../common/web/io_lib.dart';
import '../../constant/string_constant.dart';
import '../../data/remote/common_data_models.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../injector.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/other_model.dart';
import '../../models/project_model.dart';
import '../../models/templates/template_model.dart';
import '../../models/user/user_setting.dart';
import '../../models/variable_model.dart';
import '../../models/version_control/version_control_model.dart';
import '../../network/connectivity.dart';
import '../../ui/home/editing_view.dart';
import '../../user_session.dart';
import '../component_operation/operation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';

part 'user_details_state.dart';

class UserDetailsCubit extends Cubit<UserDetailsState> {
  final OperationCubit operationCubit;
  final SelectionCubit selectionCubit;
  final UserSession _userSession;

  UserDetailsCubit(this.operationCubit, this.selectionCubit, this._userSession) : super(FlutterProjectInitial());

  // set userId
  set setUserId(String userId) {
    _userSession.user.userId = userId;
  }

  String? get userId => _userSession.user.userId;

  Future<void> updateScreen() async {
    emit(FlutterProjectScreenUpdatedState());
  }

  Future<void> waitForConnectivity() async {
    if (!await AppConnectivity.available()) {
      if (state is! UserDetailsErrorState) {
        emit(UserDetailsErrorState(message: 'Network Error'));
      }
      final stream = AppConnectivity.listen();
      await for (final check in stream) {
        if (check != ConnectivityResult.none) {
          break;
        }
      }
    }
  }

  Future<void> connectFigmaAccount() async {
    final String state = '${Random.secure().nextInt(10)}';
    final uri = _redirectURI;
    launchUrl(
      Uri.parse(
          'https://www.figma.com/oauth?client_id=${appConfig.figmaClientId}&redirect_uri=${uri}&scope=file_read&state=${state}&response_type=code'),
    ).then((value) {
      print('VALUE $value');
    });
  }

  Future<void> disconnectFigmaAccount() async {
    _userSession.settingModel?.figmaAccessToken = null;
    await operationCubit.updateUserSetting('figmaAccessToken', null);
    emit(UserDetailsFigmaTokenUpdatedState());
  }

  String get _redirectURI {
    late String uri;
    if (kIsWeb) {
      print('SEE ${html.window.location.origin}');
      uri = Uri.encodeComponent('${html.window.location.origin}/figma');
    } else if (Platform.isWindows) {
      uri = Uri.encodeComponent('fvb://code');
    } else if (Platform.isMacOS) {
      uri = Uri.encodeComponent('flutterpilot://code');
    }
    return uri;
  }

  Future<String?> onFigmaCodeReceived(String code) async {
    _userSession.settingModel?.figmaCode = code;
    emit(UserDetailsFigmaTokenGeneratingState());
    try {
      await operationCubit.updateUserSetting('figmaCode', code);
      final response = await http.post(
        Uri.parse(
            'https://www.figma.com/api/oauth/token?client_id=${appConfig.figmaClientId}&client_secret=${appConfig.figmaClientSecret}&redirect_uri=${_redirectURI}&code=$code&grant_type=authorization_code'),
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final json = Map<String, dynamic>.from(jsonDecode(response.body));
        print('BODY ${response.body}');
        if (json.containsKey('access_token')) {
          _userSession.settingModel?.figmaAccessToken = json['access_token'];
          await operationCubit.updateUserSetting('figmaAccessToken', json['access_token']);
          emit(UserDetailsFigmaTokenUpdatedState());
        }
      }
    } on Exception catch (e) {
      emit(UserDetailsErrorState(message: e.toString()));
      return e.toString();
    }
    return null;
  }

  Future<void> loadProjectList() async {
    emit(ProjectListLoadingState());
    try {
      await waitForConnectivity();
      await LoadTimeChecker.checkTime('Loading Projects', () async {
        final [userDetails as UserSettingModel?, projects as List<FVBProject>?] = await Future.wait([
          if (_userSession.settingModel != null)
            Future.value(_userSession.settingModel!)
          else
            dataBridge.loadUserDetails(userId!),
          if (_userSession.settingModel?.projects.isEmpty ?? true)
            dataBridge.loadProjectList(userId!)
          else
            Future.value(_userSession.settingModel!.projects.toList()),
        ]);
        _userSession.settingModel = userDetails;
        _userSession.settingModel?.projects.clear();
        _userSession.settingModel?.projects.addAll(projects ?? []);
      });

      operationCubit.loadGlobalComponentList();
      operationCubit.loadFavourites();
      emit(UserDetailsLoadedState(_userSession.settingModel!));
    } on Exception catch (e) {
      emit(UserDetailsErrorState(message: e.toString()));
    }
  }

  Future<void> deleteProject(final FVBProject project) async {
    emit(ProjectUpdateLoadingState());
    try {
      await waitForConnectivity();
      await dataBridge.deleteProject(_userSession.user.userId!, project, _userSession.settingModel!.projects);
      _userSession.settingModel!.projects.removeWhere((value) => value.id == project.id);
      collection.project = null;
      emit(ProjectUpdateSuccessState(deleted: true));
    } on Exception catch (e) {
      emit(UserDetailsErrorState(message: e.toString()));
    }
  }

  Future<void> renameProject(final FVBProject project, String name) async {
    emit(ProjectUpdateLoadingState());
    try {
      await waitForConnectivity();
      await dataBridge.updateProjectValue(project, 'name', name);
      project.name = name;

      emit(ProjectUpdateSuccessState());
    } on Exception catch (e) {
      emit(UserDetailsErrorState(message: e.toString()));
    }
  }

  Future<FVBProject?> createProject(final String name, {FVBTemplate? template}) async {
    try {
      emit(ProjectCreationLoadingState());
      await waitForConnectivity();
      AppLoader.update(0.1);
      final FVBProject? project;
      if (template == null) {
        project = FVBProject.createNewProject(name, _userSession.user);
      } else {
        final response = await dataBridge.loadProject(template.projectId, checkIfPublic: true);
        if (response.isLeft) {
          project = response.a!;
          project.name = name;
          for (final screen in response.a?.screens ?? <Screen>[]) {
            screen.id = randomId;
            screen.project = project;
          }

          for (final component in response.a?.customComponents ?? <CustomComponent>[]) {
            component.id = randomId;
            component.project = project;
          }

          project.userId = _userSession.user.userId!;
        } else {
          emit(
              UserDetailsErrorState(message: '${response.right.projectLoadError.name}: ${response.right.error ?? ''}'));
          return null;
        }
      }
      Processor.init();
      collection.project = project;
      project.variables.addAll({
        'tabletWidthLimit': VariableModel('tabletWidthLimit', DataType.fvbDouble,
            description: 'maximum width tablet can have', value: 1200, deletable: false, uiAttached: true),
        'phoneWidthLimit': VariableModel('phoneWidthLimit', DataType.fvbDouble,
            deletable: false, value: 900, uiAttached: true, description: 'maximum width phone can have')
      });
      await dataBridge.createProject(_userSession.user.userId!, project);
      AppLoader.update(0.9);
      _userSession.settingModel!.projects.insert(0, project);
      emit(FlutterProjectLoadedState(project, created: true));
      return project;
    } on Exception catch (e) {
      emit(UserDetailsErrorState(message: e.toString()));
    }
    return null;
  }

  Future<FVBImage> takeScreenShot(Screen screen) async {
    final boundary = ScreenKey('${screen.id}').currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return FVBImage(name: screen.name, bytes: Uint8List.fromList([]));
    }
    final image = await boundary.toImage(pixelRatio: 0.5);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    final temp = decodeImage(bytes!.buffer.asUint8List());
    final jpeg = encodeJpg(temp!, quality: 70);
    return FVBImage(name: screen.name, bytes: jpeg);
  }

  void addToTemplates(FVBProject project, String description) async {
    try {
      emit(ProjectUploadAsTemplateLoadingState());
      await waitForConnectivity();
      final images = await Future.wait([for (final screen in project.screens) takeScreenShot(screen)]);
      await Future.wait([
        dataBridge.addToTemplates(
          FVBTemplate(
              userId: project.userId,
              projectId: project.id,
              name: project.name,
              imageURLs: images.map((e) => e.name ?? '').toList(),
              description: description,
              device: project.device ?? 'iPhone X',
              id: randomId,
              likes: 0,
              public: true),
        ),
        for (final image in images) dataBridge.uploadImageOnPath(ImageRef.templateImage(image.name!), image)
      ]);
      for (final image in images) byteCache[ImageRef.templateImage(image.name!)] = image.bytes!;
      emit(ProjectUploadAsTemplateSuccessState());
    } on Exception catch (e) {
      emit(UserDetailsErrorState(message: e.toString()));
    }
    return null;
  }

  void loadTemplates({String? userId}) async {
    try {
      emit(ProjectTemplatesLoadingState());
      await waitForConnectivity();
      final templates = await dataBridge.loadTemplates(userId: userId);
      emit(ProjectTemplatesLoadedState(userId, templates ?? []));
    } on Exception catch (e) {
      emit(UserDetailsErrorState(message: e.toString()));
    }
    return null;
  }

  void reloadProject({required int userId}) {
    loadProject(operationCubit.project!.id, userId: _userSession.user.userId!, name: operationCubit.project!.name);
  }

  void loadProject(final String id, {required String? userId, String? name}) async {
    emit(ProjectLoadingState());
    await LoadTimeChecker.checkTime('PROJECT', () async {
      try {
        await waitForConnectivity();
        AppLoader.update(0.3);
        if (userId != null) {
          setUserId = userId;
        } else {
          await dataBridge.loginAnonymously();
        }
        final errorBloc = sl<EventLogBloc>();
        errorBloc.consoleVisible = false;
        final response = await dataBridge.loadProject(id, checkIfPublic: userId != _userSession.user.userId);
        if (response.a != null) {
          collection.project = response.a!;
        }
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
                print('Project not found ${name ?? id} $userId');
              }
              break;
            case ProjectLoadError.notFound:
              if (kDebugMode) {
                print('Project not found ${name ?? id} $userId');
              }
              break;
          }

          emit(FlutterProjectLoadingErrorState(model: response.right));
          return;
        }
        final project = response.left;
        if (project.screens.isNotEmpty) {
          project.screens.sort((page1, page2) => page1.createdAt.isAfter(page2.createdAt) ? 1 : -1);
        }
        final List<FVBImage> imageDataList = [];
        operationCubit.setFlutterProject = project;
        // final idList = componentOperationCubit.project!.favouriteList
        //     .map((e) => e.component.id)
        //     .toList();

        for (final screen in project.screens) {
          screen.rootComponent?.forEachWithClones((component) {
            if (component.hasImageAsset) {
              final imageData = component.parameters[0].value as FVBImage?;
              if (imageData != null) {
                imageDataList.add(imageData);
              }
            }
            return false;
          });
        }
        AppLoader.update(0.8);
        if (project.screens.isNotEmpty) {
          project.screens.sort((page1, page2) => page1.createdAt.isAfter(page2.createdAt) ? 1 : -1);
        }
        AppLoader.update(0.95);
        if (userId != null) {
          await Future.wait([
            operationCubit.loadAllImages(userId),
            for (final FVBImage imageData in imageDataList)
              Future(() async {
                if (!byteCache.containsKey(imageData.name!)) {
                  imageData.bytes = await dataBridge.loadImage(userId, imageData.name!);
                  if (imageData.bytes?.isNotEmpty ?? false) {
                    byteCache[imageData.name!] = imageData.bytes!;
                  }
                } else {
                  imageData.bytes = byteCache[imageData.name!];
                }
              }),
            if (_userSession.settingModel == null)
              Future(() async {
                final [settings as UserSettingModel?, projects as List<FVBProject>?] =
                    await Future.wait([dataBridge.loadUserDetails(userId), dataBridge.loadProjectList(userId)]);
                _userSession.settingModel = settings;

                if (projects != null) {
                  _userSession.settingModel?.projects.addAll(projects);
                }
              })
          ]);
        }

        AppLoader.update(1);

        if (project.variables.entries.firstWhereOrNull((e) => e.key == 'tabletWidthLimit') == null) {
          operationCubit.addVariable(VariableModel('tabletWidthLimit', DataType.fvbDouble,
              deletable: false, description: 'maximum width tablet can have', value: 1200, uiAttached: true));
        }
        if (project.variables.entries.firstWhereOrNull((e) => e.key == 'phoneWidthLimit') == null) {
          operationCubit.addVariable(VariableModel('phoneWidthLimit', DataType.fvbDouble,
              deletable: false, description: 'maximum width tablet can have', value: 900, uiAttached: true));
        }

        errorBloc.consoleVisible = true;
        collection.project = project;
        final index = _userSession.settingModel?.projects.indexWhere((element) => element.id == project.id) ?? -1;
        if (index >= 0) {
          _userSession.settingModel!.projects.removeAt(index);
          _userSession.settingModel!.projects.insert(index, project);
        }
        if (project.settings.firebaseConnect != null) {
          await dataBridge.connect(project.id, project.settings.firebaseConnect!.json);
        }
        if (_userSession.settingModel?.openAISecretToken != null) componentGenerator.initialize();

        emit(FlutterProjectLoadedState(project));
      } on Exception catch (error) {
        print('ERROR $error');
        emit(UserDetailsErrorState(message: 'Error: $error'));
      }
    });
  }

  void restoreProject(FVBCommit commit, Set<String> screens, Set<String> components, FVBProject project) async {
    emit(ProjectLoadingState());
    try {
      AppLoader.update(0.7);
      await dataBridge.restoreCommit(commit, screens, components, project);
      AppLoader.update(0.95);
      emit(FlutterProjectLoadedState(project));
    } on Exception catch (e) {
      emit(UserDetailsErrorState(message: 'Error: ${e.toString()}'));
    }
  }
}
