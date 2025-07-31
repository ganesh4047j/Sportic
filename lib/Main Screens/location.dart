import 'dart:ui';
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

class LocationInputScreen extends ConsumerWidget {
  final bool shouldRedirectToHome;
  const LocationInputScreen({super.key, this.shouldRedirectToHome = true});

  Future<void> _updateLocationToFirestore(String location) async {
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
      debugPrint("✅ Location updated successfully in $collectionName/$uid");
    } on FirebaseException catch (e) {
      debugPrint("❌ FirebaseException: ${e.message}");
    } catch (e) {
      debugPrint("❌ Error updating location: $e");
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(userLocationProvider);
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
    ];

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
            // Responsive animated background particles
            ...List.generate(
              isSmall ? 15 : 20,
              (index) => Positioned(
                left: (index * (isSmall ? 40.0 : 50.0)) % screenWidth,
                top: (index * (isSmall ? 60.0 : 80.0)) % screenHeight,
                child: Container(
                      width: isSmall ? 3 : 4,
                      height: isSmall ? 3 : 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: (2000 + index * 100).ms)
                    .then()
                    .fadeOut(duration: (2000 + index * 100).ms)
                    .animate(onComplete: (controller) => controller.repeat()),
              ),
            ),

            // Responsive Main Lottie Animation
            if (!isShort)
              Positioned.fill(
                child: Center(
                  child: Animate(
                    effects: [
                      ScaleEffect(duration: 800.ms, curve: Curves.elasticOut),
                    ],
                    child: Lottie.asset(
                      'assets/Globe.json',
                      fit: BoxFit.contain,
                      height: isSmall ? screenHeight * 0.4 : screenHeight * 0.5,
                      width: isSmall ? screenWidth * 0.7 : screenWidth * 0.8,
                      repeat: true,
                    ),
                  ),
                ),
              ),

            // Responsive floating orbs
            Positioned(
              top: screenHeight * (isShort ? 0.1 : 0.15),
              right: screenWidth * 0.1,
              child: Container(
                    width: isSmall ? 60 : 80,
                    height: isSmall ? 60 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE60073).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .scale(
                    duration: 3000.ms,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                  )
                  .animate(
                    onComplete:
                        (controller) => controller.repeat(reverse: true),
                  ),
            ),

            Positioned(
              bottom: screenHeight * (isShort ? 0.15 : 0.2),
              left: screenWidth * 0.05,
              child: Container(
                    width: isSmall ? 45 : 60,
                    height: isSmall ? 45 : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .scale(
                    duration: 2500.ms,
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.3, 1.3),
                  )
                  .animate(
                    onComplete:
                        (controller) => controller.repeat(reverse: true),
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
                      // Responsive header section
                      Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 16 : 20,
                              vertical: isSmall ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                isSmall ? 25 : 30,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isSmall ? 6 : 8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE60073,
                                    ).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: isSmall ? 18 : 20,
                                  ),
                                ),
                                SizedBox(width: isSmall ? 8 : 10),
                                Text(
                                  "Choose Your Location",
                                  style: GoogleFonts.poppins(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      16,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(
                            begin: -0.3,
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),

                      SizedBox(height: isShort ? 20 : 40),

                      // Responsive main card with glassmorphism effect
                      Animate(
                        effects: [
                          FadeEffect(duration: 800.ms, delay: 200.ms),
                          SlideEffect(
                            duration: 800.ms,
                            delay: 200.ms,
                            begin: const Offset(0, 0.3),
                            curve: Curves.easeOutCubic,
                          ),
                          ScaleEffect(
                            duration: 800.ms,
                            delay: 200.ms,
                            begin: const Offset(0.8, 0.8),
                            curve: Curves.easeOutBack,
                          ),
                        ],
                        child: Container(
                          width: _getResponsiveCardWidth(context),
                          constraints: BoxConstraints(
                            maxWidth: 500,
                            minHeight: isShort ? 300 : 350,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              isSmall ? 20 : 25,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              isSmall ? 20 : 25,
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: _getResponsiveCardPadding(context),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Responsive title with icon
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                              padding: EdgeInsets.all(
                                                isSmall ? 10 : 12,
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
                                                    ).withOpacity(0.3),
                                                    blurRadius: 15,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.place,
                                                color: Colors.white,
                                                size: isSmall ? 20 : 24,
                                              ),
                                            )
                                            .animate()
                                            .scale(
                                              duration: 2000.ms,
                                              begin: const Offset(0.9, 0.9),
                                              end: const Offset(1.1, 1.1),
                                            )
                                            .animate(
                                              onComplete:
                                                  (controller) => controller
                                                      .repeat(reverse: true),
                                            ),
                                        SizedBox(width: isSmall ? 12 : 15),
                                        Expanded(
                                          child: Text(
                                                "Select Your Area",
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      _getResponsiveFontSize(
                                                        context,
                                                        22,
                                                      ),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                                textAlign: TextAlign.center,
                                              )
                                              .animate()
                                              .fadeIn(delay: 400.ms)
                                              .slideX(
                                                begin: 0.3,
                                                duration: 600.ms,
                                              ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: isShort ? 20 : 30),

                                    // Responsive enhanced dropdown
                                    Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withOpacity(0.9),
                                                Colors.white.withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              isSmall ? 15 : 18,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 15,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: DropdownButtonFormField<
                                            String
                                          >(
                                            value:
                                                (currentLocation != null &&
                                                        currentLocation
                                                            .isNotEmpty)
                                                    ? currentLocation
                                                    : null,
                                            items:
                                                trichyLocations.map((location) {
                                                  return DropdownMenuItem(
                                                    value: location,
                                                    child: Text(
                                                      location,
                                                      style: GoogleFonts.inter(
                                                        fontSize:
                                                            _getResponsiveFontSize(
                                                              context,
                                                              16,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                            onChanged: (value) {
                                              if (value != null) {
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
                                                      16,
                                                    ),
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.location_city,
                                                color: const Color(
                                                  0xFFE60073,
                                                ).withOpacity(0.7),
                                                size: isSmall ? 20 : 22,
                                              ),
                                              filled: true,
                                              fillColor: Colors.transparent,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isSmall ? 15 : 18,
                                                    ),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isSmall ? 15 : 18,
                                                    ),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isSmall ? 15 : 18,
                                                    ),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE60073),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal:
                                                        isSmall ? 16 : 20,
                                                    vertical: isSmall ? 15 : 18,
                                                  ),
                                            ),
                                            dropdownColor: Colors.white,
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: const Color(
                                                0xFFE60073,
                                              ).withOpacity(0.7),
                                              size: isSmall ? 24 : 28,
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(duration: 800.ms, delay: 600.ms)
                                        .slideY(begin: 0.2, duration: 800.ms),

                                    SizedBox(height: isShort ? 25 : 35),

                                    // Responsive enhanced save button
                                    Container(
                                          width: double.infinity,
                                          height: isSmall ? 50 : 58,
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
                                              isSmall ? 14 : 16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFE60073,
                                                ).withOpacity(0.4),
                                                blurRadius: 20,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final selected = ref.read(
                                                userLocationProvider,
                                              );
                                              if (selected != null &&
                                                  selected.isNotEmpty) {
                                                await _updateLocationToFirestore(
                                                  selected,
                                                );

                                                final prefs =
                                                    await SharedPreferences.getInstance();
                                                await prefs.setString(
                                                  'user_location',
                                                  selected,
                                                );

                                                ref
                                                    .read(
                                                      userLocationProvider
                                                          .notifier,
                                                    )
                                                    .state = selected;

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              isSmall ? 8 : 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            "Location saved: $selected",
                                                            style: GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
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
                                                        Colors.green[600],
                                                    behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    margin: EdgeInsets.all(
                                                      isSmall ? 12 : 16,
                                                    ),
                                                  ),
                                                );

                                                if (shouldRedirectToHome) {
                                                  Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              const HomeScreen(),
                                                    ),
                                                    (route) => false,
                                                  );
                                                } else {
                                                  Navigator.pop(context);
                                                }
                                              }
                                            },
                                            icon: Icon(
                                              Icons.bookmark_added_rounded,
                                              color: Colors.white,
                                              size: isSmall ? 18 : 22,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isSmall ? 14 : 16,
                                                    ),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            label: Text(
                                              "Save Location",
                                              style: GoogleFonts.inter(
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      18,
                                                    ),
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 1000.ms,
                                          delay: 800.ms,
                                        )
                                        .slideY(
                                          begin: 0.3,
                                          duration: 1000.ms,
                                          curve: Curves.easeOutBack,
                                        )
                                        .then()
                                        .shimmer(
                                          duration: 2000.ms,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                  ],
                                ),
                              ),
                            ),
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
