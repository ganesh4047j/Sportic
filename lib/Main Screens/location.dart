import 'dart:ui';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sports/Main%20Screens/home.dart';
import 'package:sports/Providers/turfscreen_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationInputScreen extends ConsumerStatefulWidget {
  final bool shouldRedirectToHome;
  const LocationInputScreen({super.key, this.shouldRedirectToHome = true});

  @override
  ConsumerState<LocationInputScreen> createState() =>
      _LocationInputScreenState();
}

class _LocationInputScreenState extends ConsumerState<LocationInputScreen>
    with TickerProviderStateMixin {
  String? selectedLocation;
  bool isLoading = false;
  bool isLoadingUserLocation = true; // Add loading state for initial load
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Load user-specific location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserLocation();
    });
  }

  // NEW METHOD: Load user-specific location
  Future<void> _loadUserLocation() async {
    try {
      setState(() {
        isLoadingUserLocation = true;
      });

      final firebaseUser = FirebaseAuth.instance.currentUser;
      String? uid;
      String? loginMethod;
      const storage = FlutterSecureStorage();

      if (firebaseUser != null) {
        uid = firebaseUser.uid;
        loginMethod = "email";
      } else {
        uid = await storage.read(key: 'custom_uid');
        loginMethod = "phone";
      }

      if (uid == null) {
        debugPrint("❌ UID not found during location load");
        setState(() {
          isLoadingUserLocation = false;
        });
        return;
      }

      // First try to get from SharedPreferences (faster)
      final prefs = await SharedPreferences.getInstance();
      String? localLocation = prefs.getString(
        'user_location_$uid',
      ); // USER-SPECIFIC KEY

      if (localLocation != null && localLocation.isNotEmpty) {
        setState(() {
          selectedLocation = localLocation;
        });
        // Update provider with user-specific location
        ref.read(userLocationProvider.notifier).state = localLocation;
        debugPrint("✅ Loaded location from SharedPreferences: $localLocation");
      } else {
        // If not found locally, try Firestore
        await _loadLocationFromFirestore(uid, loginMethod!);
      }
    } catch (e) {
      debugPrint("❌ Error loading user location: $e");
    } finally {
      setState(() {
        isLoadingUserLocation = false;
      });
    }
  }

  // NEW METHOD: Load location from Firestore for specific user
  Future<void> _loadLocationFromFirestore(
    String uid,
    String loginMethod,
  ) async {
    try {
      final collectionName =
          loginMethod == "email" ? "user_details_email" : "user_details_phone";

      final docSnapshot =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(uid)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final location = data['location'] as String?;

        if (location != null && location.isNotEmpty) {
          setState(() {
            selectedLocation = location;
          });

          // Save to SharedPreferences with user-specific key
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_location_$uid', location);

          // Update provider
          ref.read(userLocationProvider.notifier).state = location;

          debugPrint("✅ Loaded location from Firestore: $location");
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading location from Firestore: $e");
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _updateLocationToFirestore(String location) async {
    setState(() {
      isLoading = true;
    });

    final firebaseUser = FirebaseAuth.instance.currentUser;
    String? uid;
    String? loginMethod;
    const storage = FlutterSecureStorage();

    if (firebaseUser != null) {
      uid = firebaseUser.uid;
      loginMethod = "email";
    } else {
      uid = await storage.read(key: 'custom_uid');
      loginMethod = "phone";
    }

    if (uid == null) {
      debugPrint("❌ UID or login method not found");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final collectionName =
        loginMethod == "email" ? "user_details_email" : "user_details_phone";

    final docRef = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(uid);

    try {
      await docRef.update({
        'location': location,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // IMPORTANT: Save to SharedPreferences with USER-SPECIFIC key
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_location_$uid',
        location,
      ); // USER-SPECIFIC KEY

      debugPrint("✅ Location updated successfully in $collectionName/$uid");
    } on FirebaseException catch (e) {
      debugPrint("❌ FirebaseException: ${e.message}");
    } catch (e) {
      debugPrint("❌ Error updating location: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Responsive utility methods
  double _getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  double _getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  bool _isSmallScreen(BuildContext context) => _getScreenWidth(context) < 380;

  bool _isMediumScreen(BuildContext context) =>
      _getScreenWidth(context) >= 380 && _getScreenWidth(context) <= 430;

  bool _isLargeScreen(BuildContext context) => _getScreenWidth(context) > 430;

  bool _isShortScreen(BuildContext context) => _getScreenHeight(context) < 700;

  double _getResponsivePadding(BuildContext context) {
    if (_isSmallScreen(context)) return 16.0;
    if (_isLargeScreen(context)) return 32.0;
    return 24.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = _getScreenWidth(context);
    if (width < 360) return baseFontSize * 0.85;
    if (width > 430) return baseFontSize * 1.1;
    return baseFontSize;
  }

  double _getResponsiveCardWidth(BuildContext context) {
    final width = _getScreenWidth(context);
    if (_isSmallScreen(context)) return width * 0.95;
    if (_isLargeScreen(context)) return width * 0.85;
    return width * 0.9;
  }

  EdgeInsets _getResponsiveCardPadding(BuildContext context) {
    if (_isSmallScreen(context)) {
      return const EdgeInsets.all(20.0);
    }
    if (_isLargeScreen(context)) {
      return const EdgeInsets.all(32.0);
    }
    return const EdgeInsets.all(28.0);
  }

  Widget _buildAnimatedParticle(
    double screenWidth,
    double screenHeight,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.1) % 1.0;
        final x = screenWidth * math.sin(progress * 2 * math.pi + index);
        final y = screenHeight * progress;
        final opacity = math.sin(progress * math.pi);

        return Positioned(
          left: x.abs() % screenWidth,
          top: y % screenHeight,
          child: Container(
            width: 4 + math.sin(progress * 4 * math.pi) * 2,
            height: 4 + math.sin(progress * 4 * math.pi) * 2,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity * 0.6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(opacity * 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingOrb({
    required double top,
    required double left,
    required double size,
    required List<Color> colors,
    required Duration duration,
  }) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Positioned(
          top: top + _floatingAnimation.value,
          left: left,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: colors),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
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
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = _getScreenHeight(context);
    final screenWidth = _getScreenWidth(context);
    final isSmall = _isSmallScreen(context);
    final isShort = _isShortScreen(context);
    final responsivePadding = _getResponsivePadding(context);

    final List<String> trichyLocations = [
      "Ariyamangalam",
      "BHEL Township",
      "Cantonment",
      "Edamalaipatti Pudur",
      "Golden Rock",
      "K.K. Nagar",
      "Karumandapam",
      "Palakkarai",
      "Sangillyandapuram",
      "Srirangam",
      "Tennur",
      "Thillai Nagar",
      "Tiruverumbur",
      "TVS Tollgate",
      "Woraiyur",
      "Srinivasa Nagar",
      "Khajamalai",
      "MIET",
      "Metro town(Melur)",
      "Kattur",
      "Kumaran Nagar",
      "Sanjeev Nagar",
      "Bharathi Nagar",
    ];

    // Show loading screen while fetching user location
    if (isLoadingUserLocation) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFFE60073),
                  ),
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  "Loading your location...",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
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
        child: Stack(
          children: [
            // Enhanced animated background particles
            ...List.generate(
              isSmall ? 20 : 30,
              (index) =>
                  _buildAnimatedParticle(screenWidth, screenHeight, index),
            ),

            // Multiple floating orbs with different animations
            _buildFloatingOrb(
              top: screenHeight * 0.1,
              left: screenWidth * 0.8,
              size: isSmall ? 60 : 80,
              colors: [
                const Color(0xFFE60073).withOpacity(0.4),
                const Color(0xFFFF6B9D).withOpacity(0.2),
                Colors.transparent,
              ],
              duration: const Duration(seconds: 3),
            ),

            _buildFloatingOrb(
              top: screenHeight * 0.7,
              left: screenWidth * 0.1,
              size: isSmall ? 45 : 60,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ],
              duration: const Duration(seconds: 2),
            ),

            _buildFloatingOrb(
              top: screenHeight * 0.3,
              left: screenWidth * 0.05,
              size: isSmall ? 30 : 40,
              colors: [
                const Color(0xFF452152).withOpacity(0.6),
                const Color(0xFF3D1A4A).withOpacity(0.3),
                Colors.transparent,
              ],
              duration: const Duration(seconds: 4),
            ),

            // Enhanced Main Lottie Animation with rotation
            if (!isShort)
              Positioned.fill(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _particleController.value * 0.1,
                        child: Animate(
                          effects: [
                            ScaleEffect(
                              duration: 1200.ms,
                              curve: Curves.elasticOut,
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.0, 1.0),
                            ),
                            FadeEffect(duration: 800.ms),
                          ],
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Lottie.asset(
                              'assets/Globe.json',
                              fit: BoxFit.contain,
                              height:
                                  isSmall
                                      ? screenHeight * 0.35
                                      : screenHeight * 0.45,
                              width:
                                  isSmall
                                      ? screenWidth * 0.6
                                      : screenWidth * 0.7,
                              repeat: true,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  height: screenHeight - MediaQuery.of(context).padding.top,
                  padding: EdgeInsets.all(responsivePadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Enhanced header section with glow effect
                      Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 20 : 24,
                              vertical: isSmall ? 12 : 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                isSmall ? 30 : 35,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE60073,
                                  ).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          isSmall ? 8 : 10,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFE60073),
                                              Color(0xFFFF6B9D),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFE60073,
                                              ).withOpacity(0.5),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: isSmall ? 20 : 24,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(width: isSmall ? 12 : 15),
                                Text(
                                  "Choose Your Location",
                                  style: GoogleFonts.poppins(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      18,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .slideY(
                            begin: -0.5,
                            duration: 800.ms,
                            curve: Curves.easeOutBack,
                          )
                          .then()
                          .shimmer(
                            duration: 2000.ms,
                            color: Colors.white.withOpacity(0.3),
                          ),

                      SizedBox(height: isShort ? 30 : 50),

                      // Enhanced main card with advanced glassmorphism
                      Animate(
                        effects: [
                          FadeEffect(duration: 1000.ms, delay: 300.ms),
                          SlideEffect(
                            duration: 1000.ms,
                            delay: 300.ms,
                            begin: const Offset(0, 0.4),
                            curve: Curves.easeOutCubic,
                          ),
                          ScaleEffect(
                            duration: 1000.ms,
                            delay: 300.ms,
                            begin: const Offset(0.7, 0.7),
                            curve: Curves.easeOutBack,
                          ),
                        ],
                        child: Container(
                          width: _getResponsiveCardWidth(context),
                          constraints: BoxConstraints(
                            maxWidth: 500,
                            minHeight: isShort ? 320 : 380,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              isSmall ? 25 : 30,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: const Offset(0, -10),
                              ),
                              BoxShadow(
                                color: const Color(0xFFE60073).withOpacity(0.1),
                                blurRadius: 40,
                                spreadRadius: -5,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              isSmall ? 25 : 30,
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Padding(
                                padding: _getResponsiveCardPadding(context),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Enhanced title with icon and glow
                                    Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AnimatedBuilder(
                                              animation: _pulseController,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale:
                                                      1.0 +
                                                      (_pulseController.value *
                                                          0.1),
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                      isSmall ? 12 : 16,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFFE60073),
                                                              Color(0xFFFF6B9D),
                                                              Color(0xFF452152),
                                                            ],
                                                          ),
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFFE60073,
                                                          ).withOpacity(0.6),
                                                          blurRadius: 25,
                                                          spreadRadius: 3,
                                                        ),
                                                        BoxShadow(
                                                          color: Colors.white
                                                              .withOpacity(0.3),
                                                          blurRadius: 15,
                                                          spreadRadius: 1,
                                                          offset: const Offset(
                                                            0,
                                                            -2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.place,
                                                      color: Colors.white,
                                                      size: isSmall ? 24 : 28,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            SizedBox(width: isSmall ? 16 : 20),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Select Your Area",
                                                    style: GoogleFonts.poppins(
                                                      fontSize:
                                                          _getResponsiveFontSize(
                                                            context,
                                                            24,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                      letterSpacing: 0.5,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black
                                                              .withOpacity(0.4),
                                                          blurRadius: 15,
                                                          offset: const Offset(
                                                            0,
                                                            3,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    "Find sports venues near you",
                                                    style: GoogleFonts.inter(
                                                      fontSize:
                                                          _getResponsiveFontSize(
                                                            context,
                                                            14,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                        .animate()
                                        .fadeIn(delay: 600.ms)
                                        .slideX(begin: 0.3, duration: 800.ms),

                                    SizedBox(height: isShort ? 25 : 35),

                                    // Enhanced dropdown with better animations
                                    Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withOpacity(0.95),
                                                Colors.white.withOpacity(0.9),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              isSmall ? 18 : 22,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFFE60073,
                                              ).withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.15,
                                                ),
                                                blurRadius: 20,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 8),
                                              ),
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFE60073,
                                                ).withOpacity(0.1),
                                                blurRadius: 15,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return DropdownButtonFormField<
                                                String
                                              >(
                                                value: selectedLocation,
                                                items:
                                                    trichyLocations.map((
                                                      location,
                                                    ) {
                                                      return DropdownMenuItem(
                                                        value: location,
                                                        child: Container(
                                                          width:
                                                              constraints
                                                                  .maxWidth -
                                                              100,
                                                          child: Text(
                                                            location,
                                                            style: GoogleFonts.inter(
                                                              fontSize:
                                                                  _getResponsiveFontSize(
                                                                    context,
                                                                    15,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors
                                                                      .grey[800],
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    setState(() {
                                                      selectedLocation = value;
                                                    });
                                                    ref
                                                        .read(
                                                          userLocationProvider
                                                              .notifier,
                                                        )
                                                        .state = value;
                                                  }
                                                },
                                                decoration: InputDecoration(
                                                  labelText: "Choose Area",
                                                  labelStyle: GoogleFonts.inter(
                                                    fontSize:
                                                        _getResponsiveFontSize(
                                                          context,
                                                          14,
                                                        ),
                                                    color: const Color(
                                                      0xFFE60073,
                                                    ).withOpacity(0.8),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  prefixIcon: Container(
                                                    margin: EdgeInsets.all(
                                                      isSmall ? 8 : 10,
                                                    ),
                                                    padding: EdgeInsets.all(
                                                      isSmall ? 6 : 8,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFFE60073),
                                                              Color(0xFFFF6B9D),
                                                            ],
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.location_city,
                                                      color: Colors.white,
                                                      size: isSmall ? 16 : 18,
                                                    ),
                                                  ),
                                                  suffixIcon: Container(
                                                    margin: EdgeInsets.only(
                                                      right: isSmall ? 8 : 12,
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      color: const Color(
                                                        0xFFE60073,
                                                      ).withOpacity(0.8),
                                                      size: isSmall ? 24 : 28,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.transparent,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          isSmall ? 18 : 22,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              isSmall ? 18 : 22,
                                                            ),
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              isSmall ? 18 : 22,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFFE60073,
                                                              ),
                                                              width: 2.5,
                                                            ),
                                                      ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal:
                                                            isSmall ? 16 : 20,
                                                        vertical:
                                                            isSmall ? 16 : 20,
                                                      ),
                                                ),
                                                dropdownColor: Colors.white,
                                                icon: const SizedBox.shrink(),
                                                style: GoogleFonts.inter(
                                                  fontSize:
                                                      _getResponsiveFontSize(
                                                        context,
                                                        15,
                                                      ),
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[800],
                                                ),
                                                selectedItemBuilder: (context) {
                                                  return trichyLocations.map((
                                                    location,
                                                  ) {
                                                    return Container(
                                                      width:
                                                          constraints.maxWidth -
                                                          120,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        location,
                                                        style: GoogleFonts.inter(
                                                          fontSize:
                                                              _getResponsiveFontSize(
                                                                context,
                                                                15,
                                                              ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    );
                                                  }).toList();
                                                },
                                                isExpanded: true,
                                              );
                                            },
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 1000.ms,
                                          delay: 800.ms,
                                        )
                                        .slideY(begin: 0.3, duration: 1000.ms)
                                        .then()
                                        .shimmer(
                                          duration: 1500.ms,
                                          color: const Color(
                                            0xFFE60073,
                                          ).withOpacity(0.2),
                                        ),

                                    SizedBox(height: isShort ? 30 : 40),

                                    // Enhanced save button with loading state
                                    Container(
                                          width: double.infinity,
                                          height: isSmall ? 56 : 64,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFFE60073),
                                                Color(0xFFFF6B9D),
                                                Color(0xFF452152),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              isSmall ? 16 : 20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFE60073,
                                                ).withOpacity(0.5),
                                                blurRadius: 25,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 10),
                                              ),
                                              BoxShadow(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 15,
                                                spreadRadius: 0,
                                                offset: const Offset(0, -3),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                isLoading
                                                    ? null
                                                    : () async {
                                                      if (selectedLocation !=
                                                              null &&
                                                          selectedLocation!
                                                              .isNotEmpty) {
                                                        await _updateLocationToFirestore(
                                                          selectedLocation!,
                                                        );

                                                        // Update provider with user's location
                                                        ref
                                                                .read(
                                                                  userLocationProvider
                                                                      .notifier,
                                                                )
                                                                .state =
                                                            selectedLocation!;

                                                        if (mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Row(
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          6,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                            0.2,
                                                                          ),
                                                                      shape:
                                                                          BoxShape
                                                                              .circle,
                                                                    ),
                                                                    child: const Icon(
                                                                      Icons
                                                                          .check_circle,
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      size: 20,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width:
                                                                        isSmall
                                                                            ? 10
                                                                            : 15,
                                                                  ),
                                                                  Expanded(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Text(
                                                                          "Location Updated!",
                                                                          style: GoogleFonts.inter(
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            fontSize: _getResponsiveFontSize(
                                                                              context,
                                                                              16,
                                                                            ),
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          "Now showing venues in $selectedLocation",
                                                                          style: GoogleFonts.inter(
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            fontSize: _getResponsiveFontSize(
                                                                              context,
                                                                              13,
                                                                            ),
                                                                            color: Colors.white.withOpacity(
                                                                              0.9,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              backgroundColor:
                                                                  Colors
                                                                      .green[600],
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      16,
                                                                    ),
                                                              ),
                                                              margin:
                                                                  EdgeInsets.all(
                                                                    isSmall
                                                                        ? 12
                                                                        : 16,
                                                                  ),
                                                              elevation: 10,
                                                              duration:
                                                                  const Duration(
                                                                    seconds: 3,
                                                                  ),
                                                            ),
                                                          );

                                                          // Add a small delay for better UX
                                                          await Future.delayed(
                                                            const Duration(
                                                              milliseconds: 500,
                                                            ),
                                                          );

                                                          if (widget
                                                              .shouldRedirectToHome) {
                                                            Navigator.pushAndRemoveUntil(
                                                              context,
                                                              PageRouteBuilder(
                                                                pageBuilder:
                                                                    (
                                                                      context,
                                                                      animation,
                                                                      secondaryAnimation,
                                                                    ) =>
                                                                        const HomeScreen(),
                                                                transitionsBuilder: (
                                                                  context,
                                                                  animation,
                                                                  secondaryAnimation,
                                                                  child,
                                                                ) {
                                                                  return FadeTransition(
                                                                    opacity:
                                                                        animation,
                                                                    child: SlideTransition(
                                                                      position: Tween<
                                                                        Offset
                                                                      >(
                                                                        begin: const Offset(
                                                                          1.0,
                                                                          0.0,
                                                                        ),
                                                                        end:
                                                                            Offset.zero,
                                                                      ).animate(
                                                                        CurvedAnimation(
                                                                          parent:
                                                                              animation,
                                                                          curve:
                                                                              Curves.easeInOutCubic,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          child,
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                              (route) => false,
                                                            );
                                                          } else {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          }
                                                        }
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .warning_amber_rounded,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                                SizedBox(
                                                                  width:
                                                                      isSmall
                                                                          ? 10
                                                                          : 15,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    "Please select a location first",
                                                                    style: GoogleFonts.inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          _getResponsiveFontSize(
                                                                            context,
                                                                            14,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            backgroundColor:
                                                                Colors
                                                                    .orange[600],
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            margin:
                                                                EdgeInsets.all(
                                                                  isSmall
                                                                      ? 12
                                                                      : 16,
                                                                ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                            icon:
                                                isLoading
                                                    ? SizedBox(
                                                      width: isSmall ? 20 : 24,
                                                      height: isSmall ? 20 : 24,
                                                      child: const CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                    : Icon(
                                                      Icons
                                                          .bookmark_added_rounded,
                                                      color: Colors.white,
                                                      size: isSmall ? 22 : 26,
                                                    ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isSmall ? 16 : 20,
                                                    ),
                                              ),
                                              padding: EdgeInsets.zero,
                                              elevation: 0,
                                            ),
                                            label: Text(
                                              isLoading
                                                  ? "Saving..."
                                                  : "Save Location",
                                              style: GoogleFonts.inter(
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      18,
                                                    ),
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.8,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 1200.ms,
                                          delay: 1000.ms,
                                        )
                                        .slideY(
                                          begin: 0.4,
                                          duration: 1200.ms,
                                          curve: Curves.easeOutBack,
                                        )
                                        .then()
                                        .shimmer(
                                          duration: 2500.ms,
                                          color: Colors.white.withOpacity(0.4),
                                        ),

                                    if (selectedLocation != null) ...[
                                      SizedBox(height: isShort ? 15 : 20),
                                      Container(
                                            padding: EdgeInsets.all(
                                              isSmall ? 12 : 16,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(
                                                    0xFFE60073,
                                                  ).withOpacity(0.1),
                                                  const Color(
                                                    0xFFFF6B9D,
                                                  ).withOpacity(0.05),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    isSmall ? 12 : 16,
                                                  ),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFE60073,
                                                ).withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFE60073,
                                                    ).withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.location_on,
                                                    color: const Color(
                                                      0xFFE60073,
                                                    ),
                                                    size: isSmall ? 16 : 18,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: isSmall ? 8 : 12,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "Selected: $selectedLocation",
                                                    style: GoogleFonts.inter(
                                                      fontSize:
                                                          _getResponsiveFontSize(
                                                            context,
                                                            14,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .animate()
                                          .fadeIn(duration: 600.ms)
                                          .scale(
                                            begin: const Offset(0.8, 0.8),
                                            duration: 600.ms,
                                          ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Enhanced floating action hint
                      SizedBox(height: isShort ? 20 : 30),

                      Animate(
                        effects: [
                          FadeEffect(duration: 1000.ms, delay: 1500.ms),
                          SlideEffect(
                            duration: 1000.ms,
                            delay: 1500.ms,
                            begin: const Offset(0, 0.3),
                          ),
                        ],
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 16 : 20,
                            vertical: isSmall ? 8 : 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              isSmall ? 20 : 25,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.white.withOpacity(0.8),
                                size: isSmall ? 16 : 18,
                              ),
                              SizedBox(width: isSmall ? 8 : 10),
                              Text(
                                "We'll show venues near your selected area",
                                style: GoogleFonts.inter(
                                  fontSize: _getResponsiveFontSize(context, 12),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.8),
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
          ],
        ),
      ),
    );
  }
}
