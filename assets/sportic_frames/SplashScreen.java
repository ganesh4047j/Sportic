import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_sequence_animator/image_sequence_animator.dart';
import 'package:sportic/Authentication/phn_validation.dart';
import 'package:sportic/Main%20Screens/home.dart';
import 'package:sportic/Providers/secure_storage_service.dart';
import 'package:sportic/main.dart'; // for FCM handler
import 'Providers/splashscreen_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  Future<void> _handleNavigation(BuildContext context) async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    final user = FirebaseAuth.instance.currentUser;
    final isPhoneLoggedIn = await SecureStorageService.isPhoneLoggedIn();
    final isLoggedIn = user != null || isPhoneLoggedIn;

    final destination = isLoggedIn ? const HomeScreen() : const PhoneLoginScreen();

    setupFCMNotificationListeners(context);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1500),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTimerFinished = ref.watch(splashProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ImageSequenceAnimator(
          'assets/sportic_frames/', // Folder path
          'frame_',                 // Frame name prefix
          0,                        // Start index
          33,                       // End index (for 34 images: 0 to 33)
          'png',                    // File extension
          30,                       // Frame rate (fps)
          isLooping: false,
          isAutoPlay: true,
          onFinish: () {
            if (isTimerFinished) {
              _handleNavigation(context);
            }
          },
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          fps: 30,
        ),
      ),
    );
  }
}
