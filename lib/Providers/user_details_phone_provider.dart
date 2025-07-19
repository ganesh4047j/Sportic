// provider/user_details_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nameProvider = StateProvider<String>((ref) => '');
final emailProvider = StateProvider<String>((ref) => '');
final genderProvider = StateProvider<String?>((ref) => null);
