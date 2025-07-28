import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Main Screens/profile.dart';

/// 🌍 User Location Provider
final userLocationProvider = StateProvider<String?>((ref) => null);

/// 🏷 Selected sport filter (like All Sports, Cricket, etc.)
final selectedFilterProvider = StateProvider<String>((ref) => 'All Sports');

/// 🔍 Search query
final searchTurfProvider = StateProvider<String>((ref) => '');

/// 🔽 Bottom navigation index for Turf screen
final turfNavIndexProvider = StateProvider<int>((ref) => 3);

/// 🏟 Turf Model
class TurfModel {
  final String id;
  final String name;
  final String imageUrl;
  final String sport;
  final String startTime;
  final String endTime;
  final String location;
  final String ownerId;
  final bool isFavorite;

  TurfModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sport,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.ownerId,
    this.isFavorite = false,
  });

  TurfModel copyWith({bool? isFavorite}) {
    return TurfModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      sport: sport,
      startTime: startTime,
      endTime: endTime,
      location: location,
      ownerId: ownerId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory TurfModel.fromMap(
    String id,
    Map<String, dynamic> data,
    String? variant,
  ) {
    final dynamic sportField = data['sports'] ?? data['sport'];
    final List<String> sports =
        sportField is List
            ? List<String>.from(sportField)
            : [sportField?.toString() ?? ''];

    final images = (data['images'] as List?) ?? [];

    return TurfModel(
      id: '${variant ?? 'single'}_$id',
      name: data['turf_name'] ?? '',
      imageUrl:
          images.isNotEmpty
              ? images.first
              : 'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
      sport: sports.first,
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      location: data['location'] ?? 'Unknown',
      ownerId: data['ownerId']! ?? '',
    );
  }
}

/// 🧠 Turf List Notifier
class TurfListNotifier extends StateNotifier<List<TurfModel>> {
  TurfListNotifier() : super([]) {
    fetchTurfs();
  }

  Future<void> fetchTurfs() async {
    final List<TurfModel> allTurfs = [];
    final firestore = FirebaseFirestore.instance;

    try {
      final multiSnapshot = await firestore.collection('multi_variant').get();
      for (var doc in multiSnapshot.docs) {
        final data = doc.data();
        final dynamic sportField = data['sports'] ?? data['sport'];
        final List<String> sports =
            sportField is List
                ? List<String>.from(sportField)
                : [sportField?.toString() ?? ''];

        for (final sport in sports) {
          final turf = TurfModel(
            id: 'multi_${doc.id}_$sport',
            name: data['turf_name'] ?? '',
            imageUrl:
                (data['images'] as List?)?.first ??
                'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
            sport: sport,
            startTime: data['start_time'] ?? '',
            endTime: data['end_time'] ?? '',
            location: data['location'] ?? 'Unknown',
            ownerId: data['ownerId']! ?? '',
          );
          allTurfs.add(turf);
        }
      }

      state = allTurfs;
    } catch (e) {
      print('🔥 Error fetching turfs: $e');
      state = [];
    }
  }

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

final turfListProvider =
    StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
      return TurfListNotifier();
    });

/// 🎯 Filtered Turfs based on location & selected sport
final filteredTurfListProvider = Provider<List<TurfModel>>((ref) {
  final allTurfs = ref.watch(turfListProvider);
  final selectedFilter = ref.watch(selectedFilterProvider);
  final selectedLocation = ref.watch(userLocationProvider);

  return allTurfs.where((turf) {
    final matchSport =
        selectedFilter == 'All Sports' ||
        turf.sport.toLowerCase() == selectedFilter.toLowerCase();

    final matchLocation =
        selectedLocation == null ||
        turf.location.toLowerCase() == selectedLocation.toLowerCase();

    return matchSport && matchLocation;
  }).toList();
});

/// 📍 Nearest turfs based only on location

final nearestTurfProvider = Provider<List<Map<String, String>>>((ref) {
  final turfList = ref.watch(turfListProvider);
  final userProfile = ref.watch(userProfileProvider);
  final selectedLocation = ref.watch(userLocationProvider); // manual override

  // fallback logic for location
  String? location;

  // Priority: manually selected > stored in Firestore > null
  userProfile.whenOrNull(
    data: (profile) {
      location = selectedLocation ?? profile['location'];
    },
  );

  if (location == null || location!.isEmpty) return [];

  final filteredTurfs =
      turfList
          .where((turf) {
            return turf.location.toLowerCase().contains(
              location!.toLowerCase(),
            );
          })
          .map((turf) {
            return {
              'name': turf.name,
              'imageUrl':
                  turf.imageUrl.isNotEmpty
                      ? turf.imageUrl
                      : 'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
              'location': turf.location,
              'ownerId': turf.ownerId,
            };
          })
          .toList();

  return filteredTurfs;
});
