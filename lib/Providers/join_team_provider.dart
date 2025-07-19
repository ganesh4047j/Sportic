import 'package:flutter_riverpod/flutter_riverpod.dart';

final leaderboardProvider =
StateNotifierProvider<LeaderboardNotifier, List<Map<String, dynamic>>>(
      (ref) => LeaderboardNotifier(),
);

class LeaderboardNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  LeaderboardNotifier() : super([]) {
    fetchLeaderboard();
  }

  void fetchLeaderboard() {
    final mockData = [
      {
        "name": "Akash",
        "location": "koothur,trichy",
        "score": 410,
        "imageUrl": "https://i.pravatar.cc/300"
      },
      {
        "name": "Godwin",
        "location": "velianur,trichy",
        "score": 250,
        "imageUrl": "https://i.pravatar.cc/300"
      },
      {
        "name": "Ajay",
        "location": "tollgate,trichy",
        "score": 210,
        "imageUrl": "https://i.pravatar.cc/300"
      },
      {
        "name": "Mukesh",
        "location": "rockfort,trichy",
        "score": 200,
        "imageUrl": "https://i.pravatar.cc/300"
      },
      {
        "name": "Dhanush",
        "location": "samayapuram,trichy",
        "score": 200,
        "imageUrl": "https://i.pravatar.cc/300"
      },
      {
        "name": "Karthik",
        "location": "valadi,trichy",
        "score": 180,
        "imageUrl": "https://i.pravatar.cc/300"
      },
      {
        "name": "Heman",
        "location": "koothur,trichy",
        "score": 110,
        "imageUrl": "https://i.pravatar.cc/300"
      }
    ];

    mockData.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    state = mockData;
  }
}