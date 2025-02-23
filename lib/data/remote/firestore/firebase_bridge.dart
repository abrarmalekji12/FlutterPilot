import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_config.dart';
import '../../../common/api/api_model.dart';
import '../../../common/app_loader.dart';
import '../../../common/logger.dart';
import '../../../common/web/io_lib.dart';
import '../../../components/component_impl.dart';
import '../../../constant/preference_key.dart';
import '../../../constant/string_constant.dart';
import '../../../cubit/component_operation/operation_cubit.dart';
import '../../../firebase_options.dart';
import '../../../injector.dart';
import '../../../models/fvb_ui_core/component/component_model.dart';
import '../../../models/fvb_ui_core/component/custom_component.dart';
import '../../../models/global_component.dart';
import '../../../models/other_model.dart';
import '../../../models/project_model.dart';
import '../../../models/template_model.dart';
import '../../../models/templates/template_model.dart';
import '../../../models/user/user_setting.dart';
import '../../../models/variable_model.dart';
import '../../../models/version_control/version_control_model.dart';
import '../../../network/auth_response/auth_response_model.dart';
import '../../../ui/boundary_widget.dart';
import '../../../ui/feedback/model/feedback.dart';
import '../../../ui/paint_tools/paint_tools.dart';
import '../../../view_model/auth_viewmodel.dart';
import '../common_data_models.dart';
import '../data_bridge.dart';
import 'firebase_lib.dart';

const int _kThousand = 1000;
const int _kMillion = 1000000;

final FirebaseFirestore fireStore = FirebaseFirestore.instance;
final FirebaseStorage storage =
    FirebaseStorage.instanceFor(bucket: appConfig.storageBucket);
final FirebaseDataBridge dataBridge = FirebaseDataBridge();

enum DBType { old, latest1 }

const DBType dbType = DBType.latest1;

String get randomId {
  const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  return String.fromCharCodes(Iterable.generate(
      28,
      (_) => _chars.codeUnitAt(
            _rnd.nextInt(_chars.length),
          )));
}

String randomIdOf(int chars) {
  const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  return String.fromCharCodes(Iterable.generate(
      chars,
      (_) => _chars.codeUnitAt(
            _rnd.nextInt(_chars.length),
          )));
}

class FirebaseDataBridge extends DataBridge {
  bool initialized = false;
  FirebaseApp? app;

  @override
  Future<void> init() async {
    // await Firebase.initializeApp(
    //     options: FirebaseOptions.fromMap(const {
    //   'apiKey': 'AIzaSyBCYM-y341AVf0v-Ix6dq7UXhnDbIFjwOk',
    //   'authDomain': 'flutter-visual-builder.firebaseapp.com',
    //   'projectId': 'flutter-visual-builder',
    //   'storageBucket': 'flutter-visual-builder.appspot.com',
    //   'messagingSenderId': '357010413683',
    //   'appId': '1:357010413683:web:851137f5a4916cc6587206'
    // }));
    if (initialized) {
      return;
    }
    // await Firebase.initializeApp(
    //     options: const FirebaseOptions(
    //         apiKey: 'AIzaSyDOJQUOBFfomuLrYK6oCXr8-uJMXo-AByg',
    //         authDomain: 'flutter-visual-builder-2.firebaseapp.com',
    //         projectId: 'flutter-visual-builder-2',
    //         storageBucket: 'flutter-visual-builder-2.appspot.com',
    //         messagingSenderId: '1087783488343',
    //         appId: '1:1087783488343:web:3fc0a75ab1e3ef3da88c12'));

    if (!Platform.isIOS && !Platform.isMacOS) {
      await Firebase.initializeApp(
          options: const FirebaseOptions(
              apiKey: 'AIzaSyBCwzU0FyuCsD-pDX4Vvt3oHth4KdNWwnw',
              authDomain: 'flutter-visual-builder-staging.firebaseapp.com',
              projectId: 'flutter-visual-builder-staging',
              storageBucket: 'flutter-visual-builder-staging.appspot.com',
              messagingSenderId: '585919568929',
              appId: '1:585919568929:web:20c22834346fe6ad98d760'));
    }
    else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    initialized = true;
  }

  @override
  Future<bool> connect(String id, Map<String, dynamic> map) async {
    try {
      if (!Platform.isMacOS &&
          map['apiKey'] is String &&
          map['appId'] is String &&
          map['messagingSenderId'] is String &&
          map['projectId'] is String &&
          map['authDomain'] is String &&
          map['storageBucket'] is String)
        app = await Firebase.initializeApp(
          name: id,
          options: FirebaseOptions(
            apiKey: map['apiKey'],
            appId: map['appId'],
            messagingSenderId: map['messagingSenderId'],
            projectId: map['projectId'],
            authDomain: map['authDomain'],
            storageBucket: map['storageBucket'],
          ),
        );
      return true;
    } on Exception catch (e) {
      print('Error ${e.toString()}');
    }
    return false;
  }

  @override
  Future<bool> disconnect() async {
    try {
      if (app != null) {
        app = null;
      }
      return true;
    } on Exception catch (e) {
      print('Error ${e.toString()}');
    }
    return false;
  }

  @override
  Future<void> assistOperationAdd(
      String path, String? docId, Map<String, dynamic> data) async {
    if (app == null) {
      return;
    }
    final split = path.split('/');
    dynamic collection =
        FirebaseFirestore.instanceFor(app: app!).collection(split[0]);
    for (int i = 1; i < split.length; i++) {
      if (split[i].isNotEmpty) {
        if (i % 2 != 0) {
          collection = collection.doc(split[i]);
        } else {
          collection = collection._collection(split[i]);
        }
      }
    }
    if (collection is CollectionReference) {
      if (docId != null) {
        await collection.doc(docId).set(data);
      } else {
        await collection.add(data);
      }
    }
  }

  @override
  Future<void> assistOperationUpdate(
      String path, String? docId, Map<String, dynamic> data) async {
    if (app == null) {
      return;
    }
    final split = path.split('/');
    dynamic collection =
        FirebaseFirestore.instanceFor(app: app!).collection(split[0]);
    for (int i = 1; i < split.length; i++) {
      if (split[i].isNotEmpty) {
        if (i % 2 != 0) {
          collection = collection.doc(split[i]);
        } else {
          collection = collection._collection(split[i]);
        }
      }
    }
    if (collection is CollectionReference) {
      if (docId != null) {
        await collection.doc(docId).update(data);
      }
    }
  }

  @override
  Future<void> updateCustomComponent(
      FVBProject project, CustomComponent customComponent) async {
    await FirePath.customComponent(customComponent.id)
        .update(customComponent.toMainJson());
  }

  @override
  Future<void> addCustomComponent(String userId, FVBProject flutterProject,
      CustomComponent customComponent) async {
    await FirePath.customComponent(customComponent.id)
        .set(customComponent.toMainJson());

    logger('=== FIRE-BRIDGE == addNewGlobalCustomComponent ==');
  }

  @override
  Future<void> removeCustomComponent(
      String userId, FVBProject project, CustomComponent component) async {
    await FirePath.customComponent(component.id).delete();
    logger('=== FIRE-BRIDGE == deleteGlobalCustomComponent ==');
  }

  /// Delete Project
  @override
  Future<void> deleteProject(String userId, FVBProject project,
      final List<FVBProject> projects) async {
    final screens = await fireStore
        .collection(Collections.kScreens)
        .where('projectId', isEqualTo: project.id)
        .get();
    final customComponents = await fireStore
        .collection(Collections.kCustomComponents)
        .where('projectId', isEqualTo: project.id)
        .get();
    await Future.wait([
      fireStore.collection(Collections.kProjects).doc(project.id).delete(),
      for (final screen in screens.docs) FirePath.screen(screen.id).delete(),
      for (final component in customComponents.docs)
        FirePath.customComponent(component.id).delete(),
    ]);
  }

  @override
  Future<void> addToTemplates(FVBTemplate template) async {
    await FirePath.template(template.id).set(template.toJson());
  }

  @override
  Future<List<FVBTemplate>?> loadTemplates({String? userId}) async {
    dynamic query = fireStore.collection(Collections.kTemplates);
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    } else {
      query = query.where('public', isEqualTo: true);
    }
    final templates = await query.get();
    List<FVBTemplate> fvbTemplates = templates.docs
        .map<FVBTemplate>((e) => FVBTemplate.fromJson(e.data()))
        .toList();
    await Future.wait(fvbTemplates
        .where((element) => element.imageURLs.isNotEmpty)
        .expand((v) => v.imageURLs)
        .map((e) => loadRefImage(ImageRef.templateImage(e), e)));
    return fvbTemplates;
  }

  @override
  Future<void> moveDocument(List<DocData> fromData, List<DocData> toData,
      {bool deleteOld = true, Map<String, dynamic>? additionalData}) async {
    final Map<String, dynamic>? data;
    late DocumentReference reference = fireStore
        .collection(fromData.first.collectId)
        .doc(fromData.first.docId);
    for (final doc in fromData.sublist(1)) {
      reference = reference.collection(doc.collectId).doc(doc.docId);
    }
    data = (await reference.get()).data() as Map<String, dynamic>;
    late DocumentReference destReference =
        fireStore.collection(toData.first.collectId).doc(toData.first.docId);
    for (final doc in toData.sublist(1)) {
      destReference = destReference.collection(doc.collectId).doc(doc.docId);
    }
    await destReference.set(data..addAll(additionalData ?? {}));
    if (deleteOld) {
      await reference.delete();
    }
  }

  @override
  Future<void> moveCollection(List<DocData> fromData, List<DocData> toData,
      {bool deleteOld = true,
      Map<String, dynamic>? additionalData,
      snapshot,
      String? appendTargetDocKey}) async {
    final List<DocumentSnapshot>? data;
    late CollectionReference reference =
        fireStore.collection(fromData.first.collectId);
    if (snapshot != null) {
      for (final doc in fromData.sublist(1)) {
        reference = reference.doc(doc.docId).collection(doc.collectId);
      }
      data = (await reference.get()).docs;
    } else {
      data = snapshot!.docs;
    }
    late CollectionReference destReference =
        fireStore.collection(toData.first.collectId);
    for (final doc in toData.sublist(1)) {
      destReference = destReference.doc(doc.docId).collection(doc.collectId);
    }
    for (final DocumentSnapshot doc in data ?? []) {
      await destReference.doc(doc.id + (appendTargetDocKey ?? '')).set(
          (doc.data() as Map<String, dynamic>)..addAll(additionalData ?? {}));
      if (deleteOld) {
        await reference.doc(doc.id).delete();
      }
    }
  }

  @override
  Future<List<FavouriteModel>> loadFavourites(final String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    snapshot =
        await FirePath.user(userId).collection(Collections.kFavourites).get();

    final List<FavouriteModel> favouriteModels = [];
    for (final document in snapshot.docs) {
      final json = document.data();
      final List<CustomComponent> customComponents = [];
      for (final doc in ((json['customComponents'] as List?) ?? [])) {
        final Map<String, dynamic> componentBody = doc as Map<String, dynamic>;
        customComponents.add(CustomComponent.fromJson(componentBody));
      }
      fetchCustomComponentsFromJson(((json['customComponents'] as List?) ?? []),
          customComponents, customComponents);
      favouriteModels.add(FavouriteModel.fromJson(customComponents, json));
      for (final custom in customComponents)
        collection.project!.customComponents.remove(custom);
    }
    return favouriteModels;
  }

  @override
  Future<Map<String, List<CustomComponent>>> loadAllCustomComponents(
      final String userId) async {
    final snapshot = await fireStore
        .collection(Collections.kCustomComponents)
        .where('userId', isEqualTo: userId)
        .get();
    final List<CustomComponent> list =
        snapshot.docs.map((e) => CustomComponent.fromJson(e.data())).toList();

    for (int i = 0; i < list.length; i++) {
      final Map<String, dynamic> componentBody = snapshot.docs[i].data();
      list[i].rootComponent = componentBody['code'] != null
          ? Component.fromJson(componentBody['code']!, collection.project!)
          : null;
    }
    final Map<String, List<CustomComponent>> map = {};
    for (final comp in list) {
      if (comp.project != null) {
        if (map.containsKey(comp.project?.id)) {
          map[comp.project!.id]!.add(comp);
        } else {
          map[comp.project!.id] = [comp];
        }
      }
    }
    return map;
  }

  @override
  Future<void> uploadTemplate(TemplateModel model) async {
    await Future.wait([
      fireStore
          .collection(Collections.kScreenTemplates)
          .doc(model.id)
          .set(model.toJson()),
      for (final image in model.images)
        if (image.bytes != null)
          storage.ref(ImageRef.publicImages(image.name!)).putData(image.bytes!)
    ]);
  }

  @override
  Future<void> deleteTemplate(TemplateModel model) async {
    final docs = await fireStore
        .collection(Collections.kScreenTemplates)
        .where('name', isEqualTo: model.name)
        .where('publisherId', isEqualTo: model.publisherId)
        .where('description', isEqualTo: model.description)
        .where('timeStamp', isEqualTo: model.timeStamp)
        .get();
    await Future.wait([
      docs.docs[0].reference.delete(),
      for (final image in model.images)
        storage.ref(ImageRef.publicImages(image.name!)).delete()
    ]);
  }

  @override
  Future<List<GlobalComponentModel>?> loadGlobalComponentList() async {
    final data = await fireStore.collection(Collections.kComponents).get();
    if (data.docs.isNotEmpty) {
      final list = List.generate(
        data.docs.length,
        (index) => GlobalComponentModel.fromJson(data.docs[index].data())
          ..id = data.docs[index].id,
      );
      // for (int i = 0; i < list.length; i++) {
      //   fireStore.collection('components').doc(data.docs[i].id).update({
      //     'component': list[i].component.toJson(),
      //     'customs':list[i].customs.map((e) => e.toJson()).toList()
      //   });
      // }
      return list;
    }
    return null;
  }

  @override
  Future<bool> updateFVBPaintObj(
      FVBProject project, String id, List<FVBPaintObj> obj) async {
    try {
      await FirePath.project(project.userId)
          .collection(Collections.kPaintObjs)
          .doc(id)
          .set({'objList': obj.map((e) => e.toJson()).toList(growable: false)});
      return true;
    } on Exception catch (e) {
      print(e);
      return false;
    }
  }

  @override
  Future<bool> addGlobalComponent(
    String? id,
    GlobalComponentModel model,
  ) async {
    final json = model.toJson();
    if (id == null) {
      id = randomId;
      model.id = id;
    }
    await fireStore.collection(Collections.kComponents).doc(id).set(json);
    return true;
  }

  @override
  Future<void> addFeedback(FVBFeedback feedback) async {
    await fireStore
        .collection(Collections.kFeedbacks)
        .doc(feedback.id)
        .set(feedback.toJson());
  }

  @override
  Future<bool> removeGlobalComponent(String id) async {
    await fireStore.collection('components').doc(id).delete();
    return true;
  }

  @override
  Future<TemplatePaginate> loadScreenTemplateList(last, int count,
      {String? userId}) async {
    final query = last != null
        ? await fireStore
            .collection(Collections.kScreenTemplates)
            .startAfterDocument(last)
            .limit(count)
        : await fireStore.collection(Collections.kScreenTemplates).limit(count);

    final list = await (userId != null
        ? query.where('publisherId', isEqualTo: userId).get()
        : query.get());
    final List<TemplateModel> templates = [];
    for (final template in list.docs) {
      final List<CustomComponent> customComponents = [];
      final json = template.data();
      final variables = List.from(json['variables'] ?? [])
          .map((e) => VariableModel.fromJson(e))
          .toList(growable: false);
      for (final doc in ((json['customComponents'] as List?) ?? [])) {
        final Map<String, dynamic> componentBody = doc as Map<String, dynamic>;
        customComponents.add(
            CustomComponent.fromJson(componentBody, parentVars: variables));
      }
      fetchCustomComponentsFromJson(((json['customComponents'] as List?) ?? []),
          customComponents, customComponents);
      final model = TemplateModel.fromJson(json, variables);
      model.customComponents.addAll(customComponents);
      // final images = await Future.wait(
      //     [for (final image in model.images) storage.ref(Images.publicImages(image.name!)).getData()]);
      model.screen.rootComponent = Component.fromJson(
          json['screen']['root'], null,
          customs: customComponents);
      templates.add(model);
    }
    templates.sort(
        (temp1, temp2) => temp1.createdAt.isAfter(temp2.createdAt) ? -1 : 0);
    return TemplatePaginate(templates, list.docs.lastOrNull);
  }

  @override
  Future<bool> uploadPublicImage(FVBImage image) async {
    try {
      if (image.id == null) {
        image.id = randomId;
      }
      image.path = ImageRef.publicImages(image.name!);
      await Future.wait([
        fireStore
            .collection(Collections.kImages)
            .doc(image.id)
            .set(image.toJson()),
        storage.ref(image.path!).putData(image.bytes!)
      ]);
      return true;
    } on Exception catch (e) {
      print('PUBLIC IMAGE UPLOAD ${e.toString()}');
      return false;
    }
  }

  @override
  Future<FVBImage?> getPublicImage(String image) async {
    if (byteCache.containsKey(image)) {
      return FVBImage(name: image, bytes: byteCache[image]);
    }
    final [data as QuerySnapshot?, (bytes as Uint8List?)] = await Future.wait([
      fireStore
          .collection(Collections.kImages)
          .where('name', isEqualTo: image)
          .get(),
      storage.ref(ImageRef.publicImages(image)).getData()
    ]);
    if (data?.docs.isNotEmpty ?? false) {
      final imageData =
          FVBImage.fromJson(data!.docs.first.data() as Map<String, dynamic>);
      if (bytes?.isNotEmpty ?? false) {
        imageData.bytes = bytes;
        byteCache[imageData.name!] = bytes!;
        return imageData;
      }
    }
    return null;
  }

  @override
  Future<void> addToFavourites(String userId, FavouriteModel model) async {
    model.id = randomId;
    await fireStore
        .collection(Collections.kUsers)
        .doc(userId)
        .collection(Collections.kFavourites)
        .doc(model.id!)
        .set(model.toJson());
  }

  @override
  Future<void> removeFromFavourites(String userId, String id) async {
    final snapshot = await FirePath.user(userId)
        .collection(Collections.kFavourites)
        .where('id', isEqualTo: id)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs[0].reference.delete();
    }
  }

  @override
  Future<AuthResponse> registerUser(FVBUser model) async {
    try {
      final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: model.email, password: model.password);
      if (user.user == null) {
        return AuthResponse.right('User could not added');
      }
      model.userId = user.user!.uid;
      await fireStore
          .collection(Collections.kUsers)
          .doc(user.user!.uid)
          .set(model.toJson());

      return AuthResponse.left(model);
    } on FirebaseAuthException catch (e) {
      return AuthResponse.right(
        switch (e.code) {
          'ERROR_EMAIL_ALREADY_IN_USE' ||
          'account-exists-with-different-credential' ||
          'email-already-in-use' ||
          'EMAIL_EXISTS' =>
            'Email already exist. Please use different email',
          'ERROR_INVALID_EMAIL' ||
          'invalid-email' =>
            'Email address is invalid.',
          'ERROR_USER_DISABLED' || 'user-disabled' => 'User disabled.',
          'ERROR_TOO_MANY_REQUESTS' ||
          'operation-not-allowed' =>
            'Too many requests to log into this account.',
          'ERROR_OPERATION_NOT_ALLOWED' ||
          'operation-not-allowed' =>
            'Server error, please try again later.',
          _ => 'Something went wrong! Please try again.',
        },
      );
    }
  }

  @override
  Future<List<FVBProject>?> loadProjectList(
    String userId,
  ) async {
    final List<FVBProject>? projectList = (await Future.wait([
      fireStore
          .collection(Collections.kProjects)
          .where('userId', isEqualTo: userId)
          .get(),
      fireStore
          .collection(Collections.kProjects)
          .where('collaboratorIds', arrayContains: userId)
          .get(),
    ]))
        .expand((element) => element.docs)
        .map((e) => FVBProject.fromJson(e.data()))
        .toList();
    projectList?.sort((a, b) => (b.updatedAt == null)
        ? 0
        : (a.updatedAt == null
            ? 1
            : (b.updatedAt!.isAfter(a.updatedAt!))
                ? 1
                : -1));
    return projectList;
  }

  @override
  Future<UserSettingModel?> loadUserDetails(String userId) async {
    final snapshot =
        await fireStore.collection(Collections.kUsers).doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    if (snapshot.data() != null) {
      final model = UserSettingModel.fromJson(snapshot.data()!);
      return model;
    }
    return null;
  }

  @override
  Future<FVBUser?> loadUserDetailsFromEmail(String email) async {
    final snapshot = await fireStore
        .collection(Collections.kUsers)
        .where('email', isEqualTo: email)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return FVBUser.fromJson(snapshot.docs.first.data());
  }

  @override
  Future<void> createProject(String userId, FVBProject project) async {
    final List<CustomComponent> components = project.customComponents;
    project.id = randomId;
    await fireStore
        .collection(Collections.kProjects)
        .doc(project.id)
        .set(project.toJson());
    AppLoader.update(0.3);
    await Future.wait([
      for (final screen in project.screens)
        fireStore
            .collection(Collections.kScreens)
            .doc(screen.id)
            .set(screen.toJson())
    ]);

    AppLoader.update(0.5);
    await Future.wait([
      for (final component in components)
        fireStore
            .collection(Collections.kCustomComponents)
            .doc(component.id)
            .set(component.toMainJson())
    ]);
    AppLoader.update(0.9);
  }

  @override
  Stream<Component> loadMainScreen(
      FVBProject project, OperationCubit operationCubit) {
    if (project.mainScreen == null) {
      return const Stream.empty();
    }
    return fireStore
        .collection(Collections.kScreens)
        .doc(project.mainScreen!.id)
        .snapshots()
        .map((event) {
      final comp = Component.fromJson(
        event.data()?['root'],
        project,
      );
      final List<Component> list = [];
      comp.forEach((p0) {
        if (p0 is CNotRecognizedWidget || p0 is CustomComponent) {
          list.add(p0);
        }
        return false;
      });
      for (final component in list) {
        final custom = StreamComponent(
          loadCustomComponentStream(project, component.id),
        );
        operationCubit.replaceChildOfParent(component, custom);
      }
      return comp;
    });
  }

  @override
  Stream<Component> loadCustomComponentStream(FVBProject project, String id) {
    return fireStore
        .collection(Collections.kCustomComponents)
        .doc(id)
        .snapshots()
        .map((event) {
      final customComponent = CustomComponent.fromJson(event.data()!,
          project: project,
          parentVars:
              project.variables.values.whereType<VariableModel>().toList());
      final code = event.data()!['code'];
      customComponent.rootComponent = code != null
          ? Component.fromJson(code, null, customs: project.customComponents)
          : null;
      project.customComponents.removeWhere((element) => element.id == id);
      project.customComponents.add(customComponent);
      return customComponent;
    });
  }

  @override
  Future<Optional<FVBProject, ProjectLoadErrorModel>> loadProject(String id,
      {bool checkIfPublic = false}) async {
    try {
      final snapshot =
          await fireStore.collection(Collections.kProjects).doc(id).get();
      if (!snapshot.exists) {
        return Optional.right(ProjectLoadErrorModel(
            ProjectLoadError.notFound, 'Project "$id" not found'));
      }
      AppLoader.update(0.5);
      if (!checkIfPublic)
        fireStore.collection(Collections.kProjects).doc(id).update({
          'updatedAt': timestamp(DateTime.now()),
        });
      final projectData = snapshot.data() as Map<String, dynamic>;

      final FVBProject project = FVBProject.fromJson(projectData);
      if (checkIfPublic && !project.settings.isPublic) {
        return Optional.right(
            ProjectLoadErrorModel(ProjectLoadError.notPermission, null));
      }
      project.apiModel = projectData['apiModel'] != null
          ? ApiGroupModel.fromJson(projectData['apiModel'], project)
          : ApiGroupModel([], [], project);

      // for (final modelJson in projectData['models'] ?? []) {
      //   final model = LocalModel.fromJson(modelJson);
      //   flutterProject.models.add(model);
      // }

      // for (final modelJson in projectData['screens'] ?? []) {
      //   final screen = UIScreen.fromJson(modelJson, flutterProject);
      //   flutterProject.uiScreens.add(screen);
      // }

      AppLoader.update(0.6);

      /// Old-fashion code to load custom-components
      // final customDocs = await FirePath.customComponentsReferenceByProjectName(userId, project.id).get();
      // customDocuments = customDocs.docs;
      // await moveCollection([DocData('us$userId', ''), DocData('Custom|${project.id}', Collections.kProjects)],
      //     [DocData('us$userId', ''), DocData('Custom', Collections.kProjects)],
      //     additionalData: {'project': project.name},
      //     snapshot: customDocs,
      //     deleteOld: false,
      //     appendTargetDocKey: '|${project.name}');

      final [
        List<DocumentSnapshot<Map<String, dynamic>>> customDocumentSnapshot,
        List<DocumentSnapshot<Map<String, dynamic>>> screenDocuments,
      ] = await Future.wait([
        Future<List<DocumentSnapshot<Map<String, dynamic>>>>(() async {
          return (await fireStore
                  .collection(Collections.kCustomComponents)
                  .where('projectId', isEqualTo: project.id)
                  .get())
              .docs;
        }),
        Future<List<DocumentSnapshot<Map<String, dynamic>>>>(() async {
          return (await fireStore
                  .collection(Collections.kScreens)
                  .where('projectId', isEqualTo: project.id)
                  .get())
              .docs;
        })
      ]);
      AppLoader.update(0.8);
      _extractCustomComponentModelFromDocs(
          project.customComponents, customDocumentSnapshot, project);

      _extractScreenModelFromDocs(project.screens, screenDocuments, project);
      if (project.screens.isNotEmpty && projectData['mainScreen'] != null) {
        project.mainScreen = project.screens.firstWhereOrNull(
                (element) => element.id == projectData['mainScreen']) ??
            project.screens.first;
      }

      try {
        List.from(projectData['models'] ?? [])
            .forEach((e) => FVBModelClass.fromJson(e, project));
      } on Exception catch (e) {
        print('MODELS ERROR $e');
        e.printError();
      }
      return Optional.left(project);
    } on Exception catch (e) {
      print('Load Project ERROR $e');
      e.printError();
      return Optional.right(
          ProjectLoadErrorModel(ProjectLoadError.otherError, e.toString()));
    }
  }

  @override
  void fetchCustomComponentsFromJson(
      List<dynamic> customDocuments,
      List<CustomComponent> customComponents,
      List<CustomComponent> allCustomComponents) {
    for (int i = 0; i < customDocuments.length; i++) {
      final Map<String, dynamic> componentBody =
          customDocuments[i] as Map<String, dynamic>;
      customComponents[i].rootComponent = componentBody['code'] != null
          ? Component.fromJson(componentBody['code']!, null,
              customs: allCustomComponents)
          : null;
    }
    for (int i = 0; i < customDocuments.length; i++) {
      customComponents[i].rootComponent?.forEachWithClones((p0) {
        if (p0 is CustomComponent) {
          p0.rootComponent = allCustomComponents
              .firstWhere((element) => element.name == p0.name)
              .rootComponent
              ?.clone(null, deepClone: false, connect: true);
        }
        return false;
      });
    }
  }

  @override
  Future<Uint8List?> loadImage(String userId, String name) async {
    if (byteCache.containsKey(name)) {
      return byteCache[name]!;
    }
    try {
      final bytes =
          await storage.ref(ImageRef.userImages(userId, name)).getData();
      if (bytes?.isNotEmpty ?? false) {
        byteCache[name] = bytes!;
        return bytes;
      }
    } on Exception catch (e) {
      print('EXCEPTION ${e.toString()}');
    }
    return null;
  }

  @override
  Future<Uint8List?> loadRefImage(String path, String name) async {
    if (byteCache.containsKey(name)) {
      return byteCache[name]!;
    }
    final bytes = await storage.ref(path).getData();
    if (bytes?.isNotEmpty ?? false) {
      byteCache[name] = bytes!;
      return bytes;
    }
    return null;
  }

  @override
  Future<List<FVBImage>?> loadAllImages(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> image;
    image = await fireStore
        .collection(Collections.kUsers)
        .doc(userId)
        .collection(Collections.kImages)
        .get();
    if (image.docs.isNotEmpty) {
      final List<FVBImage> list = [];

      for (final doc in image.docs) {
        list.add(FVBImage.fromJson(doc.data()));
      }
      final imageData = await Future.wait([
        for (int i = 0; i < list.length; i++)
          storage.ref(ImageRef.userImages(userId, list[i].name!)).getData()
      ]);
      for (int i = 0; i < list.length; i++) {
        if (imageData[i]?.isNotEmpty ?? false) {
          list[i].bytes = imageData[i];
        }
      }
      return list;
    }
    return null;
  }

  @override
  Future<String?> resetPassword(String userName) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: userName);
    return null;
  }

  bool isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  String? get currentUserId => sl<SharedPreferences>().getString(PrefKey.UID);

  @override
  Future<FVBUser?> tryLoginWithPreference() async {
    final pref = sl<SharedPreferences>();
    if (pref.containsKey(PrefKey.userData)) {
      Map? userData;
      try {
        userData = jsonDecode(pref.getString(PrefKey.userData) ?? '');
      } catch (e) {}
      if (userData != null) {
        final model = FVBUser.fromJson(userData);
        final response = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: model.email, password: model.password);
        if (response.user != null) {
          return model;
        } else {
          return null;
        }
      }
    }
    return null;
  }

  @override
  Future<void> loginAnonymously() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  @override
  Future<AuthResponse> login(String userName, String password) async {
    try {
      final loginResponse = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: userName, password: password);
      if (loginResponse.user == null) {
        return AuthResponse.right('Login failed');
      }
      final response = await fireStore
          .collection(Collections.kUsers)
          .doc(loginResponse.user!.uid)
          .get();
      if (!response.exists || response.data() == null) {
        return AuthResponse.right('User-data doesn\'t exist!');
      }
      final data = response.data();

      /// For old-data refreshment
      if (data!['userId'] is int) {
        data['userId'] = loginResponse.user!.uid;
      }
      final pref = sl<SharedPreferences>();
      pref.setString(PrefKey.UID, data['userId']);
      final userData = {...data, 'password': password};
      pref.setString(PrefKey.userData, jsonEncode(userData));
      return AuthResponse.left(FVBUser.fromJson(data));
    } on FirebaseAuthException catch (e) {
      return AuthResponse.right(switch (e.code) {
        'EMAIL_NOT_FOUND' => 'Invalid credentials. Please try again',
        'ERROR_WRONG_PASSWORD' ||
        'INVALID_PASSWORD' ||
        'wrong-password' =>
          'Password is invalid',
        'ERROR_USER_NOT_FOUND' ||
        'user-not-found' =>
          'No user found with this email.',
        'ERROR_INVALID_EMAIL' || 'invalid-email' => 'Email address is invalid.',
        'ERROR_USER_DISABLED' ||
        'USER_DISABLED' ||
        'user-disabled' =>
          'User is Disabled.',
        'ERROR_TOO_MANY_REQUESTS' ||
        'operation-not-allowed' =>
          'Too many requests to log into this account.',
        'ERROR_OPERATION_NOT_ALLOWED' ||
        'operation-not-allowed' =>
          'Server error, please try again later.',
        _ =>e.message??'',
      });
    }
  }

  Future<void> updateProjectThumbnail(
      FVBProject project, Uint8List thumbnail) async {
    await storage.ref(ImageRef.projectThumbnail(project)).putData(thumbnail);
  }

  @override
  Future<void> uploadImage(
      String userId, String projectId, FVBImage image) async {
    image.id = randomId;
    final path = ImageRef.userImages(userId, image.name!);
    image.path = path;
    if (byteCache.containsKey(image.name)) {
      await Future.wait([
        storage.ref(path).putData(byteCache[image.name!]!),
        fireStore
            .collection(Collections.kUsers)
            .doc(userId)
            .collection(Collections.kImages)
            .doc(image.id)
            .set(image.toJson()),
      ]);
    }
  }

  @override
  Future<void> uploadImageOnPath(String path, FVBImage image) async {
    image.id = randomId;
    image.path = path;
    await Future.wait([
      storage.ref(path).putData(image.bytes!),
    ]);
  }

  @override
  Future<void> removeImage(String userId, String name) async {
    final snapshot = await fireStore
        .collection(Collections.kUsers)
        .doc(userId)
        .collection(Collections.kImages)
        .where('name', isEqualTo: name)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await Future.wait([
        snapshot.docs[0].reference.delete(),
        storage.ref(ImageRef.userImages(userId, name)).delete(),
      ]);
    }
  }

  // @override
  // Future<void> addModel(
  //     final String userId, final FVBProject project, final LocalModel localModel, Screen screen) async {
  //   await fireStore.collection(Collections.kProjects).doc(project.id).update({
  //     'models': FieldValue.arrayUnion([localModel.toJson()])
  //   });
  //   logger('=== FIRE-BRIDGE == addLocalModel ==');
  //   // }
  // }

  @override
  Future<void> addVariables(final String userId, final FVBProject project,
      final List<VariableModel> variables) async {
    if (Platform.isWindows) {
      final variablesRef = FirePath.project(project.id);
      final oldResponse = await variablesRef.get();
      if (oldResponse.data() is Map &&
          (oldResponse.data() as Map)['variables'] != null) {
        final variablesMap = (oldResponse.data() as Map)['variables'];
        await variablesRef.update({
          'variables': List.from(variablesMap ?? [])
            ..addAll(variables.map((e) => e.toJson()))
        });
      } else {
        await variablesRef.update({
          'variables': variables.map((e) => e.toJson()).toList(growable: false)
        });
      }
    } else {
      await FirePath.project(project.id).update({
        'variables': FieldValue.arrayUnion(
            variables.map((e) => e.toJson()).toList(growable: false))
      });
    }
    logger('=== FIRE-BRIDGE == addVariable ==');
  }

  @override
  Future<void> addVariableForScreen(
      final String userId,
      final FVBProject project,
      final VariableModel variableModel,
      Screen screen) async {
    if (Platform.isWindows) {
      final variablesRef = FirePath.screen(screen.id);
      final oldResponse = await variablesRef.get();
      if ((oldResponse.data() as Map?)!['variables'] != null) {
        await variablesRef.update({
          'variables': List.from((oldResponse.data()! as Map)['variables'])
            ..add(variableModel.toJson())
        });
      }
    } else {
      await FirePath.screen(screen.id).update({
        'variables': FieldValue.arrayUnion([variableModel.toJson()])
      });
    }
    logger('=== FIRE-BRIDGE == addVariable ==');
  }

  @override
  Future<void> updateVariable(
      final String userId, final FVBProject project) async {
    await FirePath.project(project.id).update({
      'variables': project.variables.values
          .where((element) =>
              element is VariableModel &&
              element.uiAttached &&
              !element.isDynamic)
          .map((e) => e.toJson())
          .toList(growable: false)
    });
    logger('=== FIRE-BRIDGE == update variable ==');
  }

  @override
  Future<void> updateModels(
      final String userId, final FVBProject project) async {
    await FirePath.project(project.id).update({
      'models': Processor.classes.values
          .whereType<FVBModelClass>()
          .map((e) => e.toJson())
          .toList(growable: false)
    });
    logger('=== FIRE-BRIDGE == update models ==');
  }

  @override
  Future<void> updateUIScreenVariable(Screen screen) async {
    await FirePath.screen(screen.id).update({
      'variables': screen.variables.values
          .where((element) =>
              element is VariableModel &&
              element.uiAttached &&
              !element.isDynamic)
          .map((e) => e.toJson())
          .toList(growable: false)
    });
    logger('=== FIRE-BRIDGE == update variable ==');
  }

  @override
  Future<void> updateVariableForCustomComponent(
    final String userId,
    final FVBProject project,
    final CustomComponent component,
  ) async {
    await FirePath.customComponent(component.id).update({
      'variables': component.variables.values
          .where((element) =>
              element is VariableModel &&
              element.uiAttached &&
              !element.isDynamic)
          .map((e) => e.toJson())
          .toList(growable: false)
    });
    logger('=== FIRE-BRIDGE == update variable ==');
  }

  @override
  Future<void> updateCustomComponentActionCode(
      final CustomComponent component) async {
    await FirePath.customComponent(component.id).update({
      'actionCode': component.actionCode,
    });
  }

  @override
  Future<void> updateCustomComponentArguments(
      final CustomComponent component) async {
    await FirePath.customComponent(component.id).update({
      'arguments': component.argumentVariables
          .map((e) => e.toJson())
          .toList(growable: false),
    });
  }

  @override
  Future<void> updateCustomComponentField(
      final CustomComponent component, String key, dynamic value) async {
    await FirePath.customComponent(component.id).update({key: value});
  }

  @override
  Future<void> updateDeviceSelection(final String userId,
      final FVBProject project, final String device) async {
    await FirePath.project(project.id).update({'device': device});
  }

  @override
  Future<void> updateProjectSettings(final FVBProject project) async {
    await FirePath.project(project.id)
        .update({'settings': project.settings.toJson()});
  }

  @override
  Future<void> updateCurrentScreen(
      String userId, final FVBProject project, Viewable screen) async {
    await FirePath.project(project.id).update({'currentScreen': screen.id});
  }

  @override
  Future<void> updateMainScreen(String userId, final FVBProject project) async {
    await FirePath.project(project.id)
        .update({'mainScreen': project.mainScreen?.id});
  }

  @override
  Future<void> updateProjectValue(
      final FVBProject project, String key, dynamic value) async {
    await FirePath.project(project.id).update({key: value});
  }

  @override
  Future<void> updateUserValue(
      final String userId, String key, dynamic value) async {
    await FirePath.user(userId).update({key: value});
  }

  @override
  Future<void> updateActionCode(String userId, final FVBProject project) async {
    await FirePath.project(project.id)
        .update({'actionCode': project.actionCode});
  }

  @override
  Future<void> updateScreenActionCode(
      String userId, final FVBProject project, Screen screen) async {
    await fireStore.collection(Collections.kScreens).doc(screen.id).update(
      {
        'actionCode': screen.actionCode,
      },
    );
  }

  @override
  Future<void> updateScreenValue(
      Screen screen, String key, String value) async {
    await fireStore.collection(Collections.kScreens).doc(screen.id).update(
      {
        key: value,
      },
    );
  }

  // static Future<void> updateRootComponent(
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
  @override
  Future<void> createScreen(final String userId, final FVBProject project,
      final Screen uiScreen) async {
    final screen = uiScreen.toJson();
    await fireStore
        .collection(Collections.kScreens)
        .doc(uiScreen.id)
        .set(screen);
    logger('=== FIRE-BRIDGE == addUIScreen ==');
  }

  Future<void> updateScreenRootComponent(final String userId,
      final Screen screen, final Component? component) async {
    // final code = CodeOperations.trim(
    //   component?.code(clean: false),
    // );
    final json = component?.toJson();
    await FirePath.screen(screen.id).update({
      'root': json,
    });
  }

  Future<void> updateProjectRootComponent(final FVBProject project) async {
    // final code = CodeOperations.trim(
    //   component?.code(clean: false),
    // );
    final json = project.rootComponent?.toJson();
    await FirePath.project(project.id).update({
      'rootComponent': json,
    });
  }

  static void check(value) {
    if (value is Map) {
      value.forEach((key, value) {
        check(key);
        check(value);
      });
    } else if (value is List) {
      value.forEach((element) {
        check(element);
      });
    } else if (value != null &&
        value is! num &&
        value is! bool &&
        value is! String) {
      print('TYPE $value');
    }
  }

  @override
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await sl<SharedPreferences>().clear();
  }

  @override
  Future<void> removeScreen(final String userId,
      final FVBProject flutterProject, final Screen screen) async {
    await fireStore.collection(Collections.kScreens).doc(screen.id).delete();
  }

  static timestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    final microseconds = dateTime.microsecondsSinceEpoch;
    final int seconds = microseconds ~/ _kMillion;
    final int nanoseconds = (microseconds - seconds * _kMillion) * _kThousand;
    return 'Timestamp(seconds=$seconds, nanoseconds=$nanoseconds)';
  }

  static DateTime? timestampToDate(timestamp) {
    if (timestamp == null) {
      return null;
    }
    if (timestamp is! String) {
      timestamp = timestamp.toString();
    }
    final int i = timestamp.indexOf('(');
    if (i == -1) {
      return null;
    }
    final int e = timestamp.indexOf(')');
    final split = timestamp.substring(i + 1, e).split(',');
    return Timestamp(int.parse(split[0].split('=')[1]),
            int.parse(split[1].split('=')[1]))
        .toDate();
  }

  @override
  Future<void> addCommit(FVBCommit commit, FVBProject project) async {
    // final commitVersion = FVBCommitVersion(
    //   commitId: commit.id,
    //   customComponents: project.customComponents,
    //   screens: project.screens,
    // );
    if (project.settings.versionControl == null) {
      project.settings.versionControl = FVBVersionControl(commits: [commit]);
    } else {
      project.settings.versionControl!.commits.add(commit);
    }
    updateProjectSettings(project);
    final screens = commit.screens.map((e) => e.id).toSet();
    final components = commit.customComponents.map((e) => e.id).toSet();
    final commitDoc = FirePath.userVCS(project.userId, project.id)
        .collection(Collections.kCommits)
        .doc(commit.id);
    await Future.wait([
      FirePath.userVCS(project.userId, project.id)
          .collection(Collections.kCommits)
          .doc(commit.id)
          .set({
        'message': commit.message,
        'id': commit.id,
      }),
      for (final screen in project.screens)
        if (screens.contains(screen.id))
          commitDoc
              .collection(Collections.kScreens)
              .doc(screen.id)
              .set(screen.toJson()),
      for (final component in project.customComponents)
        if (components.contains(component.id))
          commitDoc
              .collection(Collections.kCustomComponents)
              .doc(component.id)
              .set(component.toMainJson()),
    ]);
  }

  @override
  Future<void> removeCommit(FVBCommit commit, FVBProject project) async {
    // final commitVersion = FVBCommitVersion(
    //   commitId: commit.id,
    //   customComponents: project.customComponents,
    //   screens: project.screens,
    // );
    project.settings.versionControl!.commits.remove(commit);
    final screens = commit.screens.map((e) => e.id).toSet();
    final components = commit.customComponents.map((e) => e.id).toSet();
    final commitDoc = FirePath.userVCS(project.userId, project.id)
        .collection(Collections.kCommits)
        .doc(commit.id);
    updateProjectSettings(project);
    await Future.wait([
      commitDoc.delete(),
      for (final screen in screens)
        commitDoc.collection(Collections.kScreens).doc(screen).delete(),
      for (final component in components)
        commitDoc
            .collection(Collections.kCustomComponents)
            .doc(component)
            .delete(),
    ]);
  }

  @override
  Future<void> restoreCommit(FVBCommit commit, Set<String> screenIds,
      Set<String> componentIds, FVBProject project) async {
    final commitDoc = FirePath.userVCS(project.userId, project.id)
        .collection(Collections.kCommits)
        .doc(commit.id);

    final [
      QuerySnapshot<Map<String, dynamic>> screenSnapshot,
      QuerySnapshot<Map<String, dynamic>> customComponentSnapshot,
    ] = await Future.wait([
      commitDoc.collection(Collections.kScreens).get(),
      commitDoc.collection(Collections.kCustomComponents).get(),
    ]);
    final customDocs = customComponentSnapshot.docs.toList();
    final screenDocs = screenSnapshot.docs.toList();
    if (customComponentSnapshot.docs.isNotEmpty) {
      project.customComponents
          .removeWhere((element) => componentIds.contains(element.id));
      customDocs.removeWhere((element) => !componentIds.contains(element.id));
      _extractCustomComponentModelFromDocs(
          project.customComponents, customDocs, project);
    }

    if (screenSnapshot.docs.isNotEmpty) {
      project.screens.removeWhere((element) => screenIds.contains(element.id));
      screenDocs.removeWhere((element) => !screenIds.contains(element.id));
      _extractScreenModelFromDocs(project.screens, screenDocs, project);
    }
    await Future.wait([
      for (final screen in screenSnapshot.docs)
        FirePath.screen(screen.id).set(screen.data()),
      for (final component in customComponentSnapshot.docs)
        FirePath.customComponent(component.id).set(component.data())
    ]);
  }

  void _extractCustomComponentModelFromDocs(
      List<CustomComponent> customComponents,
      List<DocumentSnapshot<Map<String, dynamic>>> customDocumentSnapshot,
      FVBProject project) {
    final List<CustomComponent> temp = [];
    for (final doc in customDocumentSnapshot) {
      final Map<String, dynamic> componentBody = doc.data()!;
      temp.add(CustomComponent.fromJson(componentBody, project: project));
    }
    customComponents.addAll(temp);
    fetchCustomComponentsFromJson(
        customDocumentSnapshot.map((e) => e.data()).toList(growable: false),
        temp,
        customComponents);
    customComponents.sort((pre, current) =>
        pre.dateCreated != null && current.dateCreated != null
            ? (pre.dateCreated!.isAfter(current.dateCreated!) ? 1 : 0)
            : 0);
  }

  void _extractScreenModelFromDocs(
      List<Screen> screens,
      List<DocumentSnapshot<Map<String, dynamic>>> projectDocuments,
      FVBProject project) {
    final List<Screen> tempScreens = [];
    for (final screenDoc in projectDocuments) {
      final screen = Screen.fromJson(screenDoc.data()!, project: project);
      tempScreens.add(screen);
    }

    screens.addAll(tempScreens);
    for (int i = 0; i < tempScreens.length; i++) {
      if (projectDocuments[i].data()!['root'] != null) {
        tempScreens[i].rootComponent =
            Component.fromJson(projectDocuments[i].data()!['root'], project);
      }
    }
    screens.sort(
        (pre, current) => (pre.createdAt.isAfter(current.createdAt)) ? 1 : 0);
  }
}

abstract class FirePath {
  static DocumentReference project(String id) =>
      fireStore.collection(Collections.kProjects).doc(id);

  static DocumentReference user(String id) =>
      fireStore.collection(Collections.kUsers).doc(id);

  static DocumentReference userVCS(String id, String projectId) => fireStore
      .collection(Collections.kUsers)
      .doc(id)
      .collection(Collections.kVersionControl)
      .doc(projectId);

  static DocumentReference screen(String id) =>
      fireStore.collection(Collections.kScreens).doc(id);

  static DocumentReference template(String id) =>
      fireStore.collection(Collections.kTemplates).doc(id);

  static DocumentReference customComponent(String id) =>
      fireStore.collection(Collections.kCustomComponents).doc(id);
}
