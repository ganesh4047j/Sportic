import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

final lottieControllerProvider = Provider.autoDispose<AnimationController?>(
  (ref) => null,
);

class CenterLottieScreen extends ConsumerStatefulWidget {
  const CenterLottieScreen({super.key});

  @override
  ConsumerState<CenterLottieScreen> createState() => _CenterLottieScreenState();
}

class _CenterLottieScreenState extends ConsumerState<CenterLottieScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _rotationController;
  late final AnimationController _slideController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Lottie controller
    _controller = AnimationController(vsync: this);

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Rotation animation for background elements
    _rotationController = AnimationController(
      duration: const Duration(minutes: 2),
      vsync: this,
    );

    // Slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _rotationController.repeat();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            children: [
              // Animated background particles
              ...List.generate(20, (index) => _buildFloatingParticle(index)),

              // Animated background rings
              _buildAnimatedRings(),

              // Main content with SingleChildScrollView to prevent overflow
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Enhanced title with multiple effects
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Animated icon
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.pink.withOpacity(0.3),
                                                Colors.purple.withOpacity(0.2),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.rocket_launch,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Enhanced animated text
                                  ShaderMask(
                                    shaderCallback:
                                        (bounds) => const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.pink,
                                            Colors.purple,
                                            Colors.white,
                                          ],
                                          stops: [0.0, 0.3, 0.7, 1.0],
                                        ).createShader(bounds),
                                    child: DefaultTextStyle(
                                      style: GoogleFonts.nunito(
                                        fontSize: 32.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 2.0,
                                      ),
                                      child: AnimatedTextKit(
                                        repeatForever: true,
                                        animatedTexts: [
                                          TypewriterAnimatedText(
                                            'Coming Soon...',
                                            speed: const Duration(
                                              milliseconds: 150,
                                            ),
                                          ),
                                          TypewriterAnimatedText(
                                            'Get Ready! 🚀',
                                            speed: const Duration(
                                              milliseconds: 150,
                                            ),
                                          ),
                                          TypewriterAnimatedText(
                                            'Stay Tuned! ⭐',
                                            speed: const Duration(
                                              milliseconds: 150,
                                            ),
                                          ),
                                        ],
                                        pause: const Duration(seconds: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Enhanced Lottie animation with container
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.width * 0.7,
                              constraints: const BoxConstraints(
                                maxWidth: 280,
                                maxHeight: 280,
                                minWidth: 200,
                                minHeight: 200,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.pink.withOpacity(0.1),
                                    Colors.purple.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.2),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Lottie.asset(
                                'assets/coming_soon.json',
                                repeat: true,
                                controller: _controller,
                                onLoaded: (composition) {
                                  _controller
                                    ..duration = composition.duration
                                    ..repeat();
                                },
                              ),
                            ),
                          ),

                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05,
                          ),

                          // Additional content - subtitle and features
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.08,
                              ),
                              padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.06,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.03),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Something Amazing is Coming!',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.045,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.02,
                                  ),
                                  Text(
                                    'We\'re working hard to bring you an incredible experience. Stay tuned for updates!',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.035,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.025,
                                  ),

                                  // Feature indicators with responsive layout
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final itemWidth =
                                          constraints.maxWidth / 4;
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Flexible(
                                            child: _buildFeatureIcon(
                                              Icons.sports_soccer,
                                              'Sports',
                                              itemWidth,
                                            ),
                                          ),
                                          Flexible(
                                            child: _buildFeatureIcon(
                                              Icons.live_tv,
                                              'Live',
                                              itemWidth,
                                            ),
                                          ),
                                          Flexible(
                                            child: _buildFeatureIcon(
                                              Icons.group,
                                              'Teams',
                                              itemWidth,
                                            ),
                                          ),
                                          Flexible(
                                            child: _buildFeatureIcon(
                                              Icons.emoji_events,
                                              'Tournaments',
                                              itemWidth,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Loading indicator
                          AnimatedBuilder(
                            animation: _rotationAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationAnimation.value * 2 * 3.14159,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        Colors.pink,
                                        Colors.purple,
                                        Colors.blue,
                                        Colors.pink,
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF1B0723),
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = (index * 1234) % 1000;
    final size = 2.0 + (random % 8);
    final left = (random % 100).toDouble();
    final top = ((random * 7) % 100).toDouble();
    final duration = 3000 + (random % 4000);

    return Positioned(
      left: MediaQuery.of(context).size.width * left / 100,
      top: MediaQuery.of(context).size.height * top / 100,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: duration),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -20 * value),
            child: Opacity(
              opacity: (1 - value) * 0.6,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.pink.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        onEnd: () {
          // Restart animation
          setState(() {});
        },
      ),
    );
  }

  Widget _buildAnimatedRings() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return CustomPaint(painter: RingsPainter(_rotationAnimation.value));
        },
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, double itemWidth) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: itemWidth,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.03,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.pink.withOpacity(0.2 * _pulseAnimation.value),
                      Colors.purple.withOpacity(0.1 * _pulseAnimation.value),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  size: MediaQuery.of(context).size.width * 0.05,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: MediaQuery.of(context).size.width * 0.03,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class RingsPainter extends CustomPainter {
  final double animationValue;

  RingsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.7;

    for (int i = 0; i < 3; i++) {
      final radius = maxRadius * (0.3 + i * 0.2);
      final opacity = 0.1 * (1 - animationValue + i * 0.1);

      paint.color = Colors.white.withOpacity(opacity.clamp(0.0, 0.3));

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
