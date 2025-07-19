import 'package:flutter_riverpod/flutter_riverpod.dart';

// State provider to hold the selected MVP player name
final selectedMvpProvider = StateProvider<String?>((ref) => null);