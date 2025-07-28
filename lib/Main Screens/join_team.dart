// ignore_for_file: avoid_print, unused_element, unused_local_variable

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'split_pay.dart';

// Only keeping the providers we actually need
final isTeamJoinedProvider = StateProvider<bool>((ref) => false);
final joinedPlayersProvider = StateProvider<int>((ref) => 5);
final neededPlayersProvider = StateProvider<int>((ref) => 6);

class JoinTeamPage extends ConsumerStatefulWidget {
  const JoinTeamPage({super.key});

  @override
  ConsumerState<JoinTeamPage> createState() => _JoinTeamPageState();
}

class _JoinTeamPageState extends ConsumerState<JoinTeamPage>
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

  List<Map<String, dynamic>> availableTeams = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchAvailableTeams();
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

  Future<void> _fetchAvailableTeams() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('Starting to fetch available teams...');

      // First, check if we can connect to Firestore at all
      final firestoreInstance = FirebaseFirestore.instance;

      // Add timeout and better error handling
      final querySnapshot = await firestoreInstance
          .collection('created_team')
          .where('status', isEqualTo: 'active')
          .where('need_players', isGreaterThan: 0)
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out after 30 seconds');
            },
          );

      print('Query completed. Found ${querySnapshot.docs.length} documents');

      if (!mounted) return;

      List<Map<String, dynamic>> teams = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('Processing team document: ${doc.id}');
          print('Team data keys: ${data.keys.toList()}');

          // More flexible validation - check for essential fields only
          if (_isValidTeamData(data)) {
            // Check if slot time is still valid
            if (!_isSlotTimeExpired(
              data['slot_time']?.toString() ?? '',
              data['slot_date']?.toString() ?? '',
            )) {
              final teamData = {
                ...data,
                'team_id': doc.id,
                // Ensure required fields have default values
                'creator_name': data['creator_name']?.toString() ?? 'Unknown',
                'creator_id': data['creator_id']?.toString() ?? 'unknown_id',
                'turf_name': data['turf_name']?.toString() ?? 'Unknown Turf',
                'turf_location':
                    data['turf_location']?.toString() ?? 'Unknown Location',
                'selected_sport':
                    data['selected_sport']?.toString() ?? 'Football',
                'slot_time': data['slot_time']?.toString() ?? 'TBD',
                'slot_date': data['slot_date']?.toString() ?? 'TBD',
                'need_players': _parseToInt(data['need_players'], 1),
                'total_players': _parseToInt(data['total_players'], 11),
                'amount': _parseToInt(data['amount'], 1000),
                'joined_players': data['joined_players'] ?? [],
                'status': data['status']?.toString() ?? 'active',
                'created_at': data['created_at'],
                'updated_at': data['updated_at'],
                // Add any other fields that might be needed by SplitPaymentScreen
                'turf_image': data['turf_image']?.toString() ?? '',
                'description': data['description']?.toString() ?? '',
                'rules': data['rules'] ?? [],
              };

              teams.add(teamData);
              print('Successfully added team: ${teamData['creator_name']}');
            } else {
              print('Team slot expired: ${data['creator_name']}');
            }
          } else {
            print('Team data validation failed for doc: ${doc.id}');
            print('Missing or invalid required fields');
          }
        } catch (e) {
          print('Error processing individual team doc ${doc.id}: $e');
          // Continue processing other documents
        }
      }

      print('Final processed teams count: ${teams.length}');

      if (mounted) {
        setState(() {
          availableTeams = teams;
          isLoading = false;
          errorMessage = null;
        });
      }
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      if (mounted) {
        setState(() {
          availableTeams = [];
          isLoading = false;
          errorMessage =
              'Request timed out. Please check your connection and try again.';
        });
      }
    } on FirebaseException catch (e) {
      print('Firebase error: ${e.code} - ${e.message}');
      String userFriendlyMessage;

      switch (e.code) {
        case 'permission-denied':
          userFriendlyMessage =
              'Permission denied. Please check your authentication.';
          break;
        case 'unavailable':
          userFriendlyMessage =
              'Service temporarily unavailable. Please try again.';
          break;
        case 'network-request-failed':
          userFriendlyMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          userFriendlyMessage =
              'Database error: ${e.message ?? 'Unknown error'}';
      }

      if (mounted) {
        setState(() {
          availableTeams = [];
          isLoading = false;
          errorMessage = userFriendlyMessage;
        });
      }
    } catch (e) {
      print('Unexpected error fetching teams: $e');
      if (mounted) {
        setState(() {
          availableTeams = [];
          isLoading = false;
          errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  // Helper method to validate team data
  bool _isValidTeamData(Map<String, dynamic> data) {
    // Check for essential fields
    final requiredFields = [
      'creator_name',
      'turf_name',
      'slot_time',
      'slot_date',
    ];

    for (String field in requiredFields) {
      if (!data.containsKey(field) ||
          data[field] == null ||
          data[field].toString().trim().isEmpty) {
        print('Missing or empty required field: $field');
        return false;
      }
    }

    // Validate need_players is a positive number
    final needPlayers = _parseToInt(data['need_players'], 0);
    if (needPlayers <= 0) {
      print('Invalid need_players value: ${data['need_players']}');
      return false;
    }

    return true;
  }

  // Helper method to safely parse integers
  int _parseToInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  bool _isSlotTimeExpired(String slotTime, String slotDate) {
    try {
      if (slotTime.isEmpty || slotDate.isEmpty) {
        print('Empty slot time or date');
        return false; // Don't filter out if we can't determine
      }

      final now = DateTime.now();
      print('Current time: $now');
      print('Checking slot: $slotDate $slotTime');

      // Parse the slot date (format: "28-7-2025" or "28-07-2025")
      final dateParts = slotDate.split('-');
      if (dateParts.length != 3) {
        print('Invalid date format: $slotDate');
        return false;
      }

      final day = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final year = int.tryParse(dateParts[2]);

      if (day == null || month == null || year == null) {
        print('Failed to parse date parts: $slotDate');
        return false;
      }

      // Validate date values
      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 2020) {
        print('Invalid date values: day=$day, month=$month, year=$year');
        return false;
      }

      // Parse slot time (format: "6 PM - 7 PM" or "6:00 PM - 7:00 PM")
      final timeParts = slotTime.split(' - ');
      if (timeParts.length != 2) {
        print('Invalid time format: $slotTime');
        return false;
      }

      final startTimeStr = timeParts[0].trim();
      final endTimeStr = timeParts[1].trim();

      final startTime = _parseTimeString(startTimeStr);
      final endTime = _parseTimeString(endTimeStr);

      // Create DateTime objects for slot start and end
      final slotStartDateTime = DateTime(
        year,
        month,
        day,
        startTime.hour,
        startTime.minute,
      );
      final slotEndDateTime = DateTime(
        year,
        month,
        day,
        endTime.hour,
        endTime.minute,
      );

      print('Slot start: $slotStartDateTime');
      print('Slot end: $slotEndDateTime');

      // Only filter out if the slot has completely ended
      final hasExpired = now.isAfter(slotEndDateTime);
      print('Has expired: $hasExpired');

      return hasExpired;
    } catch (e) {
      print('Error parsing slot time: $e');
      return false; // Don't filter out if there's an error
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      print('Parsing time string: $timeStr');

      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) {
        print('Invalid time format: $timeStr');
        return const TimeOfDay(hour: 12, minute: 0);
      }

      final timePart = parts[0];
      final amPm = parts[1].toUpperCase();

      int hour;
      int minute = 0;

      if (timePart.contains(':')) {
        final hourMinute = timePart.split(':');
        hour = int.tryParse(hourMinute[0]) ?? 12;
        minute = int.tryParse(hourMinute[1]) ?? 0;
      } else {
        hour = int.tryParse(timePart) ?? 12;
      }

      // Convert to 24-hour format
      if (amPm == 'PM' && hour != 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }

      // Validate hour and minute
      hour = hour.clamp(0, 23);
      minute = minute.clamp(0, 59);

      final result = TimeOfDay(hour: hour, minute: minute);
      print('Parsed time: ${result.hour}:${result.minute}');
      return result;
    } catch (e) {
      print('Error in _parseTimeString: $e');
      return const TimeOfDay(hour: 12, minute: 0);
    }
  }

  // Add method to show error dialog
  void _showErrorDialog() {
    if (!mounted || errorMessage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF3D1A4A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade300, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Connection Error',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              errorMessage!,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchAvailableTeams(); // Retry
                },
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Colors.blue.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    color: Colors.pink.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTeamJoined = ref.watch(isTeamJoinedProvider);
    final joinedPlayers = ref.watch(joinedPlayersProvider);
    final neededPlayers = ref.watch(neededPlayersProvider);

    // Show error dialog if there's an error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (errorMessage != null && !isLoading) {
        _showErrorDialog();
      }
    });

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
                    child: _buildTotalAmountSection(),
                  ),
                  const SizedBox(height: 30),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildAvailableTeamsSection(),
                  ),
                  const SizedBox(height: 20),
                  _buildAvailableTeamsList(),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: _buildProcessToBookButtonAdvanced(context),
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

  Widget _buildAvailableTeamsList() {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (availableTeams.isEmpty) {
      return _buildNoTeamsWidget();
    }

    return Column(
      children:
          availableTeams
              .map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildTeamCard(team),
                ),
              )
              .toList(),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.pink.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading available teams...',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTeamsWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.pink.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage != null ? 'Connection Error' : 'No Teams Available',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ??
                'There are no active teams looking for players right now. Check back later!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchAvailableTeams,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5D2968),
                    Color(0xFF4D2558),
                    Color(0xFF3D1D48),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.pink.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
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
                                gradient: const LinearGradient(
                                  colors: [Colors.pink, Colors.purple],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.transparent,
                                backgroundImage: NetworkImage(
                                  "https://i.pravatar.cc/150?img=${team['creator_name'].hashCode % 50}",
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
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
                                "${team['creator_name']}'s Team",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Captain: ${team['creator_name']}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "Sport: ${team['selected_sport']} • ${team['slot_time']}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withOpacity(0.8),
                              Colors.teal.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "${team['need_players']} players needed",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.sports_soccer,
                              color: Colors.pink,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                team['turf_name'],
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                team['turf_location'],
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              team['slot_date'],
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pink.withOpacity(0.8),
                                    Colors.purple.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "₹${(team['amount'] / team['total_players']).round()}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _joinTeam(team),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.withOpacity(0.8),
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Join Team',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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

  void _joinTeam(Map<String, dynamic> team) {
    print('Joining team with data: $team');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF3D1A4A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.groups, color: Colors.pink, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Join Team',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Do you want to join ${team['creator_name']}\'s team?',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Details:',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Turf: ${team['turf_name']}',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '• Sport: ${team['selected_sport']}',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '• Date: ${team['slot_date']}',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '• Time: ${team['slot_time']}',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '• Your payment: ₹${(team['amount'] / team['total_players']).round()}',
                        style: GoogleFonts.poppins(
                          color: Colors.pink.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToSplitPayment(team);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Join & Pay',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _navigateToSplitPayment(Map<String, dynamic> team) {
    print('Navigating to SplitPaymentScreen with team data: $team');

    // Update the provider with selected team data
    ref.read(selectedTeamProvider.notifier).state = team;

    // Navigate to SplitPaymentScreen with team data
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                SplitPaymentScreen(teamData: team),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
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
              'Join Dream Team',
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

  Widget _buildTotalAmountSection() {
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
                    'Available Teams',
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
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
                        end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
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
                    '${availableTeams.length} Teams',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTeamsSection() {
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
                                Icons.sports_soccer,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AVAILABLE TEAMS',
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
                  const SizedBox(height: 16),
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
                                'Find Your Perfect Team',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join existing teams and start playing!',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        builder: (context, animValue, child) {
                          return Transform.scale(
                            scale: animValue,
                            child: Transform.rotate(
                              angle: animValue * 0.1,
                              child: Lottie.asset(
                                'assets/football.json',
                                height: 120,
                                width: 120,
                              ),
                            ),
                          );
                        },
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
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: TextButton.icon(
                      onPressed: _fetchAvailableTeams,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'Refresh Teams',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  Widget _buildProcessToBookButtonAdvanced(BuildContext context) {
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
        (config['fontSize'] as double) / textScaleFactor.clamp(0.8, 1.3);

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
                          availableTeams.isNotEmpty
                              ? () {
                                // Navigate to create team screen or show message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Create team feature coming soon! Join an existing team above.',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.purple.withOpacity(
                                      0.8,
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                              : null,
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: config['iconSize'],
                            ),
                            SizedBox(width: config['iconTextSpacing']),
                            Flexible(
                              child: Text(
                                'Create New Team',
                                style: GoogleFonts.nunito(
                                  fontSize: adjustedFontSize,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: isExtraSmall ? 0.2 : 0.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: config['textArrowSpacing']),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1200),
                              builder: (context, animValue, child) {
                                return Transform.translate(
                                  offset: Offset(5 * animValue, 0),
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
