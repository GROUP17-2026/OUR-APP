import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../models/chat_message.dart';

final messagesStreamProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).watchMessages(groupId);
});
