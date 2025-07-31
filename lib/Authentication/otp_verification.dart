import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import 'package:sports/Main%20Screens/user_details_phone.dart';
import '../Providers/otp_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Providers/secure_storage_service.dart';
import '../Services/fcm_token.dart';

// Constants for better maintainability
class AppConstants {
  static const int otpLength = 4;
  static const int retryChannel = 11;
  static const String customUidKey = 'custom_uid';
  static const String userDetailsCollection = 'user_details_phone';

  // UI Constants
  static const double horizontalPadding = 24.0;
  static const double verticalPadding = 40.0;
  static const double pinFieldHeight = 70.0;
  static const double pinFieldWidth = 60.0;
  static const double borderRadius = 15.0;
  static const double buttonBorderRadius = 25.0;
}

// Enhanced state management
final verificationStateProvider =
    StateNotifierProvider<VerificationStateNotifier, VerificationState>((ref) {
      return VerificationStateNotifier();
    });

class VerificationState {
  final bool isLoading;
  final bool isRetrying;
  final String? error;
  final String otpText;

  const VerificationState({
    this.isLoading = false,
    this.isRetrying = false,
    this.error,
    this.otpText = '',
  });

  VerificationState copyWith({
    bool? isLoading,
    bool? isRetrying,
    String? error,
    String? otpText,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      isRetrying: isRetrying ?? this.isRetrying,
      error: error,
      otpText: otpText ?? this.otpText,
    );
  }
}

class VerificationStateNotifier extends StateNotifier<VerificationState> {
  VerificationStateNotifier() : super(const VerificationState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setRetrying(bool retrying) {
    state = state.copyWith(isRetrying: retrying);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void updateOtpText(String text) {
    state = state.copyWith(otpText: text);
  }

  void clearState() {
    state = const VerificationState();
  }
}

class PinCodeVerificationScreen extends ConsumerStatefulWidget {
  final String? phoneNumber;
  final String? requestId;

  const PinCodeVerificationScreen({
    super.key,
    this.phoneNumber,
    this.requestId,
  });

  @override
  ConsumerState<PinCodeVerificationScreen> createState() =>
      _PinCodeVerificationScreenState();
}

class _PinCodeVerificationScreenState
    extends ConsumerState<PinCodeVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _textEditingController;
  late final FlutterSecureStorage _secureStorage;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _secureStorage = const FlutterSecureStorage();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  // Input validation
  bool _isOtpValid(String otp) {
    return otp.length == AppConstants.otpLength &&
        RegExp(r'^\d+$').hasMatch(otp);
  }

  // Show user-friendly messages
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Optimized OTP retry with proper error handling
  Future<void> _handleRetryOtp() async {
    if (widget.requestId == null) {
      _showMessage(
        'Invalid request. Please restart the verification process.',
        isError: true,
      );
      return;
    }

    final verificationNotifier = ref.read(verificationStateProvider.notifier);
    verificationNotifier.setRetrying(true);
    verificationNotifier.setError(null);

    try {
      final data = {
        'reqId': widget.requestId!,
        'retryChannel': AppConstants.retryChannel,
      };

      final response = await OTPWidget.retryOTP(data);
      debugPrint('Retry OTP Response: $response');

      if (response?['type'] == 'success') {
        _showMessage('OTP resent successfully!');
      } else {
        _showMessage('Failed to resend OTP. Please try again.', isError: true);
      }
    } catch (e) {
      debugPrint('❌ Retry OTP Error: $e');
      verificationNotifier.setError('Failed to resend OTP');
      _showMessage(
        'Network error. Please check your connection.',
        isError: true,
      );
    } finally {
      verificationNotifier.setRetrying(false);
    }
  }

  // Optimized UID generation with better error handling
  Future<String?> _getOrCreateCustomUID() async {
    try {
      final existingUID = await _secureStorage.read(
        key: AppConstants.customUidKey,
      );

      if (existingUID != null && existingUID.isNotEmpty) {
        debugPrint('Using existing UID: $existingUID');
        return existingUID;
      }

      final newUID = const Uuid().v4();
      debugPrint('Generated new UID: $newUID');

      await _secureStorage.write(key: AppConstants.customUidKey, value: newUID);
      return newUID;
    } catch (e) {
      debugPrint('❌ UID Generation Error: $e');
      return null;
    }
  }

  // Enhanced Firestore operations with better error handling
  Future<bool> _saveUserToFirestore(String uid) async {
    try {
      final userDoc = FirebaseFirestore.instance
          .collection(AppConstants.userDetailsCollection)
          .doc(uid);

      await userDoc.set({
        'phone_number': widget.phoneNumber ?? '',
        'name': '',
        'email': '',
        'location': '',
        'photoUrl': '',
        'gender': '',
        'verified_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('❌ Firestore save error: $e');
      return false;
    }
  }

  // Enhanced FCM token saving
  Future<void> _saveFcmTokenSafely() async {
    try {
      await saveFcmTokenToFirestore(
        collection: AppConstants.userDetailsCollection,
      );
      debugPrint('✅ FCM token saved successfully');
    } catch (e) {
      debugPrint('❌ FCM token save error: $e');
      // Non-critical error, don't block user flow
    }
  }

  // Main OTP verification with comprehensive error handling
  Future<void> _handleVerifyOtp() async {
    final otp = _textEditingController.text.trim();
    final verificationNotifier = ref.read(verificationStateProvider.notifier);

    // Input validation
    if (!_isOtpValid(otp)) {
      verificationNotifier.setError('Please enter a valid 4-digit OTP');
      _showMessage('Please enter a valid 4-digit OTP', isError: true);
      return;
    }

    if (widget.requestId == null) {
      _showMessage(
        'Invalid request. Please restart the verification process.',
        isError: true,
      );
      return;
    }

    verificationNotifier.setLoading(true);
    verificationNotifier.setError(null);

    try {
      // Step 1: Verify OTP
      final data = {'reqId': widget.requestId!, 'otp': otp};
      final response = await OTPWidget.verifyOTP(data);
      debugPrint('OTP Verify Response: $response');

      if (response?['type'] != 'success') {
        _showMessage('Invalid OTP. Please try again.', isError: true);
        return;
      }

      // Step 2: Generate/Get UID
      final uid = await _getOrCreateCustomUID();
      if (uid == null) {
        _showMessage(
          'Failed to generate user ID. Please try again.',
          isError: true,
        );
        return;
      }

      // Step 3: Save user to Firestore
      final firestoreSaved = await _saveUserToFirestore(uid);
      if (!firestoreSaved) {
        _showMessage(
          'Failed to save user details. Please try again.',
          isError: true,
        );
        return;
      }

      // Step 4: Save login state
      await SecureStorageService.setPhoneLoggedIn(true);

      // Step 5: Save FCM token (non-blocking)
      _saveFcmTokenSafely();

      // Step 6: Navigate to next screen
      if (mounted) {
        _showMessage('Phone number verified successfully!');

        // Small delay to show success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CollectUserDetailsPage(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ OTP Verification failed: $e');
      verificationNotifier.setError('Verification failed');
      _showMessage('Something went wrong. Please try again.', isError: true);
    } finally {
      verificationNotifier.setLoading(false);
    }
  }

  void _clearFields() {
    _textEditingController.clear();
    ref.read(verificationStateProvider.notifier).clearState();
    ref.read(otpProvider.notifier).updateText('');
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
            vertical: AppConstants.verticalPadding,
          ),
          child: Column(
            children: [
              _buildLottieAnimation(),
              const SizedBox(height: 10),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 20),
              _buildPinCodeField(),
              const SizedBox(height: 16),
              _buildResendSection(),
              const SizedBox(height: 16),
              _buildVerifyButton(),
              _buildClearButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 3.2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Lottie.asset('password.json'),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Phone Number Verification',
      style: GoogleFonts.robotoSlab(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      "Enter the code sent to ${widget.phoneNumber ?? 'your phone'}",
      style: GoogleFonts.robotoSlab(color: Colors.white, fontSize: 15),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPinCodeField() {
    final otpState = ref.watch(otpProvider);
    final verificationState = ref.watch(verificationStateProvider);

    return Column(
      children: [
        PinCodeTextField(
          appContext: context,
          textStyle: GoogleFonts.robotoSlab(color: Colors.white),
          pastedTextStyle: GoogleFonts.robotoSlab(
            color: const Color(0xff189d1e),
            fontWeight: FontWeight.bold,
          ),
          length: AppConstants.otpLength,
          obscureText: true,
          obscuringCharacter: '*',
          obscuringWidget: const FlutterLogo(size: 24),
          blinkWhenObscuring: true,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderWidth: 2.0,
            errorBorderColor: Colors.red,
            activeColor: Colors.white,
            selectedColor: Colors.white,
            inactiveColor: Colors.white54,
            fieldHeight: AppConstants.pinFieldHeight,
            fieldWidth: AppConstants.pinFieldWidth,
          ),
          animationDuration: const Duration(milliseconds: 300),
          enableActiveFill: false,
          errorAnimationController: otpState.errorController,
          controller: _textEditingController,
          keyboardType: TextInputType.number,
          enabled: !verificationState.isLoading,
          onCompleted: (_) => _handleVerifyOtp(),
          onChanged: (value) {
            ref.read(otpProvider.notifier).updateText(value);
            ref.read(verificationStateProvider.notifier).updateOtpText(value);
            // Clear error when user starts typing
            if (verificationState.error != null) {
              ref.read(verificationStateProvider.notifier).setError(null);
            }
          },
          beforeTextPaste: (text) => _isOtpValid(text ?? ''),
        ),
        if (otpState.hasError || verificationState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              verificationState.error ??
                  "*Please fill up all the cells properly",
              style: GoogleFonts.robotoSlab(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildResendSection() {
    final verificationState = ref.watch(verificationStateProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code?",
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        if (verificationState.isRetrying)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF91D3B3)),
              ),
            ),
          )
        else
          TextButton(
            onPressed: verificationState.isLoading ? null : _handleRetryOtp,
            child: Text(
              "RESEND",
              style: GoogleFonts.robotoSlab(
                color:
                    verificationState.isLoading
                        ? Colors.grey
                        : const Color(0xFF91D3B3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    final verificationState = ref.watch(verificationStateProvider);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE60073),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
      ),
      onPressed: verificationState.isLoading ? null : _handleVerifyOtp,
      child:
          verificationState.isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(
                "VERIFY",
                style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
    );
  }

  Widget _buildClearButton() {
    final verificationState = ref.watch(verificationStateProvider);

    return TextButton(
      onPressed: verificationState.isLoading ? null : _clearFields,
      child: Text(
        "Clear Fields",
        style: GoogleFonts.robotoSlab(
          color: verificationState.isLoading ? Colors.grey : Colors.white,
        ),
      ),
    );
  }
}
