import 'dart:core';
import 'dart:typed_data';

import '../../cubit/component_operation/operation_cubit.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/global_component.dart';
import '../../models/other_model.dart';
import '../../models/project_model.dart';
import '../../models/template_model.dart';
import '../../models/templates/template_model.dart';
import '../../models/user/user_setting.dart';
import '../../models/variable_model.dart';
import '../../models/version_control/version_control_model.dart';
import '../../network/auth_response/auth_response_model.dart';
import '../../ui/boundary_widget.dart';
import '../../ui/feedback/model/feedback.dart';
import '../../ui/paint_tools/paint_tools.dart';
import '../../view_model/auth_viewmodel.dart';
import 'common_data_models.dart';

abstract class DataBridge {
  Future<void> init();

  Future<void> connect(String name, Map<String, dynamic> map);
  Future<void> disconnect();

  Future<void> assistOperationAdd(
      String path, String? docId, Map<String, dynamic> data);
  Future<void> assistOperationUpdate(
      String path, String? docId, Map<String, dynamic> data);

  Future<void> updateCustomComponent(
      FVBProject project, CustomComponent customComponent);

  Future<void> addCustomComponent(String userId, FVBProject flutterProject,
      CustomComponent customComponent);

  Future<void> removeCustomComponent(
      String userId, FVBProject project, CustomComponent component);

  Future<void> deleteProject(
      String userId, FVBProject project, final List<FVBProject> projects);

  Future<void> addToTemplates(FVBTemplate template);

  Future<List<FVBTemplate>?> loadTemplates({String? userId});

  Future<void> moveDocument(List<DocData> fromData, List<DocData> toData,
      {bool deleteOld = true, Map<String, dynamic>? additionalData});

  Future<void> moveCollection(List<DocData> fromData, List<DocData> toData,
      {bool deleteOld = true,
      Map<String, dynamic>? additionalData,
      snapshot,
      String? appendTargetDocKey});

  Future<List<FavouriteModel>> loadFavourites(final String userId);

  Future<Map<String, List<CustomComponent>>> loadAllCustomComponents(
      final String userId);

  Future<void> uploadTemplate(TemplateModel model);

  Future<void> deleteTemplate(TemplateModel model);

  Future<List<GlobalComponentModel>?> loadGlobalComponentList();

  Future<bool> updateFVBPaintObj(
      FVBProject project, String id, List<FVBPaintObj> obj);

  Future<bool> addGlobalComponent(
    String? id,
    GlobalComponentModel model,
  );

  Future<void> addFeedback(FVBFeedback feedback);

  Future<bool> removeGlobalComponent(String id);

  Future<TemplatePaginate> loadScreenTemplateList(dynamic last, int count,
      {String? userId});

  Future<bool> uploadPublicImage(FVBImage image);

  Future<FVBImage?> getPublicImage(String image);

  Future<void> addToFavourites(String userId, FavouriteModel model);

  Future<void> removeFromFavourites(String userId, String id);

  Future<AuthResponse> registerUser(FVBUser model);

  Future<List<FVBProject>?> loadProjectList(
    String userId,
  );

  Future<UserSettingModel?> loadUserDetails(
    String userId,
  );
  Future<FVBUser?> loadUserDetailsFromEmail(String email);

  Future<void> createProject(String userId, FVBProject project);

  Stream<Component> loadMainScreen(
      FVBProject project, OperationCubit operationCubit);

  Stream<Component> loadCustomComponentStream(FVBProject project, String name);

  Future<Optional<FVBProject, ProjectLoadErrorModel>> loadProject(String id,
      {bool checkIfPublic = false});

  fetchCustomComponentsFromJson(
      List<dynamic> customDocuments,
      List<CustomComponent> customComponents,
      List<CustomComponent> allCustomComponents);

  Future<Uint8List?> loadImage(String userId, String imgName);

  Future<Uint8List?> loadRefImage(String path, String name);

  Future<List<FVBImage>?> loadAllImages(String userId);

  Future<String?> resetPassword(String userName);

  Future<FVBUser?> tryLoginWithPreference();

  Future<AuthResponse> login(String userName, String password);
  Future<void> loginAnonymously();

  Future<void> uploadImage(
      String userId, String projectName, FVBImage imageData);
  Future<void> uploadImageOnPath(String path, FVBImage image);

  Future<void> removeImage(String userId, String imgName);

  // Future<void> addModel(final String userId, final FVBProject project, final LocalModel localModel, Screen screen);

  Future<void> addVariables(final String userId, final FVBProject project,
      final List<VariableModel> variables);

  Future<void> addVariableForScreen(
      final String userId,
      final FVBProject project,
      final VariableModel variableModel,
      Screen screen);

  Future<void> updateVariable(final String userId, final FVBProject project);

  Future<void> updateModels(final String userId, final FVBProject project);

  Future<void> updateUIScreenVariable(final Screen screen);

  Future<void> updateVariableForCustomComponent(
    final String userId,
    final FVBProject project,
    final CustomComponent component,
  );

  Future<void> updateCustomComponentActionCode(final CustomComponent component);

  Future<void> updateCustomComponentArguments(final CustomComponent component);
  Future<void> updateCustomComponentField(
      final CustomComponent component, String key, dynamic value);
  Future<void> updateDeviceSelection(
      final String userId, final FVBProject project, final String device);

  Future<void> updateProjectSettings(final FVBProject project);

  Future<void> updateCurrentScreen(
      String userId, final FVBProject project, Viewable screen);

  Future<void> updateMainScreen(String userId, final FVBProject project);

  Future<void> updateProjectValue(
      final FVBProject project, String key, dynamic value);

  Future<void> updateUserValue(final String userId, String key, dynamic value);

  Future<void> updateActionCode(String userId, final FVBProject project);

  Future<void> updateScreenActionCode(
      String userId, final FVBProject project, Screen screen);

  Future<void> updateScreenValue(Screen screen, String key, String value);

  // Future<void> updateRootComponent(
  //     String userId, String projectName, Component component) async {
  //   final document = await fireStore
  //       .collection('us$userId')
  //       .doc(Strings.kFlutterProject)
  //       .collection(projectName)
  //       .where('project_name', isNull: false)
  //       .get(const GetOptions(source: Source.server));
  //   final documentData = document.docs[0].data();
  //   final Map<String, dynamic> body = {};
  //   final rootCode = CodeOperations.trim(component.code(clean: false));
  //   if (documentData['root'] != rootCode) {
  //     body['root'] = rootCode;
  //   }
  //   if (body.isNotEmpty) {
  //     await fireStore
  //         .collection('us$userId')
  //         .doc(Strings.kFlutterProject)
  //         .collection(projectName)
  //         .doc(document.docs[0].id)
  //         .update(body);
  //     logger('=== FIRE-BRIDGE == updateGlobalCustomComponent ==');
  //   }
  // }
  //

  Future<void> createScreen(
      final String userId, final FVBProject project, final Screen uiScreen);

  Future<void> updateScreenRootComponent(
      final String userId, final Screen uiScreen, final Component? component);

  Future<void> logout();

  Future<void> addCommit(FVBCommit commit, FVBProject project);
  Future<void> removeCommit(FVBCommit commit, FVBProject project);
  Future<void> restoreCommit(FVBCommit commit, Set<String> screens,
      Set<String> components, FVBProject project);

  Future<void> removeScreen(final String userId,
      final FVBProject flutterProject, final Screen uiScreen);
}
