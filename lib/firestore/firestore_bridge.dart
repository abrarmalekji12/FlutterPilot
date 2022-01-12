import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

  static void addNewGlobalCustomComponent(CustomComponent customComponent) {
    final String type;
    switch (customComponent.runtimeType) {
      case StatelessComponent:
        type = 'stateless';
        break;
      default:
        type = 'other';
        break;
    }
    FirebaseFirestore.instance.collection(Strings.kCustomComponents).add({
      'name': customComponent.name,
      'code': customComponent.root?.code(),
      'type': type
    }).then((value) {
      logger('=== FIRE-BRIDGE == addNewGlobalCustomComponent ==');
    });
  }

  static void updateGlobalCustomComponent(CustomComponent customComponent,
      {String? newName}) async {
    final document = await FirebaseFirestore.instance
        .collection(Strings.kCustomComponents)
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
          .collection(Strings.kCustomComponents)
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

  static void deleteGlobalCustomComponent(CustomComponent customComponent) {
    FirebaseFirestore.instance
        .collection(Strings.kCustomComponents)
        .doc(customComponent.name)
        .delete()
        .then((value) {
      logger('=== FIRE-BRIDGE == deleteGlobalCustomComponent ==');
    });
  }

  static Future<List<CustomComponent>> loadAllGlobalCustomComponents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(Strings.kCustomComponents)
        .get();
    final List<CustomComponent> components = [];
    for (final doc in snapshot.docs) {
      final componentBody = doc.data();

      components.add(StatelessComponent(name: componentBody['name'])
        ..root = componentBody['code'] != null
            ? Component.fromCode(componentBody['code']!.toString().replaceAll('\n', '').replaceAll(' ', ''))
            : null);
    }

    return components;
  }

  static Future<CustomComponent> retrieveComponent(String name) async {
    final snapshot = await FirebaseFirestore.instance.collection(name).get();
    return StatelessComponent(name: name)
      ..root = Component.fromCode(snapshot.docs[0]['code']);
  }
}
