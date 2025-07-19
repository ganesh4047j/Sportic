import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';

final friendshipStatusProvider = FutureProvider.family<bool, String>((
  ref,
  otherUserId,
) async {
  final currentUid = await SecureStorageService.getUid();
  final doc =
      await FirebaseFirestore.instance
          .collection('connections')
          .doc(currentUid)
          .collection('friends')
          .doc(otherUserId)
          .get();

  return doc.exists;
});

Future<void> sendFriendRequest(String receiverUid) async {
  final currentUid = await SecureStorageService.getUid();
  final timestamp = FieldValue.serverTimestamp();

  await FirebaseFirestore.instance
      .collection('friend_requests')
      .doc(currentUid)
      .collection('outgoing')
      .doc(receiverUid)
      .set({
        'receiver': receiverUid,
        'sender': currentUid,
        'status': 'pending',
        'sent_at': timestamp,
      });

  await FirebaseFirestore.instance
      .collection('friend_requests')
      .doc(receiverUid)
      .collection('incoming')
      .doc(currentUid)
      .set({
        'receiver': receiverUid,
        'sender': currentUid,
        'status': 'pending',
        'sent_at': timestamp,
      });
}
