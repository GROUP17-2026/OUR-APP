import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/campus_resource.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  final _search = TextEditingController();
  String _typeFilter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final pick = await FilePicker.platform.pickFiles(withData: true);
    if (pick == null || pick.files.isEmpty) return;
    final file = pick.files.first;
    final bytes = file.bytes;
    if (bytes == null && file.path == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final storage = ref.read(storageServiceProvider);
      String url;
      if (bytes != null) {
        url = await storage.uploadBytes(
          bytes: bytes,
          mimeHint: file.extension == 'pdf'
              ? 'application/pdf'
              : 'application/octet-stream',
          folder: 'resources',
        );
      } else {
        url = await storage.uploadFile(File(file.path!), folder: 'resources');
      }
      final res = CampusResource(
        id: const Uuid().v4(),
        title: file.name,
        type: file.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'file',
        url: url,
        uploadedBy: uid,
        subject: 'General',
        createdAt: DateTime.now(),
        uploaderName: FirebaseAuth.instance.currentUser?.displayName ?? 'Student',
      );
      await ref.read(firestoreServiceProvider).addResource(res);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _openResource(CampusResource r) async {
    try {
      if (r.url.startsWith('data:')) {
        final parts = r.url.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/${r.title}');
          await file.writeAsBytes(bytes);
          await OpenFile.open(file.path);
          return;
        }
      }
      if (r.url.startsWith('firestore://')) {
        final docPath = r.url.replaceFirst('firestore://', '');
        final docSnap = await FirebaseFirestore.instance.doc(docPath).get();
        final dataUrl = docSnap.data()?['data'] as String?;
        if (dataUrl != null) {
          final parts = dataUrl.split(',');
          if (parts.length == 2) {
            final bytes = base64Decode(parts[1]);
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/${r.title}');
            await file.writeAsBytes(bytes);
            await OpenFile.open(file.path);
          }
        }
        return;
      }
      final uri = Uri.parse(r.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(resourcesStreamProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Resources')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Upload'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by title or subject',
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final t in const ['all', 'pdf', 'image', 'file'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: _typeFilter == t,
                      onSelected: (_) => setState(() => _typeFilter = t),
                      selectedColor: AppColors.primary.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              data: (list) {
                final q = _search.text.toLowerCase();
                var filtered = list;
                if (q.isNotEmpty) {
                  filtered = list
                      .where(
                        (r) =>
                            r.title.toLowerCase().contains(q) ||
                            r.subject.toLowerCase().contains(q),
                      )
                      .toList();
                }
                if (_typeFilter != 'all') {
                  filtered = filtered
                      .where((r) => r.type == _typeFilter)
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const Center(child: Text('No resources match your filters.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    final icon = r.type == 'pdf'
                        ? Icons.picture_as_pdf
                        : r.type == 'image'
                            ? Icons.image_outlined
                            : Icons.insert_drive_file_outlined;
                    return GlassCard(
                      onTap: () => _openResource(r),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: AppColors.accent, size: 30),
                          const Spacer(),
                          Text(
                            r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            r.subject,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r.uploaderName.isEmpty ? 'Student' : r.uploaderName,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              error: (e, _) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
