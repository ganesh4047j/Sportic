import 'package:flutter/cupertino.dart';
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

    print('Fetching Single Variant turfs...');
    final singleSnapshot = await firestore.collection('single_variant').get();
    for (var doc in singleSnapshot.docs) {
      final data = doc.data();
      debugPrint('Single Turf Found: ${data['turf_name']}');

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

    debugPrint('Fetching Multi Variant turfs...');
    final multiSnapshot = await firestore.collection('multi_variant').get();
    for (var ownerDoc in multiSnapshot.docs) {
      final turfNames = List<String>.from(ownerDoc.data()['turf_names'] ?? []);
      debugPrint('Multi Variant Owner: ${ownerDoc.id}, Turf Names: $turfNames');

      for (final turfName in turfNames) {
        final detailsSnap = await firestore
            .collection('multi_variant')
            .doc(ownerDoc.id)
            .collection(turfName)
            .doc('details')
            .get();

        if (detailsSnap.exists) {
          final data = detailsSnap.data()!;
          debugPrint('Multi Turf Found: ${data['turf_name']}');

          final turf = TurfModel(
            id: 'multi_${ownerDoc.id}_$turfName',
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

    debugPrint('✅ Total turfs loaded: ${allTurfs.length}');
    for (var turf in allTurfs) {
      print(
        '🏟️ Turf: ${turf.name}, Sport: ${turf.sports}, Start: ${turf.startTime}',
      );
    }

    state = allTurfs;
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
