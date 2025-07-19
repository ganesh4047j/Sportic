import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether a team has been created or not
final isTeamCreatedProvider = StateProvider<bool>((ref) => false);

/// Stores the generated team code
final teamCodeProvider = StateProvider<String?>((ref) => null);

/// Represents individual team members
class TeamMember {
  final String name;
  final String avatarUrl;
  final PaymentStatus status;

  TeamMember({required this.name, this.avatarUrl = '', required this.status});
}

/// Enum to track payment status of members
enum PaymentStatus { paid, requested }

/// Team members list
final teamProvider = StateProvider<List<TeamMember>>(
  (ref) => [
    TeamMember(
      name: 'Godwin',
      avatarUrl: 'https://i.ibb.co/hRKvkpX/person.jpg',
      status: PaymentStatus.paid,
    ),
    for (int i = 0; i < 6; i++)
      TeamMember(name: 'waiting', status: PaymentStatus.requested),
  ],
);

/// Tracks how many players have joined
final playerCountProvider = StateProvider<int>((ref) => 1);

/// Total number of players required
final totalPlayersProvider = StateProvider<int>((ref) => 7);

/// Computes how many more players are needed
final needPlayersProvider = Provider<int>((ref) {
  final total = ref.watch(totalPlayersProvider);
  final joined = ref.watch(playerCountProvider);
  return total - joined;
});

/// Generates a random team code (e.g., "AB12CD")
String generateRandomTeamCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}
