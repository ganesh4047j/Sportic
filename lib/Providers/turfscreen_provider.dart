import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Main Screens/profile.dart';
import '../Services/user_utils.dart';

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
  final String managerName;
  final String managerNumber;
  final String acquisition;
  final String imageUrl;
  final String sport;
  final String startTime;
  final String endTime;
  final String location;
  final String ownerId;
  final bool isFavorite;
  final String weekdayDayTime;
  final String weekdayNightTime;
  final String weekendDayTime;
  final String weekendNightTime;

  TurfModel({
    required this.id,
    required this.name,
    required this.managerName,
    required this.managerNumber,
    required this.acquisition,
    required this.imageUrl,
    required this.sport,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.ownerId,
    this.isFavorite = false,
    required this.weekdayDayTime,
    required this.weekdayNightTime,
    required this.weekendDayTime,
    required this.weekendNightTime,
  });

  TurfModel copyWith({bool? isFavorite}) {
    return TurfModel(
      id: id,
      name: name,
      managerName: managerName,
      managerNumber: managerNumber,
      acquisition: acquisition,
      imageUrl: imageUrl,
      sport: sport,
      startTime: startTime,
      endTime: endTime,
      location: location,
      ownerId: ownerId,
      isFavorite: isFavorite ?? this.isFavorite,
      weekdayDayTime: weekdayDayTime,
      weekdayNightTime: weekdayNightTime,
      weekendDayTime: weekendDayTime,
      weekendNightTime: weekendNightTime,
    );
  }

  // Convert TurfModel to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'turf_name': name,
      'imageUrl': imageUrl,
      'manager_name': managerName,
      'manager_number': managerNumber,
      'acquisition': acquisition,
      'sport': sport,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'ownerId': ownerId,
      'weekday_amounts': {
        'day_time': weekdayDayTime,
        'night_time': weekdayNightTime,
      },
      'weekend_amounts': {
        'day_time': weekendDayTime,
        'night_time': weekendNightTime,
      },
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TurfModel.fromMap(
    String id,
    Map<String, dynamic> data,
    String? variant,
  ) {
    print('🔍 Creating TurfModel from data: $data'); // Debug print

    final dynamic sportField = data['sports'] ?? data['sport'];
    final List<String> sports =
        sportField is List
            ? List<String>.from(sportField)
            : [sportField?.toString() ?? ''];

    final images = (data['images'] as List?) ?? [];

    final weekdayAmounts =
        data['weekday_amounts'] as Map<String, dynamic>? ?? {};
    final weekendAmounts =
        data['weekend_amounts'] as Map<String, dynamic>? ?? {};

    final turf = TurfModel(
      id: '${variant ?? 'single'}_$id',
      name: data['turf_name'] ?? '',
      managerName: data['manager_name'],
      managerNumber: data['manager_number'],
      acquisition: data['acquisition'],
      imageUrl:
          images.isNotEmpty
              ? images.first
              : 'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
      sport: sports.first,
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      location: data['location'] ?? 'Unknown',
      ownerId: data['ownerId'] ?? '',
      weekdayDayTime: weekdayAmounts['day_time']?.toString() ?? '0',
      weekdayNightTime: weekdayAmounts['night_time']?.toString() ?? '0',
      weekendDayTime: weekendAmounts['day_time']?.toString() ?? '0',
      weekendNightTime: weekendAmounts['night_time']?.toString() ?? '0',
    );

    print(
      '✅ Created turf: ${turf.name} - ${turf.sport} - ${turf.location}',
    ); // Debug print

    print(
      '💰 Pricing - Weekday: Day(${turf.weekdayDayTime}), Night(${turf.weekdayNightTime})',
    );
    print(
      '💰 Pricing - Weekend: Day(${turf.weekendDayTime}), Night(${turf.weekendNightTime})',
    );

    return turf;
  }
}

/// 🧠 Turf List Notifier
class TurfListNotifier extends StateNotifier<List<TurfModel>> {
  final Ref ref;

  TurfListNotifier(this.ref) : super([]) {
    fetchTurfs();
  }

  Future<void> fetchTurfs() async {
    print('🚀 Starting to fetch turfs...'); // Debug print

    final List<TurfModel> allTurfs = [];
    final firestore = FirebaseFirestore.instance;

    try {
      // Check if multi_variant collection exists
      print('📡 Fetching from multi_variant collection...');
      final multiSnapshot = await firestore.collection('multi_variant').get();

      print(
        '📊 Found ${multiSnapshot.docs.length} documents in multi_variant',
      ); // Debug print

      if (multiSnapshot.docs.isEmpty) {
        print('⚠️ No documents found in multi_variant collection');

        // Try alternative collection names
        await _tryAlternativeCollections(firestore, allTurfs);
      } else {
        for (var doc in multiSnapshot.docs) {
          print('📄 Processing document: ${doc.id}'); // Debug print

          final data = doc.data();
          print('📋 Document data: $data'); // Debug print

          final dynamic sportField = data['sports'] ?? data['sport'];
          final List<String> sports =
              sportField is List
                  ? List<String>.from(sportField)
                  : [sportField?.toString() ?? 'Unknown Sport'];

          print('🏅 Sports found: $sports'); // Debug print

          final weekdayAmounts =
              data['weekday_amounts'] as Map<String, dynamic>? ?? {};
          final weekendAmounts =
              data['weekend_amounts'] as Map<String, dynamic>? ?? {};

          for (final sport in sports) {
            final turf = TurfModel(
              id: 'multi_${doc.id}_$sport',
              name: data['turf_name'] ?? 'Unknown Turf',
              managerName: data['manager_name'],
              managerNumber: data['manager_number'],
              acquisition: data['acquisition'],
              imageUrl:
                  (data['images'] as List?)?.first ??
                  'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
              sport: sport,
              startTime: data['start_time'] ?? '09:00',
              endTime: data['end_time'] ?? '10:00',
              location: data['location'] ?? 'Unknown Location',
              ownerId: data['ownerId'] ?? '',
              weekdayDayTime: weekdayAmounts['day_time']?.toString() ?? '0',
              weekdayNightTime: weekdayAmounts['night_time']?.toString() ?? '0',
              weekendDayTime: weekendAmounts['day_time']?.toString() ?? '0',
              weekendNightTime: weekendAmounts['night_time']?.toString() ?? '0',
            );
            allTurfs.add(turf);
            print('➕ Added turf: ${turf.name}'); // Debug print
            print(
              '💰 Pricing - Weekday: Day(${turf.weekdayDayTime}), Night(${turf.weekdayNightTime})',
            );
            print(
              '💰 Pricing - Weekend: Day(${turf.weekendDayTime}), Night(${turf.weekendNightTime})',
            );
          }
        }
      }

      print('📈 Total turfs collected: ${allTurfs.length}'); // Debug print

      // Load favorites status for current user
      await _loadFavoritesStatus(allTurfs);

      state = allTurfs;
      print(
        '✅ Successfully set state with ${allTurfs.length} turfs',
      ); // Debug print
    } catch (e) {
      print('🔥 Error fetching turfs: $e');
      print('Stack trace: ${StackTrace.current}'); // Debug stack trace

      // Set empty state but don't fail silently
      state = [];
    }
  }

  /// Try alternative collection names if multi_variant doesn't exist
  Future<void> _tryAlternativeCollections(
    FirebaseFirestore firestore,
    List<TurfModel> allTurfs,
  ) async {
    final alternativeCollections = [
      'turfs',
      'turf_details',
      'sports_turfs',
      'venues',
      'single_variant',
    ];

    for (String collectionName in alternativeCollections) {
      try {
        print('🔍 Trying collection: $collectionName');
        final snapshot = await firestore.collection(collectionName).get();

        if (snapshot.docs.isNotEmpty) {
          print('✅ Found ${snapshot.docs.length} documents in $collectionName');

          for (var doc in snapshot.docs) {
            final data = doc.data();
            print('📋 Document data from $collectionName: $data');

            // Try to create turf from this data
            try {
              final turf = TurfModel.fromMap(doc.id, data, collectionName);
              allTurfs.add(turf);
            } catch (e) {
              print('⚠️ Could not create turf from document ${doc.id}: $e');
            }
          }
          break; // Stop trying other collections if we found data
        }
      } catch (e) {
        print('❌ Error accessing collection $collectionName: $e');
        continue;
      }
    }

    if (allTurfs.isEmpty) {
      print('❌ No turf data found in any collection');
      await _createSampleData(firestore);
    }
  }

  /// Create sample data for testing
  Future<void> _createSampleData(FirebaseFirestore firestore) async {
    print('🔧 Creating sample data...');

    try {
      await firestore.collection('multi_variant').doc('sample_turf_1').set({
        'turf_name': 'Sample Cricket Ground',
        'sports': ['Cricket', 'Football'],
        'images': ['https://example.com/sample1.jpg'],
        'location': 'K.K. Nagar',
        'start_time': '06:00',
        'end_time': '23:00',
        'ownerId': 'sample_owner_1',
      });

      await firestore.collection('multi_variant').doc('sample_turf_2').set({
        'turf_name': 'Elite Sports Arena',
        'sports': ['Badminton', 'Tennis'],
        'images': ['https://example.com/sample2.jpg'],
        'location': 'K.K. Nagar',
        'start_time': '05:00',
        'end_time': '22:00',
        'ownerId': 'sample_owner_2',
      });

      print('✅ Sample data created successfully');

      // Refresh data
      await fetchTurfs();
    } catch (e) {
      print('🔥 Error creating sample data: $e');
    }
  }

  /// Load favorites status from Firestore
  Future<void> _loadFavoritesStatus(List<TurfModel> turfs) async {
    try {
      print('❤️ Loading favorites status...'); // Debug print

      // Get user ID using your existing user utils
      final userIdAsync = await ref.read(currentUserIdProvider.future);

      if (userIdAsync == null) {
        print('⚠️ No user ID available for favorites');
        return;
      }

      print('👤 Loading favorites for user: $userIdAsync'); // Debug print

      final favoritesSnapshot =
          await FirebaseFirestore.instance
              .collection('favourites')
              .doc(userIdAsync)
              .collection('user_favourites')
              .get();

      final favoriteIds = favoritesSnapshot.docs.map((doc) => doc.id).toSet();
      print(
        '❤️ Found ${favoriteIds.length} favorites: $favoriteIds',
      ); // Debug print

      for (int i = 0; i < turfs.length; i++) {
        if (favoriteIds.contains(turfs[i].id)) {
          turfs[i] = turfs[i].copyWith(isFavorite: true);
          print('💖 Marked ${turfs[i].name} as favorite'); // Debug print
        }
      }
    } catch (e) {
      print('🔥 Error loading favorites: $e');
    }
  }

  /// Toggle favorite status and update Firestore
  Future<void> toggleFavorite(String turfId) async {
    try {
      print('❤️ Toggling favorite for turf: $turfId'); // Debug print

      // Find the turf in current state
      final turfIndex = state.indexWhere((turf) => turf.id == turfId);
      if (turfIndex == -1) {
        print('❌ Turf not found in state: $turfId');
        return;
      }

      final turf = state[turfIndex];
      final newFavoriteStatus = !turf.isFavorite;

      // Update local state first for immediate UI feedback
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == turfIndex)
            state[i].copyWith(isFavorite: newFavoriteStatus)
          else
            state[i],
      ];

      // Get user ID using your existing user utils
      final userId = await ref.read(currentUserIdProvider.future);

      if (userId == null) {
        print('❌ User not authenticated');
        throw Exception('User not authenticated');
      }

      print('✅ Using user ID: $userId');

      // Reference to user's favorites subcollection
      final favoritesCollection = FirebaseFirestore.instance
          .collection('favourites')
          .doc(userId)
          .collection('user_favourites');

      if (newFavoriteStatus) {
        // Add to favorites - create subcollection with turf ID as document ID
        await favoritesCollection.doc(turf.id).set(turf.toMap());
        print('✅ Added ${turf.name} to favorites');
      } else {
        // Remove from favorites - delete the subcollection document
        await favoritesCollection.doc(turf.id).delete();
        print('🗑️ Removed ${turf.name} from favorites');
      }
    } catch (e) {
      print('🔥 Error toggling favorite: $e');
      print('Stack trace: ${StackTrace.current}'); // Debug stack trace

      // Revert state on error
      state = [
        for (final turf in state)
          if (turf.id == turfId)
            turf.copyWith(isFavorite: !turf.isFavorite)
          else
            turf,
      ];
      rethrow; // Re-throw to let UI handle the error
    }
  }
}

final turfListProvider =
    StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
      return TurfListNotifier(ref);
    });

/// 🎯 Filtered Turfs based on location & selected sport
final filteredTurfListProvider = Provider<List<TurfModel>>((ref) {
  final allTurfs = ref.watch(turfListProvider);
  final selectedFilter = ref.watch(selectedFilterProvider);

  print('🔍 Filtering turfs: ${allTurfs.length} total'); // Debug print
  print('🏅 Selected filter: $selectedFilter'); // Debug print

  final filtered =
      allTurfs.where((turf) {
        final matchSport =
            selectedFilter == 'All Sports' ||
            turf.sport.toLowerCase() == selectedFilter.toLowerCase();

        print('🏟 Turf: ${turf.name}, Sport: ${turf.sport}');
        print('   Sport match: $matchSport');

        return matchSport;
      }).toList();

  print('✅ Filtered result: ${filtered.length} turfs'); // Debug print

  return filtered;
});

/// 📍 Nearest turfs based only on location
final nearestTurfProvider = Provider<List<Map<String, String>>>((ref) {
  final turfList = ref.watch(turfListProvider);
  final userProfile = ref.watch(userProfileProvider);
  final selectedLocation = ref.watch(userLocationProvider);

  String? location;

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
              'manager_name': turf.managerName,
              'manager_number': turf.managerNumber,
              'acquisition': turf.acquisition,
            };
          })
          .toList();

  return filteredTurfs;
});

/// 🔥 Provider to get user's favorite turfs
final userFavoriteTurfsProvider = StreamProvider<List<TurfModel>>((ref) async* {
  try {
    // Get user ID using your existing user utils
    final userId = await ref.watch(currentUserIdProvider.future);

    if (userId == null) {
      yield [];
      return;
    }

    yield* FirebaseFirestore.instance
        .collection('favourites')
        .doc(userId)
        .collection('user_favourites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            final weekdayAmounts =
                data['weekday_amounts'] as Map<String, dynamic>? ?? {};
            final weekendAmounts =
                data['weekend_amounts'] as Map<String, dynamic>? ?? {};

            return TurfModel(
              id: data['id'] ?? doc.id,
              name: data['turf_name'] ?? '',
              managerName: data['manager_name'] ?? '',
              managerNumber: data['manager_number'] ?? '',
              acquisition: data['acquisition'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              sport: data['sport'] ?? '',
              startTime: data['start_time'] ?? '',
              endTime: data['end_time'] ?? '',
              location: data['location'] ?? '',
              ownerId: data['ownerId'] ?? '',
              isFavorite:
                  true, // Always true since it's in favorites collection
              weekdayDayTime: weekdayAmounts['day_time']?.toString() ?? '0',
              weekdayNightTime: weekdayAmounts['night_time']?.toString() ?? '0',
              weekendDayTime: weekendAmounts['day_time']?.toString() ?? '0',
              weekendNightTime: weekendAmounts['night_time']?.toString() ?? '0',
            );
          }).toList();
        });
  } catch (e) {
    print('🔥 Error in userFavoriteTurfsProvider: $e');
    yield [];
  }
});
