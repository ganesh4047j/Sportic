import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'booking_turf.dart';

// State Providers
final teamCodeProvider = StateProvider<String?>((ref) => null);
final isTeamCreatedProvider = StateProvider<bool>((ref) => false);
final playerCountProvider = StateProvider<int>((ref) => 1);
final totalPlayersProvider = StateProvider<int>((ref) => 11);
final needPlayersProvider = StateProvider<int>((ref) => 2);

class CreateTeamScreen extends ConsumerWidget {
  const CreateTeamScreen({super.key});

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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Text(
                        'Create Team',
                        style: GoogleFonts.robotoSlab(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildTotalAmountSection(),
                  const SizedBox(height: 30),
                  _buildTeamCodeSection(ref, isTeamCreated, teamCode),
                  const SizedBox(height: 30),
                  _buildCreatorDetailsSection(ref, playerCount),
                  const SizedBox(height: 30),
                  _buildPlayersCountSection(ref, totalPlayers, needPlayers),
                  const SizedBox(height: 40),
                  _buildProcessToBookButton(context),
                  const SizedBox(height: 30),
                ],
              ),
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
              border: Border.all(
                color: const Color(0x98dcdcdc), // Border color
                width: 1.5, // Border width
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:  Align(
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
                'Create a New Team',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Only selected can join by creator',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isTeamCreated ? () {} : null,
            child: Text(
              'See My team',
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

  Widget _buildCreatorDetailsSection(WidgetRef ref, int playerCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Creator detail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4.0), // Align with label start
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.pink,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'Godwin',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const Spacer(),
              _buildCounter(ref, playerCountProvider, playerCount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersCountSection(
    WidgetRef ref,
    int totalPlayers,
    int needPlayers,
  ) {
    return Column(
      children: [
        _buildLabelWithCounter(
          'Total players',
          ref,
          totalPlayersProvider,
          totalPlayers,
        ),
        const SizedBox(height: 8),
        _buildLabelWithCounter(
          'Need players',
          ref,
          needPlayersProvider,
          needPlayers,
        ),
      ],
    );
  }

  Widget _buildProcessToBookButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookingPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:Text(
          'Process to Book',
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: Colors.white, // white text color
            fontWeight: FontWeight.bold, // bold text
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(WidgetRef ref, StateProvider<int> provider, int count) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCounterButton(
            icon: Icons.remove,
            onPressed: () {
              if (count > 0) {
                ref.read(provider.notifier).state = count - 1;
              }
            },
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.white24),
                right: BorderSide(color: Colors.white24),
              ),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          _buildCounterButton(
            icon: Icons.add,
            onPressed: () {
              ref.read(provider.notifier).state = count + 1;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(
            0xFFE0DCDC,
          ).withOpacity(0.1), // faded background
          side: const BorderSide(color: Color(0x8AE0DCDC)), // faded border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // border radius 4
          ),
        ),
        onPressed: onPressed,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildLabelWithCounter(
    String label,
    WidgetRef ref,
    StateProvider<int> provider,
    int count,
  ) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const Spacer(),
        _buildCounter(ref, provider, count),
      ],
    );
  }
}

String generateRandomTeamCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}
