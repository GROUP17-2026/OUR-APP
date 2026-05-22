import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/mesh_gradient_background.dart';
import '../../../services/notification_service.dart';
import 'register_screen.dart' show kFaculties;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithEmail(
        email: _email.text.trim(),
        password: _password.text,
      );
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid != null) {
        await NotificationService.instance.syncTokenToProfile(
          firestore: ref.read(firestoreServiceProvider),
          uid: uid,
        );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your email first, then tap Forgot password.')),
        );
      }
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset link sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset: $e')),
        );
      }
    }
  }

  Future<void> _google() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final stCtrl = TextEditingController();
        String facVal = kFaculties.first;
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: const Text('Complete your profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stCtrl,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: facVal,
                decoration: const InputDecoration(labelText: 'Faculty / Department'),
                items: kFaculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => facVal = v!,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {'studentId': stCtrl.text.trim(), 'faculty': facVal}),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle(
        faculty: result['faculty']!,
        studentId: result['studentId']!,
      );
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid != null) {
        await NotificationService.instance.syncTokenToProfile(
          firestore: ref.read(firestoreServiceProvider),
          uid: uid,
        );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
          ...List.generate(6, (i) {
            return Positioned(
              left: (i * 57.0) % 320,
              top: (i * 93.0) % 520,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.12 + (i % 3) * 0.04,
                      child: Container(
                        width: 120 + i * 10,
                        height: 120 + i * 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              i.isEven ? AppColors.primary : AppColors.accent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(slide),
                  child: FadeTransition(
                    opacity: slide,
                    child: GlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.school_rounded,
                              color: AppColors.accent, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 18),
                          GradientButton(
                            label: 'Login',
                            isLoading: _loading,
                            onPressed: _loading ? null : _submit,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _loading ? null : _google,
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Continue with Google'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text('New here? Register'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
