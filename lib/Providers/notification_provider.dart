import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Main Screens/home.dart';

// Enhanced Offer model class with turf support
class Offer {
  final String id;
  final String title;
  final String description;
  final String offerType;
  final double discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final DateTime createdAt;
  final String ownerId;
  final bool isActive;
  final List<String> selectedTurfIds;
  final List<Map<String, dynamic>> selectedTurfs;
  final String offerScope;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.offerType,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.ownerId,
    this.isActive = true,
    this.selectedTurfIds = const [],
    this.selectedTurfs = const [],
    this.offerScope = "selected_turfs",
  });

  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      offerType: map['offerType']?.toString() ?? '',
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerId: map['ownerId']?.toString() ?? '',
      isActive: map['isActive'] ?? true,
      selectedTurfIds: List<String>.from(map['selectedTurfIds'] ?? []),
      selectedTurfs:
          (map['selectedTurfs'] as List<dynamic>?)
              ?.map((turf) => Map<String, dynamic>.from(turf))
              .toList() ??
          [],
      offerScope: map['offerScope']?.toString() ?? 'selected_turfs',
    );
  }
}

// Friend request notifications provider
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
            'notificationType': 'friend_request', // Added this
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

// Enhanced Active offers provider with detailed debugging
final activeOffersProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  try {
    print('🎯 Setting up active offers listener');

    await for (final snapshot
        in FirebaseFirestore.instance
            .collection('offers')
            .orderBy('createdAt', descending: true)
            .snapshots()) {
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);
      final List<Map<String, dynamic>> activeOffers = [];

      print('🎯 Found ${snapshot.docs.length} total offers in collection');
      print('🎯 Current time: ${now.toString()}');
      print('🎯 Current TimeOfDay: ${currentTime.hour}:${currentTime.minute}');

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('🎯 Processing offer ${doc.id}:');

          // Check if this is a valid offer document
          if (!data.containsKey('title') ||
              !data.containsKey('discountPercentage')) {
            print('   ⚠️ Skipping document - missing required fields');
            continue;
          }

          final offer = Offer.fromMap(data);

          print('   Parsed offer:');
          print('     Title: ${offer.title}');
          print('     Start Date: ${offer.startDate}');
          print('     End Date: ${offer.endDate}');
          print('     Start Time: ${offer.startTime}');
          print('     End Time: ${offer.endTime}');
          print('     Discount: ${offer.discountPercentage}%');
          print('     Is Active: ${offer.isActive}');

          // FIXED: Use actual time-based validation instead of testing override
          final isTimeBasedActive = _isOfferActiveDebug(
            offer,
            now,
            currentTime,
          );
          print('   Time-based Active: $isTimeBasedActive');

          // Only add offer if it's both marked as active AND currently within time bounds
          if (offer.isActive && isTimeBasedActive) {
            final offerData = {
              'id': offer.id,
              'type': 'offer',
              'title': offer.title,
              'description': offer.description,
              'offerType': offer.offerType,
              'discountPercentage': offer.discountPercentage,
              'startDate': offer.startDate,
              'endDate': offer.endDate,
              'startTime': offer.startTime,
              'endTime': offer.endTime,
              'timestamp': Timestamp.fromDate(offer.createdAt),
              'text':
                  '${offer.discountPercentage.toInt()}% off on ${offer.offerType}',
              'notificationType': 'offer',
              'ownerId': offer.ownerId,
              'selectedTurfIds': offer.selectedTurfIds,
              'selectedTurfs': offer.selectedTurfs,
              'offerScope': offer.offerScope,
            };
            activeOffers.add(offerData);
            print('   ✅ Added to active offers');

            // Log turf details
            if (offer.selectedTurfs.isNotEmpty) {
              print('   📍 Available at turfs:');
              for (final turf in offer.selectedTurfs) {
                print('     - ${turf['name']} (${turf['location']})');
              }
            }
          } else {
            print('   ❌ Filtered out - not currently active');
            print('     isActive flag: ${offer.isActive}');
            print('     Time-based active: $isTimeBasedActive');

            // Detailed reason for filtering
            if (!offer.isActive) {
              print('     Reason: Offer marked as inactive');
            } else if (!isTimeBasedActive) {
              print('     Reason: Outside valid time/date range');
            }
          }
        } catch (e) {
          print('🚨 Error processing offer ${doc.id}: $e');
          continue;
        }
      }

      print('🎯 Final active offers count: ${activeOffers.length}');
      if (activeOffers.isNotEmpty) {
        print('🎯 Active offers:');
        for (final offer in activeOffers) {
          print('   - ${offer['title']} (${offer['discountPercentage']}%)');
          final selectedTurfs = offer['selectedTurfs'] as List<dynamic>? ?? [];
          if (selectedTurfs.isNotEmpty) {
            print(
              '     Available at: ${selectedTurfs.map((t) => t['name']).join(', ')}',
            );
          }
        }
      } else {
        print('🎯 No active offers found');
      }

      yield activeOffers;
    }
  } catch (e, stackTrace) {
    print('🚨 Error in activeOffersProvider: $e');
    print('🚨 Stack trace: $stackTrace');
    yield [];
  }
});

// TEST PROVIDER - Use this temporarily to test if notifications work at all
final testActiveOffersProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  try {
    print('🧪 TEST: Setting up test offers provider (all offers active)');

    await for (final snapshot
        in FirebaseFirestore.instance
            .collection('offers')
            .orderBy('createdAt', descending: true)
            .snapshots()) {
      final List<Map<String, dynamic>> allOffers = [];

      print('🧪 TEST: Found ${snapshot.docs.length} offers');

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final offer = Offer.fromMap(data);

          allOffers.add({
            'id': offer.id,
            'type': 'offer',
            'title': offer.title,
            'description': offer.description,
            'offerType': offer.offerType,
            'discountPercentage': offer.discountPercentage,
            'startDate': offer.startDate,
            'endDate': offer.endDate,
            'startTime': offer.startTime,
            'endTime': offer.endTime,
            'timestamp': Timestamp.fromDate(offer.createdAt),
            'text':
                '${offer.discountPercentage.toInt()}% off on ${offer.offerType}',
            'notificationType': 'offer',
            'ownerId': offer.ownerId,
            'selectedTurfIds': offer.selectedTurfIds,
            'selectedTurfs': offer.selectedTurfs,
            'offerScope': offer.offerScope,
          });

          print('🧪 TEST: Added offer: ${offer.title}');
        } catch (e) {
          print('🧪 TEST: Error processing offer ${doc.id}: $e');
          continue;
        }
      }

      print(
        '🧪 TEST: Yielding ${allOffers.length} offers (all considered active)',
      );
      yield allOffers;
    }
  } catch (e, stackTrace) {
    print('🧪 TEST: Error in testActiveOffersProvider: $e');
    yield [];
  }
});

// Enhanced debug version of _isOfferActive
bool _isOfferActiveDebug(Offer offer, DateTime now, TimeOfDay currentTime) {
  try {
    print('     🔍 Checking if offer is active...');

    // Check if offer is marked as active
    if (!offer.isActive) {
      print('     ❌ Offer is marked as inactive');
      return false;
    }

    // Check date range
    final todayDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      offer.startDate.year,
      offer.startDate.month,
      offer.startDate.day,
    );
    final endDate = DateTime(
      offer.endDate.year,
      offer.endDate.month,
      offer.endDate.day,
    );

    print('     📅 Date check:');
    print('       Today: ${todayDate.toString()}');
    print('       Start: ${startDate.toString()}');
    print('       End: ${endDate.toString()}');

    if (todayDate.isBefore(startDate)) {
      print('     ❌ Today is before start date');
      return false;
    }

    if (todayDate.isAfter(endDate)) {
      print('     ❌ Today is after end date');
      return false;
    }

    print('     ✅ Date range check passed');

    // Parse time strings
    final startTime = _parseTimeStringDebug(offer.startTime);
    final endTime = _parseTimeStringDebug(offer.endTime);

    print('     🕒 Time check:');
    print('       Start time string: "${offer.startTime}"');
    print('       End time string: "${offer.endTime}"');
    print('       Parsed start time: ${startTime?.toString()}');
    print('       Parsed end time: ${endTime?.toString()}');

    if (startTime == null || endTime == null) {
      print(
        '     ⚠️ Time parsing failed - considering offer INACTIVE for safety',
      );
      // CHANGED: Return false instead of true when time parsing fails
      // This prevents expired offers from showing due to parsing errors
      return false;
    }

    // Convert TimeOfDay to minutes for easier comparison
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    print('     ⏰ Time comparison (in minutes):');
    print(
      '       Current: $currentMinutes (${currentTime.hour}:${currentTime.minute})',
    );
    print(
      '       Start: $startMinutes (${startTime.hour}:${startTime.minute})',
    );
    print('       End: $endMinutes (${endTime.hour}:${endTime.minute})');

    // Handle case where end time is next day (e.g., 23:00 to 02:00)
    if (endMinutes < startMinutes) {
      print('     🌙 Cross-midnight offer detected');
      final isActive =
          currentMinutes >= startMinutes || currentMinutes <= endMinutes;
      print('     Result: $isActive');
      return isActive;
    } else {
      print('     🌞 Same-day offer');
      final isActive =
          currentMinutes >= startMinutes && currentMinutes <= endMinutes;
      print('     Result: $isActive');
      return isActive;
    }
  } catch (e) {
    print('     🚨 Error checking if offer is active: $e');
    // CHANGED: Return false instead of true when there's an error
    // This prevents potentially expired offers from showing due to errors
    return false;
  }
}

// Enhanced debug version of _parseTimeString
TimeOfDay? _parseTimeStringDebug(String timeString) {
  try {
    print('       Parsing time: "$timeString"');

    if (timeString.trim().isEmpty) {
      print('       ❌ Empty time string');
      return null;
    }

    // Handle 12-hour format (e.g., "9:00 AM", "5:00 PM")
    if (timeString.contains('AM') || timeString.contains('PM')) {
      return _parse12HourTimeDebug(timeString);
    }

    // Handle legacy 24-hour format (e.g., "9:0", "17:0")
    final parts = timeString.split(':');
    print('       Split parts: $parts');

    if (parts.length == 2) {
      final hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());

      if (hour < 0 || hour > 23) {
        print('       ❌ Invalid hour: $hour');
        return null;
      }

      if (minute < 0 || minute > 59) {
        print('       ❌ Invalid minute: $minute');
        return null;
      }

      final result = TimeOfDay(hour: hour, minute: minute);
      print(
        '       ✅ Parsed successfully (24-hour): ${result.hour}:${result.minute}',
      );
      return result;
    } else {
      print('       ❌ Invalid format - expected HH:MM or H:MM AM/PM');
      return null;
    }
  } catch (e) {
    print('       🚨 Error parsing time string "$timeString": $e');
    return null;
  }
}

TimeOfDay? _parse12HourTimeDebug(String timeString) {
  try {
    print('       Parsing 12-hour format: "$timeString"');

    // Remove extra spaces and normalize
    String cleanedTime = timeString.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Split by space to separate time and AM/PM
    List<String> parts = cleanedTime.split(' ');
    if (parts.length != 2) {
      print('       ❌ Invalid 12-hour format - expected "H:MM AM/PM"');
      return null;
    }

    String timePart = parts[0];
    String periodPart = parts[1].toUpperCase();

    if (periodPart != 'AM' && periodPart != 'PM') {
      print('       ❌ Invalid period - expected AM or PM, got: $periodPart');
      return null;
    }

    // Parse the time part
    List<String> timeComponents = timePart.split(':');
    if (timeComponents.length != 2) {
      print('       ❌ Invalid time format - expected H:MM');
      return null;
    }

    int hour = int.parse(timeComponents[0]);
    int minute = int.parse(timeComponents[1]);

    // Validate hour and minute
    if (hour < 1 || hour > 12) {
      print('       ❌ Invalid hour for 12-hour format: $hour');
      return null;
    }

    if (minute < 0 || minute > 59) {
      print('       ❌ Invalid minute: $minute');
      return null;
    }

    // Convert to 24-hour format
    if (periodPart == 'AM') {
      if (hour == 12) {
        hour = 0; // 12:XX AM becomes 00:XX
      }
    } else {
      // PM
      if (hour != 12) {
        hour += 12; // 1:XX PM becomes 13:XX, but 12:XX PM stays 12:XX
      }
    }

    final result = TimeOfDay(hour: hour, minute: minute);
    print(
      '       ✅ Parsed successfully (12-hour): ${result.hour}:${result.minute}',
    );
    return result;
  } catch (e) {
    print('       🚨 Error parsing 12-hour time "$timeString": $e');
    return null;
  }
}

// Original helper functions (for fallback if needed)
bool _isOfferActive(Offer offer, DateTime now, TimeOfDay currentTime) {
  try {
    if (!offer.isActive) return false;

    // Check date range
    final todayDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      offer.startDate.year,
      offer.startDate.month,
      offer.startDate.day,
    );
    final endDate = DateTime(
      offer.endDate.year,
      offer.endDate.month,
      offer.endDate.day,
    );

    if (todayDate.isBefore(startDate) || todayDate.isAfter(endDate)) {
      return false;
    }

    // Parse time strings (assuming format like "09:00" or "21:30")
    final startTime = _parseTimeString(offer.startTime);
    final endTime = _parseTimeString(offer.endTime);

    if (startTime == null || endTime == null) {
      // If time parsing fails, consider offer active for the entire day
      return true;
    }

    // Convert TimeOfDay to minutes for easier comparison
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Handle case where end time is next day (e.g., 23:00 to 02:00)
    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
  } catch (e) {
    print('Error checking if offer is active: $e');
    return true; // Default to active if there's an error
  }
}

TimeOfDay? _parseTimeString(String timeString) {
  try {
    // Handle 12-hour format (e.g., "9:00 AM", "5:00 PM")
    if (timeString.contains('AM') || timeString.contains('PM')) {
      return _parse12HourTime(timeString);
    }

    // Handle legacy 24-hour format (e.g., "9:0", "17:0")
    final parts = timeString.split(':');
    if (parts.length == 2) {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    }
  } catch (e) {
    print('Error parsing time string "$timeString": $e');
  }
  return null;
}

TimeOfDay? _parse12HourTime(String timeString) {
  try {
    // Remove extra spaces and normalize
    String cleanedTime = timeString.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Split by space to separate time and AM/PM
    List<String> parts = cleanedTime.split(' ');
    if (parts.length != 2) return null;

    String timePart = parts[0];
    String periodPart = parts[1].toUpperCase();

    if (periodPart != 'AM' && periodPart != 'PM') return null;

    // Parse the time part
    List<String> timeComponents = timePart.split(':');
    if (timeComponents.length != 2) return null;

    int hour = int.parse(timeComponents[0]);
    int minute = int.parse(timeComponents[1]);

    // Validate
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;

    // Convert to 24-hour format
    if (periodPart == 'AM') {
      if (hour == 12) hour = 0; // 12:XX AM becomes 00:XX
    } else {
      // PM
      if (hour != 12) hour += 12; // 1:XX PM becomes 13:XX
    }

    return TimeOfDay(hour: hour, minute: minute);
  } catch (e) {
    print('Error parsing 12-hour time "$timeString": $e');
    return null;
  }
}

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

// FIXED: Enhanced Combined notifications provider with proper stream handling
final allNotificationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  try {
    print('🔔 Setting up combined notifications listener');

    // Combine all notification streams properly
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      final List<Map<String, dynamic>> allNotifications = [];

      // Get all notification types
      try {
        // Get unread messages
        final messagesAsync = ref.read(unreadMessagesProvider);
        messagesAsync.whenData((messages) {
          print('📨 Adding ${messages.length} message notifications');
          for (final message in messages) {
            allNotifications.add({...message, 'notificationType': 'message'});
          }
        });

        // Get friend requests
        final friendRequestsAsync = ref.read(
          friendRequestNotificationsProvider,
        );
        friendRequestsAsync.whenData((friendRequests) {
          print(
            '👥 Adding ${friendRequests.length} friend request notifications',
          );
          for (final request in friendRequests) {
            allNotifications.add({
              ...request,
              'notificationType': 'friend_request',
            });
          }
        });

        // Get active offers
        final offersAsync = ref.read(activeOffersProvider);
        offersAsync.whenData((offers) {
          print('🎯 Adding ${offers.length} offer notifications');
          for (final offer in offers) {
            allNotifications.add({...offer, 'notificationType': 'offer'});
          }
        });
      } catch (e) {
        print('Error reading notifications: $e');
      }

      // Sort by timestamp (newest first)
      allNotifications.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      print('🔔 Final combined notifications: ${allNotifications.length}');
      for (final notif in allNotifications) {
        print(
          '  - ${notif['notificationType']}: ${notif['title'] ?? notif['text']}',
        );
      }

      yield allNotifications.take(20).toList();
    }
  } catch (e, stackTrace) {
    print('🚨 Error in allNotificationsProvider: $e');
    print('🚨 Stack trace: $stackTrace');
    yield [];
  }
});

// Enhanced Total notification count provider with debugging
final totalNotificationCountProvider = StreamProvider<int>((ref) async* {
  try {
    print('🔔 Setting up total count provider');

    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      int totalCount = 0;

      try {
        // Count messages
        final messagesAsync = ref.read(simpleUnreadCountProvider);
        messagesAsync.whenData((messageCount) {
          totalCount += messageCount;
          print('🔔 Count - Messages: $messageCount');
        });

        // Count friend requests
        final friendRequestsAsync = ref.read(
          friendRequestNotificationsProvider,
        );
        friendRequestsAsync.whenData((friendRequests) {
          totalCount += friendRequests.length;
          print('🔔 Count - Friend requests: ${friendRequests.length}');
        });

        // Count offers
        final offersAsync = ref.read(activeOffersProvider);
        offersAsync.whenData((offers) {
          totalCount += offers.length;
          print('🔔 Count - Offers: ${offers.length}');
        });
      } catch (e) {
        print('Error counting notifications: $e');
      }

      print('🔔 Total notification count: $totalCount');
      yield totalCount;
    }
  } catch (e) {
    print('🚨 Error in totalNotificationCountProvider: $e');
    yield 0;
  }
});

final turfSpecificOffersProvider = StreamProvider.family<
  List<Map<String, dynamic>>,
  String
>((ref, turfId) async* {
  try {
    print('🎯 Setting up turf-specific offers listener for turf: $turfId');

    await for (final snapshot
        in FirebaseFirestore.instance
            .collection('offers')
            .orderBy('createdAt', descending: true)
            .snapshots()) {
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);
      final List<Map<String, dynamic>> turfOffers = [];

      print(
        '🎯 Found ${snapshot.docs.length} total offers, filtering for turf: $turfId',
      );

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (!data.containsKey('title') ||
              !data.containsKey('discountPercentage')) {
            continue;
          }

          final offer = Offer.fromMap(data);

          // Check if offer is active and applies to this turf
          if (offer.isActive && _isOfferActiveDebug(offer, now, currentTime)) {
            // Check if offer applies to this specific turf
            bool appliesToThisTurf = false;

            if (offer.offerScope == 'all_turfs') {
              appliesToThisTurf = true;
            } else if (offer.selectedTurfIds.contains(turfId)) {
              appliesToThisTurf = true;
            } else {
              // Check in selectedTurfs list
              for (final turf in offer.selectedTurfs) {
                if (turf['id'] == turfId) {
                  appliesToThisTurf = true;
                  break;
                }
              }
            }

            if (appliesToThisTurf) {
              turfOffers.add({
                'id': offer.id,
                'title': offer.title,
                'description': offer.description,
                'offerType': offer.offerType,
                'discountPercentage': offer.discountPercentage,
                'startDate': offer.startDate,
                'endDate': offer.endDate,
                'startTime': offer.startTime,
                'endTime': offer.endTime,
                'ownerId': offer.ownerId,
              });
            }
          }
        } catch (e) {
          print('🚨 Error processing offer ${doc.id}: $e');
          continue;
        }
      }

      print('🎯 Found ${turfOffers.length} active offers for turf: $turfId');
      yield turfOffers;
    }
  } catch (e, stackTrace) {
    print('🚨 Error in turfSpecificOffersProvider: $e');
    yield [];
  }
});
