import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static String formatTime(DateTime dt) => DateFormat.jm().format(dt);

  static String formatDay(DateTime dt) => DateFormat.EEEE().format(dt);

  static String formatShortDate(DateTime dt) =>
      DateFormat.MMMd().format(dt);

  static String formatDateTime(DateTime dt) =>
      DateFormat.yMMMd().add_jm().format(dt);
}
