import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/screen_config/screen_config_cubit.dart';
import 'package:flutter_builder/screen_model.dart';
import '../models/variable_model.dart';
import '../code_to_component.dart';
import '../models/other_model.dart';
import '../models/project_model.dart';
import '../common/logger.dart';
import '../constant/string_constant.dart';
import '../models/component_model.dart';

abstract class FireBridge {
  static Future<void> init() async {
    await Firebase.initializeApp(
        options: FirebaseOptions.fromMap(const {
      'apiKey': 'AIzaSyBCYM-y341AVf0v-Ix6dq7UXhnDbIFjwOk',
      'authDomain': 'flutter-visual-builder.firebaseapp.com',
      'projectId': 'flutter-visual-builder',
      'storageBucket': 'flutter-visual-builder.appspot.com',
      'messagingSenderId': '357010413683',
      'appId': '1:357010413683:web:851137f5a4916cc6587206'
    }));
  }

  static void saveComponent(CustomComponent customComponent) {
    final FirebaseFirestore fireStore = FirebaseFirestore.instance;
    fireStore
        .collection(customComponent.name)
        .add({'code': customComponent.root?.code(clean: false)}).then((value) {
      logger('=== SAVED ===');
    });
  }

  static Future<void> addNewGlobalCustomComponent(
      int userId, String projectName, CustomComponent customComponent) async {
    final String type;
    switch (customComponent.runtimeType) {
      case StatelessComponent:
        type = 'stateless';
        break;
      default:
        type = 'other';
        break;
    }
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .add({
      'name': customComponent.name,
      'code': customComponent.root?.code(clean: false),
      'type': type
    });

    logger('=== FIRE-BRIDGE == addNewGlobalCustomComponent ==');
  }

  static Future<void> updateGlobalCustomComponent(
      int userId, String projectName, CustomComponent customComponent,
      {String? newName}) async {
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('name', isEqualTo: customComponent.name)
        .get();
    final documentData = document.docs[0].data();
    final Map<String, dynamic> body = {};
    if (documentData['name'] != (newName ?? customComponent.name)) {
      body['name'] = newName ?? customComponent.name;
    }
    final rootCode = customComponent.root?.code(clean: false);
    if (documentData['code'] != rootCode) {
      body['code'] = rootCode;
    }
    if (body.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(projectName)
          .doc(document.docs[0].id)
          .update(body)
          .then((value) {
        if (newName != null) {
          customComponent.name = newName;
        }
        logger('=== FIRE-BRIDGE == updateGlobalCustomComponent ==');
      });
    }
  }

  static Future<void> deleteGlobalCustomComponent(
      int userId, String projectName, CustomComponent customComponent) async {
    final value = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('name', isEqualTo: customComponent.name)
        .get();
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .doc(value.docs[0].id)
        .delete();
    logger('=== FIRE-BRIDGE == deleteGlobalCustomComponent ==');
  }

  static Future<void> saveFlutterProject(
      int userId, FlutterProject project) async {
    final List<CustomComponent> components = project.customComponents;
    final projectInfo = <String, dynamic>{};
    projectInfo['project_name'] = project.name;
    projectInfo['root'] =
        CodeOperations.trim(project.rootComponent?.code(clean: false));
    projectInfo[Strings.kImages] = [];
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(project.name)
        .add(projectInfo);
    for (final component in components) {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(project.name)
          .add({
        'variables': [],
        'name': component.name,
        'device':'iPhone X',
        'code': component.root != null
            ? (CodeOperations.trim(component.root!.code(clean: false)))
            : null
      });
    }
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProjectInfo)
        .update({
      'projects': FieldValue.arrayUnion([project.name])
    });
  }

  static Future<List<FavouriteModel>> loadFavourites(final int userId,
      {String? projectName}) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    if (projectName == null) {
      snapshot = await FirebaseFirestore.instance
          .collection('us$userId|${Strings.kFavourites}')
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('us$userId|${Strings.kFavourites}')
          .where('project_name', isEqualTo: projectName)
          .get();
    }

    final List<FavouriteModel> favouriteModels = [];
    for (final document in snapshot.docs) {
      final json = document.data();
      favouriteModels.add(FavouriteModel(
          Component.fromCode(json['code'])!
            ..boundary = Rect.fromLTWH(0, 0, json['width'], json['height']),
          json['project_name']));
    }
    return favouriteModels;
  }

  static Future<void> addToFavourites(
      int userId, Component component, String projectName) async {
    await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kFavourites}')
        .doc('${DateTime.now().millisecondsSinceEpoch}')
        .set({
      'code': CodeOperations.trim(component.code(clean: false)),
      'id': component.id,
      'project_name': projectName,
      'width': component.boundary!.width,
      'height': component.boundary!.height,
    });
  }

  static Future<void> removeFromFavourites(
      int userId, Component component) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('us$userId|${Strings.kFavourites}')
        .where('id', isEqualTo: component.id)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs[0].reference.delete();
    }
  }

  static Future<List<FlutterProject>> loadAllFlutterProjects(
    int userId,
  ) async {
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
      projectList.add(FlutterProject(projectName));
    }
    return projectList;
  }

  static Future<FlutterProject?> loadFlutterProject(
      int userId, String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(name)
        .get();
    final documents = snapshot.docs;
    final projectInfoDoc =
        documents.firstWhere((element) => element.data().containsKey('root'));
    final projectInfo = projectInfoDoc.data();
    logger(
        'PROJECT NAME ${projectInfo['project_name']} ${projectInfo['root']}');

    final FlutterProject flutterProject =
        FlutterProject(projectInfo['project_name'],device: projectInfo['device']);
    for (final variableJson in projectInfo['variables'] ?? []) {
      final model = VariableModel(
          variableJson['name'], variableJson['value'], false, null);
      ComponentOperationCubit.codeProcessor.variables[variableJson['name']] =
          model;
      flutterProject.variables.add(model);
    }
    try {
      flutterProject.rootComponent =
          Component.fromCode(CodeOperations.trim(projectInfo['root']));
    } on Exception {
      return null;
    }
    documents.retainWhere((element) => !element.data().containsKey('root'));
    for (final doc in documents) {
      final componentBody = doc.data();
      flutterProject.customComponents.add(
          StatelessComponent(name: componentBody['name'])
            ..root = componentBody['code'] != null
                ? Component.fromCode(componentBody['code']!)
                : null);
    }
    return flutterProject;
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
  }

  static Future<void> uploadImage(
      int userId, String projectName, ImageData imageData) async {
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

  static Future<void> addVariable(final int userId, final String projectName,
      final VariableModel variableModel) async {
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('project_name', isNull: false)
        .get(const GetOptions(source: Source.server));
    final Map<String, dynamic> body = {
      'variables': FieldValue.arrayUnion([
        {
          'name': variableModel.name,
          'value': variableModel.value,
        }
      ])
    };

    if (body.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(projectName)
          .doc(document.docs[0].id)
          .update(body);
      logger('=== FIRE-BRIDGE == updateGlobalCustomComponent ==');
    }
  }



  static Future<void> updateVariable(final int userId, final String projectName,
      final VariableModel variableModel) async {
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('project_name', isNull: false)
        .get(const GetOptions(source: Source.server));
    final List<dynamic> variables = document.docs[0]['variables'];
    variables.firstWhere(
            (element) => element['name'] == variableModel.name)['value'] =
        variableModel.value;
    final Map<String, dynamic> body = {'variables': variables};

    if (body.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(projectName)
          .doc(document.docs[0].id)
          .update(body);
      logger('=== FIRE-BRIDGE == update variable ==');
    }
  }
  static Future<void> updateDeviceSelection(int userId,String projectName,String device) async {
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('project_name', isNull: false)
        .get(const GetOptions(source: Source.server));
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .doc(document.docs[0].id).update({
      'device':device
    });
  }
  static Future<void> updateRootComponent(
      int userId, String projectName, Component component) async {
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('project_name', isNull: false)
        .get(const GetOptions(source: Source.server));
    final documentData = document.docs[0].data();
    final Map<String, dynamic> body = {};
    final rootCode = CodeOperations.trim(component.code(clean: false));
    if (documentData['root'] != rootCode) {
      body['root'] = rootCode;
    }
    if (body.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('us$userId')
          .doc(Strings.kFlutterProject)
          .collection(projectName)
          .doc(document.docs[0].id)
          .update(body);
      logger('=== FIRE-BRIDGE == updateGlobalCustomComponent ==');
    }
  }

  static Future<CustomComponent> retrieveComponent(
      int userId, String projectName, String name) async {
    final snapshot = await FirebaseFirestore.instance.collection(name).get();
    return StatelessComponent(name: name)
      ..root = Component.fromCode(snapshot.docs[0]['code']);
  }
}
