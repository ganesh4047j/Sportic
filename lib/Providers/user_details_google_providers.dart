import 'package:flutter_riverpod/flutter_riverpod.dart';

final phoneProvider = StateProvider<String>((ref) => '');
final genderProvider = StateProvider<String?>((ref) => null);
