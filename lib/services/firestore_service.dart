import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/announcements/models/announcement.dart';
import '../features/auth/models/user_profile.dart';
import '../features/schedule/models/class_session.dart';

/// Firestore access for Authentication, Home, Profile & Schedule.
class FirestoreService {
  FirestoreService(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

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

  Stream<List<ClassSession>> watchScheduleForDay(String uid, String dayKey) {
    return _db
        .collection('schedules')
        .doc(uid)
        .collection('classes')
        .where('day', isEqualTo: dayKey)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ClassSession.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime)),
        );
  }

  Future<void> saveClassSession(ClassSession session) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    final ref = _db
        .collection('schedules')
        .doc(uid)
        .collection('classes')
        .doc(session.id);
    await ref.set(session.toMap());
  }

  Stream<List<Announcement>> watchAnnouncements() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Announcement.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addAnnouncement(Announcement a) async {
    await _db.collection('announcements').doc(a.id).set(a.toMap());
  }
}
