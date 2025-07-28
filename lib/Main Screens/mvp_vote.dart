// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Providers/mvp_vote_provider.dart';
import 'feedback.dart';
import 'leaderboard.dart';

class Mvp_VotePage extends ConsumerStatefulWidget {
  const Mvp_VotePage({super.key});

  @override
  ConsumerState<Mvp_VotePage> createState() => _Mvp_VotePageState();
}

class _Mvp_VotePageState extends ConsumerState<Mvp_VotePage>
    with TickerProviderStateMixin {
  final String? userProfileUrl = "https://i.pravatar.cc/300";

  final List<Map<String, dynamic>> players = const [
    {"name": "Godwin", "image": "https://i.pravatar.cc/300?img=1"},
    {"name": "Jonesh", "image": "https://i.pravatar.cc/300?img=2"},
    {"name": "Jon show", "image": "https://i.pravatar.cc/300?img=3"},
    {"name": "Great ganesh", "image": "https://i.pravatar.cc/300?img=4"},
    {"name": "wick", "image": "https://i.pravatar.cc/300?img=5"},
  ];

  late AnimationController _headerController;
  late AnimationController _cardController;
  late AnimationController _buttonController;
  late AnimationController _selectedMvpController;

  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _selectedMvpAnimation;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _selectedMvpController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    _selectedMvpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectedMvpController, curve: Curves.bounceOut),
    );

    // Start animations sequentially
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardController.dispose();
    _buttonController.dispose();
    _selectedMvpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMvp = ref.watch(selectedMvpProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Trigger selected MVP animation when selection changes
    if (selectedMvp != null) {
      _selectedMvpController.reset();
      _selectedMvpController.forward();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Header
                      _buildHeader(context, isSmallScreen),

                      SizedBox(height: screenHeight * 0.02),

                      // Enhanced Title Section
                      _buildTitleSection(isSmallScreen),

                      SizedBox(height: screenHeight * 0.025),

                      // Enhanced Selected MVP Display
                      if (selectedMvp != null)
                        _buildSelectedMvpCard(selectedMvp, isSmallScreen),

                      SizedBox(height: screenHeight * 0.025),

                      // Enhanced Team Section
                      _buildTeamSection(context, isSmallScreen),

                      SizedBox(height: screenHeight * 0.02),

                      // Enhanced MVP Voting List
                      _buildVotingList(selectedMvp, isSmallScreen),

                      SizedBox(height: screenHeight * 0.1),
                    ],
                  ),
                ),
              ),

              // Enhanced Bottom Button
              _buildBottomButton(context, screenWidth, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(_headerAnimation),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.amber.shade200],
                      ).createShader(bounds),
                  child: Text(
                    "MVP VOTE",
                    style: GoogleFonts.robotoSlab(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            const LeaderboardPage(),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 8 : 10,
                  horizontal: isSmallScreen ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Leaderboard",
                  style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(bool isSmallScreen) {
    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_headerAnimation),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withOpacity(0.2),
                    Colors.orange.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.5 + (value * 0.5),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.amber, Colors.orange],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback:
                            (bounds) => LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                            ).createShader(bounds),
                        child: Text(
                          "MVP SELECTION",
                          style: GoogleFonts.robotoSlab(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Choose the best player on your turf\nOnly 1 can be selected",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isSmallScreen ? 14 : 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMvpCard(String selectedMvp, bool isSmallScreen) {
    return ScaleTransition(
      scale: _selectedMvpAnimation,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.8),
              Colors.teal.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.3), Colors.transparent],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                radius: isSmallScreen ? 24 : 28,
                child:
                    userProfileUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : ClipOval(
                          child: Image.network(
                            userProfileUrl!,
                            width: isSmallScreen ? 48 : 56,
                            height: isSmallScreen ? 48 : 56,
                            fit: BoxFit.cover,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected MVP",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    selectedMvp,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "+10",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, bool isSmallScreen) {
    return FadeTransition(
      opacity: _cardAnimation,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder:
                (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF452152),
                          const Color(0xFF3D1A4A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.group, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              "Team Members",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...players
                            .map(
                              (player) => Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(
                                        player['image'],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      player['name'],
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Close",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.purple.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                "View My Team",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVotingList(String? selectedMvp, bool isSmallScreen) {
    return Column(
      children:
          players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final name = player["name"];
            final image = player["image"];
            final isSelected = name == selectedMvp;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 800 + (index * 200)),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(50 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:
                              isSelected
                                  ? [
                                    Colors.green.withOpacity(0.3),
                                    Colors.teal.withOpacity(0.3),
                                  ]
                                  : [
                                    const Color(0xFF2E1440).withOpacity(0.8),
                                    const Color(0xFF241133).withOpacity(0.8),
                                  ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.purple.withOpacity(0.3),
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isSelected
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.2),
                            blurRadius: isSelected ? 15 : 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        leading: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors:
                                  isSelected
                                      ? [
                                        Colors.green.withOpacity(0.3),
                                        Colors.transparent,
                                      ]
                                      : [
                                        Colors.purple.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white24,
                            radius: isSmallScreen ? 20 : 24,
                            backgroundImage:
                                image.isNotEmpty ? NetworkImage(image) : null,
                            child:
                                image.isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle:
                            isSelected
                                ? Text(
                                  "Current MVP",
                                  style: GoogleFonts.poppins(
                                    color: Colors.green.shade200,
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                                : null,
                        trailing: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isSelected
                                      ? [Colors.green, Colors.teal]
                                      : [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected
                                        ? Colors.green
                                        : Colors.orange)
                                    .withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 20,
                                vertical: isSmallScreen ? 8 : 10,
                              ),
                            ),
                            onPressed: () {
                              if (!isSelected) {
                                ref.read(selectedMvpProvider.notifier).state =
                                    name;
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isSelected ? "Voted" : "Vote",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    double screenWidth,
    bool isSmallScreen,
  ) {
    return ScaleTransition(
      scale: _buttonAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Container(
          height: isSmallScreen ? 50 : 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.purpleAccent],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const FeedbackPage(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 1.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: Text(
              "Continue to Feedback",
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
