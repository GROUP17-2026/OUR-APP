import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/announcements/screens/announcements_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/discussions/screens/chat_screen.dart';
import '../features/discussions/screens/discussions_screen.dart';
import '../features/events/screens/events_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/resources/screens/resources_screen.dart';
import '../features/schedule/screens/schedule_screen.dart';
import 'app_shell.dart';
import 'go_router_refresh.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(
    ref.watch(authServiceProvider).authStateChanges(),
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final public = loc == '/splash' || loc == '/login' || loc == '/register';
      if (!loggedIn && !public) {
        return '/login';
      }
      if (loggedIn && (loc == '/login' || loc == '/register')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/schedule',
            name: 'schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: '/announcements',
            name: 'announcements',
            builder: (context, state) => const AnnouncementsScreen(),
          ),
          GoRoute(
            path: '/discussions',
            name: 'discussions',
            builder: (context, state) => const DiscussionsScreen(),
          ),
          GoRoute(
            path: '/resources',
            name: 'resources',
            builder: (context, state) => const ResourcesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/discussions/:gid/chat',
        name: 'chat',
        builder: (context, state) {
          final gid = state.pathParameters['gid']!;
          return ChatScreen(groupId: gid);
        },
      ),
    ],
  );
});
