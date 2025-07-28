import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sports/Create%20Team/turf_list.dart';

// Secure storage instance
const secureStorage = FlutterSecureStorage();

// User Profile Model
class UserProfile {
  final String uid;
  final String loginType;
  final String name;
  final String photoUrl;

  UserProfile({
    required this.uid,
    required this.loginType,
    required this.name,
    required this.photoUrl,
  });
}

// State Providers
final isTeamCreatedProvider = StateProvider<bool>((ref) => false);
final playerCountProvider = StateProvider<int>((ref) => 1);
final totalPlayersProvider = StateProvider<int>((ref) => 11);
final needPlayersProvider = StateProvider<int>((ref) => 2);

// User Profile Provider
final UserProfileProvider = FutureProvider<UserProfile>((ref) async {
  return await getUserProfile();
});

// Function to get user profile
Future<UserProfile> getUserProfile() async {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser != null) {
    final emailDoc =
        await FirebaseFirestore.instance
            .collection('user_details_email')
            .doc(firebaseUser.uid)
            .get();

    if (emailDoc.exists) {
      final profile = emailDoc.data()!;
      return UserProfile(
        uid: firebaseUser.uid,
        loginType: 'email',
        name: profile['name'] ?? 'Unknown User',
        photoUrl: profile['photoUrl'] ?? '',
      );
    }
  }

  final customUid = await secureStorage.read(key: 'custom_uid');

  if (customUid != null) {
    final phoneDoc =
        await FirebaseFirestore.instance
            .collection('user_details_phone')
            .doc(customUid)
            .get();

    if (phoneDoc.exists) {
      final profile = phoneDoc.data()!;
      return UserProfile(
        uid: customUid,
        loginType: 'phone',
        name: profile['name'] ?? 'Unknown User',
        photoUrl: profile['photoUrl'] ?? '',
      );
    }
  }

  throw Exception("User not authenticated or profile not found.");
}

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final isTeamCreated = ref.watch(isTeamCreatedProvider);
    // final playerCount = ref.watch(playerCountProvider);
    // final totalPlayers = ref.watch(totalPlayersProvider);
    // final needPlayers = ref.watch(needPlayersProvider);

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildAnimatedHeader(),
                      const SizedBox(height: 30),
                      _buildAnimatedTotalAmount(),
                      const SizedBox(height: 30),
                      _buildAnimatedTeamSection(),
                      const SizedBox(height: 30),
                      _buildAnimatedCreatorSection(),
                      const SizedBox(height: 30),
                      _buildAnimatedPlayersSection(),
                      const SizedBox(height: 40),
                      _buildAnimatedButton(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Create Dream Team',
                style: GoogleFonts.robotoSlab(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTotalAmount() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.withOpacity(0.8),
                    Colors.purple.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹ 1,100',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
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

  Widget _buildAnimatedTeamSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff4a1b5c).withOpacity(0.8),
            const Color(0xff3d0d4e).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xff8a5a9b), const Color(0xff7d6089)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'START PLAYING!',
                  style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a New Team',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build your ultimate squad and dominate the field!',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value * 0.1,
                    child: Lottie.asset(
                      'assets/football.json',
                      height: 120,
                      width: 120,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.group, color: Colors.white),
              label: Text(
                'View Team Details',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCreatorSection() {
    final userProfileAsync = ref.watch(UserProfileProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.2),
            Colors.purple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Creator',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          userProfileAsync.when(
            data:
                (userProfile) => Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink, Colors.purple],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 24,
                        backgroundImage:
                            userProfile.photoUrl.isNotEmpty
                                ? NetworkImage(userProfile.photoUrl)
                                : null,
                        child:
                            userProfile.photoUrl.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfile.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            loading:
                () => Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink, Colors.purple],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Loading...',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            error:
                (error, stack) => Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.orange],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 24,
                        child: Icon(Icons.error, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Error loading profile',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPlayersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.withOpacity(0.2), Colors.cyan.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildAnimatedLabelWithCounter(
            'Total Players',
            ref,
            totalPlayersProvider,
            ref.watch(totalPlayersProvider),
            Icons.groups,
          ),
          const SizedBox(height: 20),
          _buildAnimatedLabelWithCounter(
            'Need Players',
            ref,
            needPlayersProvider,
            ref.watch(needPlayersProvider),
            Icons.person_add,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton(BuildContext context) {
    final userProfileAsync = ref.watch(UserProfileProvider);
    final totalPlayers = ref.watch(totalPlayersProvider);
    final needPlayers = ref.watch(needPlayersProvider);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_pulseAnimation.value - 1.0) * 0.1,
          child: Center(
            child: // Responsive View Available Turfs Button
                LayoutBuilder(
              builder: (context, constraints) {
                // Get screen dimensions
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;

                // Define responsive values based on screen size
                final isSmallScreen = screenWidth < 360;
                final isMediumScreen = screenWidth >= 360 && screenWidth < 414;
                // final isLargeScreen = screenWidth >= 414;

                // Responsive dimensions
                final buttonHeight =
                    screenHeight * 0.065; // 6.5% of screen height
                final minButtonHeight = 50.0;
                final maxButtonHeight = 70.0;

                final fontSize =
                    isSmallScreen
                        ? 14.0
                        : isMediumScreen
                        ? 16.0
                        : 18.0;
                final iconSize =
                    isSmallScreen
                        ? 18.0
                        : isMediumScreen
                        ? 20.0
                        : 22.0;
                final borderRadius =
                    isSmallScreen
                        ? 12.0
                        : isMediumScreen
                        ? 14.0
                        : 16.0;
                final horizontalPadding =
                    screenWidth * 0.08; // 8% of screen width
                final verticalPadding =
                    buttonHeight * 0.25; // 25% of button height

                // Responsive spacing
                final iconTextSpacing = isSmallScreen ? 8.0 : 12.0;
                final textArrowSpacing = isSmallScreen ? 6.0 : 8.0;

                // Responsive shadow properties
                final blurRadius =
                    isSmallScreen
                        ? 15.0
                        : isMediumScreen
                        ? 18.0
                        : 20.0;
                final spreadRadius = isSmallScreen ? 1.0 : 2.0;
                final shadowOffset = Offset(0, isSmallScreen ? 3.0 : 5.0);

                return Container(
                  width: double.infinity, // Full width for better touch area
                  constraints: BoxConstraints(
                    minHeight: minButtonHeight,
                    maxHeight: maxButtonHeight,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: const LinearGradient(
                      colors: [Colors.pink, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.5),
                        blurRadius: blurRadius,
                        spreadRadius: spreadRadius,
                        offset: shadowOffset,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      userProfileAsync.whenData((userProfile) {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    TurfListingScreen(
                                      creatorName: userProfile.name,
                                      totalPlayers: totalPlayers,
                                      needPlayers: needPlayers,
                                    ),
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
                                    curve: Curves.easeInOutCubic,
                                  ),
                                ),
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding.clamp(16.0, 48.0),
                        vertical: verticalPadding.clamp(12.0, 20.0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      minimumSize: Size(double.infinity, minButtonHeight),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            color: Colors.white,
                            size: iconSize,
                          ),
                          SizedBox(width: iconTextSpacing),
                          Flexible(
                            child: Text(
                              'View Available Turfs',
                              style: GoogleFonts.nunito(
                                fontSize: fontSize,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: textArrowSpacing),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedCounter(
    WidgetRef ref,
    StateProvider<int> provider,
    int count,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedCounterButton(
            icon: Icons.remove,
            onPressed: () {
              if (count > 0) {
                ref.read(provider.notifier).state = count - 1;
              }
            },
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildAnimatedCounterButton(
            icon: Icons.add,
            onPressed: () {
              ref.read(provider.notifier).state = count + 1;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLabelWithCounter(
    String label,
    WidgetRef ref,
    StateProvider<int> provider,
    int count,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildAnimatedCounter(ref, provider, count),
      ],
    );
  }
}
