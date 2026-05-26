import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mesh_gradient_background.dart';
import '../../../services/storage_service.dart';
import '../providers/discussions_provider.dart';

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

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sendingFile = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final profile = ref.read(userProfileStreamProvider).valueOrNull;
    await ref.read(firestoreServiceProvider).sendMessage(
          groupId: widget.groupId,
          text: text,
          senderPhotoUrl: profile?.photoUrl,
        );
  }

  Future<void> _sendFile() async {
    final pick = await FilePicker.platform.pickFiles();
    if (pick == null || pick.files.isEmpty) return;
    final file = pick.files.first;
    final bytes = file.bytes;
    if (bytes == null && file.path == null) return;

    setState(() => _sendingFile = true);
    try {
      final storage = ref.read(storageServiceProvider);
      String url;
      if (bytes != null) {
        url = await storage.uploadBytes(
          bytes: bytes,
          mimeHint: 'application/octet-stream',
          folder: 'chat_files',
          filename: file.name,
        );
      } else {
        url = await storage.uploadFile(File(file.path!), folder: 'chat_files');
      }
      final profile = ref.read(userProfileStreamProvider).valueOrNull;
      await ref.read(firestoreServiceProvider).sendMessage(
            groupId: widget.groupId,
            text: '',
            senderPhotoUrl: profile?.photoUrl,
            fileUrl: url,
            fileName: file.name,
            fileSize: file.size,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingFile = false);
    }
  }

  Future<void> _openFile(String fileUrl, String fileName) async {
    try {
      if (fileUrl.startsWith('data:')) {
        final parts = fileUrl.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(bytes);
          await OpenFile.open(file.path);
          return;
        }
      }
      if (fileUrl.startsWith('firestore://')) {
        final docPath = fileUrl.replaceFirst('firestore://', '');
        final docSnap = await FirebaseFirestore.instance.doc(docPath).get();
        final dataUrl = docSnap.data()?['data'] as String?;
        if (dataUrl != null) {
          final parts = dataUrl.split(',');
          if (parts.length == 2) {
            final bytes = base64Decode(parts[1]);
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/$fileName');
            await file.writeAsBytes(bytes);
            await OpenFile.open(file.path);
          }
        }
        return;
      }
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final messages = ref.watch(messagesStreamProvider(widget.groupId));

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Group chat'),
        ),
        body: Column(
          children: [
            Expanded(
              child: messages.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(child: Text('Say hello 👋'));
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final m = list[i];
                      final mine = m.senderId == uid;
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!mine) ...[
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary,
                                backgroundImage: m.senderPhotoUrl != null ? _avatarProvider(m.senderPhotoUrl) : null,
                                child: m.senderPhotoUrl == null
                                    ? Text(
                                        m.senderName.isNotEmpty ? m.senderName[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: const BoxConstraints(maxWidth: 280),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(mine ? 16 : 4),
                                  bottomRight: Radius.circular(mine ? 4 : 16),
                                ),
                                gradient: mine ? AppColors.primaryGradient : null,
                                color: mine ? null : AppColors.cardSurface.withValues(alpha: 0.55),
                                border: Border.all(
                                  color: mine
                                      ? Colors.transparent
                                      : AppColors.glassBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!mine)
                                    Text(
                                      m.senderName,
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  if (m.text.isNotEmpty)
                                    Text(
                                      m.text,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  if (m.hasFile)
                                    GestureDetector(
                                      onTap: () => _openFile(m.fileUrl!, m.fileName!),
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: (mine ? Colors.white : AppColors.primary).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.attach_file_rounded,
                                              size: 16,
                                              color: mine ? AppColors.textPrimary : AppColors.accent,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                m.fileName!,
                                                style: TextStyle(
                                                  color: mine ? AppColors.textPrimary : AppColors.accent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatSize(m.fileSize),
                                              style: TextStyle(
                                                color: mine
                                                    ? AppColors.textPrimary.withValues(alpha: 0.7)
                                                    : AppColors.textSecondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.jm().format(m.timestamp),
                                    style: TextStyle(
                                      color: mine
                                          ? AppColors.textPrimary.withValues(alpha: 0.75)
                                          : AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
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
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              borderRadius: 22,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendingFile ? null : _sendFile,
                    icon: _sendingFile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file_rounded, color: AppColors.accent),
                  ),
                  IconButton(
                    onPressed: _controller.text.trim().isEmpty ? null : _send,
                    icon: Icon(Icons.send_rounded, color: _controller.text.trim().isEmpty ? Colors.grey : AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
