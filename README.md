# CampusConnect

A Flutter Android app for university students: dark/light UI, Firebase (Auth, Firestore, Storage, FCM), Riverpod, and GoRouter.

## Documentation

**Full build notes, architecture, Firestore shape, screen list, and change history:** see **[CHANGELOG_README.md](CHANGELOG_README.md)**.

## Quick start

```bash
flutter pub get
flutter analyze
flutter run
```

Use a physical device or emulator with **Google Play services** for Firebase features.

## Firebase (Android)

- **`android/app/google-services.json`** — from Firebase Console (package `com.campusconnect.app`).
- **`lib/firebase_options.dart`** — `DefaultFirebaseOptions` for the same Firebase project.
- **Gradle (matches Firebase console guidance):**
  - **`android/settings.gradle.kts`** — `id("com.google.gms.google-services") version "4.4.4" apply false`
  - **`android/app/build.gradle.kts`** — `id("com.google.gms.google-services")` plus:
    - `implementation(platform("com.google.firebase:firebase-bom:34.13.0"))`
    - `implementation("com.google.firebase:firebase-analytics")`

Dart Firebase plugins remain declared in **`pubspec.yaml`**; the BoM lines keep native Android Firebase libraries on compatible versions.

**Core library desugaring:** `flutter_local_notifications` requires desugaring on the app module. This repo sets `isCoreLibraryDesugaringEnabled = true` and adds `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` in **`android/app/build.gradle.kts`** so `:app:checkDebugAarMetadata` succeeds.

After Gradle edits, sync in Android Studio or run `flutter build apk` / `flutter run`.

## Firebase Storage — Free Tier

Firebase Storage **is included** in the free Spark plan (5 GB storage, 1 GB/day downloads, 20k uploads/day). If you see a `404 Not Found` error on upload, the bucket simply hasn't been created in the Firebase Console yet — go to **Storage → Get Started** to enable it.

**Firestore fallback (no bucket needed):** If you don't create a Storage bucket, the app automatically falls back to storing small files (≤ 500 KB — avatars, thumbnails) as base64 in a `file_store` Firestore collection. Larger files will show a clear error. When you later enable Storage, uploads seamlessly switch back to the proper bucket.

## App icon

The launcher icon is a school/graduation cap matching the splash screen. Generated via **`flutter_launcher_icons`** with adaptive icon support:
- **`assets/icon.png`** — source icon (purple `#6C63FF` on dark `#0D0D1A`).
- **`android/app/src/main/res/mipmap-*/ic_launcher.png`** — generated at all densities.
- **`android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`** — adaptive icon config.
- **`android/app/src/main/res/values/colors.xml`** — adaptive icon background color.

To regenerate after replacing `assets/icon.png`:
```bash
dart run flutter_launcher_icons
```

## Theme (Dark / Light)

Toggle between dark and light mode from **Profile → Dark mode** switch. The preference persists across app restarts via `SharedPreferences`. Default is dark mode.

## File Handling

- **Resources** — Tap any resource card to open it. Files stored in Firestore (base64) are decoded to a temp file and opened with the system file viewer. HTTP URLs open in the browser.
- **Chat file sharing** — Tap the **attach** icon in any group chat to send a file. Files are uploaded via Storage (or Firestore fallback ≤ 500 KB) and appear as a tappable chip in the message bubble. Tap to download and open.

## Notifications

- **Foreground** — FCM messages show a local notification with high priority, sound, and vibration.
- **Background** — Handled by `@pragma('vm:entry-point')` background handler.
- **Token sync** — FCM token is saved to `users/{uid}.fcmToken` on login and refreshed automatically.
- **Channels** — `campus_general` channel with `Importance.high` for announcements and alerts.

## Useful links

- [Flutter documentation](https://docs.flutter.dev/)
- [Firebase Android setup](https://firebase.google.com/docs/android/setup)
- [FlutterFire](https://firebase.flutter.dev/)
