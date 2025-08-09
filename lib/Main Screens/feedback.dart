import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math' as math;

import '../Providers/feedback_providers.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage>
    with TickerProviderStateMixin {
  final List<String> selectableOptions = const [
    "App is easy to use and navigate",
    "Booking process was smooth and fast",
    "Loved the UI and animations",
    "Great customer support response",
    "Enjoyed the group/team booking feature",
    "Others",
  ];

  late AnimationController _slideController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _floatingController;
  late AnimationController _textFieldController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _textFieldAnimation;

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final TextEditingController _feedbackTextController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _textFieldController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _floatingAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _textFieldAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textFieldController, curve: Curves.elasticOut),
    );

    // Start animations
    _slideController.forward();
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
    _floatingController.repeat(reverse: true);

    // Add focus listener for text field animation
    _textFieldFocusNode.addListener(() {
      if (_textFieldFocusNode.hasFocus) {
        _textFieldController.forward();
      } else {
        _textFieldController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _floatingController.dispose();
    _textFieldController.dispose();
    _feedbackTextController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

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
        };
      }
    }

    throw Exception("User not authenticated or profile not found.");
  }

  Future<void> _submitFeedback() async {
    final state = ref.read(feedbackProvider);
    final notifier = ref.read(feedbackProvider.notifier);
    final feedbackText = _feedbackTextController.text.trim();

    if (!notifier.isComplete || feedbackText.isEmpty) {
      _showAnimatedSnackBar(
        "Please select a topic and add your comments.",
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProfile = await getUserProfile();
      final uid = userProfile['uid'];
      final name = userProfile['name'];

      await FirebaseFirestore.instance
          .collection('user_feedback')
          .doc(uid)
          .set({
            'selectedOption': state.selectedOption,
            'feedbackText': feedbackText,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': uid,
            'user_id': name,
          });

      _showAnimatedSnackBar("Feedback submitted successfully!", Colors.green);

      // Reset form after successful submission
      notifier.reset();
      _feedbackTextController.clear();
      _textFieldFocusNode.unfocus();
    } catch (e) {
      _showAnimatedSnackBar(
        "Failed to submit feedback. Please try again.",
        Colors.red,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showAnimatedSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double _getResponsiveFontSize(double screenWidth, bool isTablet) {
    if (screenWidth < 320) {
      return 18; // Very small screens
    } else if (screenWidth < 360) {
      return 20; // Small screens
    } else if (screenWidth < 400) {
      return 22; // Medium-small screens
    } else if (isTablet) {
      return 32; // Tablets
    } else {
      return 24; // Default mobile
    }
  }

  Widget _buildAnimatedTextField(bool isTablet, double screenHeight) {
    return AnimatedBuilder(
      animation: _textFieldAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_textFieldAnimation.value * 0.05),
          child: Container(
            margin: EdgeInsets.only(bottom: screenHeight * 0.03),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(
                    0.2 + (_textFieldAnimation.value * 0.3),
                  ),
                  blurRadius: math.max(
                    0.0,
                    15.0 + (_textFieldAnimation.value * 10.0),
                  ),
                  spreadRadius: math.max(
                    0.0,
                    2.0 + (_textFieldAnimation.value * 3.0),
                  ),
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(
                      0.1 + (_textFieldAnimation.value * 0.05),
                    ),
                    Colors.white.withOpacity(
                      0.05 + (_textFieldAnimation.value * 0.05),
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.pink.withOpacity(
                    0.3 + (_textFieldAnimation.value * 0.4),
                  ),
                  width: math.max(0.0, 1.0 + (_textFieldAnimation.value * 1.0)),
                ),
              ),
              child: TextField(
                controller: _feedbackTextController,
                focusNode: _textFieldFocusNode,
                maxLines: 5,
                maxLength: 500,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                ),
                decoration: InputDecoration(
                  hintText: "Tell us more about your experience...",
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: isTablet ? 16 : 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(isTablet ? 20 : 16),
                  counterStyle: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
                cursorColor: Colors.pink,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedbackProvider);
    final notifier = ref.read(feedbackProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF452152),
            const Color(0xFF3D1A4A),
            const Color(0xFF200D28),
            const Color(0xFF1B0723),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: const BackButton(color: Colors.white),
                ),
              );
            },
          ),
          title: AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [Colors.white, Colors.pink, Colors.white],
                    stops: [
                      math.max(
                        0.0,
                        (_shimmerAnimation.value - 0.5).clamp(0.0, 1.0),
                      ),
                      _shimmerAnimation.value.clamp(0.0, 1.0),
                      math.min(
                        1.0,
                        (_shimmerAnimation.value + 0.5).clamp(0.0, 1.0),
                      ),
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  "Feedback",
                  style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: isTablet ? 28 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          centerTitle: true,
        ),
        body: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),

                  // Animated Image Container with new network image
                  AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingAnimation.value),
                        child: Container(
                          height: isTablet ? 200 : 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.3),
                                blurRadius: 20.0,
                                spreadRadius: 5.0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                Image.asset(
                                  "assets/images/feedback.png",
                                  height: double.infinity,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Animated Title
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Share Your Feedback",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cutive(
                              fontSize: _getResponsiveFontSize(
                                screenWidth,
                                isTablet,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.pink.withOpacity(0.5),
                                  blurRadius: 10.0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  Text(
                    "please select a topic and let us\nknow about your concern",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cutive(
                      color: Colors.white70,
                      fontSize: isTablet ? 18 : 14,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Animated Options
                  ...selectableOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = state.selectedOption == option;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.elasticOut,
                      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                      child: GestureDetector(
                        onTap: () => notifier.selectOption(option),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 20 : 16,
                            horizontal: isTablet ? 20 : 16,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected
                                    ? LinearGradient(
                                      colors: [
                                        Colors.pink.withOpacity(0.8),
                                        Colors.purple.withOpacity(0.8),
                                      ],
                                    )
                                    : LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.pink
                                      : Colors.white.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.4),
                                        blurRadius: 15.0,
                                        spreadRadius: 2.0,
                                        offset: const Offset(0, 5),
                                      ),
                                    ]
                                    : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5.0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isTablet ? 8 : 6,
                                height: isTablet ? 8 : 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                ),
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  SizedBox(height: screenHeight * 0.03),

                  // Animated Text Field for detailed feedback
                  _buildAnimatedTextField(isTablet, screenHeight),

                  // Animated Submit Button
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isSubmitting ? 0.95 : 1.0,
                        child: Container(
                          width: isTablet ? 300 : 200,
                          height: isTablet ? 65 : 55,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B9D), Color(0xFFC44569)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.5),
                                blurRadius: 20.0,
                                spreadRadius: 2.0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            child:
                                _isSubmitting
                                    ? SizedBox(
                                      width: isTablet ? 30 : 24,
                                      height: isTablet ? 30 : 24,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      "Submit",
                                      style: GoogleFonts.outfit(
                                        fontSize: isTablet ? 22 : 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Animation<double>>(
        '_rotationAnimation',
        _rotationAnimation,
      ),
    );
  }
}
