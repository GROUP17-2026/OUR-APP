import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/announcements/models/announcement.dart';

final _announcementFilterProvider = StateProvider<String>((ref) => 'all');

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_announcementFilterProvider);
    final async = ref.watch(announcementsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final chip in const [
                  ('all', 'All'),
                  ('academic', 'Academic'),
                  ('events', 'Events'),
                  ('urgent', 'Urgent'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(chip.$2),
                      selected: filter == chip.$1,
                      onSelected: (_) => ref
                          .read(_announcementFilterProvider.notifier)
                          .state = chip.$1,
                      selectedColor: AppColors.primary.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              data: (list) {
                final filtered = filter == 'all'
                    ? list
                    : list.where((a) => a.category == filter).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No announcements here yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = filtered[i];
                    return _AnnouncementTile(announcement: a);
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

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final body = TextEditingController();
    String category = 'academic';
    String target = 'all';

    final profile = ref.read(userProfileStreamProvider).valueOrNull;
    final myFaculty = profile?.faculty ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Make an Announcement', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: body,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Body'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'academic', child: Text('Academic')),
                      DropdownMenuItem(value: 'events', child: Text('Events')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (v) => setState(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: target,
                    decoration: const InputDecoration(labelText: 'Audience'),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Everyone (Global)')),
                      if (myFaculty.isNotEmpty)
                        DropdownMenuItem(value: myFaculty, child: Text('Only $myFaculty')),
                    ],
                    onChanged: (v) => setState(() => target = v!),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      if (title.text.isEmpty || body.text.isEmpty) return;
                      final a = Announcement(
                        id: const Uuid().v4(),
                        title: title.text.trim(),
                        body: body.text.trim(),
                        category: category,
                        authorId: profile?.uid ?? '',
                        createdAt: DateTime.now(),
                        isUrgent: category == 'urgent',
                        targetFaculty: target,
                      );
                      await ref.read(firestoreServiceProvider).addAnnouncement(a);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Post'),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}

class _AnnouncementTile extends StatefulWidget {
  const _AnnouncementTile({required this.announcement});

  final Announcement announcement;

  @override
  State<_AnnouncementTile> createState() => _AnnouncementTileState();
}

class _AnnouncementTileState extends State<_AnnouncementTile> {
  bool _expanded = false;

  Color _badgeColor(String category) {
    switch (category) {
      case 'urgent':
        return AppColors.error;
      case 'events':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final badgeColor = _badgeColor(a.category);
    return GlassCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  a.category.toUpperCase(),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(a.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            a.body,
            maxLines: _expanded ? null : 3,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}
