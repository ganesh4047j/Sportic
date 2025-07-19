import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Services/user_utils.dart';
import '../Services/notification_service.dart';

final secureStorage = FlutterSecureStorage();
final nameSearchProvider = StateProvider<String>((ref) => '');
final locationSearchProvider = StateProvider<String>((ref) => '');

/// Search users from both collections and mark request status.
final searchFriendsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final nameQuery = ref.watch(nameSearchProvider).trim().toLowerCase();
  final locationQuery = ref.watch(locationSearchProvider).trim().toLowerCase();

  final currentUser = FirebaseAuth.instance.currentUser;
  final currentUid =
      currentUser?.uid ?? await secureStorage.read(key: 'custom_uid') ?? '';
  if (currentUid.isEmpty) return [];

  // Get all users (email + phone)
  final emailSnapshot =
      await FirebaseFirestore.instance.collection('user_details_email').get();
  final phoneSnapshot =
      await FirebaseFirestore.instance.collection('user_details_phone').get();
  final allDocs = [...emailSnapshot.docs, ...phoneSnapshot.docs];

  // Get outgoing requests
  final outgoingSnapshot =
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: currentUid)
          .get();

  // Get accepted connections
  final connectionsSnapshot =
      await FirebaseFirestore.instance
          .collection('connections')
          .doc(currentUid)
          .collection('friends')
          .get();

  final outgoingMap = {
    for (var doc in outgoingSnapshot.docs) doc['to']: doc['status'],
  };

  final connectedMap = {for (var doc in connectionsSnapshot.docs) doc.id: true};

  final filtered =
      allDocs
          .where((doc) {
            final data = doc.data();
            final userId = doc.id;

            final name = (data['name'] ?? '').toString().toLowerCase();
            final location = (data['location'] ?? '').toString().toLowerCase();
            final isNotCurrentUser = userId != currentUid;

            final nameMatch = nameQuery.isEmpty || name.contains(nameQuery);
            final locationMatch =
                locationQuery.isEmpty || location.contains(locationQuery);

            return nameMatch && locationMatch && isNotCurrentUser;
          })
          .map((doc) {
            final data = doc.data();
            final userId = doc.id;

            String requestStatus = 'none';
            if (connectedMap.containsKey(userId)) {
              requestStatus = 'accepted';
            } else if (outgoingMap.containsKey(userId)) {
              requestStatus = outgoingMap[userId]; // pending/rejected
            }

            return {
              'uid': userId,
              'name': data['name'] ?? '',
              'location': data['location'] ?? '',
              'email': data['email'] ?? '',
              'phone': data['phone_number'] ?? '',
              'photoUrl': data['photoUrl'] ?? '',
              'requestStatus': requestStatus,
            };
          })
          .toList();

  return filtered;
});

/// Send friend request (one-directional; creates both incoming & outgoing entries)
// final sendFriendRequestProvider = Provider.family<Future<void>, String>((ref, receiverUid) async {
//   final firebaseUser = FirebaseAuth.instance.currentUser;
//   final senderUid = firebaseUser?.uid ?? await secureStorage.read(key: 'custom_uid');
//   if (senderUid == null || senderUid == receiverUid) throw 'Invalid user ID';
//
//   final firestore = FirebaseFirestore.instance;
//
//   final senderData = await _getUserData(senderUid);
//   final receiverData = await _getUserData(receiverUid);
//
//   final outgoingRef = firestore
//       .collection('friend_requests')
//       .doc(senderUid)
//       .collection('outgoing')
//       .doc(receiverUid);
//
//   final incomingRef = firestore
//       .collection('friend_requests')
//       .doc(receiverUid)
//       .collection('incoming')
//       .doc(senderUid);
//
//   final existing = await outgoingRef.get();
//   if (existing.exists) {
//     final status = existing.data()?['status'];
//     if (status == 'pending' || status == 'accepted') {
//       throw 'Request already sent or accepted';
//     }
//   }
//
//   final payload = {
//     'from': senderUid,
//     'to': receiverUid,
//     'fromName': senderData['name'],
//     'toName': receiverData['name'],
//     'status': 'pending',
//     'timestamp': FieldValue.serverTimestamp(),
//   };
//
//   await outgoingRef.set(payload);
//   await incomingRef.set(payload);
// });

final sendFriendRequestProvider = Provider.family<Future<void>, String>((
  ref,
  receiverUid,
) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final senderUid =
      firebaseUser?.uid ?? await secureStorage.read(key: 'custom_uid');

  if (senderUid == null || senderUid == receiverUid) {
    throw 'Invalid user ID';
  }

  final firestore = FirebaseFirestore.instance;

  final senderData = await getUserData(senderUid);
  final receiverData = await getUserData(receiverUid);

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

  final existing = await outgoingRef.get();
  if (existing.exists) {
    final status = existing.data()?['status'];
    if (status == 'pending' || status == 'accepted') {
      throw 'Request already sent or accepted';
    }
  }

  final payload = {
    'from': senderUid,
    'to': receiverUid,
    'fromName': senderData['name'],
    'toName': receiverData['name'],
    'status': 'pending',
    'timestamp': FieldValue.serverTimestamp(),
  };

  await outgoingRef.set(payload);
  await incomingRef.set(payload);

  // 🔔 Send push notification via FCMService
  final fcmToken = receiverData['fcm_token'];
  if (fcmToken != null && fcmToken.toString().isNotEmpty) {
    await FCMService.sendPushNotification(
      toToken: fcmToken,
      title: 'New Friend Request',
      body: '${senderData['name']} sent you a friend request.',
    );
  }
});
