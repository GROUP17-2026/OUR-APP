import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/models/user_profile.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService(
    this._auth,
    this._googleSignIn,
    this._firestore,
  );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String name,
    required String studentId,
    required String faculty,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    final profile = UserProfile(
      uid: cred.user!.uid,
      name: name,
      email: email,
      studentId: studentId,
      faculty: faculty,
    );
    await _firestore.userDoc(profile.uid).set(
      {
        ...profile.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return cred;
  }

  Future<UserCredential> signInWithGoogle({
    String faculty = 'General',
    String studentId = '',
  }) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw StateError('Google sign-in cancelled');
    }
    final authTokens = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authTokens.accessToken,
      idToken: authTokens.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final u = cred.user;
    if (u != null) {
      final profile = UserProfile(
        uid: u.uid,
        name: u.displayName ?? 'Student',
        email: u.email ?? '',
        studentId: studentId,
        faculty: faculty,
        photoUrl: u.photoURL,
      );
      await _firestore.userDoc(profile.uid).set(
        {
          ...profile.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    return cred;
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
