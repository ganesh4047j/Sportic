import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports/Main%20Screens/booking_turf.dart';
import 'package:sports/Main%20Screens/connections.dart';
import 'package:sports/Main%20Screens/location.dart';
import 'package:sports/Main%20Screens/profile.dart';
import 'package:sports/Main%20Screens/turfscreen.dart';
import 'package:sports/Providers/turfscreen_provider.dart';
import '../Create Team/create_team.dart';
import '../Services/privacy_policy_service.dart';
import 'category.dart';
import 'chat_screen.dart';
import 'favourites.dart';
import 'live_screen.dart';
import 'mvp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

final sportsProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {'image': 'assets/images/football.png', 'text': 'Football'},
    {'image': 'assets/images/cricket.png', 'text': 'Cricket'},
    {'image': 'assets/images/tennis.png', 'text': 'Tennis'},
    {'image': 'assets/images/badminton.png', 'text': 'Badminton'},
    {'image': 'assets/images/pickle_ball.png', 'text': 'Pickle Ball'},
  ];
});

// Fixed provider to listen to all unread messages for current user
final unreadMessagesProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  // Get current user ID
  String? currentUserId;
  try {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      currentUserId = fbUser.uid;
    } else {
      const secureStorage = FlutterSecureStorage();
      currentUserId = await secureStorage.read(key: 'custom_uid');
    }

    if (currentUserId == null || currentUserId.isEmpty) {
      print('🚨 No current user ID found for notifications');
      yield [];
      return;
    }

    print('🔔 Setting up notification listener for user: $currentUserId');

    // Step 1: Get all chats where user is a participant
    await for (final chatSnapshot
        in FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots()) {
      print('🔔 Found ${chatSnapshot.docs.length} chats for user');

      final allUnreadMessages = <Map<String, dynamic>>[];

      // Step 2: For each chat, get unread messages
      for (final chatDoc in chatSnapshot.docs) {
        try {
          final chatId = chatDoc.id;
          print('🔔 Checking chat: $chatId');

          // Get unread messages from this chat
          final messageSnapshot =
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .where('to', isEqualTo: currentUserId)
                  .where('read', isEqualTo: false)
                  .orderBy('timestamp', descending: true)
                  .limit(5) // Limit per chat
                  .get();

          print(
            '🔔 Found ${messageSnapshot.docs.length} unread messages in chat $chatId',
          );

          for (final messageDoc in messageSnapshot.docs) {
            final data = Map<String, dynamic>.from(messageDoc.data());
            data['id'] = messageDoc.id;
            data['chatId'] = chatId;

            print(
              '🔔 Unread message: ${data['id']} from ${data['from']} - "${data['text']}"',
            );
            allUnreadMessages.add(data);
          }
        } catch (e) {
          print('🚨 Error getting messages for chat ${chatDoc.id}: $e');
        }
      }

      // Step 3: Sort all messages by timestamp (newest first)
      allUnreadMessages.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      final limitedMessages = allUnreadMessages.take(10).toList();
      print('🔔 Yielding ${limitedMessages.length} total unread messages');

      yield limitedMessages;
    }
  } catch (e, stackTrace) {
    print('🚨 Error in unreadMessagesProvider: $e');
    print('🚨 Stack trace: $stackTrace');
    yield [];
  }
});

// Fallback provider that uses a simpler approach
final simpleUnreadCountProvider = StreamProvider<int>((ref) async* {
  try {
    String? currentUserId;
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      currentUserId = fbUser.uid;
    } else {
      const secureStorage = FlutterSecureStorage();
      currentUserId = await secureStorage.read(key: 'custom_uid');
    }

    if (currentUserId == null) {
      yield 0;
      return;
    }

    print('🔔 Simple count provider for user: $currentUserId');

    // Just count unread messages across all chats
    await for (final snapshot
        in FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots()) {
      int totalUnread = 0;

      for (final chatDoc in snapshot.docs) {
        try {
          final messageSnapshot =
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatDoc.id)
                  .collection('messages')
                  .where('to', isEqualTo: currentUserId)
                  .where('read', isEqualTo: false)
                  .get();

          totalUnread += messageSnapshot.docs.length;
        } catch (e) {
          print('🚨 Error counting messages in chat ${chatDoc.id}: $e');
        }
      }

      print('🔔 Total unread count: $totalUnread');
      yield totalUnread;
    }
  } catch (e) {
    print('🚨 Error in simpleUnreadCountProvider: $e');
    yield 0;
  }
});

// Provider to get user details for notifications
final userDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      if (userId.isEmpty) return null;

      try {
        // Try email collection first
        final emailDoc =
            await FirebaseFirestore.instance
                .collection('user_details_email')
                .doc(userId)
                .get();

        if (emailDoc.exists) {
          return emailDoc.data();
        }

        // Try phone collection
        final phoneDoc =
            await FirebaseFirestore.instance
                .collection('user_details_phone')
                .doc(userId)
                .get();

        if (phoneDoc.exists) {
          return phoneDoc.data();
        }

        return null;
      } catch (e) {
        print('Error fetching user details: $e');
        return null;
      }
    });

// Add providers for today's schedule
final todayBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final userProfile = await ref.watch(userProfileProvider.future);
  if (userProfile['uid'] == null) return [];

  final today = DateTime.now();
  final todayString = '${today.day}-${today.month}-${today.year}';

  try {
    final bookingsSnapshot =
        await FirebaseFirestore.instance
            .collection('booking_details')
            .doc(userProfile['uid']) // Using user's uid as document ID
            .collection(userProfile['uid'])
            .where('slot_date', isEqualTo: todayString)
            .orderBy('booking_timestamp', descending: true)
            .get();

    return bookingsSnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  } catch (e) {
    print('Error fetching bookings: $e');
    return [];
  }
});

final todayTeamsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final userProfile = await ref.watch(userProfileProvider.future);
  if (userProfile['uid'] == null) return [];

  final today = DateTime.now();
  final todayString = '${today.day}-${today.month}-${today.year}';

  try {
    final teamsSnapshot =
        await FirebaseFirestore.instance
            .collection('created_team')
            .where('slot_date', isEqualTo: todayString)
            .where('creator_user_id', isEqualTo: userProfile['uid'])
            .orderBy('team_timestamp', descending: true)
            .get();

    return teamsSnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  } catch (e) {
    print('Error fetching teams: $e');
    return [];
  }
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // Add method to show schedule popup
  void _showSchedulePopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SchedulePopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sportsAsync = ref.watch(sportsProvider);
    final turfAsync = ref.watch(turfListProvider);

    const mainImage =
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2670&q=80';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedLocation = prefs.getString('user_location');
      if (savedLocation != null) {
        ref.read(userLocationProvider.notifier).state = savedLocation;
      }
    });

    Widget _buildSection_recent(
      String title,
      List<TurfModel> turfList,
      Color titleColor,
    ) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [titleColor, titleColor.withOpacity(0.7)],
                      ).createShader(bounds),
                  child: Text(
                    title,
                    style: GoogleFonts.robotoSlab(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: turfList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final turf = turfList[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Opacity(
                            opacity: value,
                            child: Hero(
                              tag: 'turf_${turf.name}_$index',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => BookingPage(
                                              turfImages: turf.imageUrl,
                                              turfName: turf.name,
                                              location: turf.location,
                                              owner_id: turf.ownerId,
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
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(
                                            0xFF452152,
                                          ).withOpacity(0.3),
                                          const Color(
                                            0xFF3D1A4A,
                                          ).withOpacity(0.5),
                                          const Color(
                                            0xFF200D28,
                                          ).withOpacity(0.7),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: const Color(
                                          0xff979698,
                                        ).withOpacity(0.6),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF452152,
                                          ).withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      width: 320,
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Image.network(
                                                turf.imageUrl.isNotEmpty
                                                    ? turf.imageUrl
                                                    : 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                                                height: 160,
                                                width: 280,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    height: 160,
                                                    width: 280,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          const Color(
                                                            0xFF452152,
                                                          ).withOpacity(0.3),
                                                          const Color(
                                                            0xFF3D1A4A,
                                                          ).withOpacity(0.5),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              const Color(
                                                                0xFF452152,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    height: 160,
                                                    width: 280,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          const Color(
                                                            0xFF452152,
                                                          ).withOpacity(0.3),
                                                          const Color(
                                                            0xFF3D1A4A,
                                                          ).withOpacity(0.5),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.sports_soccer,
                                                          color: Colors.white70,
                                                          size: 40,
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          turf.name,
                                                          style:
                                                              GoogleFonts.robotoSlab(
                                                                color:
                                                                    Colors
                                                                        .white70,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    turf.name,
                                                    style:
                                                        GoogleFonts.robotoSlab(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                          colors: [
                                                            Color(0xFFFFD700),
                                                            Color(0xFFFFA500),
                                                          ],
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '4.8',
                                                        style:
                                                            GoogleFonts.robotoSlab(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF452152,
                                                    ).withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: Colors.white70,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    turf.location,
                                                    style:
                                                        GoogleFonts.robotoSlab(
                                                          color: Colors.white70,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildSection_top_rating_turf(
      String title,
      List<TurfModel> turfList,
      Color titleColor,
    ) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShaderMask(
                shaderCallback:
                    (bounds) => LinearGradient(
                      colors: [titleColor, titleColor.withOpacity(0.7)],
                    ).createShader(bounds),
                child: Text(
                  title,
                  style: GoogleFonts.robotoSlab(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 340,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: turfList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final turf = turfList[index];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 800 + (index * 150)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: _buildEnhancedTurfCard(context, turf, index),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildSection_nearest_turf(
      String title,
      AsyncValue<List<Map<String, String>>> sportsAsync,
      Color titleColor,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShaderMask(
              shaderCallback:
                  (bounds) => LinearGradient(
                    colors: [titleColor, titleColor.withOpacity(0.7)],
                  ).createShader(bounds),
              child: Text(
                title,
                style: GoogleFonts.robotoSlab(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 340,
            child: sportsAsync.when(
              loading:
                  () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF452152),
                      ),
                    ),
                  ),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (sports) {
                if (sports.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF452152).withOpacity(0.3),
                            const Color(0xFF3D1A4A).withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No nearest turf available for your location.',
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: sports.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final turf = sports[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: Opacity(
                            opacity: value,
                            child: _buildNearestTurfCard(context, turf, index),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: Container(
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16, // Normal bottom padding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildHeader(ref, context),
                        ),
                        const SizedBox(height: 20),
                        SlideTransition(
                          position: _slideAnimation,
                          child: _buildHeroImage(mainImage),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ShaderMask(
                            shaderCallback:
                                (bounds) => const LinearGradient(
                                  colors: [Colors.white, Color(0xFFD1C4E9)],
                                ).createShader(bounds),
                            child: Text(
                              'Sports',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildSportsCards(sportsAsync, context),
                        ),
                        const SizedBox(height: 30),
                        SlideTransition(
                          position: _slideAnimation,
                          child: _buildStartPlayingCard(context),
                        ),
                        const SizedBox(height: 30),
                        _buildActionCards(context),
                        const SizedBox(height: 30),
                        _buildSection_recent(
                          'Recent',
                          turfAsync,
                          const Color(0xFFE1BEE7),
                        ),
                        const SizedBox(height: 20),
                        _buildSection_top_rating_turf(
                          'Top Rating Turf',
                          turfAsync,
                          const Color(0xFFCE93D8),
                        ),
                        const SizedBox(height: 20),
                        Consumer(
                          builder: (context, ref, _) {
                            final nearestTurfs = ref.watch(nearestTurfProvider);
                            final asyncTurfs = AsyncValue.data(
                              nearestTurfs
                                  .map(
                                    (turf) => {
                                      'name': turf['name']!,
                                      'imageUrl': turf['imageUrl']!,
                                      'location': turf['location']!,
                                      'ownerId': turf['ownerId']!,
                                    },
                                  )
                                  .toList(),
                            );

                            return _buildSection_nearest_turf(
                              'Nearest Turf',
                              asyncTurfs,
                              const Color(0xFFBA68C8),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildFooter(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom Navigation Bar
              Container(
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
                  onTap:
                      (index) =>
                          ref.read(navIndexProvider.notifier).state = index,
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
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                      backgroundColor: Color(0xff22012c),
                    ),
                    BottomNavigationBarItem(
                      icon: IconButton(
                        onPressed: () {
                          print('Games button clicked');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.videogame_asset),
                      ),
                      label: 'Games',
                      backgroundColor: const Color(0xff22012c),
                    ),
                    BottomNavigationBarItem(
                      icon: IconButton(
                        onPressed: () {
                          print('Live button clicked');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CenterLottieScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.live_tv),
                      ),
                      label: 'Live',
                      backgroundColor: const Color(0xff22012c),
                    ),
                    BottomNavigationBarItem(
                      icon: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TurfHomeScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.sports_soccer),
                      ),
                      label: 'Turf',
                      backgroundColor: const Color(0xff22012c),
                    ),
                    BottomNavigationBarItem(
                      icon: IconButton(
                        onPressed: () {
                          print('Fav button clicked');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FollowingScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.favorite),
                      ),
                      label: 'Fav',
                      backgroundColor: const Color(0xff22012c),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Positioned Floating Action Button - Right side above bottom nav
          Positioned(
            right: 10, // Distance from right edge
            bottom: 100, // Distance from bottom (above bottom nav)
            child: _buildAnimatedFloatingActionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFloatingActionButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Try main provider first
        final unreadMessages = ref.watch(unreadMessagesProvider);
        final simpleCount = ref.watch(simpleUnreadCountProvider);

        int unreadCount = 0;

        unreadMessages.when(
          data: (messages) {
            unreadCount = messages.length;
            print('🔔 FAB: Main provider - ${messages.length} messages');
          },
          loading: () {
            print('🔔 FAB: Main provider loading...');
            // Use simple count as fallback
            simpleCount.whenData((count) {
              unreadCount = count;
              print('🔔 FAB: Using simple count - $count');
            });
          },
          error: (error, stack) {
            print('🚨 FAB: Main provider error: $error');
            // Use simple count as fallback
            simpleCount.whenData((count) {
              unreadCount = count;
              print('🔔 FAB: Fallback to simple count - $count');
            });
          },
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: unreadCount > 0 ? 1000 : 2000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + ((unreadCount > 0 ? 0.4 : 0.25) * value),
                      child: Opacity(
                        opacity: 1.0 - value,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (unreadCount > 0
                                      ? const Color(0xFFFF5722)
                                      : const Color(0xFFE91E63))
                                  .withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Middle glowing ring
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1.0 + (0.15 * value),
                  child: Opacity(
                    opacity: 0.7 - (0.7 * value),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (unreadCount > 0
                                    ? const Color(0xFFFF5722)
                                    : const Color(0xFFE91E63))
                                .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main FAB
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 0.1,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 3000),
                    tween: Tween(begin: 1.0, end: 1.08),
                    builder: (context, scaleValue, child) {
                      return Transform.scale(
                        scale: scaleValue,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors:
                                  unreadCount > 0
                                      ? [
                                        const Color(0xFFFF5722),
                                        const Color(0xFFE64A19),
                                        const Color(0xFFBF360C),
                                      ]
                                      : [
                                        const Color(0xFFE91E63),
                                        const Color(0xFFAD1457),
                                        const Color(0xFF880E4F),
                                      ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (unreadCount > 0
                                        ? const Color(0xFFFF5722)
                                        : const Color(0xFFE91E63))
                                    .withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: (unreadCount > 0
                                        ? const Color(0xFFFF5722)
                                        : const Color(0xFFE91E63))
                                    .withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showSimpleNotificationDialog(context, ref);
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Animated bell icon
                                    TweenAnimationBuilder<double>(
                                      duration: Duration(
                                        milliseconds:
                                            unreadCount > 0 ? 500 : 1000,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, bellValue, child) {
                                        return Transform.rotate(
                                          angle:
                                              (bellValue *
                                                  (unreadCount > 0
                                                      ? 0.4
                                                      : 0.2)) -
                                              (unreadCount > 0 ? 0.2 : 0.1),
                                          child: Icon(
                                            unreadCount > 0
                                                ? Icons.notifications_active
                                                : Icons.notifications,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),

                                    // Dynamic notification badge
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 10,
                                        top: 10,
                                        child: TweenAnimationBuilder<double>(
                                          duration: const Duration(
                                            milliseconds: 800,
                                          ),
                                          tween: Tween(begin: 0.8, end: 1.3),
                                          builder: (
                                            context,
                                            badgeValue,
                                            child,
                                          ) {
                                            return Transform.scale(
                                              scale: badgeValue,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFD700,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFFFFD700,
                                                      ).withOpacity(0.8),
                                                      blurRadius: 10,
                                                      spreadRadius: 3,
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    unreadCount > 9
                                                        ? '9+'
                                                        : unreadCount
                                                            .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 7,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Particle effects
            ...List.generate(6, (index) {
              return AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  final angle =
                      (index * 60.0) + (_rotationController.value * 360);
                  final radians = angle * (3.14159 / 180);
                  final radius = 40.0;

                  return Transform.translate(
                    offset: Offset(
                      radius * math.cos(radians),
                      radius * math.sin(radians),
                    ),
                    child: TweenAnimationBuilder<double>(
                      duration: Duration(
                        milliseconds:
                            (unreadCount > 0 ? 600 : 1000) + (index * 200),
                      ),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, sparkleValue, child) {
                        return Opacity(
                          opacity: sparkleValue * (unreadCount > 0 ? 0.9 : 0.7),
                          child: Container(
                            width: unreadCount > 0 ? 4 : 3,
                            height: unreadCount > 0 ? 4 : 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.5),
                                  blurRadius: unreadCount > 0 ? 6 : 4,
                                  spreadRadius: unreadCount > 0 ? 2 : 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  // Simplified notification dialog
  void _showSimpleNotificationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Consumer(
            builder: (context, ref, _) {
              final unreadMessagesAsync = ref.watch(unreadMessagesProvider);

              return AlertDialog(
                backgroundColor: const Color(0xFF452152),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFFE91E63),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: GoogleFonts.robotoSlab(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Container(
                  width: double.maxFinite,
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: unreadMessagesAsync.when(
                    loading:
                        () => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE91E63),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading notifications...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                    error:
                        (error, stack) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red.withOpacity(0.7),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading notifications',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please check your connection',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E63),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Force refresh
                                  ref.invalidate(unreadMessagesProvider);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 48,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No new notifications',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'You\'re all caught up!',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildSimpleNotificationItem(
                            context,
                            ref,
                            message,
                          );
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFE91E63),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildSimpleNotificationItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> message,
  ) {
    final messageText = message['text'] ?? 'New message';
    final time = _formatNotificationTime(message['timestamp']);
    final senderId = message['from'] ?? '';

    return Consumer(
      builder: (context, ref, _) {
        // Watch the user details for this specific sender
        final userDetailsAsync = ref.watch(userDetailsProvider(senderId));

        return userDetailsAsync.when(
          loading:
              () => _buildShimmerNotificationItemSkeleton(
                context,
                messageText,
                time,
              ),
          error: (error, stack) {
            print('Error fetching user details for $senderId: $error');
            return _buildNotificationItemContent(
              context,
              ref,
              message,
              'Unknown User', // Fallback name
              messageText,
              time,
            );
          },
          data: (userDetails) {
            // Extract the name from user details
            String senderName = 'Unknown User'; // Default fallback

            if (userDetails != null) {
              // Try different possible name fields
              senderName =
                  userDetails['name'] ??
                  userDetails['displayName'] ??
                  userDetails['username'] ??
                  userDetails['email']?.split('@')[0] ??
                  'User';
            }

            return _buildNotificationItemContent(
              context,
              ref,
              message,
              senderName,
              messageText,
              time,
            );
          },
        );
      },
    );
  }

  // Extract the actual notification item content to avoid duplication
  Widget _buildNotificationItemContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> message,
    String senderName,
    String messageText,
    String time,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChatPage(
                    chatId: message['chatId'] ?? '',
                    peerUid: message['from'] ?? '',
                    peerName: senderName, // Use the actual sender name
                    peerEmail: '',
                  ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.message,
                  color: Color(0xFF2196F3),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            senderName,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      messageText.length > 50
                          ? '${messageText.substring(0, 50)}...'
                          : messageText,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white30,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading skeleton while fetching user details
  Widget _buildShimmerNotificationItemSkeleton(
    BuildContext context,
    String messageText,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.message,
              color: Color(0xFF2196F3),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),

          // Content area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with name skeleton and time
                Row(
                  children: [
                    // Name skeleton with shimmer
                    Expanded(
                      flex: 2,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Container(
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1.0 + (2.0 * value), 0.0),
                                end: Alignment(1.0 + (2.0 * value), 0.0),
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Time - constrained to prevent overflow
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.2,
                      ),
                      child: Text(
                        time,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Message text
                Text(
                  messageText.length > 50
                      ? '${messageText.substring(0, 50)}...'
                      : messageText,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Arrow icon with padding
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white30,
              size: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Time formatting function
  String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'Now';

    try {
      final DateTime messageTime;
      if (timestamp is Timestamp) {
        messageTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        messageTime = timestamp;
      } else {
        return 'Now';
      }

      final now = DateTime.now();
      final difference = now.difference(messageTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Now';
    }
  }

  Widget _buildEnhancedTurfCard(
    BuildContext context,
    TurfModel turf,
    int index,
  ) {
    return Hero(
      tag: 'turf_top_${turf.name}_$index',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) => BookingPage(
                      turfImages: turf.imageUrl,
                      turfName: turf.name,
                      location: turf.location,
                      owner_id: turf.ownerId,
                    ),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6A1B9A).withOpacity(0.4),
                  const Color(0xFF4A148C).withOpacity(0.6),
                  const Color(0xFF1A0E2E).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            turf.imageUrl.isNotEmpty
                                ? turf.imageUrl
                                : 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                            height: 160,
                            width: 280,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'TOP RATED',
                              style: GoogleFonts.robotoSlab(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            turf.name,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: GoogleFonts.robotoSlab(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF452152).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            turf.location,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildNearestTurfCard(
    BuildContext context,
    Map<String, String> turf,
    int index,
  ) {
    final name = turf['name'] ?? 'Turf';
    final imageUrl =
        turf['imageUrl'] ??
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
    final location = turf['location'] ?? 'Unknown';

    return Hero(
      tag: 'turf_nearest_${name}_$index',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) => BookingPage(
                      turfImages: turf['imageUrl']!,
                      turfName: turf['name']!,
                      location: turf['location']!,
                      owner_id: turf['ownerId']!,
                    ),
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
                        curve: Curves.easeInOutQuart,
                      ),
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF7B1FA2).withOpacity(0.3),
                  const Color(0xFF4A148C).withOpacity(0.6),
                  const Color(0xFF1A0E2E).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF7B1FA2).withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            imageUrl,
                            height: 160,
                            width: 280,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'NEARBY',
                                  style: GoogleFonts.robotoSlab(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: GoogleFonts.robotoSlab(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

  // Updated helper functions with smaller font sizes
  double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Using a base width of 375 (iPhone 8 width)
    final scaleFactor = screenWidth / 375;

    // More aggressive scaling down for smaller screens
    double clampedScaleFactor;
    if (screenWidth < 320) {
      clampedScaleFactor = scaleFactor.clamp(0.7, 0.85); // Very small screens
    } else if (screenWidth < 360) {
      clampedScaleFactor = scaleFactor.clamp(0.75, 0.9); // Small screens
    } else if (screenWidth < 400) {
      clampedScaleFactor = scaleFactor.clamp(0.8, 0.95); // Medium small screens
    } else {
      clampedScaleFactor = scaleFactor.clamp(
        0.85,
        1.1,
      ); // Normal and large screens
    }

    return baseSize * clampedScaleFactor;
  }

  // Helper function to get responsive padding
  double getResponsivePadding(BuildContext context, double basePadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    // More aggressive padding reduction for smaller screens
    if (screenWidth < 320) return basePadding * 0.5; // Very small screens
    if (screenWidth < 360) return basePadding * 0.7; // Small screens
    if (screenWidth < 400) return basePadding * 0.8; // Medium small screens
    if (screenWidth > 600) return basePadding * 1.2; // Large screens/tablets
    return basePadding; // Normal screens
  }

  Widget _buildHeader(WidgetRef ref, BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
      data: (profile) {
        final globalLocation = ref.watch(userLocationProvider);
        final location = globalLocation ?? profile['location'] ?? 'Unknown';
        final imageUrl = profile['photoUrl'] ?? 'https://i.pravatar.cc/300';

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: getResponsivePadding(context, 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              const LocationInputScreen(
                                shouldRedirectToHome: true,
                              ),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1.0, 0.0),
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
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(
                    getResponsivePadding(context, 10),
                  ), // Reduced from 12
                  constraints: BoxConstraints(
                    minWidth:
                        MediaQuery.of(context).size.width *
                        0.32, // Reduced from 0.35
                    maxWidth:
                        MediaQuery.of(context).size.width *
                        0.50, // Reduced from 0.55
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      getResponsivePadding(
                        context,
                        14,
                      ), // Responsive border radius
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Your location",
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: getResponsiveFontSize(
                            context,
                            10,
                          ), // Reduced from 12
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: getResponsivePadding(context, 3),
                      ), // Reduced from 4
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFFE91E63),
                            size: getResponsiveFontSize(
                              context,
                              14,
                            ), // Reduced from 16
                          ),
                          SizedBox(
                            width: getResponsivePadding(context, 3),
                          ), // Reduced from 4
                          Flexible(
                            child: Text(
                              location,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: getResponsiveFontSize(
                                  context,
                                  12,
                                ), // Reduced from 14
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: getResponsivePadding(context, 8),
              ), // Responsive spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // MVP Button
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFD700).withOpacity(0.3),
                                const Color(0xFFFFA500).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              getResponsivePadding(context, 14),
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const MvpPage(),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.elasticOut,
                                        ),
                                      ),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(
                              getResponsivePadding(context, 14),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                getResponsivePadding(context, 7),
                              ), // Reduced from 8
                              child: Column(
                                children: [
                                  RotationTransition(
                                    turns: _rotationAnimation,
                                    child: Icon(
                                      Icons.emoji_events,
                                      color: const Color(0xFFFFD700),
                                      size: getResponsiveFontSize(
                                        context,
                                        16,
                                      ), // Reduced from 18
                                    ),
                                  ),
                                  SizedBox(
                                    height: getResponsivePadding(context, 2),
                                  ),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      return Text(
                                        'MVP',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: getResponsiveFontSize(
                                            context,
                                            10,
                                          ), // Reduced from 12
                                          fontWeight: FontWeight.w600,
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
                  SizedBox(
                    width: getResponsivePadding(context, 8),
                  ), // Reduced spacing
                  // Chat Button
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2196F3).withOpacity(0.3),
                                const Color(0xFF1976D2).withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              getResponsivePadding(context, 14),
                            ),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withOpacity(0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const ConnectionsPage(),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, -1.0),
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
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(
                              getResponsivePadding(context, 14),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                getResponsivePadding(context, 7),
                              ), // Reduced from 8
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.message_rounded,
                                    color: const Color(0xFF2196F3),
                                    size: getResponsiveFontSize(
                                      context,
                                      18,
                                    ), // Reduced from 20
                                  ),
                                  SizedBox(
                                    height: getResponsivePadding(context, 3),
                                  ), // Reduced from 4
                                  Text(
                                    'Chat',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: getResponsiveFontSize(
                                        context,
                                        9,
                                      ), // Reduced from 10
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: getResponsivePadding(context, 8),
                  ), // Reduced spacing
                  // Profile Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const ProfileScreen(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
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
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE91E63),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: getResponsiveFontSize(
                          context,
                          20,
                        ), // Responsive avatar size, reduced from 24
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroImage(String imageUrl) {
    return Container(
      height: 220,
      child: Stack(
        children: [
          Card(
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF452152),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.white),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME TO SPORTIC',
                          style: GoogleFonts.robotoSlab(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your ultimate sports community platform',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.robotoSlab(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsCards(
    AsyncValue<List<Map<String, String>>> sportsAsync,
    BuildContext context,
  ) {
    final List<List<Color>> cardGradients = [
      [const Color(0xFFE1BEE7), const Color(0xFFCE93D8)],
      [const Color(0xFFFFCC80), const Color(0xFFFF8A65)],
      [const Color(0xFF81D4FA), const Color(0xFF4FC3F7)],
      [const Color(0xFFC8E6C9), const Color(0xFF81C784)],
      [const Color(0xFFD1C4E9), const Color(0xFFBA68C8)],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen dimensions for responsive design
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth;

        // Define responsive breakpoints
        bool isSmallScreen = screenWidth <= 360; // iPhone SE, small Android
        bool isMediumScreen =
            screenWidth > 360 &&
            screenWidth <= 414; // iPhone 12, standard phones
        bool isLargeScreen = screenWidth > 414; // iPhone Pro Max, large phones

        // Calculate responsive dimensions
        double cardHeight, cardWidth, fontSize, padding, margin;

        if (isSmallScreen) {
          cardHeight = 130.0;
          cardWidth = (availableWidth - 32) / 3; // 3 cards with margins
          fontSize = 12.0;
          padding = 8.0;
          margin = 6.0;
        } else if (isMediumScreen) {
          cardHeight = 145.0;
          cardWidth = (availableWidth - 40) / 3;
          fontSize = 13.0;
          padding = 10.0;
          margin = 8.0;
        } else {
          cardHeight = 160.0;
          cardWidth = (availableWidth - 48) / 3;
          fontSize = 14.0;
          padding = 12.0;
          margin = 10.0;
        }

        // Ensure minimum card width
        cardWidth = cardWidth.clamp(90.0, 150.0);

        return SizedBox(
          height: cardHeight,
          child: sportsAsync.when(
            loading:
                () => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF452152),
                    ),
                  ),
                ),
            error:
                (error, stack) => Center(
                  child: Text(
                    'Error: $error',
                    style: TextStyle(color: Colors.white, fontSize: fontSize),
                  ),
                ),
            data: (sports) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: sports.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 800 + (index * 200)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(30 * (1 - value), 0),
                        child: Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              width: cardWidth,
                              height: cardHeight,
                              margin: EdgeInsets.only(
                                right: index == sports.length - 1 ? 0 : margin,
                                left: index == 0 ? 16 : 0,
                              ),
                              child: Hero(
                                tag: 'sport_${sports[index]['text']}_$index',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => const HomePage(),
                                          transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: ScaleTransition(
                                                scale: Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ).animate(
                                                  CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.elasticOut,
                                                  ),
                                                ),
                                                child: child,
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors:
                                              cardGradients[index %
                                                  cardGradients.length],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: cardGradients[index %
                                                    cardGradients.length][0]
                                                .withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Background Image
                                            TweenAnimationBuilder<double>(
                                              duration: Duration(
                                                milliseconds:
                                                    1000 + (index * 100),
                                              ),
                                              tween: Tween(
                                                begin: 1.1,
                                                end: 1.0,
                                              ),
                                              builder: (
                                                context,
                                                scaleValue,
                                                child,
                                              ) {
                                                return Transform.scale(
                                                  scale: scaleValue,
                                                  child: Image.asset(
                                                    sports[index]['image']!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      print(
                                                        'Image loading error for ${sports[index]['text']}: $error',
                                                      );
                                                      String fallbackImage =
                                                          _getFallbackImage(
                                                            sports[index]['text']!,
                                                          );

                                                      return Image.network(
                                                        fallbackImage,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (
                                                          context,
                                                          error2,
                                                          stackTrace2,
                                                        ) {
                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors:
                                                                    cardGradients[index %
                                                                        cardGradients
                                                                            .length],
                                                              ),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                sports[index]['text']!,
                                                                style: GoogleFonts.poppins(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      fontSize,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            ),

                                            // Gradient Overlay
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(
                                                      0.2,
                                                    ),
                                                    Colors.black.withOpacity(
                                                      0.7,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Text Content
                                            Positioned(
                                              bottom: padding,
                                              left: padding,
                                              right: padding,
                                              child: TweenAnimationBuilder<
                                                double
                                              >(
                                                duration: Duration(
                                                  milliseconds:
                                                      1200 + (index * 150),
                                                ),
                                                tween: Tween(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ),
                                                builder: (
                                                  context,
                                                  fadeValue,
                                                  child,
                                                ) {
                                                  return Opacity(
                                                    opacity: fadeValue,
                                                    child: Text(
                                                      sports[index]['text']!,
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: fontSize,
                                                        height: 1.1,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines:
                                                          isSmallScreen ? 1 : 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),

                                            // Shimmer Effect
                                            TweenAnimationBuilder<double>(
                                              duration: const Duration(
                                                milliseconds: 2000,
                                              ),
                                              tween: Tween(
                                                begin: -1.0,
                                                end: 1.0,
                                              ),
                                              curve: Curves.easeInOut,
                                              builder: (
                                                context,
                                                shimmerValue,
                                                child,
                                              ) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment(
                                                        -1.0 + shimmerValue,
                                                        -1.0 + shimmerValue,
                                                      ),
                                                      end: Alignment(
                                                        1.0 + shimmerValue,
                                                        1.0 + shimmerValue,
                                                      ),
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.white
                                                            .withOpacity(0.1),
                                                        Colors.transparent,
                                                      ],
                                                      stops: const [
                                                        0.0,
                                                        0.5,
                                                        1.0,
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
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
                },
              );
            },
          ),
        );
      },
    );
  }

  // Helper method to get fallback images for each sport
  String _getFallbackImage(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return 'assets/images/football.png';
      case 'cricket':
        return 'assets/images/cricket.png';
      case 'tennis':
        return 'assets/images/tennis.png';
      case 'badminton':
        return 'assets/images/badminton.png';
      case 'pickle ball':
        return 'assets/images/pickle_ball.png';
      default:
        return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
    }
  }

  Widget _buildStartPlayingCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;

                // Responsive sizing
                double containerHeight,
                    titleFontSize,
                    subtitleFontSize,
                    padding;

                if (screenWidth <= 380) {
                  // Small screens
                  containerHeight = 180.0;
                  titleFontSize = 20.0;
                  subtitleFontSize = 13.0;
                  padding = 16.0;
                } else if (screenWidth <= 414) {
                  // Medium screens
                  containerHeight = 180.0;
                  titleFontSize = 22.0;
                  subtitleFontSize = 14.0;
                  padding = 20.0;
                } else {
                  // Large screens
                  containerHeight = 200.0;
                  titleFontSize = 24.0;
                  subtitleFontSize = 14.0;
                  padding = 24.0;
                }

                return Container(
                  height: containerHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF7B1FA2).withOpacity(0.3),
                        const Color(0xFF4A148C).withOpacity(0.5),
                        const Color(0xFF1A0E2E).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF7B1FA2).withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B1FA2).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'START PLAYING!',
                            style: GoogleFonts.robotoSlab(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(height: padding * 0.6),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Invent A Game',
                                      style: GoogleFonts.robotoSlab(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE91E63),
                                      Color(0xFFAD1457),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFE91E63,
                                      ).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding * 0.8,
                                      vertical: padding * 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => const CreateTeamScreen(),
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
                                                curve: Curves.easeInOutBack,
                                              ),
                                            ),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Create',
                                        style: GoogleFonts.robotoSlab(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: padding * 0.4),
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
                        SizedBox(height: padding * 0.4),
                        Center(
                          child: TextButton(
                            onPressed: () => _showSchedulePopup(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'See My Schedule',
                                  style: GoogleFonts.robotoSlab(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get comprehensive screen information
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final cardWidth = constraints.maxWidth;

        // Define breakpoints for different device sizes
        bool isSmallScreen =
            screenWidth <= 360; // Small phones (iPhone SE, etc.)
        bool isMediumScreen =
            screenWidth > 360 && screenWidth <= 414; // Standard phones
        bool isLargeScreen = screenWidth > 414; // Large phones and tablets

        // Responsive sizing based on device categories
        double iconSize, titleFontSize, subtitleFontSize, padding, cardHeight;

        if (isSmallScreen) {
          // Small screens (iPhone SE, Galaxy S10e, etc.)
          iconSize = 20.0;
          titleFontSize = 16.0;
          subtitleFontSize = 12.0;
          padding = 12.0;
          cardHeight = 140.0;
        } else if (isMediumScreen) {
          // Medium screens (iPhone 12, Galaxy S21, etc.)
          iconSize = 24.0;
          titleFontSize = 18.0;
          subtitleFontSize = 13.5;
          padding = 16.0;
          cardHeight = 160.0;
        } else {
          // Large screens (iPhone 14 Pro Max, tablets, etc.)
          iconSize = 28.0;
          titleFontSize = 20.0;
          subtitleFontSize = 15.0;
          padding = 20.0;
          cardHeight = 180.0;
        }

        // Fine-tune based on available card width
        final widthRatio =
            cardWidth / (screenWidth / 2); // Ratio compared to half screen
        iconSize *= widthRatio.clamp(0.8, 1.2);
        titleFontSize *= widthRatio.clamp(0.9, 1.1);
        subtitleFontSize *= widthRatio.clamp(0.9, 1.1);

        return Hero(
          tag: 'action_$title',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: cardHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (gradient as LinearGradient).colors.first
                          .withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon container
                      Container(
                        padding: EdgeInsets.all(padding * 0.4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: iconSize),
                      ),

                      // Text section with flexible layout
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: padding * 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Title - always fits on one line
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: titleFontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                              ),

                              SizedBox(height: padding * 0.3),

                              // Subtitle - responsive with proper wrapping
                              Flexible(
                                child: Container(
                                  width: double.infinity,
                                  child: Text(
                                    subtitle,
                                    style: GoogleFonts.poppins(
                                      fontSize: subtitleFontSize,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: isSmallScreen ? 2 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;

                // Responsive gap calculation
                double gap;
                if (screenWidth <= 360) {
                  gap = 12.0; // Small screens
                } else if (screenWidth <= 414) {
                  gap = 16.0; // Medium screens
                } else {
                  gap = 20.0; // Large screens
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'Play',
                        'Discover players and join their games',
                        Icons.people,
                        const LinearGradient(
                          colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                        ),
                        () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const HomePage(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.8,
                                    end: 1.0,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutBack,
                                    ),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'Book',
                        'Book your slots in venues nearby you',
                        Icons.book_online,
                        const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
                        ),
                        () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const TurfHomeScreen(),
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
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7B1FA2).withOpacity(0.3),
                        const Color(0xFF4A148C).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Follow us on',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 18,
                          color: const Color(0xFFE1BEE7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          _buildSocialButton(
                            FontAwesomeIcons.instagram,
                            const Color(0xFFE91E63),
                            () {},
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildSocialButton(
                            FontAwesomeIcons.facebook,
                            const Color(0xFF3F51B5),
                            () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7B1FA2).withOpacity(0.4),
                const Color(0xFF4A148C).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
                    ).createShader(bounds),
                child: Text(
                  'SPORTIC',
                  style: GoogleFonts.robotoSerif(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'THE FIELD AWAITS',
                style: GoogleFonts.robotoSlab(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE1BEE7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Your Sports Community app',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFFBBA3C3),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const PrivacyTermsPopup(),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Privacy Policy  •  Terms of Service',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Image.asset(
                  'assets/images/sportsman.png',
                  height: 180,
                  width: 160,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 180,
                        width: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7B1FA2).withOpacity(0.3),
                              const Color(0xFF4A148C).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.sports,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: IconButton(
        icon: FaIcon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

// Schedule Popup Widget
class SchedulePopup extends ConsumerStatefulWidget {
  const SchedulePopup({super.key});

  @override
  ConsumerState<SchedulePopup> createState() => _SchedulePopupState();
}

class _SchedulePopupState extends ConsumerState<SchedulePopup>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(todayBookingsProvider);
    final teamsAsync = ref.watch(todayTeamsProvider);
    final today = DateTime.now();
    final todayFormatted = '${today.day}-${today.month}-${today.year}';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF452152),
                        Color(0xFF3D1A4A),
                        Color(0xFF200D28),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7B1FA2).withOpacity(0.3),
                              const Color(0xFF4A148C).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.today,
                                color: Color(0xFFE91E63),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Schedule",
                                    style: GoogleFonts.robotoSlab(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    todayFormatted,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bookings Section
                              _buildSectionHeader(
                                'Your Bookings',
                                Icons.book_online,
                              ),
                              const SizedBox(height: 12),
                              bookingsAsync.when(
                                loading: () => _buildLoadingCard(),
                                error:
                                    (error, stack) => _buildErrorCard(
                                      'Failed to load bookings',
                                    ),
                                data: (bookings) {
                                  if (bookings.isEmpty) {
                                    return _buildEmptyCard(
                                      'No bookings for today',
                                    );
                                  }
                                  return Column(
                                    children:
                                        bookings
                                            .map(
                                              (booking) =>
                                                  _buildBookingCard(booking),
                                            )
                                            .toList(),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Teams Section
                              _buildSectionHeader('Your Teams', Icons.groups),
                              const SizedBox(height: 12),
                              teamsAsync.when(
                                loading: () => _buildLoadingCard(),
                                error:
                                    (error, stack) =>
                                        _buildErrorCard('Failed to load teams'),
                                data: (teams) {
                                  if (teams.isEmpty) {
                                    return _buildEmptyCard(
                                      'No teams created for today',
                                    );
                                  }
                                  return Column(
                                    children:
                                        teams
                                            .map((team) => _buildTeamCard(team))
                                            .toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE91E63), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.robotoSlab(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
            strokeWidth: 2,
          ),
          const SizedBox(width: 16),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              color: Colors.white.withOpacity(0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B1FA2).withOpacity(0.2),
            const Color(0xFF4A148C).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  color: Color(0xFFE91E63),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['turf_name'] ?? 'Unknown Turf',
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      booking['location'] ?? 'Unknown Location',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking['status'] ?? 'confirmed',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.access_time, booking['slot_time'] ?? 'N/A'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.sports, booking['selected_sport'] ?? 'N/A'),
            ],
          ),
          if (booking['amount'] != null) ...[
            const SizedBox(height: 8),
            _buildInfoChip(Icons.currency_rupee, '${booking['amount']}'),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    final joinedPlayers = team['joined_players'] as List<dynamic>? ?? [];
    final totalPlayers = team['total_players'] ?? 0;
    final availableSlots = team['available_slots'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE91E63).withOpacity(0.2),
            const Color(0xFFAD1457).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['turf_name'] ?? 'Team Game',
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      team['turf_location'] ?? 'Unknown Location',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  team['status'] ?? 'active',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.access_time, team['slot_time'] ?? 'N/A'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.sports, team['selected_sport'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                Icons.people,
                '${joinedPlayers.length}/$totalPlayers',
              ),
              const SizedBox(width: 12),
              if (availableSlots > 0)
                _buildInfoChip(Icons.person_add, '$availableSlots slots left'),
            ],
          ),
          if (team['amount'] != null) ...[
            const SizedBox(height: 8),
            _buildInfoChip(Icons.currency_rupee, '${team['amount']}'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
