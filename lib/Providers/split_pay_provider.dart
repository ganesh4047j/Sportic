import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider to store selected team data from join team screen
final selectedTeamProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

/// Provider to store current user data (implement with your authentication system)
final currentUserProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => {
    'name': 'Current User', // Replace with actual user data from auth
    'user_id': 'current_user_id', // Replace with actual user ID from auth
    'avatar_url':
        'https://i.pravatar.cc/150?img=1', // Replace with actual avatar
    'email': 'user@example.com', // Replace with actual email
    'phone': '9876543210', // Replace with actual phone
  },
);

/// Stream provider for real-time team updates
final teamStreamProvider = StreamProvider.family<DocumentSnapshot?, String>((
  ref,
  teamId,
) {
  if (teamId.isEmpty) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('created_team')
      .doc(teamId)
      .snapshots();
});

/// Provider to compute joined players count from team data
final joinedPlayersCountProvider = Provider.family<int, Map<String, dynamic>?>((
  ref,
  teamData,
) {
  if (teamData == null) return 0;

  int count = 1; // Creator is always counted
  if (teamData['joined_players'] is List) {
    count += (teamData['joined_players'] as List).length;
  }
  return count;
});

/// Provider to compute needed players count from team data
final needPlayersCountProvider = Provider.family<int, Map<String, dynamic>?>((
  ref,
  teamData,
) {
  if (teamData == null) return 0;
  return (teamData['need_players'] as int?) ?? 0;
});

/// Provider to compute amount per player
final amountPerPlayerProvider = Provider.family<double, Map<String, dynamic>?>((
  ref,
  teamData,
) {
  if (teamData == null) return 0.0;

  final totalAmount = (teamData['amount'] as int?) ?? 1000;
  final totalPlayers = (teamData['total_players'] as int?) ?? 11;
  return totalAmount / totalPlayers;
});

/// Provider to get formatted joined players list
final joinedPlayersListProvider = Provider.family<
  List<Map<String, dynamic>>,
  Map<String, dynamic>?
>((ref, teamData) {
  List<Map<String, dynamic>> players = [];

  if (teamData == null) return players;

  // Add creator first
  players.add({
    'name': teamData['creator_name'] ?? 'Team Captain',
    'avatar_url':
        'https://i.pravatar.cc/150?img=${(teamData['creator_name'] ?? 'captain').hashCode % 50}',
    'status': 'paid', // Assume creator has paid
    'is_creator': true,
    'user_id': teamData['creator_id'] ?? 'creator_id',
  });

  // Add joined players
  if (teamData['joined_players'] is List) {
    final joinedPlayers = teamData['joined_players'] as List;
    for (var player in joinedPlayers) {
      players.add({
        'name': player['name'] ?? 'Player',
        'avatar_url':
            player['avatar_url'] ??
            'https://i.pravatar.cc/150?img=${player['name'].hashCode % 50}',
        'status': player['payment_status'] ?? 'pending',
        'is_creator': false,
        'user_id': player['user_id'] ?? '',
      });
    }
  }

  return players;
});

/// Provider to check if current user has paid
final hasCurrentUserPaidProvider = Provider.family<bool, Map<String, dynamic>?>(
  (ref, teamData) {
    final currentUser = ref.watch(currentUserProvider);
    final playersList = ref.watch(joinedPlayersListProvider(teamData));

    return playersList.any(
      (player) =>
          player['user_id'] == currentUser?['user_id'] &&
          player['status'] == 'paid',
    );
  },
);

/// Provider to check if current user is in team
final isCurrentUserInTeamProvider =
    Provider.family<bool, Map<String, dynamic>?>((ref, teamData) {
      final currentUser = ref.watch(currentUserProvider);
      final playersList = ref.watch(joinedPlayersListProvider(teamData));

      return playersList.any(
        (player) => player['user_id'] == currentUser?['user_id'],
      );
    });

/// Legacy providers for backward compatibility (if needed)
/// These are kept for compatibility but will use real data when teamData is available

/// Whether a team has been created or not
final isTeamCreatedProvider = StateProvider<bool>((ref) => false);

/// Stores the generated team code
final teamCodeProvider = StateProvider<String?>((ref) => null);

/// Represents individual team members
class TeamMember {
  final String name;
  final String avatarUrl;
  final PaymentStatus status;
  final String? userId;
  final bool isCreator;

  TeamMember({
    required this.name,
    this.avatarUrl = '',
    required this.status,
    this.userId,
    this.isCreator = false,
  });
}

/// Enum to track payment status of members
enum PaymentStatus { paid, requested, pending }

/// Legacy team members list - now computed from real data
final teamProvider = StateProvider<List<TeamMember>>((ref) {
  final selectedTeam = ref.watch(selectedTeamProvider);
  final playersList = ref.watch(joinedPlayersListProvider(selectedTeam));

  return playersList
      .map(
        (player) => TeamMember(
          name: player['name'],
          avatarUrl: player['avatar_url'],
          status:
              player['status'] == 'paid'
                  ? PaymentStatus.paid
                  : PaymentStatus.pending,
          userId: player['user_id'],
          isCreator: player['is_creator'] ?? false,
        ),
      )
      .toList();
});

/// Legacy player count - now computed from real data
final playerCountProvider = Provider<int>((ref) {
  final selectedTeam = ref.watch(selectedTeamProvider);
  return ref.watch(joinedPlayersCountProvider(selectedTeam));
});

/// Legacy total players - now from real data
final totalPlayersProvider = Provider<int>((ref) {
  final selectedTeam = ref.watch(selectedTeamProvider);
  return (selectedTeam?['total_players'] as int?) ?? 11;
});

/// Legacy need players - now computed from real data
final needPlayersProvider = Provider<int>((ref) {
  final selectedTeam = ref.watch(selectedTeamProvider);
  return ref.watch(needPlayersCountProvider(selectedTeam));
});

/// Utility functions

/// Generates a random team code (e.g., "AB12CD")
String generateRandomTeamCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}

/// Helper function to update team data after payment
Future<void> updateTeamAfterPayment({
  required String teamId,
  required String userId,
  required String userName,
  required String paymentId,
  String? avatarUrl,
}) async {
  final firestore = FirebaseFirestore.instance;
  final teamRef = firestore.collection('created_team').doc(teamId);

  await firestore.runTransaction((transaction) async {
    final teamDoc = await transaction.get(teamRef);

    if (!teamDoc.exists) {
      throw Exception('Team document not found');
    }

    final teamData = teamDoc.data()!;
    final currentNeedPlayers = (teamData['need_players'] as int?) ?? 0;
    final joinedPlayers = List<Map<String, dynamic>>.from(
      teamData['joined_players'] ?? [],
    );

    // Check if user is already in the team
    final userIndex = joinedPlayers.indexWhere(
      (player) => player['user_id'] == userId,
    );

    if (userIndex != -1) {
      // Update existing user's payment status
      joinedPlayers[userIndex]['payment_status'] = 'paid';
      joinedPlayers[userIndex]['payment_id'] = paymentId;
      joinedPlayers[userIndex]['payment_completed_at'] =
          FieldValue.serverTimestamp();

      transaction.update(teamRef, {
        'joined_players': joinedPlayers,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else if (currentNeedPlayers > 0) {
      // Add new user to joined_players array
      joinedPlayers.add({
        'user_id': userId,
        'name': userName,
        'avatar_url': avatarUrl ?? '',
        'payment_status': 'paid',
        'payment_id': paymentId,
        'joined_at': FieldValue.serverTimestamp(),
      });

      // Update the team document
      transaction.update(teamRef, {
        'joined_players': joinedPlayers,
        'need_players': currentNeedPlayers - 1,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('Team is already full');
    }
  });
}
