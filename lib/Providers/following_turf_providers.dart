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
  final DateTime? addedAt;

  TurfModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sport,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.ownerId,
    this.addedAt,
  });

  factory TurfModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return TurfModel(
      id: data['id'] ?? docId,
      name: data['turf_name'] ?? 'Unknown Turf',
      imageUrl: data['imageUrl'] ?? 'https://i.ibb.co/hDqLgL3/turf1.jpg',
      sport: data['sport'] ?? 'Unknown Sport',
      location: data['location'] ?? 'Unknown Location',
      startTime: data['start_time'] ?? '09:00',
      endTime: data['end_time'] ?? '22:00',
      ownerId: data['ownerId'] ?? '',
      addedAt:
          data['addedAt'] != null
              ? (data['addedAt'] as Timestamp).toDate()
              : null,
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
