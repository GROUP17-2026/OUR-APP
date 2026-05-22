class ClassSession {
  ClassSession({
    required this.id,
    required this.subject,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.lecturer,
    required this.colorValue,
  });

  final String id;
  final String subject;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final String lecturer;
  final int colorValue;

  factory ClassSession.fromMap(String id, Map<String, dynamic> m) {
    return ClassSession(
      id: id,
      subject: m['subject'] as String? ?? '',
      day: m['day'] as String? ?? 'mon',
      startTime: m['startTime'] as String? ?? '',
      endTime: m['endTime'] as String? ?? '',
      room: m['room'] as String? ?? '',
      lecturer: m['lecturer'] as String? ?? '',
      colorValue: (m['color'] as num?)?.toInt() ?? 0xFF6C63FF,
    );
  }

  Map<String, dynamic> toMap() => {
        'subject': subject,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'lecturer': lecturer,
        'color': colorValue,
      };
}
