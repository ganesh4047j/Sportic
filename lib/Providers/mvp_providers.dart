import 'package:flutter_riverpod/flutter_riverpod.dart';

// Turf Name
final turfNameProvider = StateProvider<String>((ref) => '');

// Game Type
final selectedGameProvider = StateProvider<String?>((ref) => null);

// Best Player Position
final selectedPositionProvider = StateProvider<String?>((ref) => null);
final mvpPointsProvider =
StateProvider<int>((ref) => 250); // Default points // Or your logic
final tabProvider = StateProvider<String>((ref) => "Recent");