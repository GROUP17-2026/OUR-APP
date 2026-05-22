import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();
  await NotificationService.instance.init();
  await ThemeService.instance.init();
  runApp(
    const ProviderScope(
      child: CampusConnectApp(),
    ),
  );
}
