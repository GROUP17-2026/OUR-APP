# CampusConnect — implementation log

This document records what was built from the specification in `CampusConnect_Antigravity_Prompt.md` (your uploaded plan), the architecture that was added, and what you need to do next to run the app against a real Firebase project.

---

## Summary

CampusConnect was turned from the default Flutter counter template into a **dark, glassmorphism-style** Android-oriented app with **Firebase** (Auth, Firestore, Storage, Messaging), **Riverpod** state, **GoRouter** navigation, and feature modules for **auth, home, schedule, announcements, discussions, resources, events, and profile**—aligned with the build plan in your markdown file.

---

## Dependencies and tooling

| Area | Packages / setup |
|------|------------------|
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging` |
| Auth (Google) | `google_sign_in` |
| State | `flutter_riverpod` |
| Routing | `go_router` |
| UI | `google_fonts`, `flutter_svg`, `lottie`, `cached_network_image` |
| Notifications | `flutter_local_notifications` |
| Files | `file_picker`, `path_provider` |
| Utilities | `intl`, `timeago`, `uuid`, `shared_preferences`, `permission_handler` |
| Events UI | `table_calendar` |
| Links | `url_launcher` |

**Process:** `flutter pub get` was run successfully. **`flutter analyze`** completes with **no issues** after lint cleanups.

**Note (Windows):** Flutter reported that **Developer Mode** may be needed for plugin symlink support when building. If builds fail, enable Developer Mode (Windows Settings → For developers).

---

## Android configuration

| Change | Purpose |
|--------|---------|
| Application ID **`com.campusconnect.app`** | Matches the spec’s Firebase Android package name. |
| **`minSdk 23`** | Safer baseline for Firebase / messaging. |
| **`google-services` Gradle plugin** | Required for Firebase on Android. Declared in **`android/settings.gradle.kts`** (version **4.4.4**, `apply false`) and applied in **`android/app/build.gradle.kts`**. |
| **Firebase Android BoM + Analytics** | In **`android/app/build.gradle.kts`**: `implementation(platform("com.google.firebase:firebase-bom:34.13.0"))` and `implementation("com.google.firebase:firebase-analytics")` — matches the Firebase console Android setup guidance (compatible native library versions). Flutter still uses Firebase via **`pubspec.yaml`** packages; this adds the native SDK layer the console documents. |
| **`android/app/google-services.json`** | Your **real** Firebase Android config file from the console (package **`com.campusconnect.app`**). Keep it in sync when you change Firebase apps or add SHA keys. |
| **`MainActivity`** moved to `com/campusconnect/app/` | Matches the new package / namespace. |
| **Core library desugaring** | **`compileOptions.isCoreLibraryDesugaringEnabled = true`** plus **`coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`** in **`android/app/build.gradle.kts`** — required by **`flutter_local_notifications`** (Gradle `:app:checkDebugAarMetadata` fails otherwise). |

---

## Firebase bootstrap

| File | Role |
|------|------|
| `lib/firebase_options.dart` | **`DefaultFirebaseOptions`** for `Firebase.initializeApp`. Values are aligned with your Firebase project (e.g. **`campusconnect-33b00`**) and the downloaded **`google-services.json`**. Re-run **`flutterfire configure`** if you add iOS/Web or regenerate apps. |
| `lib/services/firebase_service.dart` | `FirebaseBootstrap.ensureInitialized()` calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`. |
| `lib/main.dart` | Initializes bindings → Firebase → `NotificationService.instance.init()` → `ProviderScope` + `CampusConnectApp`. |

### Firebase Android Gradle (console setup)

Per [Firebase Android setup](https://firebase.google.com/docs/android/setup), the Android side includes:

1. **Project-level plugins** — In this Flutter repo, the `plugins { }` block lives in **`android/settings.gradle.kts`** (not a separate root `build.gradle.kts` plugins block). It includes:
   - `id("com.google.gms.google-services") version "4.4.4" apply false`
2. **App module** — **`android/app/build.gradle.kts`**:
   - `id("com.google.gms.google-services")` in the `plugins { }` block.
   - `dependencies { implementation(platform("com.google.firebase:firebase-bom:34.13.0")); implementation("com.google.firebase:firebase-analytics") }`

After changing Gradle files, sync in Android Studio or run **`flutter pub get`** / **`flutter build apk`** so Gradle resolves dependencies.

---

## Architecture (folder layout)

Implemented to mirror your spec:

- `lib/app/` — `app.dart`, `routes.dart`, `providers.dart`, `app_shell.dart`, `go_router_refresh.dart`
- `lib/core/theme/` — `app_colors.dart`, `app_theme.dart`
- `lib/core/utils/` — `date_formatter.dart`, `day_key.dart`
- `lib/core/widgets/` — `glass_card.dart`, `gradient_button.dart`, `animated_bottom_nav.dart`, `mesh_gradient_background.dart`
- `lib/services/` — `auth_service.dart`, `firestore_service.dart`, `storage_service.dart`, `notification_service.dart`, `firebase_service.dart`
- `lib/features/**` — screens + models + `schedule_provider`, `discussions_provider`

**Design rule followed:** Firestore and Storage I/O live in **service** classes; screens/widgets mostly **watch** `StreamProvider`s / call services through Riverpod.

---

## Firestore data model (as coded)

Collections and fields match your document’s intent:

- `users/{uid}` — profile, optional `fcmToken`, stats placeholders, `notifyAnnouncements`
- `schedules/{uid}/classes/{classId}` — timetable / personal sessions
- `announcements/{id}` — feed (ordered by `createdAt`)
- `groups/{groupId}` — metadata, `members`, `lastMessage`, `lastMessageAt`
- `groups/{groupId}/messages/{messageId}` — chat messages, `timestamp`
- `resources/{id}` — metadata + download `url`
- `events/{id}` — `date`, `rsvps` (array of UIDs), RSVP via **transaction**

**Announcements filtering:** categories are filtered **client-side** from the main stream so you do not need a composite index for `category + createdAt` during early prototyping.

---

## Screens implemented

1. **Splash** — gradient background, pulse logo, tagline, ~2.5s then **Login** or **Home** based on `FirebaseAuth.instance.currentUser`.
2. **Login** — glass card, email/password, gradient CTA, Google button, link to register; syncs FCM token to Firestore after sign-in.
3. **Register** — name, student ID, email, passwords, faculty dropdown; creates Auth user + Firestore `users/{uid}`; FCM token sync.
4. **Home** — greeting, stat glass cards, today’s classes, announcement previews, upcoming events; profile button → `/profile`; events CTA → `/events`.
5. **Schedule** — Mon–Sun chips (backed by `scheduleDayProvider`), list for selected day, Lottie empty state, FAB to add a **personal study session** (writes to Firestore).
6. **Announcements** — filter chips, real-time list, expandable body, cyan unread dot styling on cards.
7. **Discussions** — group list, FAB create group → navigates to chat.
8. **Chat** — real-time messages, gradient bubbles for “me”, glass for others, send bar.
9. **Resources** — search + type chips, grid cards, upload via **file_picker** + **Storage** + Firestore doc, open URL with **url_launcher**.
10. **Events** — `TableCalendar` + day-filtered list, RSVP / undo via Firestore transaction.
11. **Profile** — avatar ring, stats, notification toggle (writes profile), dark-mode switch (informational / disabled), logout.

**Shell navigation:** five tabs — Home, Schedule, Announcements (labeled “News” in the bar), Discussions (“Chat”), Resources. **Profile** and **Events** are full-screen routes outside the shell (with back).

---

## Notifications

- **FCM:** token saved to `users/{uid}.fcmToken` after login/register (and Google sign-in).
- **Foreground:** `FirebaseMessaging.onMessage` shows a **local notification** via `flutter_local_notifications`.
- **Admin push for new announcements:** not implemented server-side (would need Cloud Functions or a trusted backend). The spec’s note on this is acknowledged in code comments / this doc.

---

## Assets

- `assets/animations/empty_calendar.json` — lightweight Lottie-style JSON for the schedule empty state (referenced in `pubspec.yaml`).

---

## Tests

- `test/widget_test.dart` was replaced with a minimal **sanity** unit test so `flutter test` does not require Firebase initialization (the old template referenced `MyApp`, which no longer exists).

---

## What you should do next (checklist)

1. In [Firebase Console](https://console.firebase.google.com), use project **CampusConnect** (e.g. **`campusconnect-33b00`**) with an **Android** app whose package is **`com.campusconnect.app`**.
2. Keep **`android/app/google-services.json`** current (download again after SHA / OAuth changes).
3. Enable **Authentication** (Email/Password + Google), **Firestore**, **Storage**, **Cloud Messaging**, and **Analytics** as needed.
4. Keep **`lib/firebase_options.dart`** in sync with the same Firebase project (manually or via **`flutterfire configure`**).
5. Add **Firestore indexes** when the console prompts (especially for `groups/.../messages` orderBy `timestamp`; announcements use `createdAt` only in the default query).
6. Deploy **security rules** from your spec (users own schedule, announcements read-all / write-admin-only, etc.) — rules are **not** auto-deployed from this repo unless you add them to your pipeline.
7. For **Google Sign-In** on Android, register your **SHA-1/256** in Firebase as usual.

---

## Verification performed

| Step | Result |
|------|--------|
| `flutter pub get` | Success (dependencies resolved). |
| `flutter analyze` | **No issues found** (after fixes in this iteration). |

---

## Files touched at a high level (non-exhaustive)

- **Replaced / added** almost all of `lib/` (previous template `main.dart` counter demo removed).
- **Updated** `pubspec.yaml`, `android/settings.gradle.kts` (Google Services plugin **4.4.4**), `android/app/build.gradle.kts` (**Firebase BoM 34.13.0** + **firebase-analytics**), `AndroidManifest.xml`, Kotlin `MainActivity` path, `google-services.json`, and **`lib/firebase_options.dart`** (real project values).
- **Added** `assets/animations/`, `CHANGELOG_README.md` (this file), simplified `test/widget_test.dart`.
- **Added** `assets/icon.png`, `flutter_launcher_icons` config in `pubspec.yaml`, adaptive icon resources (`colors.xml`, `mipmap-anydpi-v26/ic_launcher.xml`).
- **Updated** `lib/services/storage_service.dart` — Firestore fallback for small files, `FirebaseFirestore` dependency.
- **Updated** `lib/services/auth_service.dart` — `sendPasswordResetEmail()` method.
- **Updated** `lib/features/auth/screens/login_screen.dart` — "Forgot password?" button.
- **Updated** `lib/features/profile/screens/profile_screen.dart` — base64 avatar support.
- **Updated** `lib/features/discussions/screens/chat_screen.dart` — base64 avatar support.
- **Updated** `lib/app/providers.dart` — `StorageService` now receives `FirebaseFirestore`.
- **Added** `lib/services/theme_service.dart` — theme persistence with SharedPreferences.
- **Added** `lib/features/discussions/models/chat_message.dart` — `fileUrl`, `fileName`, `fileSize` fields.
- **Updated** `lib/features/discussions/screens/chat_screen.dart` — file attach button, file display chips, file opening.
- **Updated** `lib/features/resources/screens/resources_screen.dart` — open files from all URL types (HTTP, data:, firestore://).
- **Updated** `lib/features/profile/screens/profile_screen.dart` — dark mode toggle enabled, base64 avatar support.
- **Updated** `lib/services/firestore_service.dart` — `sendMessage` supports file metadata.
- **Updated** `lib/services/notification_service.dart` — background handler, token refresh, cold-start tap handling.
- **Updated** `lib/core/theme/app_theme.dart` — added `AppTheme.light()`.
- **Updated** `lib/app/app.dart` — theme-aware via `ThemeService`.
- **Updated** `lib/main.dart` — initializes `ThemeService`.

---

## Recent Feature Additions (May 15, 2026)

- **Native Calendar Sync:** Installed `add_2_calendar`. Classes/Study Sessions added in the app now push directly to the device's native calendar (pre-filling date, time, and location) for built-in reminders.
- **Targeted Announcements & Events:** Upgraded models to include `targetFaculty`. Added a Floating Action Button to let students create Announcements and Events, with a dropdown to push it "Global" or strictly to their own faculty.
- **Google Auth Profiling:** Modified Google Sign-in to prompt users to complete their profile (Student ID and Faculty) before finalizing the login, ensuring feature-parity with email registration.
- **Profile Avatars & Group Chat Avatars:** Added `file_picker` integration in `ProfileScreen` to upload a profile picture to Firebase Storage. Updated `ChatMessage` and `ChatScreen` to display user avatars next to messages in discussion groups.
- **Targeted Discussion Groups:** Added target audience dropdown when creating a new discussion group, hiding course-specific chats from the general student body.

---

## App Icon Update (May 17, 2026)

- **Replaced default Flutter launcher icon** with a school/graduation cap icon matching the splash screen design.
- **`flutter_launcher_icons` v0.14.1** added as a dev dependency for automated icon generation.
- **Adaptive icon support** — dark background (`#0D0D1A`) with purple icon (`#6C63FF`) for Android 8.0+.
- **Source icon** at `assets/icon.png` (1024x1024 PNG).

---

## Firebase Storage Upload — 404 Error Resolution (May 17, 2026)

**Error:**
```
java.io.IOException: { "error": { "code": 404, "message": "Not Found." } }
```

**Root cause:** Firebase Storage **bucket not created** in the Firebase Console.

**Resolution:** The app now has a **Firestore fallback** — when Storage returns 404, small files (≤ 500 KB) are stored as base64 in a `file_store` Firestore collection. This means:
- **Avatars and small uploads work immediately** without any Storage setup.
- **Large files** show a clear error: *"File too large for offline mode. Enable Firebase Storage in the console."*
- **When you enable Storage later**, all uploads automatically use the proper bucket.

**To enable full Storage (optional, free tier includes 5 GB):**

1. Firebase Console → your project → **Storage** → **Get Started** → create a bucket.
2. Set rules to allow authenticated uploads.
3. Rebuild the app — uploads will use Storage automatically.

---

## File Sharing, Theme Toggle & Notifications (May 17, 2026)

- **Dark / Light mode toggle** — Added `ThemeService` (`lib/services/theme_service.dart`) with `SharedPreferences` persistence. Profile screen switch now toggles between dark and light themes. `AppTheme.light()` added with matching design tokens.
- **Open uploaded files** — Resources screen now handles all URL types: HTTP URLs open in browser, `data:` URLs (base64) decode to temp files and open with `open_file`, `firestore://` URLs fetch from Firestore and decode.
- **File sharing in chat** — `ChatMessage` model extended with `fileUrl`, `fileName`, `fileSize`. Chat screen has an attach button that uploads files via `StorageService` and sends them as message attachments. Files appear as tappable chips in message bubbles. `FirestoreService.sendMessage` supports file metadata.
- **Notifications improved** — Background message handler registered with `@pragma('vm:entry-point')`. `getInitialMessage()` handles cold-start taps. `onTokenRefresh` listener keeps FCM token in sync. Foreground notifications now have sound and vibration enabled. `campus_general` channel description updated.
- **New dependency:** `open_file ^3.5.10` for opening downloaded files with the system viewer.

---

## Forgot Password & Storage Fallback (May 17, 2026)

- **Forgot Password flow** — Added "Forgot password?" button on the login screen. Users enter their email and receive a Firebase Auth password reset email. Method: `AuthService.sendPasswordResetEmail()`.
- **Firestore Storage fallback** — When Firebase Storage bucket is not created, the app automatically stores small files (≤ 500 KB) as base64 data URLs in a `file_store` Firestore collection. Avatars, profile pictures, and small resource uploads work without a Storage bucket. Larger files show a clear error prompting the user to enable Storage.
- **Image display** — Profile and chat avatars now detect `firestore://` URLs and decode base64 inline via `MemoryImage`. Standard HTTP URLs continue to use `CachedNetworkImage`.
- **`StorageService`** now requires `FirebaseFirestore` as a third constructor parameter (updated in `providers.dart`).

---

*Last updated: File Sharing, Theme Toggle, Notifications — May 17, 2026.*
