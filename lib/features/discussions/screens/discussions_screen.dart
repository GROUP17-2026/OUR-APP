import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';

class DiscussionsScreen extends ConsumerWidget {
  const DiscussionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Discussions'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                'Online: —',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createGroup(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New group'),
      ),
      body: groups.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No groups yet. Create one to start chatting.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            itemCount: list.length,
            separatorBuilder: (context, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final g = list[i];
              return GlassCard(
                onTap: () => context.push('/discussions/${g.id}/chat'),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.35),
                      child: Text(
                        g.name.isNotEmpty
                            ? g.name.substring(0, 1).toUpperCase()
                            : '?',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            g.lastMessage.isEmpty
                                ? 'No messages yet'
                                : g.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          g.lastMessageAt == null
                              ? ''
                              : timeago.format(g.lastMessageAt!),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${g.memberCount} members',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
    );
  }

  Future<void> _createGroup(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final desc = TextEditingController();
    String target = 'all';

    final profile = ref.read(userProfileStreamProvider).valueOrNull;
    final myFaculty = profile?.faculty ?? '';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              title: const Text('Create group'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: desc,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: target,
                    decoration: const InputDecoration(labelText: 'Audience'),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Everyone (Global)')),
                      if (myFaculty.isNotEmpty)
                        DropdownMenuItem(value: myFaculty, child: Text('Only $myFaculty')),
                    ],
                    onChanged: (v) => setState(() => target = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    final id = await ref.read(firestoreServiceProvider).createGroup(
                          name: name.text.trim().isEmpty ? 'Study group' : name.text.trim(),
                          description: desc.text.trim(),
                          targetFaculty: target,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      context.push('/discussions/$id/chat');
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
