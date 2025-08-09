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

  // Game-specific positions mapping
  final Map<String, List<String>> gamePositions = {
    'Cricket': ['Batsman', 'Bowler', 'All Rounder', 'Wicket Keeper', 'Captain'],
    'Football': ['Goalkeeper', 'Defender', 'Midfielder', 'Forward', 'Striker'],
    'Badminton': [
      'Singles Player',
      'Doubles Player',
      'Mixed Doubles',
      'Left Court',
      'Right Court',
    ],
    'Volleyball': ['Setter', 'Spiker', 'Blocker', 'Libero', 'Server'],
    'Basketball': [
      'Point Guard',
      'Shooting Guard',
      'Small Forward',
      'Power Forward',
      'Center',
    ],
    'Pickleball': [
      'Singles Player',
      'Doubles Player',
      'Net Player',
      'Baseline Player',
      'Server',
    ],
  };

  @override
  void initState() {
    super.initState();

    // Initialize default values
    selectedGame = games.first;
    selectedCategory = category.first;
    selectedPosition = gamePositions[games.first]?.first;

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
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    // Responsive breakpoints
    final isExtraSmall = screenWidth < 320; // Very old/small phones
    final isSmall = screenWidth < 360; // Small phones
    final isMedium = screenWidth < 400; // Standard phones
    final isLarge = screenWidth >= 400; // Large phones/tablets

    // Dynamic sizing based on screen width
    final baseFontSize =
        isExtraSmall
            ? 12.0
            : isSmall
            ? 14.0
            : isMedium
            ? 16.0
            : 18.0;
    final basePadding =
        isExtraSmall
            ? 12.0
            : isSmall
            ? 16.0
            : isMedium
            ? 20.0
            : 24.0;
    final baseRadius =
        isExtraSmall
            ? 15.0
            : isSmall
            ? 18.0
            : 20.0;
    final avatarRadius =
        isExtraSmall
            ? 25.0
            : isSmall
            ? 30.0
            : isMedium
            ? 35.0
            : 40.0;

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
              horizontal: basePadding,
              vertical: basePadding * 0.8,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    _buildHeader(
                      context,
                      baseFontSize,
                      basePadding,
                      baseRadius,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Profile section
                    _buildProfileSection(
                      context,
                      baseFontSize,
                      basePadding,
                      avatarRadius,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Info Card
                    _buildInfoCard(
                      context,
                      baseFontSize,
                      basePadding,
                      baseRadius,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Tabs
                    _buildTabs(context, baseFontSize, basePadding, baseRadius),

                    SizedBox(height: screenHeight * 0.015),

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

                    SizedBox(height: screenHeight * 0.02),

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
                                context,
                                baseFontSize,
                                basePadding,
                                baseRadius,
                                screenWidth,
                              )
                              : buildPreviousMatchCards(
                                context,
                                baseFontSize,
                                basePadding,
                                baseRadius,
                              ),
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

  Widget _buildHeader(
    BuildContext context,
    double baseFontSize,
    double basePadding,
    double baseRadius,
  ) {
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
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: baseFontSize + 8,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            SizedBox(width: basePadding * 0.6),
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
                        fontSize: baseFontSize + 8,
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
                vertical: basePadding * 0.5,
                horizontal: basePadding * 0.8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(baseRadius + 5),
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
                  fontSize: baseFontSize - 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    double baseFontSize,
    double basePadding,
    double avatarRadius,
  ) {
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
                    radius: avatarRadius,
                    backgroundImage: const NetworkImage(
                      'https://i.pravatar.cc/300',
                    ),
                    backgroundColor: Colors.white24,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: basePadding * 0.6),
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
                    fontSize: baseFontSize + 4,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: basePadding * 0.3),
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
                      horizontal: basePadding,
                      vertical: basePadding * 0.4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.8),
                          Colors.orange.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(basePadding),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "MVP points = +100 🪙",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: baseFontSize - 2,
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

  Widget _buildInfoCard(
    BuildContext context,
    double baseFontSize,
    double basePadding,
    double baseRadius,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;

                // Calculate responsive font size based on screen width
                double responsiveFontSize;
                if (screenWidth <= 320) {
                  // Very small screens (iPhone SE)
                  responsiveFontSize = baseFontSize - 1;
                } else if (screenWidth <= 375) {
                  // Small screens (iPhone 8, iPhone 12 mini)
                  responsiveFontSize = baseFontSize;
                } else if (screenWidth <= 414) {
                  // Medium screens (iPhone 11, iPhone 12)
                  responsiveFontSize = baseFontSize + 1;
                } else {
                  // Large screens (iPhone 12 Pro Max, tablets)
                  responsiveFontSize = baseFontSize + 2;
                }

                // Calculate line height for better text spacing
                double lineHeight = screenWidth <= 360 ? 1.3 : 1.4;

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(basePadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF452152).withOpacity(0.8),
                        const Color(0xFF3D1A4A).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(baseRadius),
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
                      // Use RichText for better control over text layout
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: responsiveFontSize,
                            fontWeight: FontWeight.w500,
                            height: lineHeight,
                          ),
                          children: const [
                            TextSpan(text: "Get MVP Points. Play, Vote\n"),
                            TextSpan(text: "and Climb the Leaderboard ~ Be\n"),
                            TextSpan(text: "the most valuable player"),
                          ],
                        ),
                      ),

                      // Alternative approach using Text with manual line breaks
                      /*
                    Text(
                      "Get MVP Points. Play, Vote\nand Climb the Leaderboard ~ Be\nthe most valuable player",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: responsiveFontSize,
                        fontWeight: FontWeight.w500,
                        height: lineHeight,
                      ),
                    ),
                    */

                      // Alternative approach for very responsive text
                      /*
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.9,
                      ),
                      child: Text(
                        "Get MVP Points. Play, Vote and Climb the Leaderboard ~ Be the most valuable player",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: responsiveFontSize,
                          fontWeight: FontWeight.w500,
                          height: lineHeight,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    */
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabs(
    BuildContext context,
    double baseFontSize,
    double basePadding,
    double baseRadius,
  ) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(basePadding * 0.2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(baseRadius + 5),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: _buildTabButton(
                'Recent match',
                'recent',
                baseFontSize,
                basePadding,
                baseRadius,
              ),
            ),
            SizedBox(width: basePadding * 0.2),
            Flexible(
              child: _buildTabButton(
                'Previous match',
                'previous',
                baseFontSize,
                basePadding,
                baseRadius,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
    String title,
    String tabValue,
    double baseFontSize,
    double basePadding,
    double baseRadius,
  ) {
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
            horizontal: basePadding * 0.8,
            vertical: basePadding * 0.6,
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
            borderRadius: BorderRadius.circular(baseRadius),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: baseFontSize,
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPreviousMatchCards(
    BuildContext context,
    double baseFontSize,
    double basePadding,
    double baseRadius,
  ) {
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
            fontSize: baseFontSize + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: basePadding),
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
                    margin: EdgeInsets.only(bottom: basePadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff311e3e).withOpacity(0.8),
                          const Color(0xff2a1a35).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(baseRadius),
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
                      contentPadding: EdgeInsets.all(basePadding),
                      leading: Container(
                        padding: EdgeInsets.all(basePadding * 0.4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (match['color'] as Color).withOpacity(0.2),
                        ),
                        child: CircleAvatar(
                          radius: baseFontSize + 4,
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
                          fontSize: baseFontSize,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Slot: ${match['slot']}',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: baseFontSize - 2,
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
                          borderRadius: BorderRadius.circular(baseRadius),
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
                              borderRadius: BorderRadius.circular(baseRadius),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: basePadding * 0.6,
                              vertical: basePadding * 0.4,
                            ),
                          ),
                          child: Text(
                            "View",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: baseFontSize - 2,
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
    BuildContext context,
    double baseFontSize,
    double basePadding,
    double baseRadius,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose Player",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: baseFontSize + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: basePadding),

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
                  padding: EdgeInsets.all(basePadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2E1440).withOpacity(0.9),
                        const Color(0xFF241133).withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(baseRadius + 5),
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
                        baseFontSize: baseFontSize,
                        basePadding: basePadding,
                        baseRadius: baseRadius,
                      ),

                      SizedBox(height: basePadding),

                      _buildDropdown(
                        value: selectedGame!,
                        items: games,
                        label: 'Game type',
                        onChanged: (value) {
                          setState(() {
                            selectedGame = value;
                            // Reset position when game changes
                            selectedPosition = gamePositions[value]?.first;
                          });
                        },
                        baseFontSize: baseFontSize,
                        basePadding: basePadding,
                        baseRadius: baseRadius,
                      ),

                      SizedBox(height: basePadding),

                      _buildDropdown(
                        value: selectedPosition!,
                        items: gamePositions[selectedGame] ?? [],
                        label: 'Best player position',
                        onChanged:
                            (value) => setState(() => selectedPosition = value),
                        baseFontSize: baseFontSize,
                        basePadding: basePadding,
                        baseRadius: baseRadius,
                      ),

                      SizedBox(height: basePadding),

                      _buildDropdown(
                        value: selectedCategory!,
                        items: category,
                        label: 'Category',
                        onChanged:
                            (value) => setState(() => selectedCategory = value),
                        baseFontSize: baseFontSize,
                        basePadding: basePadding,
                        baseRadius: baseRadius,
                      ),

                      SizedBox(height: basePadding),

                      _buildRatingRow(
                        baseFontSize,
                        basePadding,
                        baseRadius,
                        screenWidth,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Continue button
        SizedBox(height: basePadding * 1.5),

        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            builder: (context, btnValue, child) {
              return Transform.scale(
                scale: 0.8 + (btnValue * 0.2),
                child: Container(
                  width: screenWidth * 0.8,
                  height: basePadding * 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pinkAccent, Colors.purpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(baseRadius + 5),
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
                        borderRadius: BorderRadius.circular(baseRadius + 5),
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
                        fontSize: baseFontSize + 2,
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
    required double baseFontSize,
    required double basePadding,
    required double baseRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(baseRadius),
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
        style: GoogleFonts.poppins(color: Colors.white, fontSize: baseFontSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: baseFontSize,
          ),
          filled: true,
          fillColor: const Color(0xFF3A1C4D).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(baseRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(baseRadius),
            borderSide: BorderSide(
              color: Colors.purple.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(baseRadius),
            borderSide: BorderSide(
              color: Colors.pinkAccent.withOpacity(0.6),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: basePadding,
            vertical: basePadding * 0.8,
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
    required double baseFontSize,
    required double basePadding,
    required double baseRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(baseRadius),
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
            fontSize: baseFontSize,
          ),
          filled: true,
          fillColor: const Color(0xFF3A1C4D).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(baseRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(baseRadius),
            borderSide: BorderSide(
              color: Colors.purple.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(baseRadius),
            borderSide: BorderSide(
              color: Colors.pinkAccent.withOpacity(0.6),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: basePadding,
            vertical: basePadding * 0.8,
          ),
        ),
        iconEnabledColor: Colors.white,
        iconSize: baseFontSize + 8,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: baseFontSize),
        items:
            items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: baseFontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }

  Widget _buildRatingRow(
    double baseFontSize,
    double basePadding,
    double baseRadius,
    double screenWidth,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(basePadding * 0.8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.2),
                    Colors.orange.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(baseRadius - 5),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child:
                  screenWidth < 320
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Turf rating:",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: baseFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: basePadding * 0.4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(4, (index) {
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(
                                        milliseconds: 800 + (index * 100),
                                      ),
                                      builder: (context, starValue, child) {
                                        return Transform.scale(
                                          scale: 0.5 + (starValue * 0.5),
                                          child: Icon(
                                            Icons.star,
                                            color: const Color(0xffffd537),
                                            size: baseFontSize + 2,
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
                                    builder: (context, starValue, child) {
                                      return Transform.scale(
                                        scale: 0.5 + (starValue * 0.5),
                                        child: Icon(
                                          Icons.star_border,
                                          color: const Color(0xffffd537),
                                          size: baseFontSize + 2,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: basePadding * 0.5,
                                  vertical: basePadding * 0.3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                    baseRadius - 12,
                                  ),
                                ),
                                child: Text(
                                  "4.0",
                                  style: GoogleFonts.poppins(
                                    color: Colors.amber,
                                    fontSize: baseFontSize - 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                      : Flexible(
                        child: Row(
                          children: [
                            Text(
                              "Turf rating:",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: basePadding * 0.3),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...List.generate(4, (index) {
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(
                                        milliseconds: 800 + (index * 100),
                                      ),
                                      builder: (context, starValue, child) {
                                        return Transform.scale(
                                          scale: 0.5 + (starValue * 0.5),
                                          child: Icon(
                                            Icons.star,
                                            color: const Color(0xffffd537),
                                            size: baseFontSize + 2,
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
                                    builder: (context, starValue, child) {
                                      return Transform.scale(
                                        scale: 0.5 + (starValue * 0.5),
                                        child: Icon(
                                          Icons.star_border,
                                          color: const Color(0xffffd537),
                                          size: baseFontSize + 2,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: basePadding * 0.3),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: basePadding * 0.4,
                                vertical: basePadding * 0.2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  baseRadius - 12,
                                ),
                              ),
                              child: Text(
                                "4.0",
                                style: GoogleFonts.poppins(
                                  color: Colors.amber,
                                  fontSize: baseFontSize - 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }
}
