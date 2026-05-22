import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../models/class_session.dart';
import '../../../core/utils/day_key.dart';

final scheduleDayProvider = StateProvider<String>(
  (ref) => dayKeyFromDate(DateTime.now()),
);

final scheduleClassesProvider = StreamProvider<List<ClassSession>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) {
    return Stream.value(const []);
  }
  final day = ref.watch(scheduleDayProvider);
  return ref.watch(firestoreServiceProvider).watchScheduleForDay(uid, day);
});

/// Always the device's current weekday (home dashboard).
final todaysScheduleProvider = StreamProvider<List<ClassSession>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) {
    return Stream.value(const []);
  }
  final today = dayKeyFromDate(DateTime.now());
  return ref.watch(firestoreServiceProvider).watchScheduleForDay(uid, today);
});
