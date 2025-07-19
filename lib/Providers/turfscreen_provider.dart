import 'package:flutter_riverpod/flutter_riverpod.dart';

final userLocationProvider = StateProvider<String?>((ref) => null);

/// Selected sport filter (like All Sports, Cricket, etc.)
final selectedFilterProvider = StateProvider<String>((ref) => 'All Sports');

/// Currently selected user location (default is 'Trichy')
//final userLocationProvider = StateProvider<String?>((ref) => 'Trichy');

/// Bottom navigation bar index for Turf screen
final turfNavIndexProvider = StateProvider<int>((ref) => 1);

/// Turf model representing each turf card
class TurfModel {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> sports;
  final bool isFavorite;

  TurfModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sports,
    this.isFavorite = false,
  });

  /// Clone turf with updated favorite status
  TurfModel copyWith({bool? isFavorite}) {
    return TurfModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      sports: sports,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// StateNotifier to manage the list of turfs
class TurfListNotifier extends StateNotifier<List<TurfModel>> {
  TurfListNotifier()
    : super([
        TurfModel(
          id: '1',
          name: 'Turf name 1',
          imageUrl:
              'https://static.vecteezy.com/system/resources/previews/044/547/673/non_2x/lawn-on-a-football-field-photo.jpeg',
          sports: ['Badminton', 'Box Cricket', 'Cricket', 'Football', 'Tennis'],
        ),
        TurfModel(
          id: '2',
          name: 'Turf name 2',
          imageUrl:
              'https://static.vecteezy.com/system/resources/previews/044/547/673/non_2x/lawn-on-a-football-field-photo.jpeg',
          sports: ['Badminton', 'Box Cricket', 'Cricket', 'Football', 'Tennis'],
        ),
        TurfModel(
          id: '3',
          name: 'Turf name 3',
          imageUrl:
              'https://static.vecteezy.com/system/resources/previews/044/547/673/non_2x/lawn-on-a-football-field-photo.jpeg',
          sports: ['Badminton', 'Box Cricket', 'Cricket', 'Football', 'Tennis'],
        ),
      ]);

  /// Toggle favorite status for a turf
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

/// Provider to expose the list of turfs
final turfListProvider =
    StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
      return TurfListNotifier();
    });
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// /// 🌍 Persistent User Location Provider
// final userLocationProvider =
// StateNotifierProvider<UserLocationNotifier, String?>((ref) {
//   return UserLocationNotifier();
// });
//
// class UserLocationNotifier extends StateNotifier<String?> {
//   UserLocationNotifier() : super(null) {
//     _loadInitialLocation();
//   }
//
//   Future<void> _loadInitialLocation() async {
//     final prefs = await SharedPreferences.getInstance();
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//
//     if (uid != null) {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('user_details_phone')
//           .doc(uid)
//           .get();
//
//       final locationFromFirestore = snapshot.data()?['location'] as String?;
//       state = locationFromFirestore ?? 'Unknown';
//       await prefs.setString('user_location', state!);
//     } else {
//       state = prefs.getString('user_location') ?? 'Unknown';
//     }
//   }
//
//   Future<void> setLocation(String newLocation) async {
//     final prefs = await SharedPreferences.getInstance();
//     state = newLocation;
//     await prefs.setString('user_location', newLocation);
//
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid != null) {
//       await FirebaseFirestore.instance
//           .collection('user_details_phone')
//           .doc(uid)
//           .update({'location': newLocation});
//     }
//   }
// }
//
// /// Selected sport filter
// final selectedFilterProvider = StateProvider<String>((ref) => 'All Sports');
//
// /// Bottom nav index
// final turfNavIndexProvider = StateProvider<int>((ref) => 1);
//
// /// Turf model
// class TurfModel {
//   final String id;
//   final String name;
//   final String imageUrl;
//   final List<String> sports;
//   final bool isFavorite;
//
//   TurfModel({
//     required this.id,
//     required this.name,
//     required this.imageUrl,
//     required this.sports,
//     this.isFavorite = false,
//   });
//
//   TurfModel copyWith({bool? isFavorite}) {
//     return TurfModel(
//       id: id,
//       name: name,
//       imageUrl: imageUrl,
//       sports: sports,
//       isFavorite: isFavorite ?? this.isFavorite,
//     );
//   }
// }
//
// /// Turf list notifier
// class TurfListNotifier extends StateNotifier<List<TurfModel>> {
//   TurfListNotifier()
//       : super([
//     TurfModel(
//       id: '1',
//       name: 'Turf name 1',
//       imageUrl:
//       'https://static.vecteezy.com/system/resources/previews/044/547/673/non_2x/lawn-on-a-football-field-photo.jpeg',
//       sports: ['Cricket', 'Football', 'Tennis'],
//     ),
//     TurfModel(
//       id: '2',
//       name: 'Turf name 2',
//       imageUrl:
//       'https://static.vecteezy.com/system/resources/previews/044/547/673/non_2x/lawn-on-a-football-field-photo.jpeg',
//       sports: ['Badminton', 'Football'],
//     ),
//   ]);
//
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
// final turfListProvider =
// StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
//   return TurfListNotifier();
// });
