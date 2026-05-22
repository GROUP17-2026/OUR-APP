class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.studentId,
    required this.faculty,
    this.photoUrl,
    this.fcmToken,
    this.discussionsJoined = 0,
    this.resourcesShared = 0,
    this.eventsAttended = 0,
    this.notifyAnnouncements = true,
  });

  final String uid;
  final String name;
  final String email;
  final String studentId;
  final String faculty;
  final String? photoUrl;
  final String? fcmToken;
  final int discussionsJoined;
  final int resourcesShared;
  final int eventsAttended;
  final bool notifyAnnouncements;

  factory UserProfile.fromMap(Map<String, dynamic> m, String uid) {
    return UserProfile(
      uid: uid,
      name: m['name'] as String? ?? '',
      email: m['email'] as String? ?? '',
      studentId: m['studentId'] as String? ?? '',
      faculty: m['faculty'] as String? ?? '',
      photoUrl: m['photoUrl'] as String?,
      fcmToken: m['fcmToken'] as String?,
      discussionsJoined: (m['discussionsJoined'] as num?)?.toInt() ?? 0,
      resourcesShared: (m['resourcesShared'] as num?)?.toInt() ?? 0,
      eventsAttended: (m['eventsAttended'] as num?)?.toInt() ?? 0,
      notifyAnnouncements: m['notifyAnnouncements'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'studentId': studentId,
        'faculty': faculty,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'discussionsJoined': discussionsJoined,
        'resourcesShared': resourcesShared,
        'eventsAttended': eventsAttended,
        'notifyAnnouncements': notifyAnnouncements,
      };

  UserProfile copyWith({
    String? fcmToken,
    bool? notifyAnnouncements,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid,
      name: name,
      email: email,
      studentId: studentId,
      faculty: faculty,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      discussionsJoined: discussionsJoined,
      resourcesShared: resourcesShared,
      eventsAttended: eventsAttended,
      notifyAnnouncements: notifyAnnouncements ?? this.notifyAnnouncements,
    );
  }
}
