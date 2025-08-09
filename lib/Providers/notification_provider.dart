import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Main Screens/home.dart';

final friendRequestNotificationsProvider = StreamProvider<
  List<Map<String, dynamic>>
>((ref) async* {
  try {
    String? currentUserId;
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      currentUserId = fbUser.uid;
    } else {
      const secureStorage = FlutterSecureStorage();
      currentUserId = await secureStorage.read(key: 'custom_uid');
    }

    if (currentUserId == null || currentUserId.isEmpty) {
      print('🚨 No current user ID found for friend request notifications');
      yield [];
      return;
    }

    print(
      '🔔 Setting up friend request notification listener for user: $currentUserId',
    );

    // Listen to incoming friend requests
    await for (final snapshot
        in FirebaseFirestore.instance
            .collection('friend_requests')
            .doc(currentUserId)
            .collection('incoming')
            .where('status', isEqualTo: 'pending')
            .snapshots()) {
      print('🔔 Found ${snapshot.docs.length} pending friend requests');

      final List<Map<String, dynamic>> friendRequests = [];

      for (final doc in snapshot.docs) {
        try {
          final docData = doc.data();
          final senderUid = docData['sender']?.toString();

          if (senderUid == null || senderUid.isEmpty) {
            print('Invalid sender UID in friend request: ${doc.id}');
            continue;
          }

          // Get sender data
          final senderData = await _getUserDataForNotification(senderUid);

          friendRequests.add({
            'id': doc.id,
            'type': 'friend_request',
            'from': senderUid,
            'senderName': senderData['name']?.toString() ?? 'Unknown User',
            'senderEmail': senderData['email']?.toString() ?? '',
            'senderLocation': senderData['location']?.toString() ?? '',
            'senderPhotoUrl': senderData['photoUrl']?.toString() ?? '',
            'timestamp': docData['sent_at'] ?? Timestamp.now(),
            'text': 'sent you a friend request',
            'title': 'New Friend Request',
          });
        } catch (e) {
          print('Error processing friend request ${doc.id}: $e');
          continue;
        }
      }

      print(
        '🔔 Yielding ${friendRequests.length} friend request notifications',
      );
      yield friendRequests;
    }
  } catch (e, stackTrace) {
    print('🚨 Error in friendRequestNotificationsProvider: $e');
    print('🚨 Stack trace: $stackTrace');
    yield [];
  }
});

// Helper function for getting user data for notifications
Future<Map<String, dynamic>> _getUserDataForNotification(String uid) async {
  try {
    if (uid.trim().isEmpty) {
      print('Empty UID provided to _getUserDataForNotification');
      return {};
    }

    // Try email collection first
    try {
      final emailDoc =
          await FirebaseFirestore.instance
              .collection('user_details_email')
              .doc(uid)
              .get();

      if (emailDoc.exists && emailDoc.data() != null) {
        final data = emailDoc.data()!;
        print(
          'Found user in email collection for notification: ${data['name'] ?? 'No name'}',
        );
        return data;
      }
    } catch (e) {
      print(
        'Error fetching from email collection for notification UID $uid: $e',
      );
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
        print(
          'Found user in phone collection for notification: ${data['name'] ?? 'No name'}',
        );
        return data;
      }
    } catch (e) {
      print(
        'Error fetching from phone collection for notification UID $uid: $e',
      );
    }

    print('No user data found for notification UID: $uid');
    return {};
  } catch (e) {
    print('Error fetching user data for notification UID $uid: $e');
    return {};
  }
}

// Combined notifications provider (messages + friend requests)
final allNotificationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  try {
    // Watch both providers
    final messagesAsync = ref.watch(unreadMessagesProvider);
    final friendRequestsAsync = ref.watch(friendRequestNotificationsProvider);

    await for (final _ in Stream.periodic(const Duration(milliseconds: 500))) {
      final List<Map<String, dynamic>> allNotifications = [];

      // Add message notifications
      messagesAsync.whenData((messages) {
        for (final message in messages) {
          allNotifications.add({...message, 'notificationType': 'message'});
        }
      });

      // Add friend request notifications
      friendRequestsAsync.whenData((friendRequests) {
        for (final request in friendRequests) {
          allNotifications.add({
            ...request,
            'notificationType': 'friend_request',
          });
        }
      });

      // Sort by timestamp (newest first)
      allNotifications.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      yield allNotifications
          .take(15)
          .toList(); // Limit to 15 total notifications
      break; // Only emit once per cycle
    }
  } catch (e) {
    print('🚨 Error in allNotificationsProvider: $e');
    yield [];
  }
});

// Simple count provider for combined notifications
final totalNotificationCountProvider = StreamProvider<int>((ref) async* {
  try {
    final messagesAsync = ref.watch(simpleUnreadCountProvider);
    final friendRequestsAsync = ref.watch(friendRequestNotificationsProvider);

    await for (final _ in Stream.periodic(const Duration(milliseconds: 500))) {
      int totalCount = 0;

      messagesAsync.whenData((messageCount) {
        totalCount += messageCount;
      });

      friendRequestsAsync.whenData((friendRequests) {
        totalCount += friendRequests.length;
      });

      yield totalCount;
      break;
    }
  } catch (e) {
    print('🚨 Error in totalNotificationCountProvider: $e');
    yield 0;
  }
});
