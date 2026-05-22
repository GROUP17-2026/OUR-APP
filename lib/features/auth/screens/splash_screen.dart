import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  double _taglineOpacity = 0;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _taglineOpacity = 1);
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      if (!mounted) return;
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      if (loggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.accent,
              AppColors.background,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final scale = 1 + (_pulse.value * 0.06);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.55),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: Colors.white24, width: 1.2),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 72,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'CampusConnect',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: _taglineOpacity,
              duration: const Duration(milliseconds: 700),
              child: Text(
                'Your campus. Connected.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.9),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
