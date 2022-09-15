import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// For non-windows, Uncomment the following 3 imports:
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';

/// For Windows uncomment the following import:
import 'firebase_connection.dart';
import '../common/io_lib.dart';

import 'package:get/get.dart';

import 'package:flutter/cupertino.dart';
import '../common/shared_preferences.dart';
import '../component_list.dart';
import '../constant/preference_key.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/local_model.dart';
import '../models/variable_model.dart';
import '../code_to_component.dart';
import '../models/other_model.dart';
import '../models/project_model.dart';
import '../common/logger.dart';
import '../constant/string_constant.dart';
import '../models/component_model.dart';
import '../network/auth_response/auth_response_model.dart';
import '../ui/project_setting_page.dart';

abstract class FireBridge {
  static bool initialized = false;

  static Future<void> init() async {
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
    await Firebase.initializeApp(
        options: FirebaseOptions.fromMap(const {
          'apiKey': 'AIzaSyDOJQUOBFfomuLrYK6oCXr8-uJMXo-AByg',
          'authDomain': 'flutter-visual-builder-2.firebaseapp.com',
          'projectId': 'flutter-visual-builder-2',
          'storageBucket': 'flutter-visual-builder-2.appspot.com',
          'messagingSenderId': '1087783488343',
          'appId': '1:1087783488343:web:efb618e6387c69e3a88c12'
        }));

    initialized = true;
  }

  static Future<void> saveComponent(FlutterProject project,
      CustomComponent customComponent,
      {String? newName}) async {
    if (newName != null && newName != customComponent.name) {
      final String type;
      switch (customComponent.runtimeType) {
        case StatelessComponent:
          type = 'stateless';
          break;
        default:
          type = 'other';
          break;
      }

      await FirePath.customComponentReference(
          project.userId, project.docId!, newName)
          .set(customComponent.toJson());

      await FirePath.customComponentReference(
          project.userId, project.docId!, customComponent.name)
          .delete();
      customComponent.name = newName;
    } else {
      await FirePath.customComponentReference(
          project.userId, project.docId!, customComponent.name)
          .update({
        'code': CodeOperations.trim(customComponent.root?.code(clean: false)),
        'name': customComponent.name,
        'action_code': customComponent.actionCode,
        'variables': customComponent.variables.values
            .where((element) =>
        element is VariableModel && element.uiAttached && !element.isDynamic)
            .map((e) => e.toJson())
            .toList(),
      });
    }
  }

  static Future<void> addNewGlobalCustomComponent(int userId,
      FlutterProject flutterProject, CustomComponent customComponent) async {
    final String type;
    if (customComponent is StatelessComponent) {
      type = 'stateless';
    } else {
      type = 'stateful';
    }
    await FirePath.customComponentReference(
        userId, flutterProject.docId!, customComponent.name)
        .set({
      'name': customComponent.name,
      'action_code': customComponent.actionCode,
      'code': CodeOperations.trim(customComponent.root?.code(clean: false)),
      'variables': customComponent.variables.values
          .where((element) =>
      element is VariableModel && element.uiAttached && !element.isDynamic)
          .map((e) => e.toJson())
          .toList(),
      'type': type
    });

    logger('=== FIRE-BRIDGE == addNewGlobalCustomComponent ==');
  }

  static Future<void> deleteGlobalCustomComponent(int userId,
      FlutterProject flutterProject, CustomComponent customComponent) async {
    await FirePath.customComponentReference(
        userId, flutterProject.docId!, customComponent.name)
        .delete();
    logger('=== FIRE-BRIDGE == deleteGlobalCustomComponent ==');
  }

  static Future<void> deleteProject(int userId, FlutterProject project,
      final List<FlutterProject> projects) async {
    final response = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .get();
    for (final doc in response.docs) {
      await doc.reference.delete();
    }
    if (Platform.isWindows) {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProjectInfo)
          .update({
        'projects': projects
            .where((element) => element != project)
            .map((e) => e.name)
            .toList(growable: false)
      });
    } else {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProjectInfo)
          .update({
        'projects': FieldValue.arrayRemove([project.name])
      });
    }
  }

  static Future<void> moveDocument(List<DocData> fromData, List<DocData> toData,
      {bool deleteOld = true, Map<
          String,
          dynamic>? additionalData}) async {
    final Map<String, dynamic>? data;
    late DocumentReference reference =
    FirebaseFirestore.instance.collection(fromData.first.collectId).doc(
        fromData.first.docId);
    for (final doc in fromData.sublist(1)) {
      reference = reference.collection(doc.collectId).doc(doc.docId);
    }
    data = (await reference.get()).data();
    late DocumentReference destReference =
    FirebaseFirestore.instance.collection(toData.first.collectId).doc(
        toData.first.docId);
    for (final doc in toData.sublist(1)) {
      destReference = destReference.collection(doc.collectId).doc(doc.docId);
    }
    await destReference.set(data..addAll(additionalData ?? {}));
    if (deleteOld) {
      await reference.delete();
    }
  }

  static Future<void> moveCollection(List<DocData> fromData,
      List<DocData> toData,
      {bool deleteOld = true, Map<String, dynamic>? additionalData}) async {
    final List<QueryDocumentSnapshot>? data;
    late CollectionReference reference =
    FirebaseFirestore.instance.collection(fromData.first.collectId);
    for (final doc in fromData.sublist(1)) {
      reference = reference.doc(doc.docId).collection(doc.collectId);
    }
    data = (await reference.get()).docs;
    late CollectionReference destReference =
    FirebaseFirestore.instance.collection(toData.first.collectId);
    for (final doc in toData.sublist(1)) {
      destReference = destReference.doc(doc.docId).collection(doc.collectId);
    }
    for (final QueryDocumentSnapshot doc in data ?? []) {
      await destReference.doc(doc.id).set(doc.data()
        ..addAll(additionalData ?? {}));
      if (deleteOld) {
        await reference.doc(doc.id).delete();
      }
    }
  }

  static Future<List<FavouriteModel>> loadFavourites(final int userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    snapshot = await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kFavourites}')
        .get();

    final List<FavouriteModel> favouriteModels = [];
    for (final document in snapshot.docs) {
      final json = document.data();
      favouriteModels.add(FavouriteModel(
          Component.fromCode(
              json['code'], ComponentOperationCubit.currentProject!)!
            ..boundary = Rect.fromLTWH(
                0.0,
                0.0,
                double.parse(json['width'].toString()),
                double.parse(json['height'].toString())),
          json['project_name']));
    }
    return favouriteModels;
  }

  static Future<List<CustomComponent>> loadAllCustomComponents(
      final int userId) async {
    // await FirebaseFirestore.instance
    //     .collection('us$userId')
    //     .doc(Strings.kFlutterProject).collection();
    return [];
  }

  static Future<void> addToFavourites(int userId, Component component,
      String projectName, double width, double height) async {
    await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kFavourites}')
        .doc('${DateTime
        .now()
        .millisecondsSinceEpoch}')
        .set({
      'code': CodeOperations.trim(component.code(clean: false)),
      'id': component.id,
      'project_name': projectName,
      'width': width,
      'height': height,
    });
  }

  static Future<void> removeFromFavourites(int userId,
      Component component) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kFavourites}')
        .where('id', isEqualTo: component.id)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs[0].reference.delete();
    }
  }

  static Future<AuthResponse> registerUser(String userName,
      String password) async {
    // final usersMatched=await FirebaseFirestore.instance
    //     .collection('users')
    //     .where('username', isEqualTo: userName).get();
    final user = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: userName, password: password);
    if (user.user == null) {
      return AuthResponse.right('No user found');
    }
    final doc = await FirebaseFirestore.instance
        .collection('userInfo')
        .doc('count')
        .get();
    if (doc.data() == null || !doc.exists) {
      return AuthResponse.right('No user data exist');
    }

    final newUserId = doc.data()!['count'] + 1;
    await FirebaseFirestore.instance
        .collection('userInfo')
        .doc('count')
        .update({'count': newUserId});
    await FirebaseFirestore.instance.collection('users').add({
      'username': userName,
      'password': password,
      'userId': newUserId,
      'uid': user.user!.uid
    });
    await FirebaseFirestore.instance
        .collection('us$newUserId')
        .doc(Strings.kFlutterProjectInfo)
        .set({'projects': []});
    // await FirebaseFirestore.instance
    //     .collection('us$newUserId')
    //     .doc(Strings.kFlutterProject)
    //     .set({'projects': []});
    return AuthResponse.left(newUserId);
  }

  static Future<List<FlutterProject>> loadAllFlutterProjects(
      int userId,) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProjectInfo)
        .get();
    if (!snapshot.exists || snapshot.data() == null) {
      return [];
    }
    final List<FlutterProject> projectList = [];
    final data = snapshot.data()!;
    for (final projectName in data['projects'] ?? []) {
      projectList.add(FlutterProject(projectName, userId, null, imageList: []));
    }
    return projectList;
  }

  static Future<void> saveFlutterProject(int userId,
      FlutterProject project) async {
    final List<CustomComponent> components = project.customComponents;
    final projectInfo = <String, dynamic>{
      'project_name': project.name,
      'root': CodeOperations.trim(project.rootComponent?.code(clean: false)),
      'variables': project.variables.values
          .where((element) =>
      (element is VariableModel) && element.uiAttached && !element.isDynamic)
          .map((element) => element.toJson())
          .toList(growable: false),
      // 'models': project.models.map((e) => e.toJson()).toList(growable: false),
      'device': 'iPhone X',
      'settings': project.settings.toJson(),
      'current_screen': project.uiScreens.first.name,
      'main_screen': project.uiScreens.first.name,
      'action_code': project.actionCode,
    };
    final response = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .add(projectInfo);
    final jsonList =
    project.uiScreens.map((e) => e.toJson()).toList(growable: false);
    for (final screenJson in jsonList) {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(project.name)
          .doc(screenJson['name'])
          .set(screenJson);
    }

    project.docId = response.id;
    for (final component in components) {
      final String type;
      switch (component.runtimeType) {
        case StatelessComponent:
          type = 'stateless';
          break;
        default:
          type = 'other';
          break;
      }
      await FirePath.customComponentReference(
          userId, project.docId!, component.name)
          .set({
        'name': component.name,
        'type': type,
        'code': component.root != null
            ? (CodeOperations.trim(component.root!.code(clean: false)))
            : null
      });
    }
    if (Platform.isWindows) {
      final oldResponse = await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProjectInfo)
          .get();
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProjectInfo)
          .update({
        'projects': List.from(oldResponse.data()!['projects'])
          ..add(project.name)
      });
    } else {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProjectInfo)
          .update({
        'projects': FieldValue.arrayUnion([project.name])
      });
    }
  }

  static Future<Optional<FlutterProject, ProjectLoadErrorModel>>
  loadFlutterProject(int userId, String name,
      {bool ifPublic = false}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(name)
          .get();
      final documents = snapshot.docs;
      if (documents.isEmpty) {
        return Optional.right(ProjectLoadErrorModel(
            ProjectLoadError.notFound, 'Project "$name" not found'));
      }
      final projectInfoDoc = documents
          .firstWhere((element) => element.data().containsKey('project_name'));
      final projectInfo = projectInfoDoc.data();
      final settings = projectInfo['settings'] != null
          ? ProjectSettingsModel.fromJson(projectInfo['settings'])
          : null;
      if (ifPublic && (!(settings?.isPublic ?? false))) {
        return Optional.right(
            ProjectLoadErrorModel(ProjectLoadError.notPermission, null));
      }
      final FlutterProject flutterProject = FlutterProject(
          projectInfo['project_name'], userId, projectInfoDoc.id,
          device: projectInfo['device'],
          imageList: projectInfo['image_list'] != null
              ? List<String>.from(projectInfo['image_list'])
              : [],
          actionCode: projectInfo['action_code'] ?? '',
          settings: settings);
      final variables = List.from(projectInfo['variables'] ?? [])
          .map((e) => VariableModel.fromJson(e..['uiAttached'] = true));
      for (final variable in variables) {
        flutterProject.variables[variable.name] = variable;
      }
      // for (final modelJson in projectInfo['models'] ?? []) {
      //   final model = LocalModel.fromJson(modelJson);
      //   flutterProject.models.add(model);
      // }
      ComponentOperationCubit.currentProject = flutterProject;
      documents.retainWhere(
              (element) => !element.data().containsKey('project_name'));

      // for (final modelJson in projectInfo['screens'] ?? []) {
      //   final screen = UIScreen.fromJson(modelJson, flutterProject);
      //   flutterProject.uiScreens.add(screen);
      // }

      final customDocs = await FirePath.customComponentsReferenceByProjectName(
          userId, flutterProject.docId!)
          .get();
      if (customDocs.docs.isNotEmpty) {
        moveCollection([
          DocData('us$userId', ''),
          DocData('Custom|${flutterProject.docId}', Strings.kFlutterProject)
        ], [
          DocData('us$userId', ''),
          DocData('Custom', Strings.kFlutterProject)
        ],additionalData: {
          'project':flutterProject.name
        });
      }
      for (final screenDoc in documents) {
        final screen = UIScreen.fromJson(screenDoc.data(), flutterProject);
        flutterProject.uiScreens.add(screen);
      }
      for (final doc in customDocs.docs) {
        final Map<String, dynamic> componentBody =
        doc.data()! as Map<String, dynamic>;
        if (componentBody['type'] == 'stateless') {
          flutterProject.customComponents
              .add(StatelessComponent.fromJson(componentBody));
        } else {
          flutterProject.customComponents
              .add(StatefulComponent.fromJson(componentBody));
        }
      }

      if (projectInfo['current_screen'] != null) {
        bool initializedMain = false,
            initializedCurrent = false;
        for (final screen in flutterProject.uiScreens) {
          if (screen.name == projectInfo['main_screen']) {
            flutterProject.mainScreen = screen;
            initializedMain = true;
          }
          if (screen.name == projectInfo['current_screen']) {
            flutterProject.currentScreen = screen;
            initializedCurrent = true;
          }
        }
        if (!initializedMain) {
          flutterProject.mainScreen = flutterProject.uiScreens.first;
        }
        if (!initializedCurrent) {
          flutterProject.currentScreen = flutterProject.uiScreens.first;
        }
      } else {
        if (flutterProject.uiScreens.isNotEmpty) {
          flutterProject.currentScreen = flutterProject.uiScreens.first;
        } else {
          final ui = UIScreen.mainUI();
          flutterProject.uiScreens.add(ui);
          final custom = StatelessComponent(name: 'MainPage')
            ..root = CScaffold();
          flutterProject.customComponents.add(custom);
          (ui.rootComponent as CMaterialApp).childMap['home'] =
              custom.createInstance(null);
          flutterProject.currentScreen = flutterProject.uiScreens.first;
          addUIScreen(userId, flutterProject, flutterProject.currentScreen);
        }

        flutterProject.mainScreen = flutterProject.uiScreens.first;
      }

      for (int i = 0; i < customDocs.docs.length; i++) {
        final Map<String, dynamic> componentBody =
        customDocs.docs[i].data()! as Map<String, dynamic>;
        flutterProject.customComponents[i].root = componentBody['code'] != null
            ? Component.fromCode(componentBody['code']!, flutterProject)
            : null;
      }
      for (int i = 0; i < customDocs.docs.length; i++) {
        flutterProject.customComponents[i].root?.forEach((p0) {
          if (p0 is CustomComponent) {
            p0.root = flutterProject.customComponents
                .firstWhere((element) => element.name == p0.name)
                .root
                ?.clone(null);
          }
        });
      }

      final currentScreen = flutterProject.currentScreen;
      for (int i = 0; i < flutterProject.uiScreens.length; i++) {
        flutterProject.currentScreen = flutterProject.uiScreens[i];
        flutterProject.uiScreens[i].rootComponent =
            Component.fromCode(documents[i].data()['root'], flutterProject);
      }
      flutterProject.currentScreen = currentScreen;

      return Optional.left(flutterProject);
    } on Exception catch (e) {
      print(e);
      e.printError();
      return Optional.right(
          ProjectLoadErrorModel(ProjectLoadError.otherError, e.toString()));
    }
  }

  static Future<Uint8List?> loadImage(int userId, String imgName) async {
    final QuerySnapshot<Map<String, dynamic>> image;
    image = await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kImages}')
        .where('img_name', isEqualTo: imgName)
        .get();
    if (image.docs.isNotEmpty) {
      return base64Decode(image.docs[0].data()['bytes']);
    }
    return null;
  }

  static Future<List<ImageData>?> loadAllImages(int userId) async {
    final QuerySnapshot<Map<String, dynamic>> image;
    image = await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kImages}')
        .get();
    if (image.docs.isNotEmpty) {
      final List<ImageData> list = [];
      for (final doc in image.docs) {
        list.add(ImageData(
            base64Decode(doc.data()['bytes']), doc.data()['img_name']));
      }
      return list;
    }
    return null;
  }

  static Future<String?> resetPassword(String userName) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: userName);
    return null;
  }

  static Future<int?> tryLoginWithPreference() async {
    if (Preferences.sharedPreferences.containsKey(PrefKey.UID)) {
      return Preferences.sharedPreferences.getInt(PrefKey.UID);
    }
    return null;
  }

  static Future<AuthResponse> login(String userName, String password) async {
    if (Preferences.sharedPreferences.containsKey(PrefKey.UID)) {
      return AuthResponse.left(
          Preferences.sharedPreferences.getInt(PrefKey.UID)!);
    }
    final loginResponse = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: userName, password: password);
    if (loginResponse.user == null) {
      return AuthResponse.right('Registration failed');
    }
    final response = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: loginResponse.user!.uid)
    // .where('password', isEqualTo: password)
        .get();
    if (response.docs.isEmpty || !response.docs[0].exists) {
      return AuthResponse.right(
          'Something went wrong, Please check your internet');
    }
    final data = response.docs[0].data();
    Preferences.sharedPreferences.setInt(PrefKey.UID, data['userId']);
    return AuthResponse.left(data['userId']);
  }

  static Future<void> uploadImage(int userId, String projectName,
      ImageData imageData) async {
    await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kImages}')
        .add({
      'img_name': imageData.imageName,
      'project_name': projectName,
      'bytes': base64Encode(imageData.bytes!)
    });
  }

  static Future<void> removeImage(int userId, String imgName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kImages}')
        .where('img_name', isEqualTo: imgName)
        .get();
    if (snapshot.docs.isNotEmpty) {
      snapshot.docs[0].reference.delete();
    }
  }

  static Future<void> addModel(final int userId, final FlutterProject project,
      final LocalModel localModel) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.currentScreen.name)
        .update({
      'models': FieldValue.arrayUnion([localModel.toJson()])
    });
    logger('=== FIRE-BRIDGE == addLocalModel ==');
    // }
  }

  static Future<void> updateModel(final int userId,
      final FlutterProject project, final LocalModel localModel) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.currentScreen.name)
        .update({
      'models': project.currentScreen.models
          .map((e) => e.toJson())
          .toList(growable: false)
    });
    debugPrint('=== FIRE-BRIDGE == update variable == ');
  }

  static Future<void> addVariable(final int userId,
      final FlutterProject project, final VariableModel variableModel) async {
    if (Platform.isWindows) {
      final variablesRef = FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(project.name)
          .doc(project.docId);
      final oldResponse = await variablesRef.get();
      if (oldResponse.data()!['variables'] != null) {
        await variablesRef.update({
          'variables': List.from(oldResponse.data()!['variables'] ?? [])
            ..add(variableModel.toJson())
        });
      } else {
        await variablesRef.update({
          'variables': [variableModel.toJson()]
        });
      }
    } else {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(project.name)
          .doc(project.docId)
          .update({
        'variables': FieldValue.arrayUnion([variableModel.toJson()])
      });
    }
    logger('=== FIRE-BRIDGE == addVariable ==');
  }

  static Future<void> addVariableForScreen(final int userId,
      final FlutterProject project, final VariableModel variableModel) async {
    if (Platform.isWindows) {
      final variablesRef = FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(project.name)
          .doc(project.currentScreen.name);
      final oldResponse = await variablesRef.get();
      if (oldResponse.data()!['variables'] != null) {
        await variablesRef.update({
          'variables': List.from(oldResponse.data()!['variables'])
            ..add(variableModel.toJson())
        });
      }
    } else {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(project.name)
          .doc(project.currentScreen.name)
          .update({
        'variables': FieldValue.arrayUnion([variableModel.toJson()])
      });
    }
    logger('=== FIRE-BRIDGE == addVariable ==');
  }

  static Future<void> updateVariable(final int userId,
      final FlutterProject project) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.docId)
        .update({
      'variables': project.variables.values
          .where((element) =>
      element is VariableModel && element.uiAttached && !element.isDynamic)
          .map((e) => e.toJson())
          .toList(growable: false)
    });
    logger('=== FIRE-BRIDGE == update variable ==');
  }

  static Future<void> updateUIScreenVariable(final int userId,
      final FlutterProject project) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.currentScreen.name)
        .update({
      'variables': project.currentScreen.variables.values
          .where((element) =>
      element is VariableModel && element.uiAttached && !element.isDynamic)
          .map((e) => e.toJson())
          .toList(growable: false)
    });
    logger('=== FIRE-BRIDGE == update variable ==');
  }

  static Future<void> updateVariableForCustomComponent(final int userId,
      final FlutterProject project,
      final CustomComponent component,) async {
    await FirePath.customComponentReference(
        project.userId, project.docId!, component.name)
        .update({
      'variables': component.variables.values
          .where((element) =>
      element is VariableModel && element.uiAttached && !element.isDynamic)
          .map((e) => e.toJson())
          .toList(growable: false)
    });
    logger('=== FIRE-BRIDGE == update variable ==');
  }

  static Future<void> updateDeviceSelection(final int userId,
      final FlutterProject project, final String device) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.docId)
        .update({'device': device});
  }

  static Future<void> updateSettings(final int userId,
      final FlutterProject project) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.docId)
        .update({'settings': project.settings.toJson()});
  }

  static Future<void> updateCurrentScreen(int userId,
      final FlutterProject project) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.docId)
        .update({'current_screen': project.currentScreen.name});
  }

  static Future<void> updateMainScreen(int userId,
      final FlutterProject project) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.docId)
        .update({'main_screen': project.currentScreen.name});
  }

  static Future<void> updateProjectValue(final FlutterProject project,
      String key, dynamic value) async {
    await FirebaseFirestore.instance
        .collection('us${project.userId}')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.docId)
        .update({key: value});
  }

  static Future<void> updateActionCode(int userId,
      final FlutterProject project) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.docId)
        .update({'action_code': project.actionCode});
  }

  static Future<void> updateScreenActionCode(int userId,
      final FlutterProject project) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(project.currentScreen.name)
        .update({'action_code': project.currentScreen.actionCode});
  }

  static Future<void> updateCustomComponentActionCode(int userId,
      final FlutterProject project, final CustomComponent component) async {
    await FirePath.customComponentReference(
        project.userId, project.docId!, component.name)
        .update({
      'action_code': component.actionCode,
    });
  }

  // static Future<void> updateRootComponent(
  //     int userId, String projectName, Component component) async {
  //   final document = await FirebaseFirestore.instance
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
  //     await FirebaseFirestore.instance
  //         .collection('us$userId')
  //         .doc(Strings.kFlutterProject)
  //         .collection(projectName)
  //         .doc(document.docs[0].id)
  //         .update(body);
  //     logger('=== FIRE-BRIDGE == updateGlobalCustomComponent ==');
  //   }
  // }
  //

  static Future<void> addUIScreen(final int userId,
      final FlutterProject project, final UIScreen uiScreen) async {
    final screen = uiScreen.toJson();
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .doc(uiScreen.name)
        .set(screen);
    logger('=== FIRE-BRIDGE == addUIScreen ==');
  }

  static Future<void> updateScreenRootComponent(final int userId,
      final String projectName,
      final UIScreen uiScreen,
      final Component component) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .doc(uiScreen.name)
        .update({
      'root': CodeOperations.trim(
        component.code(clean: false),
      ),
    });
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Preferences.sharedPreferences.remove(PrefKey.UID);
  }

  static removeUIScreen(final int userId, final FlutterProject flutterProject,
      final UIScreen uiScreen) async {
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(flutterProject.name)
        .doc(uiScreen.name)
        .delete();
  }
}

class FirePath {
  static DocumentReference customComponentReference(int userId,
      String projectId, String customComponentName) {
    return FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection('Custom|$projectId')
        .doc(customComponentName);
  }

  static CollectionReference customComponentsReferenceByProjectName(int userId,
      String projectId) {
    return FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection('Custom|$projectId');
  }
}

enum ProjectLoadError {
  notPermission,
  networkError,
  notFound,
  otherError,
}

class ProjectLoadErrorModel {
  final ProjectLoadError projectLoadError;
  final String? error;

  ProjectLoadErrorModel(this.projectLoadError, this.error);
}

class Optional<A, B> {
  final A? a;
  final B? b;

  Optional._(this.a, this.b);

  factory Optional.right(B b) {
    return Optional._(null, b);
  }

  factory Optional.left(A a) {
    return Optional._(a, null);
  }

  bool get isRight {
    return b != null;
  }

  bool get isLeft {
    return a != null;
  }

  A get left {
    return a!;
  }

  B get right {
    return b!;
  }
}

class DocData {
  final String collectId;
  final String docId;

  DocData(this.collectId, this.docId);
}