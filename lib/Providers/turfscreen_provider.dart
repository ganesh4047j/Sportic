import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🌍 User Location Provider
final userLocationProvider = StateProvider<String?>((ref) => null);

/// 🏷️ Selected sport filter (like All Sports, Cricket, etc.)
final selectedFilterProvider = StateProvider<String>((ref) => 'All Sports');

/// 🔍 Search query
final searchTurfProvider = StateProvider<String>((ref) => '');

/// 🔽 Bottom navigation index for Turf screen
final turfNavIndexProvider = StateProvider<int>((ref) => 1);

/// 🏟️ Turf Model
class TurfModel {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> sports;
  final String startTime;
  final String endTime;
  final bool isFavorite;

  TurfModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sports,
    required this.startTime,
    required this.endTime,
    this.isFavorite = false,
  });

  TurfModel copyWith({bool? isFavorite}) {
    return TurfModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      sports: sports,
      startTime: startTime,
      endTime: endTime,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// 🧠 Turf List Notifier
class TurfListNotifier extends StateNotifier<List<TurfModel>> {
  TurfListNotifier() : super([]);

  /// 🚀 Fetch turf data from Firestore
  Future<void> fetchTurfs() async {
    List<TurfModel> allTurfs = [];
    final firestore = FirebaseFirestore.instance;

    try {
      // ➕ Fetch Single Variant Turfs
      final singleSnapshot = await firestore.collection('single_variant').get();
      for (var doc in singleSnapshot.docs) {
        final data = doc.data();
        final turf = TurfModel(
          id: 'single_${doc.id}',
          name: data['turf_name'] ?? '',
          imageUrl: (data['images'] as List?)?.first ?? '',
          sports: [data['sport'] ?? ''],
          startTime: data['start_time'] ?? '',
          endTime: data['end_time'] ?? '',
        );
        allTurfs.add(turf);
      }

      // ➕ Fetch Multi Variant Turfs using turf_names array
      final multiSnapshot = await firestore.collection('multi_variant').get();

      for (var ownerDoc in multiSnapshot.docs) {
        final ownerId = ownerDoc.id;
        final ownerData = ownerDoc.data();

        final turfNames = List<String>.from(ownerData['turf_names'] ?? []);

        for (final turfName in turfNames) {
          final detailSnap = await firestore
              .collection('multi_variant')
              .doc(ownerId)
              .collection(turfName)
              .doc('details')
              .get();

          if (detailSnap.exists) {
            final data = detailSnap.data()!;
            final turf = TurfModel(
              id: 'multi_${ownerId}_$turfName',
              name: data['turf_name'] ?? '',
              imageUrl: (data['images'] as List?)?.first ?? '',
              sports: [data['sport'] ?? ''],
              startTime: data['start_time'] ?? '',
              endTime: data['end_time'] ?? '',
            );
            allTurfs.add(turf);
          }
        }
      }

      state = allTurfs;
    } catch (e) {
      print('🔥 Error fetching turfs: $e');
      state = []; // fallback to empty list
    }
  }

  /// ⭐ Toggle favorite status
  void toggleFavorite(String id) {
    state = [
      for (final turf in state)
        if (turf.id == id)
          turf.copyWith(isFavorite: !turf.isFavorite)
        else
          turf,
    ];
  }
}

/// 🌐 Expose Turf List Provider
final turfListProvider =
    StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
      return TurfListNotifier();
    });
