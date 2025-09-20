// lib/category.dart
// ignore_for_file: avoid_print, unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports/Main%20Screens/favourites.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sports/Main%20Screens/home.dart';
import 'package:sports/Main%20Screens/turfscreen.dart';
import '../Create Team/create_team.dart';
import '../Providers/category_providers.dart';
import 'join_team.dart';
import 'package:sports/Main%20Screens/live_screen.dart';

final navIndexProvider = StateProvider<int>((ref) => 1);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  final List<String> imageUrls = const [
    "https://th.bing.com/th/id/OIP.e2P3ReDBMC5G87UnoHrt3wHaEM?w=280&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
    "https://th.bing.com/th/id/OIP.J6biGVVwvFxtGztUncZmqgHaEo?w=290&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
    "https://th.bing.com/th/id/OIP.ij1w9viY0dwNTdrLg6IlVwHaE7?w=289&h=192&c=7&r=0&o=5&dpr=1.3&pid=1.7",
    "https://th.bing.com/th/id/OIP.GFp3tlXRClkjYMCUvUSenwHaEK?w=286&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
    "https://th.bing.com/th/id/OIP.4HrBm_oZDCClrJzwvT9GaAHaEJ?w=312&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final matchDetails = ref.watch(matchDetailsProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B46C1),
              Color(0xFF452152),
              Color(0xFF3D1A4A),
              Color(0xFF200D28),
              Color(0xFF1B0723),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Particles
            ...List.generate(
              6,
              (index) => Positioned(
                top: (index * 150.0) % screenSize.height,
                left: (index * 100.0) % screenSize.width,
                child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 2.seconds)
                    .scale(
                      begin: Offset(0.5, 0.5),
                      end: Offset(1.5, 1.5),
                      duration: 3.seconds,
                    )
                    .fadeOut(delay: 2.seconds, duration: 1.seconds),
              ),
            ),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Enhanced Header with Glassmorphism
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 30 : 20,
                      vertical: isTablet ? 20 : 15,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 25 : 20,
                      vertical: isTablet ? 20 : 15,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            )
                            .animate()
                            .scale(delay: 200.ms, duration: 400.ms)
                            .shimmer(delay: 600.ms, duration: 1.seconds),

                        SizedBox(width: isTablet ? 20 : 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                    "Games",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize:
                                          isLargeScreen
                                              ? 34
                                              : isTablet
                                              ? 30
                                              : 26,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 300.ms, duration: 600.ms)
                                  .slideX(begin: -0.3, end: 0),

                              Text(
                                    "Join or create your team",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 600.ms)
                                  .slideX(begin: -0.3, end: 0),
                            ],
                          ),
                        ),

                        // Animated Gaming Icon
                        Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xffD72664),
                                    Color(0xff6624b5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xffD72664,
                                    ).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.sports_esports,
                                color: Colors.white,
                                size: isTablet ? 28 : 24,
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .rotate(duration: 4.seconds)
                            .scale(
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.1, 1.1),
                              duration: 2.seconds,
                            )
                            .then()
                            .scale(
                              begin: const Offset(1.1, 1.1),
                              end: const Offset(1.0, 1.0),
                              duration: 2.seconds,
                            ),
                      ],
                    ),
                  ).animate().slideY(
                    begin: -1,
                    end: 0,
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  ),

                  // Enhanced Games List
                  Expanded(
                    child:
                        isLargeScreen
                            ? _buildGridView(context, ref, matchDetails)
                            : _buildListView(
                              context,
                              ref,
                              matchDetails,
                              isTablet,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Enhanced Bottom Navigation with Glassmorphism
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xff22012c),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.shifting,
          currentIndex: ref.watch(navIndexProvider),
          onTap: (index) => ref.read(navIndexProvider.notifier).state = index,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.white,
          selectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    ),
                icon: Icon(Icons.home),
              ),
              label: 'Home',
              backgroundColor: const Color(0xff22012c),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.videogame_asset),
              //),
              label: 'Games',
              backgroundColor: const Color(0xff22012c),
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveScreen(),
                      ),
                    ),
                icon: const Icon(Icons.live_tv),
              ),
              label: 'Live',
              backgroundColor: const Color(0xff22012c),
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TurfHomeScreen(),
                      ),
                    ),
                icon: const Icon(Icons.sports_soccer),
              ),
              label: 'Turf',
              backgroundColor: const Color(0xff22012c),
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FollowingScreen(),
                      ),
                    ),
                icon: const Icon(Icons.favorite),
              ),
              label: 'Fav',
              backgroundColor: const Color(0xff22012c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    VoidCallback onTap,
    int index,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? const LinearGradient(
                    colors: [Color(0xffFF6B9D), Color(0xffD72664)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xffFF6B9D).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeInOut);
  }

  Widget _buildGridView(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, String>> matchDetails,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return _buildGameCard(context, ref, index, matchDetails[index], true);
      },
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, String>> matchDetails,
    bool isTablet,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 30 : 20,
        vertical: 10,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return _buildGameCard(
          context,
          ref,
          index,
          matchDetails[index],
          false,
          isTablet: isTablet,
        );
      },
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    WidgetRef ref,
    int index,
    Map<String, String> details,
    bool isGrid, {
    bool isTablet = false,
  }) {
    return Animate(
      effects: [
        FadeEffect(delay: (index * 100).ms, duration: 600.ms),
        SlideEffect(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
          delay: (index * 100).ms,
          duration: 800.ms,
          curve: Curves.elasticOut,
        ),
        ScaleEffect(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          delay: (index * 150).ms,
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),
      ],
      child: Container(
        margin: EdgeInsets.only(bottom: isGrid ? 0 : (isTablet ? 25 : 20)),
        child: Column(
          children: [
            // Enhanced Game Image Card
            Container(
              height: isGrid ? 180 : (isTablet ? 220 : 190),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xffD72664).withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Game Image
                    Positioned.fill(
                      child: Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xffD72664).withOpacity(0.8),
                                  const Color(0xff6624b5).withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.sports_esports,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),

                    // Floating Game Info
                    Positioned(
                      bottom: 15,
                      left: 15,
                      right: 15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffD72664),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xffD72664,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              details['sport'] ?? 'Sport',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            details['turfName'] ?? 'Turf Name',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Shimmer Effect on Hover
                    Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: const Alignment(-1.0, -0.3),
                                end: const Alignment(1.0, 0.3),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .slideX(
                          begin: -2,
                          end: 2,
                          duration: 3.seconds,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
            ).animate().shimmer(delay: (index * 200).ms, duration: 1.seconds),

            const SizedBox(height: 12),

            // Enhanced Dropdown Section
            _DropdownCardSection(
              cardIndex: index,
              details: details,
              isTablet: isTablet,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownCardSection extends ConsumerWidget {
  final int cardIndex;
  final Map<String, String> details;
  final bool isTablet;

  const _DropdownCardSection({
    required this.cardIndex,
    required this.details,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(cardExpansionProvider(cardIndex));

    return Column(
      children: [
        // Enhanced Action Buttons
        Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "Join Team",
                      icon: Icons.group_add_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xffFF6B9D), Color(0xffD72664)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JoinTeamPage(),
                            ),
                          ),
                    ),
                  ),

                  SizedBox(width: isTablet ? 16 : 12),

                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: "Create Team",
                      icon: Icons.add_circle_outline_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xff8B5CF6), Color(0xff6624b5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateTeamScreen(),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut)
            .fadeIn(duration: 600.ms),

        // Enhanced Expand/Collapse Button
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap:
                  () =>
                      ref
                          .read(cardExpansionProvider(cardIndex).notifier)
                          .state = !isExpanded,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: isTablet ? 30 : 26,
                ),
              ),
            ),
          ),
        ).animate().rotate(
          begin: isExpanded ? 0.5 : 0,
          end: isExpanded ? 0 : 0.5,
          duration: 300.ms,
          curve: Curves.easeInOut,
        ),

        // Enhanced Details Card
        if (isExpanded)
          Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isTablet ? 8 : 4,
                  vertical: 8,
                ),
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4C1D95).withOpacity(0.9),
                      const Color(0xFF3D1A4A).withOpacity(0.95),
                      const Color(0xFF2D1B44).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFF6B46C1).withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sport Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffFFD700), Color(0xffFFA500)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffFFD700).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            details['sport'] ?? 'Sport',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        // Players Count Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 12 : 10,
                            vertical: isTablet ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffD72664),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_rounded,
                                color: Colors.white,
                                size: isTablet ? 16 : 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                details['players'] ?? '0',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isTablet ? 20 : 16),

                    // Details List
                    ...List.generate(3, (index) {
                      final List<MapEntry<String, String>> entries = [
                        MapEntry('Turf name', details['turfName'] ?? 'Unknown'),
                        MapEntry('Slot timing', details['timing'] ?? 'TBD'),
                        MapEntry(
                          'Creator name',
                          details['creator'] ?? 'Anonymous',
                        ),
                      ];

                      final entry = entries[index];
                      final icons = [
                        Icons.location_on_rounded,
                        Icons.access_time_rounded,
                        Icons.person_rounded,
                      ];

                      return Container(
                            margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 10 : 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xffD72664,
                                        ).withOpacity(0.8),
                                        const Color(
                                          0xff6624b5,
                                        ).withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    icons[index],
                                    color: Colors.white,
                                    size: isTablet ? 20 : 18,
                                  ),
                                ),

                                SizedBox(width: isTablet ? 16 : 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.value,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .slideX(
                            begin: 0.3,
                            end: 0,
                            delay: (index * 100).ms,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(delay: (index * 100).ms, duration: 500.ms);
                    }),
                  ],
                ),
              )
              .animate()
              .slideY(
                begin: -0.2,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 16 : 12,
              ),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: isTablet ? 20 : 18),
                  SizedBox(width: isTablet ? 10 : 8),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.easeInOut,
        )
        .shimmer(
          delay: 1.seconds,
          duration: 2.seconds,
          color: Colors.white.withOpacity(0.3),
        );
  }
}
