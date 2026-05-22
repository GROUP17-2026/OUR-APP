import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../services/theme_service.dart';
import 'routes.dart';

class CampusConnectApp extends ConsumerWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'CampusConnect',
          debugShowCheckedModeBanner: false,
          theme: ThemeService.instance.isDark ? AppTheme.dark() : AppTheme.light(),
          routerConfig: router,
        );
      },
    );
  }
}
