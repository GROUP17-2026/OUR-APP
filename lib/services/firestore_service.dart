import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/auth/models/user_profile.dart';

/// Firestore access for User 1: Authentication, Home & Profile.
class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserProfile?> watchProfile(String uid) {
    return userDoc(uid).snapshots().map((s) {
      if (!s.exists || s.data() == null) return null;
      return UserProfile.fromMap(s.data()!, uid);
    });
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await userDoc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateFcmToken(String uid, String token) {
    return userDoc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }
}
