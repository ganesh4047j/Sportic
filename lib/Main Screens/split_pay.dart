import 'dart:async'; // Add this import for StreamSubscription
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

final FlutterSecureStorage secureStorage = FlutterSecureStorage();

// Provider to store selected team data from join team screen
final selectedTeamProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

Future<Map<String, dynamic>> getUserProfile() async {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser != null) {
    final emailDoc =
        await FirebaseFirestore.instance
            .collection('user_details_email')
            .doc(firebaseUser.uid)
            .get();

    if (emailDoc.exists) {
      final profile = emailDoc.data()!;
      return {
        'uid': firebaseUser.uid,
        'loginType': 'email',
        'name': profile['name'],
        'photoUrl': profile['photoUrl'],
      };
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
      return {
        'uid': customUid,
        'loginType': 'phone',
        'name': profile['name'],
        'photoUrl': profile['photoUrl'],
      };
    }
  }

  throw Exception("User not authenticated or profile not found.");
}

// Function to get user profile by user ID from both collections
Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
  try {
    // First check in user_details_email collection
    final emailDoc =
        await FirebaseFirestore.instance
            .collection('user_details_email')
            .doc(userId)
            .get();

    if (emailDoc.exists) {
      final profile = emailDoc.data()!;
      return {
        'uid': userId,
        'loginType': 'email',
        'name': profile['name'] ?? 'Unknown User',
        'photoUrl': profile['photoUrl'] ?? '',
      };
    }

    // If not found in email collection, check phone collection
    final phoneDoc =
        await FirebaseFirestore.instance
            .collection('user_details_phone')
            .doc(userId)
            .get();

    if (phoneDoc.exists) {
      final profile = phoneDoc.data()!;
      return {
        'uid': userId,
        'loginType': 'phone',
        'name': profile['name'] ?? 'Unknown User',
        'photoUrl': profile['photoUrl'] ?? '',
      };
    }

    return null;
  } catch (e) {
    print('Error fetching user profile for $userId: $e');
    return null;
  }
}

// Provider to store current user data (you'll need to implement user management)
// Updated provider using FutureProvider to handle async data
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final userProfile = await getUserProfile();
    return {
      'name': userProfile['name'] ?? 'Unknown User',
      'user_id': userProfile['uid'],
      'avatar_url': userProfile['photoUrl'] ?? '',
    };
  } catch (e) {
    // Return null if user is not authenticated or profile not found
    return null;
  }
});

class SplitPaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? teamData;

  const SplitPaymentScreen({super.key, this.teamData});

  @override
  ConsumerState<SplitPaymentScreen> createState() => _SplitPaymentScreenState();
}

class _SplitPaymentScreenState extends ConsumerState<SplitPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  Map<String, dynamic>? teamData;
  bool isLoading = false;
  StreamSubscription<DocumentSnapshot>? teamSubscription;

  // Cache for user profiles to avoid repeated API calls
  Map<String, Map<String, dynamic>?> userProfileCache = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Set team data from widget parameter or provider
    teamData = widget.teamData ?? ref.read(selectedTeamProvider);

    if (teamData != null) {
      // Listen to real-time updates for this team
      _listenToTeamUpdates();
      // Pre-fetch user profiles
      _preloadUserProfiles();
    }
  }

  void _listenToTeamUpdates() {
    if (teamData?['team_id'] != null) {
      teamSubscription = FirebaseFirestore.instance
          .collection('created_team')
          .doc(teamData!['team_id'])
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && mounted) {
              setState(() {
                teamData = {...teamData!, ...snapshot.data()!};
              });
              // Reload user profiles when team data changes
              _preloadUserProfiles();
            }
          });
    }
  }

  // Pre-load user profiles for better performance
  Future<void> _preloadUserProfiles() async {
    if (teamData == null) return;

    // Get creator profile
    final creatorUserId = teamData!['creator_user_id'];
    if (creatorUserId != null && !userProfileCache.containsKey(creatorUserId)) {
      final creatorProfile = await getUserProfileById(creatorUserId);
      if (mounted) {
        setState(() {
          userProfileCache[creatorUserId] = creatorProfile;
        });
      }
    }

    // Get joined players profiles
    if (teamData!['joined_players'] is List) {
      final joinedPlayers = teamData!['joined_players'] as List;
      for (var player in joinedPlayers) {
        final userId = player['user_id'];
        if (userId != null && !userProfileCache.containsKey(userId)) {
          final playerProfile = await getUserProfileById(userId);
          if (mounted) {
            setState(() {
              userProfileCache[userId] = playerProfile;
            });
          }
        }
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Start animations with staggered delays
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _bounceController.forward();
    });

    _shimmerController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    teamSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // Calculate joined players count from joined_players array
  int get joinedPlayersCount {
    if (teamData?['joined_players'] is List) {
      return (teamData!['joined_players'] as List).length;
    }
    return 1; // At least the creator
  }

  // Calculate needed players
  int get needPlayersCount {
    return (teamData?['need_players'] as int?) ?? 0;
  }

  // Calculate amount per player
  double get amountPerPlayer {
    final totalAmount = (teamData?['amount'] ?? 1000).toDouble();
    final totalPlayers = (teamData?['total_players'] ?? 11).toInt();
    return totalAmount / totalPlayers;
  }

  // Get joined players list for display with actual profile data
  List<Map<String, dynamic>> get joinedPlayersList {
    List<Map<String, dynamic>> players = [];

    // Add creator first with actual profile data
    final creatorUserId = teamData?['creator_user_id'];
    final creatorProfile = userProfileCache[creatorUserId];

    players.add({
      'name':
          creatorProfile?['name'] ??
          teamData?['creator_name'] ??
          'Team Captain',
      'avatar_url': creatorProfile?['photoUrl'] ?? '',
      'status': 'paid', // Assume creator has paid
      'is_creator': true,
      'user_id': creatorUserId,
    });

    // Add joined players with actual profile data
    if (teamData?['joined_players'] is List) {
      final joinedPlayers = teamData!['joined_players'] as List;
      for (var player in joinedPlayers) {
        final userId = player['user_id'];
        final playerProfile = userProfileCache[userId];

        players.add({
          'name': playerProfile?['name'] ?? player['name'] ?? 'Player',
          'avatar_url': playerProfile?['photoUrl'] ?? '',
          'status': player['payment_status'] ?? 'pending',
          'is_creator': false,
          'user_id': userId,
        });
      }
    }

    return players;
  }

  @override
  Widget build(BuildContext context) {
    if (teamData == null) {
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
          child: const Center(
            child: CircularProgressIndicator(color: Colors.pink),
          ),
        ),
      );
    }

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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 30),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildTeamStatsSection(),
                  ),
                  const SizedBox(height: 30),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildTeamInfoSection(),
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildMyTeamSection(),
                  ),
                  const SizedBox(height: 20),
                  _buildTeamMembersList(),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    child: _buildPaymentButton(context),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 0.1,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.pink.shade200,
                    Colors.purple.shade200,
                  ],
                ).createShader(bounds),
            child: Text(
              'Team Payment',
              style: GoogleFonts.robotoSlab(
                color: Colors.white,
                fontSize: 28,
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
          ),
        ),
      ],
    );
  }

  Widget _buildTeamStatsSection() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.withOpacity(0.8),
              Colors.purple.withOpacity(0.8),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    'Team Status',
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                begin: Alignment(
                                  -1.0 + _shimmerAnimation.value,
                                  0.0,
                                ),
                                end: Alignment(
                                  1.0 + _shimmerAnimation.value,
                                  0.0,
                                ),
                                colors: [
                                  Colors.white.withOpacity(0.6),
                                  Colors.white,
                                  Colors.pink.shade100,
                                  Colors.white,
                                  Colors.white.withOpacity(0.6),
                                ],
                                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                              ).createShader(bounds),
                          child: Text(
                            '$joinedPlayersCount',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      'Joined',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                begin: Alignment(
                                  -1.0 + _shimmerAnimation.value,
                                  0.0,
                                ),
                                end: Alignment(
                                  1.0 + _shimmerAnimation.value,
                                  0.0,
                                ),
                                colors: [
                                  Colors.white.withOpacity(0.6),
                                  Colors.white,
                                  Colors.orange.shade100,
                                  Colors.white,
                                  Colors.white.withOpacity(0.6),
                                ],
                                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                              ).createShader(bounds),
                          child: Text(
                            '$needPlayersCount',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      'Needed',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfoSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff4a1554),
                    Color(0xff3d0d4e),
                    Color(0xff2d0a3a),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback:
                                  (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.pink.shade200,
                                    ],
                                  ).createShader(bounds),
                              child: Text(
                                '${teamData!['creator_name']}\'s Team',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${teamData!['turf_name']} • ${teamData!['selected_sport']}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${teamData!['slot_date']} • ${teamData!['slot_time']}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.withOpacity(0.8),
                              Colors.purple.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${amountPerPlayer.round()}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
                  Text(
                    'Your payment contribution per player',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
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

  Widget _buildMyTeamSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff4a1554),
                    Color(0xff3d0d4e),
                    Color(0xff2d0a3a),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, animValue, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * animValue),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xff9d7aa5),
                                Color(0xff7d6089),
                                Color(0xff6d5079),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.groups,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TEAM MEMBERS',
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
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [Colors.white, Colors.pink.shade200],
                              ).createShader(bounds),
                          child: Text(
                            'Active Players',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track payment status',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildTeamMembersList() {
    final players = joinedPlayersList;

    return Column(
      children:
          players
              .map(
                (player) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildMemberCard(player),
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic>? getCurrentUserData() {
    final currentUserAsync = ref.read(currentUserProvider);
    return currentUserAsync.when(
      data: (user) => user,
      loading: () => null,
      error: (error, stack) => null,
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> player) {
    return Consumer(
      builder: (context, ref, child) {
        final currentUserAsync = ref.watch(currentUserProvider);

        return currentUserAsync.when(
          data: (currentUser) {
            final isCurrentUser =
                currentUser != null &&
                player['user_id'] == currentUser['user_id'];

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(50.0 * (1.0 - value), 0.0),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:
                              isCurrentUser
                                  ? [
                                    const Color(0xFF6D2968),
                                    const Color(0xFF5D2558),
                                    const Color(0xFF4D1D48),
                                  ]
                                  : [
                                    const Color(0xFF5D2968),
                                    const Color(0xFF4D2558),
                                    const Color(0xFF3D1D48),
                                  ],
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color:
                              isCurrentUser
                                  ? Colors.yellow.withOpacity(0.5)
                                  : Colors.pink.withOpacity(0.3),
                          width: isCurrentUser ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isCurrentUser ? Colors.yellow : Colors.pink)
                                .withOpacity(0.2),
                            blurRadius: 12.0,
                            offset: const Offset(0.0, 6.0),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, animValue, child) {
                              return Transform.scale(
                                scale: animValue,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors:
                                          player['is_creator'] == true
                                              ? [
                                                const Color(0xFFFFD700),
                                                const Color(0xFFFFC107),
                                              ]
                                              : [Colors.pink, Colors.purple],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (player['is_creator'] == true
                                                ? const Color(0xFFFFD700)
                                                : Colors.pink)
                                            .withOpacity(0.4),
                                        blurRadius: 8.0,
                                        spreadRadius: 1.0,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 24.0,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        player['avatar_url'] != null &&
                                                player['avatar_url'].isNotEmpty
                                            ? CachedNetworkImageProvider(
                                              player['avatar_url'],
                                            )
                                            : null,
                                    child:
                                        player['avatar_url'] == null ||
                                                player['avatar_url'].isEmpty
                                            ? Icon(
                                              player['is_creator'] == true
                                                  ? Icons.star
                                                  : Icons.person,
                                              color: Colors.white,
                                              size: 20.0,
                                            )
                                            : null,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        player['name'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (player['is_creator'] == true) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD700),
                                              Color(0xFFFFC107),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'CAPTAIN',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.yellow,
                                              Colors.orange,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'YOU',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${amountPerPlayer.toDouble()} per player',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    player['status'] == 'paid'
                                        ? [
                                          Colors.green.withOpacity(0.8),
                                          Colors.teal.withOpacity(0.8),
                                        ]
                                        : [
                                          const Color(0xffD72664),
                                          Colors.pink.shade700,
                                        ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (player['status'] == 'paid'
                                          ? Colors.green
                                          : Colors.pink)
                                      .withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              player['status'] == 'paid' ? 'Paid' : 'Pending',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
          },
          loading: () => const SizedBox.shrink(), // Show nothing while loading
          error:
              (error, stack) =>
                  const SizedBox.shrink(), // Show nothing on error
        );
      },
    );
  }

  Widget _buildPaymentButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentUserAsync = ref.watch(currentUserProvider);

        return currentUserAsync.when(
          data: (currentUser) {
            if (currentUser == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Please login to make payment',
                  style: GoogleFonts.poppins(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              );
            }

            joinedPlayersList.any(
              (player) => player['user_id'] == currentUser['user_id'],
            );
            final hasUserPaid = joinedPlayersList.any(
              (player) =>
                  player['user_id'] == currentUser['user_id'] &&
                  player['status'] == 'paid',
            );

            // Don't show payment button if user has already paid
            if (hasUserPaid) {
              return _buildAlreadyPaidWidget();
            }

            final mediaQuery = MediaQuery.of(context);
            final screenSize = mediaQuery.size;
            final screenWidth = screenSize.width;
            final textScaleFactor = mediaQuery.textScaleFactor;

            final isExtraSmall = screenWidth < 320;
            final isSmall = screenWidth >= 320 && screenWidth < 375;
            final isMedium = screenWidth >= 375 && screenWidth < 414;
            final isLarge = screenWidth >= 414 && screenWidth < 480;
            final isExtraLarge = screenWidth >= 480;

            Map<String, dynamic> getResponsiveConfig() {
              if (isExtraSmall) {
                return {
                  'horizontalPadding': screenWidth * 0.06,
                  'verticalPadding': 12.0,
                  'fontSize': 14.0,
                  'iconSize': 16.0,
                  'borderRadius': 10.0,
                  'iconTextSpacing': 6.0,
                  'textArrowSpacing': 4.0,
                  'buttonWidth': 0.9,
                  'minHeight': 44.0,
                  'shadowBlur': 15.0,
                  'shadowOffset': 6.0,
                };
              } else if (isSmall) {
                return {
                  'horizontalPadding': screenWidth * 0.08,
                  'verticalPadding': 14.0,
                  'fontSize': 15.0,
                  'iconSize': 18.0,
                  'borderRadius': 12.0,
                  'iconTextSpacing': 8.0,
                  'textArrowSpacing': 6.0,
                  'buttonWidth': 0.88,
                  'minHeight': 48.0,
                  'shadowBlur': 18.0,
                  'shadowOffset': 7.0,
                };
              } else if (isMedium) {
                return {
                  'horizontalPadding': screenWidth * 0.10,
                  'verticalPadding': 16.0,
                  'fontSize': 16.0,
                  'iconSize': 19.0,
                  'borderRadius': 14.0,
                  'iconTextSpacing': 10.0,
                  'textArrowSpacing': 7.0,
                  'buttonWidth': 0.85,
                  'minHeight': 52.0,
                  'shadowBlur': 20.0,
                  'shadowOffset': 8.0,
                };
              } else if (isLarge) {
                return {
                  'horizontalPadding': screenWidth * 0.12,
                  'verticalPadding': 18.0,
                  'fontSize': 17.0,
                  'iconSize': 20.0,
                  'borderRadius': 16.0,
                  'iconTextSpacing': 12.0,
                  'textArrowSpacing': 8.0,
                  'buttonWidth': 0.82,
                  'minHeight': 56.0,
                  'shadowBlur': 22.0,
                  'shadowOffset': 9.0,
                };
              } else {
                return {
                  'horizontalPadding': screenWidth * 0.14,
                  'verticalPadding': 20.0,
                  'fontSize': 18.0,
                  'iconSize': 21.0,
                  'borderRadius': 18.0,
                  'iconTextSpacing': 14.0,
                  'textArrowSpacing': 10.0,
                  'buttonWidth': 0.8,
                  'minHeight': 60.0,
                  'shadowBlur': 25.0,
                  'shadowOffset': 10.0,
                };
              }
            }

            final config = getResponsiveConfig();
            final adjustedFontSize =
                (config['fontSize'] as double) /
                textScaleFactor.clamp(0.8, 1.3);

            return LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    width: constraints.maxWidth * config['buttonWidth'],
                    constraints: BoxConstraints(
                      maxWidth: isExtraLarge ? 450 : 380,
                      minWidth: isExtraSmall ? 250 : 280,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                config['borderRadius'],
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.pink.shade400,
                                  Colors.pink.shade600,
                                  Colors.purple.shade600,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.5),
                                  blurRadius: config['shadowBlur'],
                                  offset: Offset(0, config['shadowOffset']),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () => _initiatePayment(currentUser),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  horizontal: config['horizontalPadding'],
                                  vertical: config['verticalPadding'],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    config['borderRadius'],
                                  ),
                                ),
                                minimumSize: Size(
                                  constraints.maxWidth * 0.6,
                                  config['minHeight'],
                                ),
                              ),
                              child:
                                  isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      )
                                      : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.payment,
                                              color: Colors.white,
                                              size: config['iconSize'],
                                            ),
                                            SizedBox(
                                              width: config['iconTextSpacing'],
                                            ),
                                            Flexible(
                                              child: Text(
                                                'Pay ₹${amountPerPlayer.round()}',
                                                style: GoogleFonts.nunito(
                                                  fontSize: adjustedFontSize,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing:
                                                      isExtraSmall ? 0.2 : 0.5,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(
                                              width: config['textArrowSpacing'],
                                            ),
                                            TweenAnimationBuilder<double>(
                                              tween: Tween(
                                                begin: 0.0,
                                                end: 1.0,
                                              ),
                                              duration: const Duration(
                                                milliseconds: 1200,
                                              ),
                                              builder: (
                                                context,
                                                animValue,
                                                child,
                                              ) {
                                                return Transform.translate(
                                                  offset: Offset(
                                                    5 * animValue,
                                                    0,
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white,
                                                    size: config['iconSize'],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
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
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
          error:
              (error, stack) => Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading user data',
                  style: GoogleFonts.poppins(color: Colors.red.shade300),
                  textAlign: TextAlign.center,
                ),
              ),
        );
      },
    );
  }

  // Update your _initiatePayment method to accept currentUser parameter
  void _initiatePayment(Map<String, dynamic> currentUser) {
    setState(() {
      isLoading = true;
    });

    Razorpay razorpay = Razorpay();

    var options = {
      'key': 'rzp_test_0rwYxZvUXDUeW7', // Replace with your Razorpay key
      'amount': (amountPerPlayer * 100).round(), // Amount in paise
      'name': 'Team Payment',
      'description':
          'Payment for ${teamData!['turf_name']} - ${teamData!['selected_sport']}',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': currentUser['phone_number'] ?? '8888888888',
        'email': currentUser['email'] ?? 'user@example.com',
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentErrorResponse);
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccessResponse);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWalletSelected);

    try {
      razorpay.open(options);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showAlertDialog("Error", "Failed to open payment gateway: $e");
    }
  }

  // Update your _updateTeamAfterPayment method
  Future<void> _updateTeamAfterPayment(String paymentId) async {
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.when(
      data: (user) => user,
      loading: () => null,
      error: (error, stack) => null,
    );

    if (currentUser == null) {
      throw Exception('User not found');
    }

    final teamId = teamData!['team_id'];
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
      final userExists = joinedPlayers.any(
        (player) => player['user_id'] == currentUser['user_id'],
      );

      if (!userExists && currentNeedPlayers > 0) {
        // Add user to joined_players array
        joinedPlayers.add({
          'user_id': currentUser['user_id'],
          'name': currentUser['name'],
          'avatar_url': currentUser['avatar_url'] ?? '',
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
      } else if (userExists) {
        // Update existing user's payment status
        final userIndex = joinedPlayers.indexWhere(
          (player) => player['user_id'] == currentUser['user_id'],
        );

        if (userIndex != -1) {
          joinedPlayers[userIndex]['payment_status'] = 'paid';
          joinedPlayers[userIndex]['payment_id'] = paymentId;
          joinedPlayers[userIndex]['payment_completed_at'] =
              FieldValue.serverTimestamp();

          transaction.update(teamRef, {
            'joined_players': joinedPlayers,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Widget _buildAlreadyPaidWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.8),
              Colors.teal.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Payment Completed!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePaymentErrorResponse(PaymentFailureResponse response) {
    setState(() {
      isLoading = false;
    });
    _showAlertDialog(
      "Payment Failed",
      "Code: ${response.code}\nDescription: ${response.message}\nMetadata:${response.error.toString()}",
    );
  }

  void _handlePaymentSuccessResponse(PaymentSuccessResponse response) async {
    setState(() {
      isLoading = false;
    });

    try {
      await _updateTeamAfterPayment(response.paymentId!);
      _showAlertDialog(
        "Payment Successful",
        "Payment ID: ${response.paymentId}\nYou have successfully joined the team!",
        isSuccess: true,
      );
    } catch (e) {
      _showAlertDialog(
        "Update Failed",
        "Payment was successful but failed to update team data. Please contact support.\nPayment ID: ${response.paymentId}",
      );
    }
  }

  void _handleExternalWalletSelected(ExternalWalletResponse response) {
    setState(() {
      isLoading = false;
    });
    _showAlertDialog("External Wallet Selected", "${response.walletName}");
  }

  void _showAlertDialog(
    String title,
    String message, {
    bool isSuccess = false,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D1A4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red.shade300,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (isSuccess) {
                  // Optionally navigate back or to a success screen
                  Navigator.pop(context);
                }
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color:
                      isSuccess ? Colors.green.shade300 : Colors.pink.shade300,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Animation<double>>(
        '_bounceAnimation',
        _bounceAnimation,
      ),
    );
  }
}
