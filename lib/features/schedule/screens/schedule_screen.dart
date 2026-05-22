import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/day_key.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/schedule/models/class_session.dart';
import '../../../features/schedule/providers/schedule_provider.dart';

const _weekKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(scheduleDayProvider);
    final classes = ref.watch(scheduleClassesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context, ref, selected),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Study session'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _weekKeys.length,
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final key = _weekKeys[i];
                final isToday = key == dayKeyFromDate(DateTime.now());
                final selectedDay = key == selected;
                return ChoiceChip(
                  label: Text(shortDayLabel(key)),
                  selected: selectedDay,
                  onSelected: (_) {
                    ref.read(scheduleDayProvider.notifier).state = key;
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.45),
                  labelStyle: TextStyle(
                    color: isToday ? AppColors.accent : AppColors.textPrimary,
                    fontWeight: selectedDay ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: classes.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 140,
                              child: Lottie.asset(
                                'assets/animations/empty_calendar.json',
                                repeat: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No classes today, enjoy your day!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = list[i];
                    final color = Color(c.colorValue);
                    return GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 72,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.subject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${c.startTime} – ${c.endTime}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${c.room} · ${c.lecturer}',
                                  style: const TextStyle(color: AppColors.accent),
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
        ],
      ),
    );
  }

  Future<void> _openAddDialog(
    BuildContext context,
    WidgetRef ref,
    String day,
  ) async {
    final subject = TextEditingController(text: 'Study block');
    final start = TextEditingController(text: '2:00 PM');
    final end = TextEditingController(text: '3:30 PM');
    final room = TextEditingController(text: 'Library');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
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
              Text(
                'Add personal session',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subject,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: start,
                decoration: const InputDecoration(labelText: 'Start time'),
              ),
              TextField(
                controller: end,
                decoration: const InputDecoration(labelText: 'End time'),
              ),
              TextField(
                controller: room,
                decoration: const InputDecoration(labelText: 'Place'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final session = ClassSession(
                    id: const Uuid().v4(),
                    subject: subject.text.trim(),
                    day: day,
                    startTime: start.text.trim(),
                    endTime: end.text.trim(),
                    room: room.text.trim(),
                    lecturer: 'You',
                    colorValue: 0xFF00E5FF,
                  );
                  await ref.read(firestoreServiceProvider).saveClassSession(session);
                  
                  try {
                    DateTime now = DateTime.now();
                    int currentWeekday = now.weekday;
                    int targetWeekday = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].indexOf(day) + 1;
                    int daysToAdd = targetWeekday - currentWeekday;
                    if (daysToAdd < 0) daysToAdd += 7;
                    DateTime targetDate = now.add(Duration(days: daysToAdd));
                    
                    DateTime startTimeParsed;
                    DateTime endTimeParsed;
                    try {
                      final format = DateFormat('h:mm a');
                      final st = format.parse(start.text.trim().toUpperCase());
                      final et = format.parse(end.text.trim().toUpperCase());
                      startTimeParsed = DateTime(targetDate.year, targetDate.month, targetDate.day, st.hour, st.minute);
                      endTimeParsed = DateTime(targetDate.year, targetDate.month, targetDate.day, et.hour, et.minute);
                    } catch (_) {
                      startTimeParsed = targetDate;
                      endTimeParsed = targetDate.add(const Duration(hours: 1));
                    }

                    final event = Event(
                      title: subject.text.trim(),
                      description: 'CampusConnect Study Session',
                      location: room.text.trim(),
                      startDate: startTimeParsed,
                      endDate: endTimeParsed,
                    );
                    Add2Calendar.addEvent2Cal(event);
                  } catch (_) {}

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
