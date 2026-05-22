import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/mesh_gradient_background.dart';
import '../../../services/notification_service.dart';

const kFaculties = <String>[
  'Computer Science',
  'Information Technology',
  'Engineering',
  'Business',
  'Arts & Humanities',
  'Sciences',
  'Law',
  'Medicine',
  'Other',
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _faculty = kFaculties.first;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Enter your full name';
    if (_studentId.text.trim().isEmpty) return 'Enter your student ID';
    if (!_email.text.contains('@')) return 'Enter a valid email';
    if (_password.text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (_password.text != _confirm.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).registerWithEmail(
            name: _name.text.trim(),
            studentId: _studentId.text.trim(),
            faculty: _faculty,
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
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Create account'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join CampusConnect',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _studentId,
                    decoration: const InputDecoration(
                      labelText: 'Student ID',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    items: kFaculties
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _faculty = v ?? kFaculties.first),
                    decoration: const InputDecoration(
                      labelText: 'Faculty / Department',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    // ignore: deprecated_member_use
                    value: _faculty,
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Create account',
                    isLoading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
