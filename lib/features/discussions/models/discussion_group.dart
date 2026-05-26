import 'package:cloud_firestore/cloud_firestore.dart';

class DiscussionGroup {
  DiscussionGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage = '',
    this.lastMessageAt,
    this.targetFaculty = 'all',
  });

  final String id;
  final String name;
  final String description;
  final List<String> members;
  final String createdBy;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String targetFaculty;

  factory DiscussionGroup.fromMap(String id, Map<String, dynamic> m) {
    final created = m['createdAt'];
    DateTime createdAt = DateTime.now();
    if (created is Timestamp) createdAt = created.toDate();
    final lm = m['lastMessageAt'];
    DateTime? lastAt;
    if (lm is Timestamp) lastAt = lm.toDate();
    final mem = m['members'];
    return DiscussionGroup(
      id: id,
      name: m['name'] as String? ?? 'Group',
      description: m['description'] as String? ?? '',
      members: mem is List ? mem.cast<String>() : const [],
      createdBy: m['createdBy'] as String? ?? '',
      createdAt: createdAt,
      lastMessage: m['lastMessage'] as String? ?? '',
      lastMessageAt: lastAt,
      targetFaculty: m['targetFaculty'] as String? ?? 'all',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'members': members,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt,
        'targetFaculty': targetFaculty,
      };

  int get memberCount => members.length;
}
