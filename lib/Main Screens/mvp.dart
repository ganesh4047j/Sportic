import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports/Main%20Screens/mvp_vote.dart';
import 'leaderboard.dart';

class MvpPage extends StatefulWidget {
  const MvpPage({super.key});

  @override
  State<MvpPage> createState() => _MvpPageState();
}

class _MvpPageState extends State<MvpPage> with TickerProviderStateMixin {
  String selectedTab = 'recent';

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController turfController = TextEditingController(
    text: 'Sportic',
  );
  String? selectedGame;
  String? selectedCategory;
  String? selectedPosition;

  final List<String> games = [
    'Cricket',
    'Football',
    'Badminton',
    'Volleyball',
    'Basketball',
    'Pickleball',
  ];

  final List<String> category = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional',
  ];

  final List<String> positions = [
    'Batsman',
    'Striker',
    'Goalkeeper',
    'Bowler',
    'Wicket Keeper',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize default values
    selectedGame = games.first;
    selectedCategory = category.first;
    selectedPosition = positions.first;

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Create animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    turfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.02,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    _buildHeader(context, isSmallScreen),

                    SizedBox(height: screenHeight * 0.025),

                    // Profile section
                    _buildProfileSection(isSmallScreen),

                    SizedBox(height: screenHeight * 0.025),

                    // Info Card
                    _buildInfoCard(screenWidth, isSmallScreen),

                    SizedBox(height: screenHeight * 0.025),

                    // Tabs
                    _buildTabs(isSmallScreen),

                    SizedBox(height: screenHeight * 0.02),

                    Container(
                      height: 1,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child:
                          selectedTab == 'recent'
                              ? buildRecentMatchForm(
                                screenHeight,
                                screenWidth,
                                isSmallScreen,
                              )
                              : buildPreviousMatchCards(isSmallScreen),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
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
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: Text(
                      "MVP",
                      style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
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
        ),
      ],
    );
  }

  Widget _buildProfileSection(bool isSmallScreen) {
    return Center(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (value * 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.pink.withOpacity(0.6),
                        Colors.purple.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: isSmallScreen ? 35 : 40,
                    backgroundImage: const NetworkImage(
                      'https://i.pravatar.cc/300',
                    ),
                    backgroundColor: Colors.white24,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  "Hariharan S",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1400),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.8),
                          Colors.orange.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "MVP points = +250 🪙",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(double screenWidth, bool isSmallScreen) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF452152).withOpacity(0.8),
                    const Color(0xFF3D1A4A).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Get MVP Points To Play And",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Vote Teammate',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabs(bool isSmallScreen) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton('Recent match', 'recent', isSmallScreen),
            SizedBox(width: isSmallScreen ? 4 : 8),
            _buildTabButton('Previous match', 'previous', isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, String tabValue, bool isSmallScreen) {
    final isSelected = selectedTab == tabValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = tabValue;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [
                        const Color(0xff8a23ea),
                        const Color(0xff6a1bb9),
                      ],
                    )
                    : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color(0xff8a23ea).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPreviousMatchCards(bool isSmallScreen) {
    final matches = [
      {
        'image': 'https://img.icons8.com/color/2x/soccer-field.png',
        'title': 'Js brothers turf',
        'slot': 'Dec 12, 7pm - 9pm',
        'color': Colors.green,
      },
      {
        'image': 'https://img.icons8.com/color/2x/basketball.png',
        'title': 'Spotic turf',
        'slot': 'Dec 12, 8pm - 9pm',
        'color': Colors.orange,
      },
      {
        'image': 'https://img.icons8.com/color/2x/football2.png',
        'title': 'Champion turf',
        'slot': 'Dec 12, 6pm - 9pm',
        'color': Colors.blue,
      },
      {
        'image': 'https://img.icons8.com/color/2x/volleyball.png',
        'title': 'Turf hub',
        'slot': 'Dec 12, 7pm - 10pm',
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Previous Games",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        ...matches.asMap().entries.map((entry) {
          final index = entry.key;
          final match = entry.value;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 200)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(50 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff311e3e).withOpacity(0.8),
                          const Color(0xff2a1a35).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (match['color'] as Color).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (match['color'] as Color).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (match['color'] as Color).withOpacity(0.2),
                        ),
                        child: CircleAvatar(
                          radius: isSmallScreen ? 20 : 24,
                          backgroundImage: NetworkImage(
                            match['image']! as String,
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      title: Text(
                        match['title']! as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Slot: ${match['slot']}',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (match['color'] as Color),
                              (match['color'] as Color).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (match['color'] as Color).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            "View",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
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
      ],
    );
  }

  Widget buildRecentMatchForm(
    double screenHeight,
    double screenWidth,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose Player",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: double.infinity,
                  // Remove the Stack and Positioned widget approach
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 16 : 20,
                    isSmallScreen ? 20 : 24,
                    isSmallScreen ? 16 : 20,
                    isSmallScreen ? 24 : 28, // Reduced bottom padding
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2E1440).withOpacity(0.9),
                        const Color(0xFF241133).withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: turfController,
                        label: 'Turf name',
                        isSmallScreen: isSmallScreen,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      _buildDropdown(
                        value: selectedGame!,
                        items: games,
                        label: 'Game type',
                        onChanged:
                            (value) => setState(() => selectedGame = value),
                        isSmallScreen: isSmallScreen,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      _buildDropdown(
                        value: selectedPosition!,
                        items: positions,
                        label: 'Best player position',
                        onChanged:
                            (value) => setState(() => selectedPosition = value),
                        isSmallScreen: isSmallScreen,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      _buildDropdown(
                        value: selectedCategory!,
                        items: category,
                        label: 'Category',
                        onChanged:
                            (value) => setState(() => selectedCategory = value),
                        isSmallScreen: isSmallScreen,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      _buildRatingRow(isSmallScreen),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Move the Continue button outside the container as a separate widget
        SizedBox(height: isSmallScreen ? 20 : 25),

        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            builder: (context, btnValue, child) {
              return Transform.scale(
                scale: 0.8 + (btnValue * 0.2),
                child: Container(
                  width: screenWidth * 0.6,
                  height: isSmallScreen ? 45 : 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pinkAccent, Colors.purpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
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
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const Mvp_VotePage(),
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
                      "Continue",
                      style: GoogleFonts.nunito(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: isSmallScreen ? 14 : 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: isSmallScreen ? 14 : 16,
          ),
          filled: true,
          fillColor: const Color(0xFF3A1C4D).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.purple.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.pinkAccent.withOpacity(0.6),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: const Color(0xFF3A1C4D),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: isSmallScreen ? 14 : 16,
          ),
          filled: true,
          fillColor: const Color(0xFF3A1C4D).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.purple.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.pinkAccent.withOpacity(0.6),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
        iconEnabledColor: Colors.white,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: isSmallScreen ? 14 : 16,
        ),
        items:
            items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRatingRow(bool isSmallScreen) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.2),
                    Colors.orange.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "Turf rating:",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  ...List.generate(4, (index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 800 + (index * 100)),
                      builder: (context, starValue, child) {
                        return Transform.scale(
                          scale: 0.5 + (starValue * 0.5),
                          child: Icon(
                            Icons.star,
                            color: const Color(0xffffd537),
                            size: isSmallScreen ? 18 : 20,
                          ),
                        );
                      },
                    );
                  }),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, starValue, child) {
                      return Transform.scale(
                        scale: 0.5 + (starValue * 0.5),
                        child: Icon(
                          Icons.star_border,
                          color: const Color(0xffffd537),
                          size: isSmallScreen ? 18 : 20,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "4.0",
                      style: GoogleFonts.poppins(
                        color: Colors.amber,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
