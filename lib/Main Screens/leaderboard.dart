import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Providers/join_team_provider.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  Widget buildAvatar(String? url, {double radius = 30}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
          url,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person, size: radius, color: Colors.grey);
          },
        )
            : Icon(Icons.person, size: radius, color: Colors.grey),
      ),
    );
  }

  Widget buildTopPlayer(Map<String, dynamic> player) {
    return Column(
      children: [
        buildAvatar(player['imageUrl'], radius: 35),
        const SizedBox(height: 4),
        Text(player['name'], style: GoogleFonts.poppins(color: Colors.white)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${player['score']} ',
                style: GoogleFonts.poppins(color: Colors.white)),
            const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
          ],
        )
      ],
    );
  }

  Widget buildTopThree(List<Map<String, dynamic>> players) {
    if (players.length < 3) return const SizedBox.shrink();

    final first = players[0];
    final second = players[1];
    final third = players[2];

    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 0, child: buildTopPlayer(first)),
          Positioned(bottom: 0, left: 30, child: buildTopPlayer(second)),
          Positioned(bottom: 0, right: 30, child: buildTopPlayer(third)),
        ],
      ),
    );
  }

  Widget buildLeaderboardList(List<Map<String, dynamic>> players) {
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                height: 50,
                child: buildAvatar(player['imageUrl']),
              ),
            ],
          ),
          title: Text(
            player['name'],
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          subtitle: Text(player['location'],
              style: GoogleFonts.poppins(color: Colors.white70)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${player['score']}',
                  style: GoogleFonts.poppins(color: Colors.white)),
              const SizedBox(width: 5),
              const Icon(Icons.monetization_on, color: Colors.amber),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(leaderboardProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF452152),
              Color(0xFF3D1A4A),
              Color(0xFF200D28),
              Color(0xFF1B0723),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                     Text(
                      'Leaderboard',
                      style:GoogleFonts.robotoSlab(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const Icon(Icons.emoji_events, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Top 10',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
              ),
              Text(
                'players',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 20),
              buildTopThree(players),
              const SizedBox(height: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xf9441d56),
                    child: buildLeaderboardList(players),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
