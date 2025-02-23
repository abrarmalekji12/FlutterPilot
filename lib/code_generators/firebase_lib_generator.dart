class FirebaseLibGenerator {
  String generate() => '''
  //start_non_win
export 'package:cloud_firestore/cloud_firestore.dart';
export 'package:firebase_auth/firebase_auth.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_storage/firebase_storage.dart';

 //end_non_win

/// For Windows uncomment the following import:

 /*//start_win

export 'firebase_connection.dart';
// hide FirebaseStorage,FirebaseException;
// export 'package:firebase_storage/firebase_storage.dart';

 *///end_win

  ''';
}
