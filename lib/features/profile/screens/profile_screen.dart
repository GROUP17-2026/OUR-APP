import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mesh_gradient_background.dart';
import '../../../services/storage_service.dart';
import '../../../services/theme_service.dart';

ImageProvider _avatarProvider(String? url) {
  if (url == null) throw StateError('null url');
  final firestoreData = StorageService.getDataUrl(url);
  if (firestoreData != null) {
    final parts = url.split(',');
    if (parts.length == 2) {
      return MemoryImage(base64Decode(parts[1]));
    }
  }
  return CachedNetworkImageProvider(url);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileStreamProvider);

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Profile'),
        ),
        body: profile.when(
          data: (p) {
            if (p == null) {
              return const Center(child: Text('Profile not found'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (result == null || result.files.single.path == null) return;
                      
                      final file = File(result.files.single.path!);
                      try {
                        final url = await ref.read(storageServiceProvider).uploadFile(file, folder: 'avatars');
                        await ref.read(firestoreServiceProvider).upsertProfile(p.copyWith(photoUrl: url));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload picture: $e')));
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                        child: CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.cardSurface,
                        backgroundImage: p.photoUrl != null ? _avatarProvider(p.photoUrl) : null,
                        child: p.photoUrl == null
                            ? Text(
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 40),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  p.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  p.studentId.isEmpty ? 'Student ID pending' : p.studentId,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  p.faculty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.accent),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        child: Column(
                          children: [
                            Text('${p.discussionsJoined}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const Text('Discussions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassCard(
                        child: Column(
                          children: [
                            Text('${p.resourcesShared}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const Text('Resources', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassCard(
                        child: Column(
                          children: [
                            Text('${p.eventsAttended}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const Text('Events', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: p.notifyAnnouncements,
                        onChanged: (v) async {
                          await ref.read(firestoreServiceProvider).upsertProfile(
                                p.copyWith(notifyAnnouncements: v),
                              );
                        },
                        title: const Text('Announcement notifications'),
                        subtitle: const Text('Local + push when available'),
                      ),
                      const Divider(color: Colors.white12),
                      SwitchListTile(
                        value: ThemeService.instance.isDark,
                        onChanged: (_) => ThemeService.instance.toggle(),
                        title: const Text('Dark mode'),
                        subtitle: const Text('Tap to toggle dark / light'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text('Logout'),
                ),
              ],
            );
          },
          error: (e, _) => Center(child: Text('Error: $e')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
