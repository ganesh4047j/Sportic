import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A StateNotifier to manage splash screen timing logic
class SplashNotifier extends StateNotifier<bool> {
  SplashNotifier() : super(false) {
    _startTimer(); // Automatically trigger the timer on init
  }

  void _startTimer() {
    Timer(const Duration(milliseconds: 800), () {
      state = true; // Mark splash as completed
    });
  }
}

/// Riverpod provider for splash screen state
final splashProvider = StateNotifierProvider<SplashNotifier, bool>((ref) {
  return SplashNotifier();
});
