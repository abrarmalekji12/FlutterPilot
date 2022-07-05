import 'dart:convert';

import 'package:firedart/auth/user_gateway.dart' as user_gateway;
import 'package:firedart/firedart.dart' as firedart;

import '../common/shared_preferences.dart';

class FirebaseOptions {
  final Map<String, dynamic> options;

  FirebaseOptions(this.options);

  static FirebaseOptions fromMap(Map<String, dynamic> map) {
    return FirebaseOptions(map);
  }
}

class Firebase {
  static Firebase? instance;
  static FirebaseFirestore? firestore;
  final FirebaseOptions options;

  Firebase._(this.options);

  static Future<Firebase> initializeApp(
      {required FirebaseOptions options}) async {
    if (instance == null) {
      instance = Firebase._(options);
      firedart.FirebaseAuth.initialize(options.options['apiKey'], MyToken());
      firestore = FirebaseFirestore(firedart.Firestore(
          options.options['projectId'],
          auth: firedart.FirebaseAuth.instance));
    }
    return instance!;
  }
}

class MyToken extends firedart.TokenStore {
  @override
  void delete() {}

  @override
  firedart.Token? read() {
    if (Preferences.get('token') != null) {
      return firedart.Token.fromMap(
          json.decode(Preferences.get('token').toString()));
    }
    return null;
  }

  @override
  void write(firedart.Token? token) {
    Preferences.put('token', json.encode(token!.toMap()));
  }
}

class QuerySnapshot<T> {
  final firedart.Page<firedart.Document>? query;
  final List<firedart.Document>? list;

  QuerySnapshot(this.query, this.list);

  List<QueryDocumentSnapshot<T>> get docs {
    return ((query?.toList()) ?? (list!))
        .map<QueryDocumentSnapshot<T>>((e) => QueryDocumentSnapshot<T>(e))
        .toList();
  }
}

class QueryDocumentSnapshot<T> {
  final firedart.Document _document;

  QueryDocumentSnapshot(this._document);

  Map<String, dynamic> data() {
    return _document.map;
  }

  String get id => _document.id;

  bool get exists {
    return _document.map.isNotEmpty;
  }

  DocumentReference get reference {
    return DocumentReference(_document.reference);
  }
}

class FieldValue {
  static arrayRemove(List list) {
    throw UnimplementedError();
  }

  static arrayUnion(List list) {
    throw UnimplementedError();
  }

  static increment(int value) {
    throw UnimplementedError();
  }
}

class UserCredential {
  final User? user;

  UserCredential(this.user);
}

class User {
  final user_gateway.User? user;

  User(this.user);

  String? get uid => user?.id;
}

class FirebaseAuth {
  firedart.FirebaseAuth? firebaseAuth;
  static FirebaseAuth? _firebaseAuth;

  static FirebaseAuth get instance {
    if (_firebaseAuth == null) {
      _firebaseAuth = FirebaseAuth();
      _firebaseAuth!.firebaseAuth = firedart.FirebaseAuth.instance;
    }
    return _firebaseAuth!;
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    final user = await firebaseAuth?.signUp(email, password);
    return UserCredential(User(user));
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await firebaseAuth?.resetPassword(email);
  }

  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    final user = await firebaseAuth?.signIn(email, password);
    return UserCredential(User(user));
  }

  signOut() async {
    firebaseAuth?.signOut();
  }
}

class Query<T> {
  final firedart.QueryReference reference;

  Query(this.reference);

  Future<QuerySnapshot<Map<String, dynamic>>> get() async {
    return QuerySnapshot<Map<String, dynamic>>(null, await reference.get());
  }
}

class CollectionReference {
  final firedart.CollectionReference collectionReference;

  CollectionReference(this.collectionReference);

  Future<QuerySnapshot<Map<String, dynamic>>> get() async {
    return QuerySnapshot<Map<String, dynamic>>(
        await collectionReference.get(), null);
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>> add(
      Map<String, dynamic> data) async {
    return QueryDocumentSnapshot<Map<String, dynamic>>(
        await collectionReference.add(data));
  }

  Query<Map<String, dynamic>> where(String key, {dynamic isEqualTo}) {
    return Query<Map<String, dynamic>>(
        collectionReference.where(key, isEqualTo: isEqualTo));
  }

  DocumentReference doc(String? id) {
    return DocumentReference(collectionReference.document(id ?? ''));
  }
}

class DocumentReference {
  final firedart.DocumentReference documentReference;

  DocumentReference(this.documentReference);

  Future<QueryDocumentSnapshot<Map<String, dynamic>>> get() async {
    return QueryDocumentSnapshot<Map<String, dynamic>>(
        await documentReference.get());
  }

  Future<void> set(Map<String, dynamic> data) async {
    await documentReference.set(data);
  }

  CollectionReference collection(String path) {
    return CollectionReference(documentReference.collection(path));
  }

  Future<void> delete() async {
    await documentReference.delete();
  }

  Future<void> update(Map<String, dynamic> data) async {
    await documentReference.update(data);
  }
}

class FirebaseFirestore {
  final firedart.Firestore firestore;
  FirebaseFirestore(this.firestore);

  static FirebaseFirestore get instance {
    return Firebase.firestore!;
  }

  DocumentReference document(String path) {
    return DocumentReference(Firebase.firestore!.firestore.document(path));
  }

  CollectionReference collection(String path) {
    return CollectionReference(Firebase.firestore!.firestore.collection(path));
  }
}
