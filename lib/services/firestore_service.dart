import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/announcements/models/announcement.dart';
import '../features/auth/models/user_profile.dart';
import '../features/discussions/models/chat_message.dart';
import '../features/discussions/models/discussion_group.dart';
import '../features/events/models/campus_event.dart';
import '../features/resources/models/campus_resource.dart';
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

  Stream<List<DiscussionGroup>> watchGroups() {
    return _db.collection('groups').orderBy('createdAt', descending: true).snapshots().map(
          (s) => s.docs
              .map((d) => DiscussionGroup.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<String> createGroup({
    required String name,
    required String description,
    String targetFaculty = 'all',
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    final ref = await _db.collection('groups').add({
      'name': name,
      'description': description,
      'members': [uid],
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'targetFaculty': targetFaculty,
    });
    return ref.id;
  }

  Stream<List<ChatMessage>> watchMessages(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> sendMessage({
    required String groupId,
    required String text,
    String? senderPhotoUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    final name = _auth.currentUser?.displayName ?? 'Student';
    final batch = _db.batch();
    final msgRef = _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'text': text,
      'senderId': uid,
      'senderName': name,
      'timestamp': FieldValue.serverTimestamp(),
      'senderPhotoUrl': senderPhotoUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
    });
    final displayText = fileName != null ? '📎 $fileName' : text;
    batch.set(
      _db.collection('groups').doc(groupId),
      {
        'lastMessage': displayText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'members': FieldValue.arrayUnion([uid]),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Stream<List<CampusResource>> watchResources({String? queryText}) {
    return _db
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => CampusResource.fromMap(d.id, d.data())).toList();
      if (queryText == null || queryText.isEmpty) return list;
      final q = queryText.toLowerCase();
      return list
          .where(
            (r) =>
                r.title.toLowerCase().contains(q) ||
                r.subject.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  Future<void> addResource(CampusResource resource) async {
    await _db.collection('resources').doc(resource.id).set(resource.toMap());
  }

  Stream<List<CampusEvent>> watchEvents() {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => CampusEvent.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addEvent(CampusEvent e) async {
    await _db.collection('events').doc(e.id).set(e.toMap());
  }

  Future<void> toggleRsvp(String eventId) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    final ref = _db.collection('events').doc(eventId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      final list = (snap.data()?['rsvps'] as List?)?.cast<String>() ?? [];
      if (list.contains(uid)) {
        txn.update(ref, {'rsvps': FieldValue.arrayRemove([uid])});
      } else {
        txn.update(ref, {'rsvps': FieldValue.arrayUnion([uid])});
      }
    });
  }
}
