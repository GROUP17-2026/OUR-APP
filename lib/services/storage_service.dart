import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageException implements Exception {
  const StorageException(this.message, this.code);
  final String message;
  final String code;
  @override
  String toString() => 'StorageException($code): $message';
}

class StorageService {
  StorageService(this._storage, this._auth, this._firestore);

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const int _firestoreFallbackLimit = 500 * 1024; // 500KB

  Future<String> uploadBytes({
    required List<int> bytes,
    required String mimeHint,
    required String folder,
    String? filename,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final id = filename ?? const Uuid().v4();
    try {
      final ref = _storage.ref().child(folder).child(uid).child(id);
      final task = ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: mimeHint),
      );
      await task;
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'bucket-not-found') {
        return _storeInFirestore(
          bytes: bytes,
          mime: mimeHint,
          folder: folder,
          uid: uid,
          id: id,
        );
      }
      throw _mapFirebaseError(e);
    }
  }

  Future<String> uploadFile(File file, {required String folder}) async {
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final id = const Uuid().v4();
    final name = file.path.split(Platform.pathSeparator).last;
    try {
      final ref = _storage.ref().child(folder).child(uid).child('$id-$name');
      final task = ref.putFile(file);
      await task;
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'bucket-not-found') {
        final bytes = await file.readAsBytes();
        if (bytes.length > _firestoreFallbackLimit) {
          throw const StorageException(
            'File too large for offline mode. Enable Firebase Storage in the console.',
            'file-too-large',
          );
        }
        return _storeInFirestore(
          bytes: bytes,
          mime: _guessMime(name),
          folder: folder,
          uid: uid,
          id: id,
        );
      }
      throw _mapFirebaseError(e);
    }
  }

  Future<String> _storeInFirestore({
    required List<int> bytes,
    required String mime,
    required String folder,
    required String uid,
    required String id,
  }) async {
    final docId = '$folder/$uid/$id';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    await _firestore.collection('file_store').doc(docId).set({
      'data': dataUrl,
      'mime': mime,
      'size': bytes.length,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerUid': uid,
    });
    return 'firestore://file_store/$docId';
  }

  static String? getDataUrl(String url) {
    if (url.startsWith('firestore://')) {
      return url;
    }
    return null;
  }

  static String _guessMime(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }

  StorageException _mapFirebaseError(FirebaseException e) {
    final code = e.code;
    if (code == 'object-not-found' || code == 'bucket-not-found') {
      return const StorageException(
        'Firebase Storage bucket is not set up. Create a Storage bucket in the Firebase Console.',
        'bucket-not-found',
      );
    }
    if (code == 'unauthorized') {
      return const StorageException(
        'You are not authorized to upload. Please sign in again.',
        'unauthorized',
      );
    }
    if (code == 'canceled') {
      return const StorageException(
        'Upload was cancelled.',
        'canceled',
      );
    }
    if (code == 'unknown') {
      return StorageException(
        'Upload failed: ${e.message ?? 'Unknown error'}. Check your internet connection and Firebase Storage setup.',
        'unknown',
      );
    }
    return StorageException(
      'Upload failed: ${e.message ?? code}',
      code,
    );
  }
}
