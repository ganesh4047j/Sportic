import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ✅ Fetch recent chat previews (text/image), with unread count & sorted
final messagePreviewProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final me = user.email ?? user.phoneNumber;
  if (me == null) return [];

  final chatDocs = await FirebaseFirestore.instance.collection('chats').get();
  final List<Map<String, dynamic>> previews = [];

  for (var doc in chatDocs.docs) {
    final chatId = doc.id;
    final participants = chatId.split('_');
    if (!participants.contains(me)) continue;

    final peerId =
        participants.first == me ? participants.last : participants.first;

    // 🔽 Get latest message
    final msgSnap =
        await doc.reference
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    if (msgSnap.docs.isEmpty) continue;

    final lastMsg = msgSnap.docs.first.data();
    final isText = lastMsg['type'] == 'text';
    final displayText = isText ? lastMsg['text'] ?? '' : '📷 Image';
    final timestamp = (lastMsg['timestamp'] as Timestamp).toDate();

    // 🔴 Count unread messages from peer
    final unreadSnap =
        await doc.reference
            .collection('messages')
            .where('from', isNotEqualTo: me)
            .where('read', isEqualTo: false)
            .get();

    final unreadCount = unreadSnap.docs.length;

    // 🔁 Fetch peer profile
    DocumentSnapshot<Map<String, dynamic>>? peerDoc;
    try {
      peerDoc =
          await FirebaseFirestore.instance
              .collection(
                peerId.contains('@')
                    ? 'user_details_email'
                    : 'user_details_phone',
              )
              .doc(peerId)
              .get();
    } catch (_) {}

    final peerData = peerDoc?.data() ?? {};

    previews.add({
      'chatId': chatId,
      'peerEmail': peerId,
      'peerName': peerData['name'] ?? peerId,
      'photoUrl': peerData['photoUrl'] ?? '',
      'location': peerData['location'] ?? '',
      'lastMsg': displayText,
      'timestamp': timestamp,
      'unread': unreadCount,
    });
  }

  // ✅ Sort by latest message time
  previews.sort(
    (a, b) =>
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
  );

  return previews;
});

/// 🔴 Total unread messages across all chats
final unreadMessageCountProvider = FutureProvider<int>((ref) async {
  final previews = await ref.watch(messagePreviewProvider.future);
  return previews.fold<int>(
    0,
    (sum, chat) => sum + (chat['unread'] as int? ?? 0),
  );
});
