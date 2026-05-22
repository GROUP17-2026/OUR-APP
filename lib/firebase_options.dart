import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Generated from `android/app/google-services.json` (project campusconnect-33b00).
/// Re-run `flutterfire configure` if you add iOS/Web or change Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('CampusConnect is configured for Android only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'CampusConnect is configured for Android only.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4jqT1B7ktrusP-3YGMGbU7cNo4GKfKaA',
    appId: '1:663684326366:android:840039e3a7cf4c2e5df34f',
    messagingSenderId: '663684326366',
    projectId: 'campusconnect-33b00',
    storageBucket: 'campusconnect-33b00.firebasestorage.app',
  );
}
