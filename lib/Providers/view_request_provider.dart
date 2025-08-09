import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Services/notification_service.dart';
import '../Services/user_utils.dart';

final secureStorage = FlutterSecureStorage();

/// View incoming friend requests for the logged-in user
/// View incoming friend requests for the logged-in user
final viewRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final uid =
        firebaseUser?.uid ?? await secureStorage.read(key: 'custom_uid');

    // Check if uid is null or empty
    if (uid == null || uid.isEmpty) {
      print('No user ID found');
      return [];
    }

    print('Fetching friend requests for user: $uid');

    final incomingRequestsSnapshot =
        await FirebaseFirestore.instance
            .collection('friend_requests')
            .doc(uid)
            .collection('incoming')
            .where('status', isEqualTo: 'pending')
            .get();

    print('Found ${incomingRequestsSnapshot.docs.length} pending requests');

    final List<Map<String, dynamic>> requests = [];

    for (final doc in incomingRequestsSnapshot.docs) {
      try {
        final docData = doc.data();
        print('Processing document ${doc.id} with data: $docData');

        // Get the sender UID from the document data
        final senderUid = docData['sender'];

        // Debug: Print the actual value and type
        print('Sender UID value: $senderUid, Type: ${senderUid.runtimeType}');

        // Check if senderUid is null or empty - fix the condition
        if (senderUid == null) {
          print('Null sender UID in document: ${doc.id}');
          continue;
        }

        final senderUidString = senderUid.toString().trim();
        if (senderUidString.isEmpty) {
          print('Empty sender UID in document: ${doc.id}');
          continue;
        }

        print('Fetching data for sender: $senderUidString');
        final senderData = await _getUserData(senderUidString);

        if (senderData.isNotEmpty) {
          final requestData = {
            'uid': senderUidString,
            'name': senderData['name']?.toString() ?? 'Unknown User',
            'email': senderData['email']?.toString() ?? '',
            'location': senderData['location']?.toString() ?? '',
            'photoUrl': senderData['photoUrl']?.toString() ?? '',
            'requestId': doc.id, // Add request ID for reference
          };

          print('Added request data: $requestData');
          requests.add(requestData);
        } else {
          print('No user data found for sender: $senderUidString');
          // Still add the request with minimal data if user data fetch fails
          requests.add({
            'uid': senderUidString,
            'name': 'Unknown User',
            'email': '',
            'location': '',
            'photoUrl': '',
            'requestId': doc.id,
          });
        }
      } catch (e) {
        print('Error processing request document ${doc.id}: $e');
        print('Stack trace: ${StackTrace.current}');
        continue; // Skip this request and continue with others
      }
    }

    print('Successfully processed ${requests.length} friend requests');
    return requests;
  } catch (e) {
    print('Error in viewRequestsProvider: $e');
    print('Stack trace: ${StackTrace.current}');
    throw Exception('Failed to load friend requests: $e');
  }
});

/// Helper to get user data with improved null safety and better error handling
Future<Map<String, dynamic>> _getUserData(String uid) async {
  try {
    if (uid.trim().isEmpty) {
      print('Empty UID provided to _getUserData');
      return {};
    }

    print('Fetching user data for UID: $uid');

    // Try email collection first
    try {
      final emailDoc =
          await FirebaseFirestore.instance
              .collection('user_details_email')
              .doc(uid)
              .get();

      if (emailDoc.exists && emailDoc.data() != null) {
        final data = emailDoc.data()!;
        print('Found user in email collection: ${data['name'] ?? 'No name'}');
        return data;
      }
    } catch (e) {
      print('Error fetching from email collection for UID $uid: $e');
    }

    // Try phone collection
    try {
      final phoneDoc =
          await FirebaseFirestore.instance
              .collection('user_details_phone')
              .doc(uid)
              .get();

      if (phoneDoc.exists && phoneDoc.data() != null) {
        final data = phoneDoc.data()!;
        print('Found user in phone collection: ${data['name'] ?? 'No name'}');
        return data;
      }
    } catch (e) {
      print('Error fetching from phone collection for UID $uid: $e');
    }

    print('No user data found for UID: $uid');
    return {};
  } catch (e) {
    print('Error fetching user data for UID $uid: $e');
    return {};
  }
}

/// Accept friend request
final acceptRequestProvider = Provider.family<Future<void>, String>((
  ref,
  senderUid,
) async {
  try {
    // Validate input
    if (senderUid.isEmpty) {
      throw Exception('Invalid sender UID');
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final receiverUid =
        firebaseUser?.uid ?? await secureStorage.read(key: 'custom_uid');

    if (receiverUid == null || receiverUid.isEmpty) {
      throw Exception('No current user found');
    }

    print('Accepting friend request from $senderUid to $receiverUid');

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // Update friend request status
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

    batch.update(outgoingRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    batch.update(incomingRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // Create friendship connections
    final senderFriendRef = firestore
        .collection('connections')
        .doc(senderUid)
        .collection('friends')
        .doc(receiverUid);

    final receiverFriendRef = firestore
        .collection('connections')
        .doc(receiverUid)
        .collection('friends')
        .doc(senderUid);

    batch.set(senderFriendRef, {'since': FieldValue.serverTimestamp()});
    batch.set(receiverFriendRef, {'since': FieldValue.serverTimestamp()});

    // Execute all operations atomically
    await batch.commit();

    // Send notification (non-critical, so catch errors separately)
    try {
      final senderData = await getUserData(senderUid);
      final receiverData = await getUserData(receiverUid);

      final fcmToken = senderData['fcm_token']?.toString();
      final receiverName = receiverData['name']?.toString() ?? 'Someone';

      if (fcmToken != null && fcmToken.isNotEmpty) {
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
    } catch (e) {
      print('Failed to send notification: $e');
      // Don't throw error for notification failure
    }

    print('Friend request accepted successfully');
  } catch (e) {
    print('Error accepting friend request: $e');
    throw Exception('Failed to accept friend request: $e');
  }
});

/// Reject friend request
final rejectRequestProvider = Provider.family<Future<void>, String>((
  ref,
  senderUid,
) async {
  try {
    // Validate input
    if (senderUid.isEmpty) {
      throw Exception('Invalid sender UID');
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final receiverUid =
        firebaseUser?.uid ?? await secureStorage.read(key: 'custom_uid');

    if (receiverUid == null || receiverUid.isEmpty) {
      throw Exception('No current user found');
    }

    print('Rejecting friend request from $senderUid to $receiverUid');

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

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

    batch.update(outgoingRef, {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
    batch.update(incomingRef, {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    print('Friend request rejected successfully');
  } catch (e) {
    print('Error rejecting friend request: $e');
    throw Exception('Failed to reject friend request: $e');
  }
});
