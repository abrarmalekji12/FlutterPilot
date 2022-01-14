import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
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
        .add({'code': customComponent.root?.code()}).then((value) {
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
      'code': customComponent.root?.code(),
      'type': type
    });

    logger('=== FIRE-BRIDGE == addNewGlobalCustomComponent ==');
  }

  static void updateGlobalCustomComponent(
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
    final rootCode = customComponent.root?.code();
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
    projectInfo['root'] = CodeToComponent.trim(project.rootComponent?.code());
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
        'name': component.name,
        'code': component.root != null
            ? (CodeToComponent.trim(component.root!.code()))
            : null
      });
    }
  }

  static Future<FlutterProject?> loadFlutterProject(
      int userId, String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(name)
        .get();
    if (snapshot.size == 0 || snapshot.docs.isEmpty) {
      return null;
    }
    final documents = snapshot.docs;
    final projectInfoDoc =
        documents.firstWhere((element) => element.data().containsKey('root'));
    final projectInfo = projectInfoDoc.data();
    logger(
        'PROJECT NAME ${projectInfo['project_name']} ${projectInfo['root']}');
    final FlutterProject flutterProject =
        FlutterProject(projectInfo['project_name']);
    flutterProject.rootComponent =
        Component.fromCode(CodeToComponent.trim(projectInfo['root']));
    final imageList = projectInfo[Strings.kImages];
    for (final image in imageList) {
      // final bytes =
      //     await loadImageBytes(userId, projectInfo['project_name'], imagePath);
      // if (bytes != null) {
        flutterProject.byteCache[image['img_name']] = base64Decode(image['bytes']);
      // }
    }
    documents.retainWhere((element) => !element.data().containsKey('root'));
    for (final doc in documents) {
      final componentBody = doc.data();
      logger('DOCC $componentBody');
      flutterProject.customComponents.add(
          StatelessComponent(name: componentBody['name'])
            ..root = componentBody['code'] != null
                ? Component.fromCode(componentBody['code']!)
                : null);
    }
    logger('DONE');
    return flutterProject;
  }

  static Future<void> uploadImage(
      int userId, String projectName, ImageData imageData) async {
    // await FirebaseStorage.instance
    //     .ref(
    //         'us$userId/${Strings.kStorage}/${Strings.kImages}/${imageData.imagePath!.replaceAll('.', '__dot__')}')
    //     .putData(imageData.bytes!);
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('project_name', isNull: false)
        .get();
    await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .doc(document.docs[0].id)
        .update({
      Strings.kImages: FieldValue.arrayUnion([
        {
          'img_name': imageData.imagePath,
          'bytes': base64Encode(imageData.bytes!)
        }
      ])
    });
  }

  static Future<Uint8List?> loadImageBytes(
      int userId, String projectName, String imagePath) async {
    logger('LOADING ======= $imagePath');
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('project_name', isNull: false)
        .get();
   // Uint8List? bytes=document.docs[0].data()[Strings.kImages]['bytes']
    return null;
  }

  static Future<void> updateRootComponent(
      int userId, String projectName, Component component) async {
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .where('project_name', isNull: false)
        .get();
    final documentData = document.docs[0].data();
    final Map<String, dynamic> body = {};
    final rootCode = CodeToComponent.trim(component.code());
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
