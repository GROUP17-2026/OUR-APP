import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.senderPhotoUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
  });

  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final String? senderPhotoUrl;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;

  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['timestamp'];
    DateTime t = DateTime.now();
    if (ts is Timestamp) t = ts.toDate();
    return ChatMessage(
      id: id,
      text: m['text'] as String? ?? '',
      senderId: m['senderId'] as String? ?? '',
      senderName: m['senderName'] as String? ?? '',
      timestamp: t,
      senderPhotoUrl: m['senderPhotoUrl'] as String?,
      fileUrl: m['fileUrl'] as String?,
      fileName: m['fileName'] as String?,
      fileSize: m['fileSize'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'senderId': senderId,
    'senderName': senderName,
    'timestamp': timestamp,
    if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (fileName != null) 'fileName': fileName,
    if (fileSize != null) 'fileSize': fileSize,
  };
}
