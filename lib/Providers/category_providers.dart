import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 3);

// Store match details
final matchDetailsProvider = Provider<List<Map<String, String>>>((ref) {
  return const [
    {
      'sport': 'Cricket',
      'turfName': 'Chennai Cricket Turf',
      'timing': '7pm - 9pm',
      'creator': 'Hari Haran S',
      'players': '2/11',
    },
    {
      'sport': 'Football',
      'turfName': 'Bangalore Football Arena',
      'timing': '6pm - 8pm',
      'creator': 'Akhil Raj',
      'players': '8/11',
    },
    {
      'sport': 'Volleyball',
      'turfName': 'Beach Volleyball Court',
      'timing': '5pm - 7pm',
      'creator': 'Divya Sharma',
      'players': '6/11',
    },
    {
      'sport': 'Badminton',
      'turfName': 'Smash Arena',
      'timing': '4pm - 6pm',
      'creator': 'Rahul Menon',
      'players': '4/6',
    },
    {
      'sport': 'Basketball',
      'turfName': 'Hoopers Court',
      'timing': '3pm - 5pm',
      'creator': 'Sneha Patel',
      'players': '5/10',
    },
  ];
});

// Store expanded state per card
final cardExpansionProvider =
StateProvider.family<bool, int>((ref, index) => false);
