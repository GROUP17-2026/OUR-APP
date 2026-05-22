import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn(scopes: const ['email', 'profile']),
);

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(
    FirebaseFirestore.instance,
    ref.watch(firebaseAuthProvider),
  ),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    ref.watch(firestoreServiceProvider),
  ),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

final userProfileStreamProvider = StreamProvider((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(firestoreServiceProvider).watchProfile(user.uid);
});

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(
    FirebaseStorage.instance,
    ref.watch(firebaseAuthProvider),
    FirebaseFirestore.instance,
  ),
);
