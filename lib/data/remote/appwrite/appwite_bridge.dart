// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:ui';
//
// import '../../../common/api/api_model.dart';
// import '../../../common/compiler/fvb_class.dart';
// import '../../../common/logger.dart';
// import '../../../common/shared_preferences.dart';
// import '../../../common/web/io_lib.dart';
// import '../../../components/component_impl.dart';
// import '../../../constant/preference_key.dart';
// import '../../../constant/string_constant.dart';
// import '../../../cubit/component_operation/component_operation_cubit.dart';
// import '../../../injector.dart';
// import '../../../models/component_model.dart';
// import '../../../models/global_component.dart';
// import '../../../models/other_model.dart';
// import '../../../models/project_model.dart';
// import '../../../models/project_setting_model.dart';
// import '../../../models/template_model.dart';
// import '../../../models/user/user_setting.dart';
// import '../../../models/variable_model.dart';
// import '../../../network/auth_response/auth_response_model.dart';
// import '../common_data_models.dart';
// import '../data_bridge.dart';
// import 'package:appwrite/appwrite.dart';
// import 'package:collection/collection.dart';
//
//
// class AppWriteDataBridge extends DataBridge {
//   bool initialized = false;
//   final Client client=Client();
//   late Databases databases;
//
//   Future<void> init() async {
//     if (initialized) {
//       return;
//     }
//     databases=Databases(client);
//     initialized = true;
//
//   }
//
//   Future<void> initWithJson(Map<String, dynamic> map) async {
//
//     return null;
//   }
//
//   Future<void> update(String path, String? docId, Map<String, dynamic> data) async {
//
//   }
//
//   Future<void> updateCustomComponent(FVBProject project, CustomComponent customComponent, {String? newName}) async {
//     if (newName != null && newName != customComponent.name) {
//       await databases;
//       await FirePath.customComponentsReferenceUpdated(project.userId, project.name, customComponent.name).delete();
//       customComponent.name = newName;
//     } else {
//       await FirePath.customComponentsReferenceUpdated(project.userId, project.name, customComponent.name)
//           .update(customComponent.toJson());
//     }
//   }
//
//   Future<void> addCustomComponent(int userId, FVBProject flutterProject, CustomComponent customComponent) async {
//     await FirePath.customComponentsReferenceUpdated(flutterProject.userId, flutterProject.name, customComponent.name)
//         .set(customComponent.toJson());
//
//     logger('=== FIRE-BRIDGE == addNewGlobalCustomComponent ==');
//   }
//
//   Future<void> removeCustomComponent(int userId, FVBProject project, CustomComponent component) async {
//     await FirePath.customComponentsReferenceUpdated(project.userId, project.name, component.name).delete();
//     logger('=== FIRE-BRIDGE == deleteGlobalCustomComponent ==');
//   }
//
//   Future<void> deleteProject(int userId, FVBProject project, final List<FVBProject> projects) async {
//     final response = await fireStore.collection('us$userId').doc(Strings.kProjects).collection(project.name).get();
//     for (final doc in response.docs) {
//       await doc.reference.delete();
//     }
//     if (Platform.isWindows) {
//       await fireStore.collection('us$userId').doc(Strings.kFlutterProjectInfo).update(
//           {'projects': projects.where((element) => element != project).map((e) => e.name).toList(growable: false)});
//     } else {
//       await fireStore.collection('us$userId').doc(Strings.kFlutterProjectInfo).update({
//         'projects': FieldValue.arrayRemove([project.name])
//       });
//     }
//   }
//
//   Future<void> moveDocument(List<DocData> fromData, List<DocData> toData,
//       {bool deleteOld = true, Map<String, dynamic>? additionalData}) async {
//     final Map<String, dynamic>? data;
//     late DocumentReference reference = fireStore.collection(fromData.first.collectId).doc(fromData.first.docId);
//     for (final doc in fromData.sublist(1)) {
//       reference = reference.collection(doc.collectId).doc(doc.docId);
//     }
//     data = (await reference.get()).data() as Map<String, dynamic>;
//     late DocumentReference destReference = fireStore.collection(toData.first.collectId).doc(toData.first.docId);
//     for (final doc in toData.sublist(1)) {
//       destReference = destReference.collection(doc.collectId).doc(doc.docId);
//     }
//     await destReference.set(data..addAll(additionalData ?? {}));
//     if (deleteOld) {
//       await reference.delete();
//     }
//   }
//
//   Future<void> moveCollection(List<DocData> fromData, List<DocData> toData,
//       {bool deleteOld = true, Map<String, dynamic>? additionalData, snapshot, String? appendTargetDocKey}) async {
//     final List<QueryDocumentSnapshot>? data;
//     late CollectionReference reference = fireStore.collection(fromData.first.collectId);
//     if (snapshot != null) {
//       for (final doc in fromData.sublist(1)) {
//         reference = reference.doc(doc.docId).collection(doc.collectId);
//       }
//       data = (await reference.get()).docs;
//     } else {
//       data = snapshot!.docs;
//     }
//     late CollectionReference destReference = fireStore.collection(toData.first.collectId);
//     for (final doc in toData.sublist(1)) {
//       destReference = destReference.doc(doc.docId).collection(doc.collectId);
//     }
//     for (final QueryDocumentSnapshot doc in data ?? []) {
//       await destReference
//           .doc(doc.id + (appendTargetDocKey ?? ''))
//           .set((doc.data() as Map<String, dynamic>)..addAll(additionalData ?? {}));
//       if (deleteOld) {
//         await reference.doc(doc.id).delete();
//       }
//     }
//   }
//
//   Future<List<FavouriteModel>> loadFavourites(final int userId) async {
//     final QuerySnapshot<Map<String, dynamic>> snapshot;
//     snapshot = await fireStore.collection('us$userId|${Strings.kFavourites}').get();
//
//     final List<FavouriteModel> favouriteModels = [];
//     for (final document in snapshot.docs) {
//       final json = document.data();
//       final List<CustomComponent> customComponents = [];
//       for (final doc in ((json['customComponents'] as List?) ?? [])) {
//         final Map<String, dynamic> componentBody = doc as Map<String, dynamic>;
//         customComponents.add(CustomComponent.fromJson(componentBody));
//       }
//       fetchCustomComponentsFromJson(((json['customComponents'] as List?) ?? []), customComponents);
//       favouriteModels.add(FavouriteModel(
//           Component.fromJson(json['code'], null, customs: customComponents)
//             ..boundary = Rect.fromLTWH(
//                 0.0, 0.0, double.parse(json['width'].toString()), double.parse(json['height'].toString())),
//           json['project_name'],
//           customComponents,
//           timestampToDate(json['createdAt'])));
//       for (final custom in customComponents) collection.project!.customComponents.remove(custom);
//     }
//     return favouriteModels;
//   }
//
//   Future<Map<String, List<CustomComponent>>> loadAllCustomComponents(final int userId) async {
//     final snapshot = await FirePath.customComponentsReferenceByProjectNameUpdated(userId).get();
//     final List<CustomComponent> list =
//     snapshot.docs.map((e) => CustomComponent.fromJson(e.data()! as Map<String, dynamic>)).toList();
//
//     for (int i = 0; i < list.length; i++) {
//       final Map<String, dynamic> componentBody = snapshot.docs[i].data()! as Map<String, dynamic>;
//       list[i].rootComponent =
//       componentBody['code'] != null ? Component.fromJson(componentBody['code']!, collection.project!) : null;
//     }
//     final Map<String, List<CustomComponent>> map = {};
//     for (final comp in list) {
//       if (map.containsKey(comp.project)) {
//         map[comp.project]!.add(comp);
//       } else {
//         map[comp.project] = [comp];
//       }
//     }
//     return map;
//   }
//
//   Future<void> uploadTemplate(TemplateModel model) async {
//     await fireStore.collection('templates').add(model.toJson());
//   }
//
//   Future<void> deleteTemplate(TemplateModel model) async {
//     final docs = await fireStore
//         .collection('templates')
//         .where('name', isEqualTo: model.name)
//         .where('publisher_id', isEqualTo: model.publisherId)
//         .where('description', isEqualTo: model.description)
//         .where('timeStamp', isEqualTo: model.timeStamp)
//         .get();
//     await docs.docs[0].reference.delete();
//   }
//
//   Future<List<GlobalComponentModel>?> loadGlobalComponentList() async {
//     final data = await fireStore.collection('components').get();
//     if (data.docs.isNotEmpty) {
//       final list = List.generate(
//         data.docs.length,
//             (index) => GlobalComponentModel.fromJson(data.docs[index].data())..id = data.docs[index].id,
//       );
//       // for (int i = 0; i < list.length; i++) {
//       //   fireStore.collection('components').doc(data.docs[i].id).update({
//       //     'component': list[i].component.toJson(),
//       //     'customs':list[i].customs.map((e) => e.toJson()).toList()
//       //   });
//       // }
//       return list;
//     }
//     return null;
//   }
//
//   Future<bool> updateFVBPaintObj(FVBProject project, String id, List<FVBPaintObj> obj) async {
//     try {
//       await FirePath.project(project.userId, project.name)
//           .doc('__paint__$id')
//           .set({'objList': obj.map((e) => e.toJson()).toList(growable: false)});
//       return true;
//     } catch (e) {
//       print(e);
//       return false;
//     }
//   }
//
//   Future<bool> addGlobalComponent(
//       String? id,
//       GlobalComponentModel model,
//       ) async {
//     final json = model.toJson();
//     if (id == null) {
//       id = fireStore.collection('components').doc().id;
//       model.id = id;
//     }
//     await fireStore.collection('components').doc(id).set(json);
//     return true;
//   }
//
//   Future<bool> removeGlobalComponent(String id) async {
//     await fireStore.collection('components').doc(id).delete();
//     return true;
//   }
//
//   Future<TemplatePaginate> loadTemplateList(last, int count, {int? userId}) async {
//     final list = last != null
//         ? await fireStore
//         .collection('templates')
//         .startAfterDocument(last)
//         .limit(count)
//         .where('publisher_id', isEqualTo: userId)
//         .get()
//         : await fireStore.collection('templates').limit(count).where('publisher_id', isEqualTo: userId).get();
//
//     final List<TemplateModel> templates = [];
//     for (final template in list.docs) {
//       final List<CustomComponent> customComponents = [];
//       final json = template.data();
//       final variables =
//       List.from(json['variables'] ?? []).map((e) => VariableModel.fromJson(e)).toList(growable: false);
//       for (final doc in ((json['customComponents'] as List?) ?? [])) {
//         final Map<String, dynamic> componentBody = doc as Map<String, dynamic>;
//         customComponents.add(CustomComponent.fromJson(componentBody, parentVars: variables));
//       }
//       fetchCustomComponentsFromJson(((json['customComponents'] as List?) ?? []), customComponents);
//       final model = TemplateModel.fromJson(json, variables);
//       model.customComponents.addAll(customComponents);
//       model.screen.rootComponent = Component.fromJson(json['screen']['root'], null, customs: customComponents);
//       templates.add(model);
//     }
//     templates.sort((temp1, temp2) => temp1.createdAt.isAfter(temp2.createdAt) ? -1 : 0);
//     return TemplatePaginate(templates, list.docs.lastOrNull);
//   }
//
//   Future<bool> uploadPublicImage(FVBImage image) async {
//     try {
//       await fireStore.collection('images').doc(image.imageName).set(image.toJson());
//       return true;
//     } on Exception catch (e) {
//       return false;
//     }
//   }
//
//   Future<FVBImage> getPublicImage(String image) async {
//     if (byteCache.containsKey(image)) {
//       return FVBImage(byteCache[image], image);
//     }
//     final data = await fireStore.collection('images').doc(image).get();
//     if (data.exists) {
//       final imageData = FVBImage.fromJson(data.data() as Map<String, dynamic>);
//       byteCache[imageData.imageName!] = imageData.bytes!;
//       return imageData;
//     }
//     byteCache[image] = Uint8List(0);
//     return FVBImage(Uint8List(0), image);
//   }
//
//   Future<void> addFavourite(int userId, FavouriteModel model) async {
//     await fireStore
//         .collection('us$userId|${Strings.kFavourites}')
//         .doc('${DateTime.now().millisecondsSinceEpoch}')
//         .set(model.toJson());
//   }
//
//   Future<void> removeFromFavourites(int userId, Component component) async {
//     final snapshot =
//     await fireStore.collection('us$userId|${Strings.kFavourites}').where('id', isEqualTo: component.id).get();
//     if (snapshot.docs.isNotEmpty) {
//       await snapshot.docs[0].reference.delete();
//     }
//   }
//
//   Future<AuthResponse> registerUser(String userName, String password) async {
//     // final usersMatched=await fireStore
//     //     .collection('users')
//     //     .where('username', isEqualTo: userName).get();
//     final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: userName, password: password);
//     if (user.user == null) {
//       return AuthResponse.right('No user found');
//     }
//     final doc = await fireStore.collection('userInfo').doc('count').get();
//     if (doc.data() == null || !doc.exists) {
//       return AuthResponse.right('No user data exist');
//     }
//     final newUserId = doc.data()!['count'] + 1;
//     await fireStore.collection('userInfo').doc('count').update({'count': newUserId});
//     await fireStore
//         .collection('users')
//         .add({'username': userName, 'password': password, 'userId': newUserId, 'uid': user.user!.uid});
//     await fireStore.collection('us$newUserId').doc(Strings.kFlutterProjectInfo).set({'projects': []});
//     // await fireStore
//     //     .collection('us$newUserId')
//     //     .doc(Strings.kFlutterProject)
//     //     .set({'projects': []});
//     return AuthResponse.left(newUserId);
//   }
//
//   Future<UserSettingModel?> loadUserDetails(
//       int userId,
//       ) async {
//     final snapshot = await fireStore.collection('us$userId').doc(Strings.kFlutterProjectInfo).get();
//     if (!snapshot.exists || snapshot.data() == null) {
//       return null;
//     }
//     final List<FVBProject> projectList = [];
//     final data = snapshot.data();
//     final projects = List.of(data!['projects'] ?? []);
//     final doc = fireStore.collection('us$userId').doc(Strings.kProjects);
//     try {
//       await Future.wait((projects).map((projectName) =>
//           doc.collection(projectName).where('project_name', isEqualTo: projectName).get().then((project) {
//             if (project.docs.isNotEmpty) {
//               final data = project.docs.first.data();
//
//               projectList.add(FVBProject(projectName, userId, project.docs[0].id,
//                   imageList: [],
//                   createdAt: data['createdAt'] != null ? timestampToDate(data['createdAt']) : null,
//                   updatedAt: data['updatedAt'] != null ? timestampToDate(data['updatedAt']) : null));
//             }
//           })));
//     } on Exception catch (e) {
//       print(e.toString() ?? '');
//     }
//     projectList.sort((a, b) => (b.updatedAt == null)
//         ? 0
//         : (a.updatedAt == null
//         ? 1
//         : (b.updatedAt!.isAfter(a.updatedAt!))
//         ? 1
//         : -1));
//     final model = UserSettingModel.fromJson(data);
//     model.projects.addAll(projectList);
//
//     return model;
//   }
//
//   Future<void> saveFlutterProject(int userId, FVBProject project) async {
//     final List<CustomComponent> components = project.customComponents;
//     final projectInfo = <String, dynamic>{
//       'project_name': project.name,
//       'createdAt': Timestamp.now(),
//       'updatedAt': Timestamp.now(),
//       'variables': project.variables.values
//           .where((element) => (element is VariableModel) && element.uiAttached && !element.isDynamic)
//           .map((element) => element.toJson())
//           .toList(growable: false),
//       'device': 'iPhone X',
//       'settings': project.settings.toJson(),
//       'mainScreen': null,
//       'action_code': project.actionCode,
//     };
//     final response = await FirePath.project(userId, project.name).add(projectInfo);
//     final jsonList = project.screens.map((e) => e.toJson()).toList(growable: false);
//     for (final screenJson in jsonList) {
//       await fireStore
//           .collection('us$userId')
//           .doc(Strings.kProjects)
//           .collection(project.name)
//           .doc(screenJson['name'])
//           .set(screenJson);
//     }
//
//     project.docId = response.id;
//     for (final component in components) {
//       await FirePath.customComponentsReferenceUpdated(userId, project.name!, component.name).set(component.toJson());
//     }
//     if (Platform.isWindows) {
//       final oldResponse = await fireStore.collection('us$userId').doc(Strings.kFlutterProjectInfo).get();
//       await fireStore
//           .collection('us$userId')
//           .doc(Strings.kFlutterProjectInfo)
//           .update({'projects': List.from(oldResponse.data()!['projects'])..add(project.name)});
//     } else {
//       await fireStore.collection('us$userId').doc(Strings.kFlutterProjectInfo).update({
//         'projects': FieldValue.arrayUnion([project.name])
//       });
//     }
//   }
//
//   Stream<Component> loadScreen(FVBProject project, OperationCubit operationCubit) {
//     return fireStore
//         .collection('us${project.userId}')
//         .doc('projects')
//         .collection(project.name)
//         .doc(project.mainScreen.name)
//         .snapshots()
//         .map((event) {
//       final comp = Component.fromJson(
//         event.data()?['root'],
//         project,
//       )!;
//       final List<Component> list = [];
//       comp.forEach((p0) {
//         if (p0 is CNotRecognizedWidget || p0 is CustomComponent) {
//           list.add(p0);
//         }
//         return false;
//       });
//       for (final component in list) {
//         final custom = StreamComponent(loadCustom(project, component.name));
//         operationCubit.replaceChildOfParent(component, custom);
//       }
//       return comp;
//     });
//   }
//
//   Stream<Component> loadCustom(FVBProject project, String name) {
//     return fireStore
//         .collection('us${project.userId}')
//         .doc(Strings.kProjects)
//         .collection('Custom')
//         .doc('$name|${project.name}')
//         .snapshots()
//         .map((event) {
//       final customComponent = CustomComponent.fromJson(event.data()!,
//           parentVars: project.variables.values.whereType<VariableModel>().toList());
//       final code = event.data()!['code'];
//       customComponent.rootComponent =
//       code != null ? Component.fromJson(code, null, customs: project.customComponents) : null;
//       project.customComponents.removeWhere((element) => element.name == name);
//       project.customComponents.add(customComponent);
//       return customComponent;
//     });
//   }
//
//   Future<Optional<FVBProject, ProjectLoadErrorModel>> loadFlutterProject(int userId, String name,
//       {bool ifPublic = false}) async {
//     try {
//       final snapshot = await fireStore.collection('us$userId').doc(Strings.kProjects).collection(name).get();
//
//       final documents = snapshot.docs;
//       if (documents.isEmpty) {
//         return Optional.right(ProjectLoadErrorModel(ProjectLoadError.notFound, 'Project "$name" not found'));
//       }
//       final projectInfoDoc = documents.firstWhere((element) => element.data().containsKey('project_name'));
//       final projectInfo = projectInfoDoc.data();
//       collection.allProjects.firstWhereOrNull((element) => element.docId == projectInfoDoc.id)?.updatedAt =
//           DateTime.now();
//       fireStore.collection('us$userId').doc(Strings.kProjects).collection(name).doc(projectInfoDoc.id).update({
//         'updatedAt': timestamp(DateTime.now()),
//       });
//       final settings = projectInfo['settings'] != null ? ProjectSettingsModel.fromJson(projectInfo['settings']) : null;
//       if (ifPublic && (!(settings?.isPublic ?? false))) {
//         return Optional.right(ProjectLoadErrorModel(ProjectLoadError.notPermission, null));
//       }
//       final FVBProject project = FVBProject(
//         projectInfo['project_name'],
//         userId,
//         projectInfoDoc.id,
//         device: projectInfo['device'],
//         createdAt: projectInfo['createdAt'] != null ? timestampToDate(projectInfo['createdAt']) : null,
//         updatedAt: projectInfo['updatedAt'] != null ? timestampToDate(projectInfo['updatedAt']) : null,
//         imageList: projectInfo['image_list'] != null ? List<String>.from(projectInfo['image_list']) : [],
//         actionCode: projectInfo['action_code'] ?? '',
//         settings: settings,
//       );
//       project.apiModel = projectInfo['api_model'] != null
//           ? ApiGroupModel.fromJson(projectInfo['api_model'], project)
//           : ApiGroupModel([], [], project);
//       final variables =
//       List.from(projectInfo['variables'] ?? []).map((e) => VariableModel.fromJson(e..['uiAttached'] = true));
//       project.variables.clear();
//       for (final variable in variables) {
//         project.variables[variable.name] = variable;
//       }
//       // for (final modelJson in projectInfo['models'] ?? []) {
//       //   final model = LocalModel.fromJson(modelJson);
//       //   flutterProject.models.add(model);
//       // }
//       collection.project = project;
//
//       documents.retainWhere((element) => !element.data().containsKey('project_name'));
//
//       // for (final modelJson in projectInfo['screens'] ?? []) {
//       //   final screen = UIScreen.fromJson(modelJson, flutterProject);
//       //   flutterProject.uiScreens.add(screen);
//       // }
//
//         final customDocs = await FirePath.customComponentsReferenceByProjectName(userId, project.docId!).get();
//         await moveCollection([DocData('us$userId', ''), DocData('Custom|${project.docId}', Strings.kProjects)],
//             [DocData('us$userId', ''), DocData('Custom', Strings.kProjects)],
//             additionalData: {'project': project.name},
//             snapshot: customDocs,
//             deleteOld: false,
//             appendTargetDocKey: '|${project.name}');
//       for (final screenDoc in documents) {
//         if (screenDoc.data().containsKey('name')) {
//           final screen = Screen.fromJson(screenDoc.data());
//           project.screens.add(screen);
//         } else {
//           await screenDoc.reference.delete();
//         }
//       }
//
//       for (final doc in customDocs.docs) {
//         final Map<String, dynamic> componentBody = doc.data()! as Map<String, dynamic>;
//         project.customComponents.add(CustomComponent.fromJson(componentBody));
//       }
//
//       if (project.screens.isNotEmpty && projectInfo['mainScreen'] != null) {
//         project.mainScreen =
//             project.screens.firstWhereOrNull((element) => element.name == projectInfo['mainScreen']) ??
//                 project.screens.first;
//       }
//       fetchCustomComponentsFromJson(
//           customDocs.docs.map((e) => e.data()).toList(growable: false), project.customComponents);
//       for (int i = 0; i < project.screens.length; i++) {
//         project.screens[i].rootComponent = Component.fromJson(documents[i].data()['root'], project);
//       }
//       try {
//         List.from(projectInfo['models'] ?? []).forEach((e) => FVBModelClass.fromJson(e, project));
//       } catch (e) {
//         print('MODELS ERROR $e');
//         e.printError();
//       }
//       return Optional.left(project);
//     } on Exception catch (e) {
//       print('Load Project ERROR $e');
//       e.printError();
//       return Optional.right(ProjectLoadErrorModel(ProjectLoadError.otherError, e.toString()));
//     }
//   }
//
//   fetchCustomComponentsFromJson(List<dynamic> customDocuments, List<CustomComponent> customComponents) {
//     for (int i = 0; i < customDocuments.length; i++) {
//       final Map<String, dynamic> componentBody = customDocuments[i] as Map<String, dynamic>;
//       customComponents[i].rootComponent = componentBody['code'] != null
//           ? Component.fromJson(componentBody['code']!, null, customs: customComponents)
//           : null;
//     }
//     for (int i = 0; i < customDocuments.length; i++) {
//       customComponents[i].rootComponent?.forEachWithClones((p0) {
//         if (p0 is CustomComponent) {
//           p0.rootComponent = customComponents
//               .firstWhere((element) => element.name == p0.name)
//               .rootComponent
//               ?.clone(null, deepClone: false, connect: true);
//         }
//         return false;
//       });
//     }
//   }
//
//   Future<Uint8List?> loadImage(int userId, String imgName) async {
//     if (byteCache.containsKey(imgName)) {
//       return byteCache[imgName]!;
//     }
//     final QuerySnapshot<Map<String, dynamic>> image;
//     image = await fireStore.collection('us$userId|${Strings.kImages}').where('img_name', isEqualTo: imgName).get();
//     if (image.docs.isNotEmpty) {
//       return byteCache[imgName] = base64Decode(image.docs[0].data()['bytes']);
//     }
//     return null;
//   }
//
//   Future<List<FVBImage>?> loadAllImages(int userId) async {
//     final QuerySnapshot<Map<String, dynamic>> image;
//     image = await fireStore.collection('us$userId|${Strings.kImages}').get();
//     if (image.docs.isNotEmpty) {
//       final List<FVBImage> list = [];
//       for (final doc in image.docs) {
//         list.add(FVBImage.fromJson(doc.data()));
//       }
//       return list;
//     }
//     return null;
//   }
//
//   Future<String?> resetPassword(String userName) async {
//     await FirebaseAuth.instance.sendPasswordResetEmail(email: userName);
//     return null;
//   }
//
//   Future<int?> tryLoginWithPreference() async {
//     final pref = Preferences.sharedPreferences;
//     if (pref.containsKey(PrefKey.UID) &&
//         pref.getString(PrefKey.USERNAME) != null &&
//         pref.getString(PrefKey.PASS) != null) {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//           email: pref.getString(PrefKey.USERNAME)!, password: pref.getString(PrefKey.PASS)!);
//       return Preferences.sharedPreferences.getInt(PrefKey.UID);
//     }
//     return null;
//   }
//
//   Future<AuthResponse> login(String userName, String password) async {
//     if (Preferences.sharedPreferences.containsKey(PrefKey.UID)) {
//       return AuthResponse.left(Preferences.sharedPreferences.getInt(PrefKey.UID)!);
//     }
//     final loginResponse = await FirebaseAuth.instance.signInWithEmailAndPassword(email: userName, password: password);
//     if (loginResponse.user == null) {
//       return AuthResponse.right('Registration failed');
//     }
//     final response = await fireStore
//         .collection('users')
//         .where('uid', isEqualTo: loginResponse.user!.uid)
//     // .where('password', isEqualTo: password)
//         .get();
//     if (response.docs.isEmpty || !response.docs[0].exists) {
//       return AuthResponse.right('Something went wrong, Please check your internet');
//     }
//     final data = response.docs[0].data();
//     Preferences.sharedPreferences.setInt(PrefKey.UID, data['userId']);
//     Preferences.sharedPreferences
//       ..setString(PrefKey.USERNAME, userName)
//       ..setString(PrefKey.PASS, password);
//     return AuthResponse.left(data['userId']);
//   }
//
//   Future<void> uploadImage(int userId, String projectName, FVBImage imageData) async {
//     await fireStore.collection('us$userId|${Strings.kImages}').add(imageData.toJson());
//   }
//
//   Future<void> removeImage(int userId, String imgName) async {
//     final snapshot =
//     await fireStore.collection('us$userId|${Strings.kImages}').where('name', isEqualTo: imgName).get();
//     if (snapshot.docs.isNotEmpty) {
//       snapshot.docs[0].reference.delete();
//     }
//   }
//
//   Future<void> addModel(final int userId, final FVBProject project, final LocalModel localModel, Screen screen) async {
//     await fireStore.collection('us$userId').doc(Strings.kProjects).collection(project.name).doc(screen.name).update({
//       'models': FieldValue.arrayUnion([localModel.toJson()])
//     });
//     logger('=== FIRE-BRIDGE == addLocalModel ==');
//     // }
//   }
//
//   Future<void> addVariables(final int userId, final FVBProject project, final List<VariableModel> variables) async {
//     if (Platform.isWindows) {
//       final variablesRef =
//       fireStore.collection('us$userId').doc(Strings.kProjects).collection(project.name).doc(project.docId);
//       final oldResponse = await variablesRef.get();
//       if (oldResponse.data()!['variables'] != null) {
//         await variablesRef.update(
//             {'variables': List.from(oldResponse.data()!['variables'] ?? [])..addAll(variables.map((e) => e.toJson()))});
//       } else {
//         await variablesRef.update({'variables': variables.map((e) => e.toJson()).toList(growable: false)});
//       }
//     } else {
//       await fireStore
//           .collection('us$userId')
//           .doc(Strings.kProjects)
//           .collection(project.name)
//           .doc(project.docId)
//           .update({'variables': FieldValue.arrayUnion(variables.map((e) => e.toJson()).toList(growable: false))});
//     }
//     logger('=== FIRE-BRIDGE == addVariable ==');
//   }
//
//   Future<void> addVariableForScreen(
//       final int userId, final FVBProject project, final VariableModel variableModel, Screen screen) async {
//     if (Platform.isWindows) {
//       final variablesRef =
//       fireStore.collection('us$userId').doc(Strings.kProjects).collection(project.name).doc(screen.name);
//       final oldResponse = await variablesRef.get();
//       if (oldResponse.data()!['variables'] != null) {
//         await variablesRef
//             .update({'variables': List.from(oldResponse.data()!['variables'])..add(variableModel.toJson())});
//       }
//     } else {
//       await fireStore.collection('us$userId').doc(Strings.kProjects).collection(project.name).doc(screen.name).update({
//         'variables': FieldValue.arrayUnion([variableModel.toJson()])
//       });
//     }
//     logger('=== FIRE-BRIDGE == addVariable ==');
//   }
//
//   Future<void> updateVariable(final int userId, final FVBProject project) async {
//     await fireStore.collection('us$userId').doc(Strings.kProjects).collection(project.name).doc(project.docId).update({
//       'variables': project.variables.values
//           .where((element) => element is VariableModel && element.uiAttached && !element.isDynamic)
//           .map((e) => e.toJson())
//           .toList(growable: false)
//     });
//     logger('=== FIRE-BRIDGE == update variable ==');
//   }
//
//   Future<void> updateModels(final int userId, final FVBProject project) async {
//     await fireStore.collection('us$userId').doc(Strings.kProjects).collection(project.name).doc(project.docId).update(
//         {'models': Processor.classes.values.whereType<FVBModelClass>().map((e) => e.toJson()).toList(growable: false)});
//     logger('=== FIRE-BRIDGE == update models ==');
//   }
//
//   Future<void> updateUIScreenVariable(final int userId, final FVBProject project, Screen screen) async {
//     await fireStore.collection('us$userId').doc(Strings.kProjects).collection(project.name).doc(screen.name).update({
//       'variables': screen.variables.values
//           .where((element) => element is VariableModel && element.uiAttached && !element.isDynamic)
//           .map((e) => e.toJson())
//           .toList(growable: false)
//     });
//     logger('=== FIRE-BRIDGE == update variable ==');
//   }
//
//   Future<void> updateVariableForCustomComponent(
//       final int userId,
//       final FVBProject project,
//       final CustomComponent component,
//       ) async {
//     await FirePath.customComponentsReferenceUpdated(project.userId, project.name, component.name).update({
//       'variables': component.variables.values
//           .where((element) => element is VariableModel && element.uiAttached && !element.isDynamic)
//           .map((e) => e.toJson())
//           .toList(growable: false)
//     });
//     logger('=== FIRE-BRIDGE == update variable ==');
//   }
//
//   Future<void> updateCustomComponentActionCode(
//       int userId, final FVBProject project, final CustomComponent component) async {
//     await FirePath.customComponentsReferenceUpdated(project.userId, project.name, component.name).update({
//       'action_code': component.actionCode,
//     });
//   }
//
//   Future<void> updateCustomComponentArguments(
//       int userId, final FVBProject project, final CustomComponent component) async {
//     await FirePath.customComponentsReferenceUpdated(project.userId, project.name, component.name).update({
//       'arguments': component.argumentVariables.map((e) => e.toJson()).toList(growable: false),
//     });
//   }
//
//   Future<void> updateDeviceSelection(final int userId, final FVBProject project, final String device) async {
//     await fireStore
//         .collection('us$userId')
//         .doc(Strings.kProjects)
//         .collection(project.name)
//         .doc(project.docId)
//         .update({'device': device});
//   }
//
//   Future<void> updateSettings(final int userId, final FVBProject project) async {
//     await fireStore
//         .collection('us$userId')
//         .doc(Strings.kProjects)
//         .collection(project.name)
//         .doc(project.docId)
//         .update({'settings': project.settings.toJson()});
//   }
//
//   Future<void> updateCurrentScreen(int userId, final FVBProject project, Viewable screen) async {
//     await fireStore
//         .collection('us$userId')
//         .doc(Strings.kProjects)
//         .collection(project.name)
//         .doc(project.docId)
//         .update({'currentScreen': screen.name});
//   }
//
//   Future<void> updateMainScreen(int userId, final FVBProject project) async {
//     await fireStore
//         .collection('us$userId')
//         .doc(Strings.kProjects)
//         .collection(project.name)
//         .doc(project.docId)
//         .update({'mainScreen': project.mainScreen.name});
//   }
//
//   Future<void> updateProjectValue(final FVBProject project, String key, dynamic value) async {
//     await fireStore
//         .collection('us${project.userId}')
//         .doc(Strings.kProjects)
//         .collection(project.name)
//         .doc(project.docId)
//         .update({key: value});
//   }
//
//   Future<void> updateUserValue(final FVBProject project, String key, dynamic value) async {
//     await fireStore.collection('us${project.userId}').doc(Strings.kFlutterProjectInfo).update({key: value});
//   }
//
//   Future<void> updateActionCode(int userId, final FVBProject project) async {
//     await fireStore
//         .collection('us$userId')
//         .doc(Strings.kProjects)
//         .collection(project.name)
//         .doc(project.docId)
//         .update({'action_code': project.actionCode});
//   }
//
//   Future<void> updateScreenActionCode(int userId, final FVBProject project, Screen screen) async {
//     await fireStore
//         .collection('us$userId')
//         .doc(Strings.kProjects)
//         .collection(project.name)
//         .doc(screen.name)
//         .update({'action_code': screen.actionCode});
//   }
//
//   // static Future<void> updateRootComponent(
//   //     int userId, String projectName, Component component) async {
//   //   final document = await fireStore
//   //       .collection('us$userId')
//   //       .doc(Strings.kFlutterProject)
//   //       .collection(projectName)
//   //       .where('project_name', isNull: false)
//   //       .get(const GetOptions(source: Source.server));
//   //   final documentData = document.docs[0].data();
//   //   final Map<String, dynamic> body = {};
//   //   final rootCode = CodeOperations.trim(component.code(clean: false));
//   //   if (documentData['root'] != rootCode) {
//   //     body['root'] = rootCode;
//   //   }
//   //   if (body.isNotEmpty) {
//   //     await fireStore
//   //         .collection('us$userId')
//   //         .doc(Strings.kFlutterProject)
//   //         .collection(projectName)
//   //         .doc(document.docs[0].id)
//   //         .update(body);
//   //     logger('=== FIRE-BRIDGE == updateGlobalCustomComponent ==');
//   //   }
//   // }
//   //
//
//   Future<void> addUIScreen(final int userId, final FVBProject project, final Screen uiScreen) async {
//     final screen = uiScreen.toJson();
//     await fireStore
//         .collection('us$userId')
//         .doc(Strings.kProjects)
//         .collection(project.name)
//         .doc(uiScreen.name)
//         .set(screen);
//     logger('=== FIRE-BRIDGE == addUIScreen ==');
//   }
//
//   Future<void> updateScreenRootComponent(
//       final int userId, final String projectName, final Screen uiScreen, final Component? component) async {
//     // final code = CodeOperations.trim(
//     //   component?.code(clean: false),
//     // );
//     final json = component?.toJson();
//     await fireStore.collection('us$userId').doc(Strings.kProjects).collection(projectName).doc(uiScreen.name).update({
//       'root': json,
//     });
//   }
//
//   static void check(value) {
//     if (value is Map) {
//       value.forEach((key, value) {
//         check(key);
//         check(value);
//       });
//     } else if (value is List) {
//       value.forEach((element) {
//         check(element);
//       });
//     } else if (value != null && value is! num && value is! bool && value is! String) {
//       print('TYPE $value');
//     }
//   }
//
//   Future<void> logout() async {
//     await FirebaseAuth.instance.signOut();
//     Preferences.sharedPreferences.remove(PrefKey.UID);
//   }
//
//   removeUIScreen(final int userId, final FVBProject flutterProject, final Screen uiScreen) async {
//     await fireStore
//         .collection('us$userId')
//         .doc(Strings.kProjects)
//         .collection(flutterProject.name)
//         .doc(uiScreen.name)
//         .delete();
//   }
//
//   static timestamp(DateTime dateTime) {
//     final microseconds = dateTime.microsecondsSinceEpoch;
//     final int seconds = microseconds ~/ _kMillion;
//     final int nanoseconds = (microseconds - seconds * _kMillion) * _kThousand;
//     return 'Timestamp(seconds=$seconds, nanoseconds=$nanoseconds)';
//   }
//
//   static DateTime? timestampToDate(timestamp) {
//     if (timestamp == null) {
//       return null;
//     }
//     if (timestamp is! String) {
//       timestamp = timestamp.toString();
//     }
//     final int i = timestamp.indexOf('(');
//     if (i == -1) {
//       return null;
//     }
//     final int e = timestamp.indexOf(')');
//     final split = timestamp.substring(i + 1, e).split(',');
//     return Timestamp(int.parse(split[0].split('=')[1]), int.parse(split[1].split('=')[1])).toDate();
//   }
// }
//
// abstract class FirePath {
//   static CollectionReference project(int id, String name) =>
//       fireStore.collection('us$id').doc(Strings.kProjects).collection(name);
//
//   static DocumentReference customComponentReference(int userId, String projectId, String customComponentName) =>
//       fireStore.collection('us$userId').doc(Strings.kProjects).collection('Custom|$projectId').doc(customComponentName);
//
//   static CollectionReference customComponentsReferenceByProjectName(int userId, String projectId) =>
//       fireStore.collection('us$userId').doc(Strings.kProjects).collection('Custom|$projectId');
//
//   static CollectionReference customComponentsReferenceByProjectNameUpdated(int userId) =>
//       fireStore.collection('us$userId').doc(Strings.kProjects).collection('Custom');
//
//   static DocumentReference customComponentsReferenceUpdated(int userId, String project, String name) =>
//       fireStore.collection('us$userId').doc(Strings.kProjects).collection('Custom').doc(name + '|' + project);
// }
