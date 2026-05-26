import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mesh_gradient_background.dart';
import '../models/campus_event.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  List<CampusEvent> _forDay(List<CampusEvent> all, DateTime day) {
    return all.where((e) {
      return e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventsStreamProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Events'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAddDialog(context, ref, _selected ?? DateTime.now()),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add),
        ),
        body: async.when(
          data: (events) {
            return Column(
              children: [
                TableCalendar<CampusEvent>(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) =>
                      _selected != null && isSameDay(_selected, d),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selected = selected;
                      _focused = focused;
                    });
                  },
                  onPageChanged: (focused) => setState(() => _focused = focused),
                  eventLoader: (day) => _forDay(events, day),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
                    defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
                  ),
                  headerStyle: HeaderStyle(
                    titleTextStyle: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.textPrimary) ??
                        const TextStyle(),
                    formatButtonVisible: false,
                    leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: AppColors.textSecondary),
                    weekendStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const Divider(color: Colors.white12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = _selected ?? DateTime.now();
                      final list = _forDay(events, day);
                      if (list.isEmpty) {
                        return const Center(
                          child: Text('No events on this day.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = list[i];
                          final going = uid != null && e.rsvps.contains(uid);
                          return GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  e.description,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeago.format(e.date),
                                  style: const TextStyle(color: AppColors.accent),
                                ),
                                Text(
                                  e.location,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text('${e.goingCount} going'),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: uid == null
                                          ? null
                                          : () async {
                                              await ref
                                                  .read(firestoreServiceProvider)
                                                  .toggleRsvp(e.id);
                                            },
                                      child: Text(going ? 'Undo RSVP' : 'RSVP'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
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

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref, DateTime day) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final location = TextEditingController();
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
                  Text('Create Event', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: description,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(labelText: 'Location / Room'),
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
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      if (title.text.isEmpty) return;
                      final e = CampusEvent(
                        id: const Uuid().v4(),
                        title: title.text.trim(),
                        description: description.text.trim(),
                        date: day,
                        location: location.text.trim(),
                        rsvps: [],
                        createdBy: profile?.uid ?? '',
                        targetFaculty: target,
                      );
                      await ref.read(firestoreServiceProvider).addEvent(e);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Create'),
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
