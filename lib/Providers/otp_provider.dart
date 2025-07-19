import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

final otpProvider = StateNotifierProvider<OtpNotifier, OtpState>((ref) {
  return OtpNotifier();
});

class OtpState {
  final String currentText;
  final bool hasError;
  final StreamController<ErrorAnimationType> errorController;

  OtpState({
    required this.currentText,
    required this.hasError,
    required this.errorController,
  });

  OtpState copyWith({
    String? currentText,
    bool? hasError,
  }) {
    return OtpState(
      currentText: currentText ?? this.currentText,
      hasError: hasError ?? this.hasError,
      errorController: errorController,
    );
  }
}

class OtpNotifier extends StateNotifier<OtpState> {
  OtpNotifier()
      : super(OtpState(
    currentText: '',
    hasError: false,
    errorController: StreamController<ErrorAnimationType>(),
  ));

  void updateText(String text) {
    state = state.copyWith(currentText: text);
  }

  void verifyOTP(BuildContext context) {
    if (state.currentText.length != 4 || state.currentText != "1234") {
      state.errorController.add(ErrorAnimationType.shake);
      state = state.copyWith(hasError: true);
    } else {
      state = state.copyWith(hasError: false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified!!")),
      );
    }
  }

  void disposeController() {
    state.errorController.close();
  }
}