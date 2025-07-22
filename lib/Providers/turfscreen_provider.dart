// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// //
// // /// 🌍 User Location Provider
// // final userLocationProvider = StateProvider<String?>((ref) => null);
// //
// // /// 🏷️ Selected sport filter (like All Sports, Cricket, etc.)
// // final selectedFilterProvider = StateProvider<String>((ref) => 'All Sports');
// //
// // /// 🔍 Search query
// // final searchTurfProvider = StateProvider<String>((ref) => '');
// //
// // /// 🔽 Bottom navigation index for Turf screen
// // final turfNavIndexProvider = StateProvider<int>((ref) => 1);
// //
// // /// 🏟️ Turf Model
// // class TurfModel {
// //   final String id;
// //   final String name;
// //   final String imageUrl;
// //   final List<String> sports;
// //   final String startTime;
// //   final String endTime;
// //   final String location;
// //   final bool isFavorite;
// //
// //   TurfModel({
// //     required this.id,
// //     required this.name,
// //     required this.imageUrl,
// //     required this.sports,
// //     required this.startTime,
// //     required this.endTime,
// //     required this.location,
// //     this.isFavorite = false,
// //   });
// //
// //   TurfModel copyWith({bool? isFavorite}) {
// //     return TurfModel(
// //       id: id,
// //       name: name,
// //       imageUrl: imageUrl,
// //       sports: sports,
// //       startTime: startTime,
// //       endTime: endTime,
// //       location: location,
// //       isFavorite: isFavorite ?? this.isFavorite,
// //     );
// //   }
// // }
// //
// // /// 🧠 Turf List Notifier
// // class TurfListNotifier extends StateNotifier<List<TurfModel>> {
// //   TurfListNotifier() : super([]) {
// //     fetchTurfs();
// //   }
// //
// //   /// 🚀 Fetch turf data from Firestore
// //   Future<void> fetchTurfs() async {
// //     List<TurfModel> allTurfs = [];
// //     final firestore = FirebaseFirestore.instance;
// //
// //     try {
// //       // 🔹 Fetch Single Variant Turfs
// //       final singleSnapshot = await firestore.collection('single_variant').get();
// //       for (var doc in singleSnapshot.docs) {
// //         final data = doc.data();
// //         final turf = TurfModel(
// //           id: 'single_${doc.id}',
// //           name: data['turf_name'] ?? '',
// //           imageUrl: (data['images'] as List?)?.first ?? '',
// //           sports: [data['sport'] ?? ''],
// //           startTime: data['start_time'] ?? '',
// //           endTime: data['end_time'] ?? '',
// //           location: data['location'] ?? 'Unknown',
// //         );
// //         allTurfs.add(turf);
// //       }
// //
// //       // 🔹 Fetch Multi Variant Turfs
// //       final multiSnapshot = await firestore.collection('multi_variant').get();
// //
// //       final grouped = <String, List<QueryDocumentSnapshot>>{};
// //
// //       for (var doc in multiSnapshot.docs) {
// //         final data = doc.data();
// //         final turfName = data['turf_name'] ?? 'Unknown';
// //         grouped.putIfAbsent(turfName, () => []);
// //         grouped[turfName]!.add(doc);
// //       }
// //
// //       for (final entry in grouped.entries) {
// //         final turfName = entry.key;
// //         final variants = entry.value;
// //
// //         final sports = <String>{};
// //         String? imageUrl;
// //         String? startTime;
// //         String? endTime;
// //         String? location;
// //
// //         for (final doc in variants) {
// //           final data = doc.data() as Map<String, dynamic>?;
// //
// //           if (data != null) {
// //             // ✅ Handle sport field that might be either String or List
// //             final dynamic sportField = data['sports'] ?? data['sport'];
// //             if (sportField is List) {
// //               sports.addAll(List<String>.from(sportField));
// //             } else if (sportField is String) {
// //               sports.add(sportField);
// //             }
// //
// //             if ((data['images'] as List?)?.isNotEmpty ?? false) {
// //               imageUrl ??= (data['images'] as List).first;
// //             }
// //
// //             startTime ??= data['start_time'] as String?;
// //             endTime ??= data['end_time'] as String?;
// //             location ??= data['location'] as String?;
// //           }
// //         }
// //
// //         final turf = TurfModel(
// //           id: 'multi_$turfName',
// //           name: turfName,
// //           imageUrl: imageUrl ?? '',
// //           sports: sports.toList(),
// //           startTime: startTime ?? '',
// //           endTime: endTime ?? '',
// //           location: location ?? 'Unknown',
// //         );
// //
// //         print('✅ Multi Turf Loaded: ${turf.name} | Sports: ${turf.sports}');
// //         allTurfs.add(turf);
// //       }
// //
// //       state = allTurfs;
// //     } catch (e) {
// //       print('🔥 Error fetching turfs: $e');
// //       state = [];
// //     }
// //   }
// //
// //   /// ⭐ Toggle favorite status
// //   void toggleFavorite(String id) {
// //     state = [
// //       for (final turf in state)
// //         if (turf.id == id)
// //           turf.copyWith(isFavorite: !turf.isFavorite)
// //         else
// //           turf,
// //     ];
// //   }
// // }
// //
// // /// 🌐 Expose Turf List Provider
// // final turfListProvider =
// // StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
// //   return TurfListNotifier();
// // });
// //
// // /// 🎯 Filtered Turf List based on selected sport AND location
// // final filteredTurfListProvider = Provider<List<TurfModel>>((ref) {
// //   final allTurfs = ref.watch(turfListProvider);
// //   final selectedFilter = ref.watch(selectedFilterProvider);
// //   final selectedLocation = ref.watch(userLocationProvider);
// //
// //   return allTurfs.where((turf) {
// //     final matchSport = selectedFilter == 'All Sports' ||
// //         turf.sports.any(
// //                 (sport) => sport.toLowerCase() == selectedFilter.toLowerCase());
// //
// //     final matchLocation = selectedLocation == null ||
// //         turf.location.toLowerCase() == selectedLocation.toLowerCase();
// //
// //     return matchSport && matchLocation;
// //   }).toList();
// // });
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// /// 🌍 User Location Provider
// final userLocationProvider = StateProvider<String?>((ref) => null);
//
// /// 🏷️ Selected sport filter (like All Sports, Cricket, etc.)
// final selectedFilterProvider = StateProvider<String>((ref) => 'All Sports');
//
// /// 🔍 Search query
// final searchTurfProvider = StateProvider<String>((ref) => '');
//
// /// 🔽 Bottom navigation index for Turf screen
// final turfNavIndexProvider = StateProvider<int>((ref) => 1);
//
// /// 🏟️ Turf Model for single sport display
// class TurfModel {
//
//   final String id;
//   final String name;
//   final String imageUrl;
//   final String sport;
//   final String startTime;
//   final String endTime;
//   final String location;
//   final bool isFavorite;
//
//   TurfModel({
//     required this.id,
//     required this.name,
//     required this.imageUrl,
//     required this.sport,
//     required this.startTime,
//     required this.endTime,
//     required this.location,
//     this.isFavorite = false,
//   });
//
//   TurfModel copyWith({bool? isFavorite}) {
//     return TurfModel(
//       id: id,
//       name: name,
//       imageUrl: imageUrl,
//       sport: sport,
//       startTime: startTime,
//       endTime: endTime,
//       location: location,
//       isFavorite: isFavorite ?? this.isFavorite,
//     );
//   }
// }
//
// /// 🧠 Turf List Notifier
// class TurfListNotifier extends StateNotifier<List<TurfModel>> {
//   TurfListNotifier() : super([]) {
//     fetchTurfs();
//   }
//
//   /// 🚀 Fetch turf data from Firestore
//   Future<void> fetchTurfs() async {
//     List<TurfModel> allTurfs = [];
//     final firestore = FirebaseFirestore.instance;
//
//     try {
//       // 🔹 Fetch Single Variant Turfs
//       final singleSnapshot = await firestore.collection('single_variant').get();
//       for (var doc in singleSnapshot.docs) {
//         final data = doc.data();
//         final turf = TurfModel(
//           id: 'single_${doc.id}',
//           name: data['turf_name'] ?? '',
//           imageUrl: (data['images'] as List?)?.first ?? '',
//           sport: data['sport'] ?? '',
//           startTime: data['start_time'] ?? '',
//           endTime: data['end_time'] ?? '',
//           location: data['location'] ?? 'Unknown',
//         );
//         allTurfs.add(turf);
//       }
//
//       // 🔹 Fetch Multi Variant Turfs (each variant becomes one TurfModel entry)
//       final multiSnapshot = await firestore.collection('multi_variant').get();
//       for (var doc in multiSnapshot.docs) {
//         final data = doc.data();
//         final turfName = data['turf_name'] ?? 'Unknown';
//         final images = (data['images'] as List?) ?? [];
//         final imageUrl = images.isNotEmpty ? images.first : '';
//         final startTime = data['start_time'] ?? '';
//         final endTime = data['end_time'] ?? '';
//         final location = data['location'] ?? 'Unknown';
//
//         final dynamic sportField = data['sports'] ?? data['sport'];
//         List<String> sports = [];
//
//         if (sportField is List) {
//           sports = List<String>.from(sportField);
//         } else if (sportField is String) {
//           sports = [sportField];
//         }
//
//         for (final sport in sports) {
//           final turf = TurfModel(
//             id: 'multi_${doc.id}_$sport',
//             name: turfName,
//             imageUrl: imageUrl,
//             sport: sport,
//             startTime: startTime,
//             endTime: endTime,
//             location: location,
//           );
//
//           allTurfs.add(turf);
//         }
//       }
//
//       state = allTurfs;
//     } catch (e) {
//       print('🔥 Error fetching turfs: $e');
//       state = [];
//     }
//   }
//
//   /// ⭐ Toggle favorite status
//   void toggleFavorite(String id) {
//     state = [
//       for (final turf in state)
//         if (turf.id == id)
//           turf.copyWith(isFavorite: !turf.isFavorite)
//         else
//           turf,
//     ];
//   }
// }
//
// /// 🌐 Expose Turf List Provider
// final turfListProvider =
// StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
//   return TurfListNotifier();
// });
//
// /// 🎯 Filtered Turf List based on selected sport AND location
// final filteredTurfListProvider = Provider<List<TurfModel>>((ref) {
//   final allTurfs = ref.watch(turfListProvider);
//   final selectedFilter = ref.watch(selectedFilterProvider);
//   final selectedLocation = ref.watch(userLocationProvider);
//
//   return allTurfs.where((turf) {
//     final matchSport = selectedFilter == 'All Sports' ||
//         turf.sport.toLowerCase() == selectedFilter.toLowerCase();
//
//     final matchLocation = selectedLocation == null ||
//         turf.location.toLowerCase() == selectedLocation.toLowerCase();
//
//     return matchSport && matchLocation;
//   }).toList();
// });
// final nearestTurfProvider = Provider<List<TurfModel>>((ref) {
//   final allTurfs = ref.watch(turfListProvider);
//   final selectedLocation = ref.watch(userLocationProvider);
//
//   if (selectedLocation == null || selectedLocation.isEmpty) {
//     return [];
//   }
//
//   // Match turfs exactly or loosely (ignore case)
//   final nearestTurfs = allTurfs.where((turf) =>
//       turf.location.toLowerCase().contains(selectedLocation.toLowerCase())).toList();
//
//   return nearestTurfs;
// });
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
  final String sport;
  final String startTime;
  final String endTime;
  final String location;
  final bool isFavorite;

  TurfModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sport,
    required this.startTime,
    required this.endTime,
    required this.location,
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
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory TurfModel.fromMap(String id, Map<String, dynamic> data, String? variant) {
    final dynamic sportField = data['sports'] ?? data['sport'];
    final List<String> sports = sportField is List
        ? List<String>.from(sportField)
        : [sportField?.toString() ?? ''];

    final images = (data['images'] as List?) ?? [];

    return TurfModel(
      id: '${variant ?? 'single'}_$id',
      name: data['turf_name'] ?? '',
      imageUrl: images.isNotEmpty ? images.first : '',
      sport: sports.first,
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      location: data['location'] ?? 'Unknown',
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
      final singleSnapshot = await firestore.collection('single_variant').get();
      for (var doc in singleSnapshot.docs) {
        final data = doc.data();
        allTurfs.add(TurfModel.fromMap(doc.id, data, 'single'));
      }

      final multiSnapshot = await firestore.collection('multi_variant').get();
      for (var doc in multiSnapshot.docs) {
        final data = doc.data();
        final dynamic sportField = data['sports'] ?? data['sport'];
        final List<String> sports = sportField is List
            ? List<String>.from(sportField)
            : [sportField?.toString() ?? ''];

        for (final sport in sports) {
          final turf = TurfModel(
            id: 'multi_${doc.id}_$sport',
            name: data['turf_name'] ?? '',
            imageUrl: (data['images'] as List?)?.first ?? '',
            sport: sport,
            startTime: data['start_time'] ?? '',
            endTime: data['end_time'] ?? '',
            location: data['location'] ?? 'Unknown',
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

/// 🌐 All Turfs
// final turfListProvider =
// StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
//   return TurfListNotifier();
// });
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
    final matchSport = selectedFilter == 'All Sports' ||
        turf.sport.toLowerCase() == selectedFilter.toLowerCase();

    final matchLocation = selectedLocation == null ||
        turf.location.toLowerCase() == selectedLocation.toLowerCase();

    return matchSport && matchLocation;
  }).toList();
});

/// 📍 Nearest turfs based only on location
// final nearestTurfProvider = Provider<List<TurfModel>>((ref) {
//   final allTurfs = ref.watch(turfListProvider);
//   final selectedLocation = ref.watch(userLocationProvider);
//
//   if (selectedLocation == null || selectedLocation.isEmpty) return [];
//
//   return allTurfs.where((turf) =>
//       turf.location.toLowerCase().contains(selectedLocation.toLowerCase())).toList();
// });
final nearestTurfProvider = Provider<List<TurfModel>>((ref) {
  final allTurfs = ref.watch(turfListProvider);
  final selectedLocation = ref.watch(userLocationProvider);

  print('📍 User selected location: $selectedLocation');

  if (selectedLocation == null) return [];

  final nearestTurfs = allTurfs.where((turf) {
    print('📌 Checking turf: ${turf.name}, Location: ${turf.location}');
    final match = turf.location.toLowerCase().contains(selectedLocation.toLowerCase());
    print('➡️ Match result: $match');
    return match;
  }).toList();

  print('✅ Nearest Turfs Found: ${nearestTurfs.length}');
  return nearestTurfs;
});
