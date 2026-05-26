import 'package:cloud_firestore/cloud_firestore.dart';

class CampusEvent {
  CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.bannerUrl,
    required this.rsvps,
    required this.createdBy,
    this.targetFaculty = 'all',
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String? bannerUrl;
  final List<String> rsvps;
  final String createdBy;
  final String targetFaculty;

  int get goingCount => rsvps.length;

  factory CampusEvent.fromMap(String id, Map<String, dynamic> m) {
    final d = m['date'];
    DateTime date = DateTime.now();
    if (d is Timestamp) date = d.toDate();
    final r = m['rsvps'];
    return CampusEvent(
      id: id,
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      date: date,
      location: m['location'] as String? ?? '',
      bannerUrl: m['bannerUrl'] as String?,
      rsvps: r is List ? r.cast<String>() : const [],
      createdBy: m['createdBy'] as String? ?? '',
      targetFaculty: m['targetFaculty'] as String? ?? 'all',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'date': date,
        'location': location,
        if (bannerUrl != null) 'bannerUrl': bannerUrl,
        'rsvps': rsvps,
        'createdBy': createdBy,
        'targetFaculty': targetFaculty,
      };
}
