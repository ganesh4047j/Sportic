// ignore_for_file: avoid_print, unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'create_team.dart';
import 'split_pay.dart';

class JoinTeamPage extends ConsumerWidget {
  const JoinTeamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeamCreated = ref.watch(isTeamCreatedProvider);
    final teamCode = ref.watch(teamCodeProvider);
    final playerCount = ref.watch(playerCountProvider);
    final totalPlayers = ref.watch(totalPlayersProvider);
    final needPlayers = ref.watch(needPlayersProvider);

    return Scaffold(
      body: Container(
        height: double.infinity,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      'Join Team',
                      style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildTotalAmountSection(),
                const SizedBox(height: 30),
                _buildTeamCodeSection(context, ref, isTeamCreated, teamCode),
                const SizedBox(height: 30),
                _buildJoinTeamCard(playerCount, needPlayers),
                const SizedBox(height: 40),
                _buildProcessToBookButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalAmountSection() {
    return  Center(
      child: Column(
        children: [
          Text(
            'Total amount',
            style: GoogleFonts.nunito(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 4),
          Text(
            'Rs. 1100',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCodeSection(
    BuildContext context,
    WidgetRef ref,
    bool isTeamCreated,
    String? teamCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff3d0d4e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xff7d6089),
              border: Border.all(color: const Color(0x98dcdcdc), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'START PLAYING!',
                style: GoogleFonts.robotoSlab(
                  color: Color(0xffb1acac),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Get a New Team',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Lottie.asset('assets/football.json', height: 150, width: 150),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only selected can join by creator',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey, thickness: 0.5),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                isTeamCreated
                    ? () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text("My Team"),
                              content: const Text(
                                "Team details will be shown here.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                      );
                    }
                    : null,
            child:  Text(
              'See My Team',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTeamCard(int joinedPlayers, int neededPlayers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF4D2558),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=10"),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Godwin",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Joined players: $joinedPlayers",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    "Need players: $neededPlayers",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Text(
              "Rs.100",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessToBookButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SplitPaymentScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:  Text(
          'Process to Book',
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
