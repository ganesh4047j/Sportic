import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Services/user_utils.dart';

class TurfModel {
  final String id;
  final String name;
  final String imageUrl;
  final String sport;
  final String location;
  final String startTime;
  final String endTime;
  final String ownerId;
  final String managerName;
  final String managerNumber;
  final DateTime? addedAt;

  final String weekdayDayTime;
  final String weekdayNightTime;
  final String weekendDayTime;
  final String weekendNightTime;

  TurfModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sport,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.ownerId,
    required this.managerName,
    required this.managerNumber,
    this.addedAt,
    required this.weekdayDayTime,
    required this.weekdayNightTime,
    required this.weekendDayTime,
    required this.weekendNightTime,
  });

  factory TurfModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final weekdayAmounts =
        data['weekday_amounts'] as Map<String, dynamic>? ?? {};
    final weekendAmounts =
        data['weekend_amounts'] as Map<String, dynamic>? ?? {};

    return TurfModel(
      id: data['id'] ?? docId,
      name: data['turf_name'] ?? 'Unknown Turf',
      imageUrl: data['imageUrl'] ?? 'https://i.ibb.co/hDqLgL3/turf1.jpg',
      sport: data['sport'] ?? 'Unknown Sport',
      location: data['location'] ?? 'Unknown Location',
      startTime: data['start_time'] ?? '09:00',
      endTime: data['end_time'] ?? '10:00',
      ownerId: data['ownerId'] ?? '',
      managerName: data['manager_name'] ?? 'Unknown',
      managerNumber: data['manager_number'] ?? 'Unknown Number',
      addedAt:
          data['addedAt'] != null
              ? (data['addedAt'] as Timestamp).toDate()
              : null,
      weekdayDayTime: weekdayAmounts['day_time']?.toString() ?? '0',
      weekdayNightTime: weekdayAmounts['night_time']?.toString() ?? '0',
      weekendDayTime: weekendAmounts['day_time']?.toString() ?? '0',
      weekendNightTime: weekendAmounts['night_time']?.toString() ?? '0',
    );
  }
}

/// Provider to get user's favorite turfs from Firestore
final turfProvider = StreamProvider<List<TurfModel>>((ref) async* {
  try {
    print('🔍 Starting to fetch user favorites...');

    // Get user ID using your existing user utils
    final userId = await ref.watch(currentUserIdProvider.future);

    if (userId == null) {
      print('❌ No user ID available');
      yield [];
      return;
    }

    print('✅ Using user ID: $userId');

    // Stream from user's favorites collection
    yield* FirebaseFirestore.instance
        .collection('favourites')
        .doc(userId)
        .collection('user_favourites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 Retrieved ${snapshot.docs.length} favorite turfs');

          return snapshot.docs.map((doc) {
            final data = doc.data();
            print('📄 Processing favorite turf: ${data['turf_name']}');

            return TurfModel.fromFirestore(data, doc.id);
          }).toList();
        });
  } catch (e) {
    print('🔥 Error fetching favorite turfs: $e');
    yield [];
  }
});

/// Provider for favorites count
final favoritesCountProvider = Provider<int>((ref) {
  final turfs = ref.watch(turfProvider);
  return turfs.when(
    data: (turfList) => turfList.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider to check if favorites are empty
final isEmptyFavoritesProvider = Provider<bool>((ref) {
  final turfs = ref.watch(turfProvider);
  return turfs.when(
    data: (turfList) => turfList.isEmpty,
    loading: () => false,
    error: (_, __) => true,
  );
});
