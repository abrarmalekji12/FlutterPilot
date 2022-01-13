import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
    projectInfo['name'] = project.name;
    projectInfo['root'] = (project.rootComponent?.code())
      ?..replaceAll('\n', '').replaceAll(' ', '');
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
            ? (component.root!.code()..replaceAll('\n', '').replaceAll(' ', ''))
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
    final projectInfo = snapshot.docs.first.data();
    logger('PROJECT NAME ${projectInfo['name']} ${projectInfo['root']}');
    final FlutterProject flutterProject = FlutterProject(projectInfo['name']);
    flutterProject.rootComponent = projectInfo['root'] != null
        ? Component.fromCode(
            projectInfo['root'].replaceAll('\n', '').replaceAll(' ', ''))
        : null;
    for (final doc in snapshot.docs.sublist(1)) {
      final componentBody = doc.data();
      logger('DOCC $componentBody');
      flutterProject.customComponents.add(
          StatelessComponent(name: componentBody['name'])
            ..root = componentBody['code'] != null
                ? Component.fromCode(componentBody['code']!
                    .toString()
                    .replaceAll('\n', '')
                    .replaceAll(' ', ''))
                : null);
    }
    logger('DONE');
    return flutterProject;
  }

  static Future<void> updateRootComponent(
      int userId, String projectName, Component component) async {
    final document = await FirebaseFirestore.instance
        .collection('us$userId')
        .doc(Strings.kFlutterProject)
        .collection(projectName)
        .limit(1)
        .get();
    final documentData = document.docs[0].data();
    final Map<String, dynamic> body = {};
    final rootCode = component.code();
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
