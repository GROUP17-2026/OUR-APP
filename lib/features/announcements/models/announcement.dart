import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.authorId,
    required this.createdAt,
    this.isUrgent = false,
    this.targetFaculty = 'all',
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final String authorId;
  final DateTime createdAt;
  final bool isUrgent;
  final String targetFaculty;

  factory Announcement.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    DateTime created = DateTime.now();
    if (ts is Timestamp) created = ts.toDate();
    return Announcement(
      id: id,
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      category: m['category'] as String? ?? 'academic',
      authorId: m['authorId'] as String? ?? '',
      createdAt: created,
      isUrgent: m['isUrgent'] as bool? ?? false,
      targetFaculty: m['targetFaculty'] as String? ?? 'all',
    );
  }
  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'category': category,
        'authorId': authorId,
        'createdAt': createdAt,
        'isUrgent': isUrgent,
        'targetFaculty': targetFaculty,
      };
}
