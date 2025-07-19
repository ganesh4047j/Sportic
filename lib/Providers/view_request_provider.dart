import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Services/notification_service.dart';
import '../Services/user_utils.dart';

final secureStorage = FlutterSecureStorage();

/// View incoming friend requests for the logged-in user
final viewRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final uid = firebaseUser?.uid ?? await secureStorage.read(key: 'custom_uid');
  if (uid == null) return [];

  final incomingRequestsSnapshot =
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(uid)
          .collection('incoming')
          .where('status', isEqualTo: 'pending')
          .get();

  final List<Map<String, dynamic>> requests = [];

  for (final doc in incomingRequestsSnapshot.docs) {
    final senderUid = doc.data()['from'];
    final senderData = await _getUserData(senderUid);
    if (senderData.isNotEmpty) {
      requests.add({
        'uid': senderUid,
        'name': senderData['name'] ?? '',
        'email': senderData['email'] ?? '',
        'location': senderData['location'] ?? '',
        'photoUrl': senderData['photoUrl'] ?? '',
      });
    }
  }

  return requests;
});

/// Accept friend request
final acceptRequestProvider = Provider.family<Future<void>, String>((
  ref,
  senderUid,
) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final receiverUid =
      firebaseUser?.uid ?? await secureStorage.read(key: 'custom_uid');
  final firestore = FirebaseFirestore.instance;

  final outgoingRef = firestore
      .collection('friend_requests')
      .doc(senderUid)
      .collection('outgoing')
      .doc(receiverUid);

  final incomingRef = firestore
      .collection('friend_requests')
      .doc(receiverUid)
      .collection('incoming')
      .doc(senderUid);

  await outgoingRef.update({'status': 'accepted'});
  await incomingRef.update({'status': 'accepted'});

  // Save connection in both user docs
  await firestore
      .collection('connections')
      .doc(senderUid)
      .collection('friends')
      .doc(receiverUid)
      .set({'since': FieldValue.serverTimestamp()});
  await firestore
      .collection('connections')
      .doc(receiverUid)
      .collection('friends')
      .doc(senderUid)
      .set({'since': FieldValue.serverTimestamp()});

  // 🔔 Fetch user data
  final senderData = await getUserData(senderUid);
  final receiverData = await getUserData(receiverUid!);

  final fcmToken = senderData['fcm_token'];
  final receiverName = receiverData['name'] ?? 'Someone';

  if (fcmToken != null && fcmToken.toString().isNotEmpty) {
    await FCMService.sendPushNotification(
      toToken: fcmToken,
      title: 'Friend Request Accepted',
      body: '$receiverName accepted your friend request!',
      data: {
        'type': 'friend_accept',
        'from': receiverUid,
        'fromName': receiverName,
      },
    );
  }
});

/// Reject friend request
final rejectRequestProvider = Provider.family<Future<void>, String>((
  ref,
  senderUid,
) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final receiverUid =
      firebaseUser?.uid ?? await secureStorage.read(key: 'custom_uid');
  final firestore = FirebaseFirestore.instance;

  final outgoingRef = firestore
      .collection('friend_requests')
      .doc(senderUid)
      .collection('outgoing')
      .doc(receiverUid);

  final incomingRef = firestore
      .collection('friend_requests')
      .doc(receiverUid)
      .collection('incoming')
      .doc(senderUid);

  await outgoingRef.update({'status': 'rejected'});
  await incomingRef.update({'status': 'rejected'});
});

/// Helper to get user data
Future<Map<String, dynamic>> _getUserData(String uid) async {
  final emailDoc =
      await FirebaseFirestore.instance
          .collection('user_details_email')
          .doc(uid)
          .get();
  if (emailDoc.exists) return emailDoc.data()!;
  final phoneDoc =
      await FirebaseFirestore.instance
          .collection('user_details_phone')
          .doc(uid)
          .get();
  if (phoneDoc.exists) return phoneDoc.data()!;
  return {};
}
