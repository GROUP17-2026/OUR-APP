import 'package:cloud_firestore/cloud_firestore.dart';

class CampusResource {
  CampusResource({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.uploadedBy,
    required this.subject,
    required this.createdAt,
    this.uploaderName = '',
  });

  final String id;
  final String title;
  final String type;
  final String url;
  final String uploadedBy;
  final String subject;
  final DateTime createdAt;
  final String uploaderName;

  factory CampusResource.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    DateTime created = DateTime.now();
    if (ts is Timestamp) created = ts.toDate();
    return CampusResource(
      id: id,
      title: m['title'] as String? ?? '',
      type: m['type'] as String? ?? 'file',
      url: m['url'] as String? ?? '',
      uploadedBy: m['uploadedBy'] as String? ?? '',
      subject: m['subject'] as String? ?? '',
      createdAt: created,
      uploaderName: m['uploaderName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': type,
        'url': url,
        'uploadedBy': uploadedBy,
        'subject': subject,
        'uploaderName': uploaderName,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
