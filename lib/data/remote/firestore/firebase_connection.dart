// import 'dart:convert';
// import 'dart:math';
//
// import 'package:firebase_dart/firebase_dart.dart' as firebaseDart;
// import 'package:firedart/auth/exceptions.dart';
// import 'package:firedart/auth/user_gateway.dart' as user_gateway;
// import 'package:firedart/firedart.dart' as firedart;
// import 'package:firedart/firestore/models.dart';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../../injector.dart';
//
// export 'package:firedart/generated/google/protobuf/timestamp.pb.dart';
//
// const int _kThousand = 1000;
// const int _kMillion = 1000000;
//
// class Timestamp {
//   final int seconds;
//   final int nanoSeconds;
//
//   Timestamp(this.seconds, this.nanoSeconds);
//
//   static String fromDate(DateTime dateTime) {
//     final microseconds = dateTime.microsecondsSinceEpoch;
//     final int seconds = microseconds ~/ _kMillion;
//     final int nanoseconds = (microseconds - seconds * _kMillion) * _kThousand;
//     return 'Timestamp(seconds=$seconds, nanoseconds=$nanoseconds)';
//   }
//
//   int get microsecondsSinceEpoch => seconds * _kMillion + nanoSeconds ~/ _kThousand;
//
//   /// Converts [Timestamp] to [DateTime]
//   DateTime toDate() {
//     return DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
//   }
//
//   static String now() {
//     final now = DateTime.now();
//     final microseconds = now.microsecondsSinceEpoch;
//     final int seconds = microseconds ~/ _kMillion;
//     final int nanoseconds = (microseconds - seconds * _kMillion) * _kThousand;
//     return 'Timestamp(seconds=$seconds, nanoseconds=$nanoseconds)';
//   }
// }
//
// class FirebaseOptions {
//   const FirebaseOptions({
//     required this.apiKey,
//     required this.appId,
//     required this.messagingSenderId,
//     required this.projectId,
//     this.authDomain,
//     this.databaseURL,
//     this.storageBucket,
//     this.measurementId,
//     // ios specific
//     this.trackingId,
//     this.deepLinkURLScheme,
//     this.androidClientId,
//     this.iosClientId,
//     this.iosBundleId,
//     this.appGroupId,
//   });
//
//   /// Named constructor to create [FirebaseOptions] from a the response of Pigeon channel.
//   ///
//   /// This constructor is used when platforms cannot directly return a
//   /// [FirebaseOptions] instance, for example when data is sent back from a
//   /// [MethodChannel].
//
//   /// An API key used for authenticating requests from your app to Google
//   /// servers.
//   final String apiKey;
//
//   /// The Google App ID that is used to uniquely identify an instance of an app.
//   final String appId;
//
//   /// The unique sender ID value used in messaging to identify your app.
//   final String messagingSenderId;
//
//   /// The Project ID from the Firebase console, for example "my-awesome-app".
//   final String projectId;
//
//   /// The auth domain used to handle redirects from OAuth provides on web
//   /// platforms, for example "my-awesome-app.firebaseapp.com".
//   final String? authDomain;
//
//   /// The database root URL, for example "https://my-awesome-app.firebaseio.com."
//   ///
//   /// This property should be set for apps that use Firebase Database.
//   final String? databaseURL;
//
//   /// The Google Cloud Storage bucket name, for example
//   /// "my-awesome-app.appspot.com".
//   final String? storageBucket;
//
//   /// The project measurement ID value used on web platforms with analytics.
//   final String? measurementId;
//
//   /// The tracking ID for Google Analytics, for example "UA-12345678-1", used to
//   /// configure Google Analytics.
//   ///
//   /// This property is used on iOS only.
//   final String? trackingId;
//
//   /// The URL scheme used by iOS secondary apps for Dynamic Links.
//   final String? deepLinkURLScheme;
//
//   /// The Android client ID from the Firebase Console, for example
//   /// "12345.apps.googleusercontent.com."
//   ///
//   /// This value is used by iOS only.
//   final String? androidClientId;
//
//   /// The iOS client ID from the Firebase Console, for example
//   /// "12345.apps.googleusercontent.com."
//   ///
//   /// This value is used by iOS only.
//   final String? iosClientId;
//
//   /// The iOS bundle ID for the application. Defaults to `[[NSBundle mainBundle] bundleID]`
//   /// when not set manually or in a plist.
//   ///
//   /// This property is used on iOS only.
//   final String? iosBundleId;
//
//   /// The iOS App Group identifier to share data between the application and the
//   /// application extensions.
//   ///
//   /// Note that if using this then the App Group must be configured in the
//   /// application and on the Apple Developer Portal.
//   ///
//   /// This property is used on iOS only.
//   final String? appGroupId;
//
//   Map<String, String?> get asMap {
//     return <String, String?>{
//       'apiKey': apiKey,
//       'appId': appId,
//       'messagingSenderId': messagingSenderId,
//       'projectId': projectId,
//       'authDomain': authDomain,
//       'databaseURL': databaseURL,
//       'storageBucket': storageBucket,
//       'measurementId': measurementId,
//       'trackingId': trackingId,
//       'deepLinkURLScheme': deepLinkURLScheme,
//       'androidClientId': androidClientId,
//       'iosClientId': iosClientId,
//       'iosBundleId': iosBundleId,
//       'appGroupId': appGroupId,
//     };
//   }
// }
//
// class FirebaseApp {
//   final String name;
//   final Firebase? instance;
//
//   FirebaseApp(this.instance, this.name);
// }
//
// class FirebaseStorage {
//   final firebaseDart.FirebaseStorage _instance;
//   static FirebaseStorage? _storage;
//
//   FirebaseStorage(this._instance);
//
//   firebaseDart.Reference ref([String? path]) {
//     return _instance.ref(path);
//   }
//
//   static get instance {
//     // if (_storage == null) {
//     //   _storage = FirebaseStorage(firebaseDart.FirebaseStorage.instance);
//     // }
//     return Firebase.storage!;
//   }
//
//   static instanceFor({String? bucket}) {
//     if (_storage == null) {
//       _storage = FirebaseStorage(
//         firebaseDart.FirebaseStorage.instanceFor(bucket: bucket),
//       );
//     }
//     return _storage!;
//   }
// }
//
// class Firebase {
//   static Firebase? instance;
//   static FirebaseFirestore? firestore;
//   static FirebaseStorage? storage;
//   final FirebaseOptions options;
//   static Map<String, Firebase> instances = {};
//
//   Firebase._(this.options);
//
//   static Future<FirebaseApp> initializeApp({required FirebaseOptions options, String? name}) async {
//     if (name == null) {
//       FirebaseAuth.initAuth();
//       FirebaseAuth.instance.firebaseAuth = firedart.FirebaseAuth.initialize(
//         options.apiKey,
//         MyToken(sl()),
//       );
//       firestore = FirebaseFirestore(firedart.Firestore(options.projectId,
//               // : firedart.FirebaseAuth.instance
//       ));
//
//       instance = Firebase._(options);
//       firebaseDart.FirebaseDart.setup(
//         storagePath: 'C:\\firebase',
//       );
//       await firebaseDart.Firebase.initializeApp(options: firebaseDart.FirebaseOptions.fromMap(options.asMap));
//       storage = FirebaseStorage(firebaseDart.FirebaseStorage.instance);
//       return FirebaseApp(instance, name ?? '');
//     } else {
//       instances[name] = Firebase._(options);
//       FirebaseFirestore.instances[name] = FirebaseFirestore(firedart.Firestore(
//         options.projectId,
//       ));
//       return FirebaseApp(instances[name], name);
//     }
//   }
// }
//
// class MyToken extends firedart.TokenStore {
//   final SharedPreferences _pref;
//
//   MyToken(this._pref);
//
//   @override
//   void delete() {}
//
//   @override
//   firedart.Token? read() {
//     if (_pref.containsKey('token')) {
//       return firedart.Token.fromMap(json.decode(_pref.getString('token')!));
//     }
//     return null;
//   }
//
//   @override
//   void write(firedart.Token? token) {
//     _pref.setString('token', json.encode(token!.toMap()));
//   }
// }
//
// class QuerySnapshot<T> {
//   final firedart.Page<firedart.Document>? query;
//   final List<firedart.Document>? list;
//
//   QuerySnapshot(this.query, this.list);
//
//   List<JsonDocumentSnapshot<T>> get docs {
//     return ((query?.toList()) ?? (list!)).map<JsonDocumentSnapshot<T>>((e) => JsonDocumentSnapshot<T>(e)).toList();
//   }
// }
//
// abstract class DocumentSnapshot<T extends Object?> {
//   String get id;
//
//   /// Returns the reference of this snapshot.
//   DocumentReference<T> get reference;
//
//   /// Metadata about this document concerning its source and if it has local
//   /// modifications.
//   // SnapshotMetadata get metadata;
//
//   /// Returns `true` if the document exists.
//   bool get exists;
//
//   /// Contains all the data of this document snapshot.
//   T? data();
// }
//
// class JsonDocumentSnapshot<T extends Object?> extends DocumentSnapshot<T> {
//   final firedart.Document _document;
//
//   JsonDocumentSnapshot(this._document);
//
//   T data() {
//     return _document.map as T;
//   }
//
//   String get id => _document.id;
//
//   bool get exists {
//     return _document.map.isNotEmpty;
//   }
//
//   DocumentReference<T> get reference {
//     return DocumentReference<T>(_document.reference);
//   }
// }
//
// class FieldValue {
//   static arrayRemove(List list) {
//     throw UnimplementedError();
//   }
//
//   static arrayUnion(List list) {
//     throw UnimplementedError();
//   }
//
//   static increment(int value) {
//     throw UnimplementedError();
//   }
// }
//
// class UserCredential {
//   final User? user;
//
//   UserCredential(this.user);
// }
//
// class User {
//   final user_gateway.User? user;
//
//   User(this.user);
//
//   String? get uid => user?.id;
// }
//
// class FirebaseAuth {
//   firedart.FirebaseAuth? firebaseAuth;
//   static FirebaseAuth? _firebaseAuth;
//   User? _currentUser;
//
//   static FirebaseAuth get instance {
//     if (_firebaseAuth == null) {
//       _firebaseAuth = FirebaseAuth();
//       _firebaseAuth!.firebaseAuth = firedart.FirebaseAuth.instance;
//     }
//     return _firebaseAuth!;
//   }
//
//   static void initAuth() {
//     _firebaseAuth = FirebaseAuth();
//   }
//
//   Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) async {
//     try {
//       _currentUser = User(await firebaseAuth?.signUp(email, password));
//     } on AuthException catch (e) {
//       throw FirebaseAuthException(code: e.errorCode, message: e.message);
//     }
//     return UserCredential(_currentUser!);
//   }
//
//   Future<void> sendPasswordResetEmail({required String email}) async {
//     await firebaseAuth?.resetPassword(email);
//   }
//
//   Future<void> signInAnonymously() async {
//     await firebaseAuth?.signInAnonymously();
//   }
//
//   User? get currentUser {
//     return _currentUser;
//   }
//
//   Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
//     try {
//       _currentUser = User(await firebaseAuth?.signIn(email, password));
//     } on AuthException catch (e) {
//       throw FirebaseAuthException(code: e.errorCode, message: e.message);
//     }
//     return UserCredential(_currentUser!);
//   }
//
//   signOut() async {
//     firebaseAuth?.signOut();
//     _currentUser = null;
//   }
// }
//
// class Query<T> {
//   final firedart.QueryReference reference;
//
//   Query(this.reference);
//
//   Future<QuerySnapshot<Map<String, dynamic>>> get() async {
//     return QuerySnapshot<Map<String, dynamic>>(null, await reference.get());
//   }
//
//   Query<Map<String, dynamic>> limit(int count) {
//     return Query<Map<String, dynamic>>(reference.limit(count));
//   }
//
//   Query<Map<String, dynamic>> where(String key, {dynamic isEqualTo}) {
//     return Query<Map<String, dynamic>>(reference.where(key, isEqualTo: isEqualTo));
//   }
// }
//
// class CollectionReference<T extends Object?> {
//   final firedart.CollectionReference collectionReference;
//
//   CollectionReference(this.collectionReference);
//
//   Future<QuerySnapshot<T>> get<T>() async {
//     return QuerySnapshot<T>(await collectionReference.get(), null);
//   }
//
//   Future<JsonDocumentSnapshot<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
//     return JsonDocumentSnapshot<Map<String, dynamic>>(await collectionReference.add(data));
//   }
//
//   Query<Map<String, dynamic>> where(
//     String key, {
//     dynamic isEqualTo,
//     dynamic isLessThan,
//     dynamic isLessThanOrEqualTo,
//     dynamic isGreaterThan,
//     dynamic isGreaterThanOrEqualTo,
//     dynamic arrayContains,
//     List<dynamic>? arrayContainsAny,
//     List<dynamic>? whereIn,
//     bool isNull = false,
//   }) {
//     return Query<Map<String, dynamic>>(collectionReference.where(
//       key,
//       isEqualTo: isEqualTo,
//       isLessThan: isLessThan,
//       isLessThanOrEqualTo: isLessThanOrEqualTo,
//       isGreaterThan: isGreaterThan,
//       isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
//       arrayContains: arrayContains,
//       arrayContainsAny: arrayContainsAny,
//       whereIn: whereIn,
//       isNull: isNull,
//     ));
//   }
//
//   DocumentReference<T?> doc<T>([String? id]) {
//     return DocumentReference<T?>(collectionReference.document(id ?? _getRandomString(28)));
//   }
//
//   static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
//   static Random _rnd = Random();
//
//   String _getRandomString(int length) =>
//       String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
//
//   Query<Map<String, dynamic>> startAfterDocument(JsonDocumentSnapshot last) {
//     return Query<Map<String, dynamic>>(QueryReference(collectionReference.gateway, ''));
//   }
//
//   Query<Map<String, dynamic>> limit(int count) {
//     return Query<Map<String, dynamic>>(collectionReference.limit(count));
//   }
// }
//
// class DocumentReference<T extends Object?> {
//   final firedart.DocumentReference documentReference;
//
//   DocumentReference(this.documentReference);
//
//   Future<DocumentSnapshot<T>> get<T>() async {
//     return JsonDocumentSnapshot<T>(await documentReference.get());
//   }
//
//   Future<void> set(Map<String, dynamic> data) async {
//     await documentReference.set(data);
//   }
//
//   CollectionReference<Map<String, dynamic>?> collection(String path) {
//     return CollectionReference<Map<String, dynamic>?>(documentReference.collection(path));
//   }
//
//   String get id => documentReference.id;
//
//   Future<void> delete() async {
//     await documentReference.delete();
//   }
//
//   Future<void> update(Map<String, dynamic> data) async {
//     await documentReference.update(data);
//   }
//
//   Stream<JsonDocumentSnapshot<T>> snapshots() {
//     return documentReference.stream.map((event) => JsonDocumentSnapshot<T>(event!));
//   }
// }
//
// class FirebaseFirestore {
//   final firedart.Firestore firestore;
//   static final Map<String, FirebaseFirestore> instances = {};
//
//   FirebaseFirestore(this.firestore);
//
//   static FirebaseFirestore instanceFor({required FirebaseApp app}) {
//     return instances[app.name]!;
//   }
//
//   static FirebaseFirestore get instance {
//     return Firebase.firestore!;
//   }
//
//   DocumentReference<T> doc<T>(String path) {
//     return DocumentReference<T>(firestore.document(path));
//   }
//
//   CollectionReference collection<T>(String path) {
//     return CollectionReference<T>(firestore.collection(path));
//   }
// }
//
// @immutable
// class FirebaseException implements Exception {
//   /// A generic class which provides exceptions in a Firebase-friendly format
//   /// to users.
//   ///
//   /// ```dart
//   /// try {
//   ///   await Firebase.initializeApp();
//   /// } catch (e) {
//   ///   print(e.toString());
//   /// }
//   /// ```
//   FirebaseException({
//     required this.plugin,
//     this.message,
//     String? code,
//     this.stackTrace,
//     // ignore: unnecessary_this
//   }) : this.code = code ?? 'unknown';
//
//   /// The plugin the exception is for.
//   ///
//   /// The value will be used to prefix the message to give more context about
//   /// the exception.
//   final String plugin;
//
//   /// The long form message of the exception.
//   final String? message;
//
//   /// The optional code to accommodate the message.
//   ///
//   /// Allows users to identify the exception from a short code-name, for example
//   /// "no-app" is used when a user attempts to read a [FirebaseApp] which does
//   /// not exist.
//   final String code;
//
//   /// The stack trace which provides information to the user about the call
//   /// sequence that triggered an exception
//   final StackTrace? stackTrace;
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     if (other is! FirebaseException) return false;
//     return other.hashCode == hashCode;
//   }
//
//   @override
//   int get hashCode => Object.hash(plugin, code, message);
//
//   @override
//   String toString() {
//     String output = '[$plugin/$code] $message';
//
//     if (stackTrace != null) {
//       output += '\n\n$stackTrace';
//     }
//
//     return output;
//   }
// }
//
// class FirebaseAuthException extends FirebaseException implements Exception {
//   // ignore: public_member_api_docs
//   @protected
//   FirebaseAuthException({
//     String? message,
//     required String code,
//     this.email,
//     this.credential,
//     this.phoneNumber,
//     this.tenantId,
//   }) : super(plugin: 'firebase_auth', message: message, code: code);
//
//   /// The email of the user's account used for sign-in/linking.
//   final String? email;
//
//   /// The [AuthCredential] that can be used to resolve the error.
//   final AuthCredential? credential;
//
//   /// The phone number of the user's account used for sign-in/linking.
//   final String? phoneNumber;
//
//   /// The tenant ID being used for sign-in/linking.
//   final String? tenantId;
// }
//
// class AuthCredential {
//   // ignore: public_member_api_docs
//   @protected
//   const AuthCredential({
//     required this.providerId,
//     required this.signInMethod,
//     this.token,
//     this.accessToken,
//   });
//
//   /// The authentication provider ID for the credential. For example,
//   /// 'facebook.com', or 'google.com'.
//   final String providerId;
//
//   /// The authentication sign in method for the credential. For example,
//   /// 'password', or 'emailLink'. This corresponds to the sign-in method
//   /// identifier returned in [fetchSignInMethodsForEmail].
//   final String signInMethod;
//
//   /// A token used to identify the AuthCredential on native platforms.
//   final int? token;
//
//   /// The OAuth access token associated with the credential if it belongs to an
//   /// OAuth provider, such as `facebook.com`, `twitter.com`, etc.
//   /// Using the OAuth access token, you can call the provider's API.
//   final String? accessToken;
//
//   /// Returns the current instance as a serialized [Map].
//   Map<String, dynamic> asMap() {
//     return <String, dynamic>{
//       'providerId': providerId,
//       'signInMethod': signInMethod,
//       'token': token,
//       'accessToken': accessToken,
//     };
//   }
//
//   @override
//   String toString() =>
//       'AuthCredential(providerId: $providerId, signInMethod: $signInMethod, token: $token, accessToken: $accessToken)';
// }
