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

bool isLoading = false;

class _PinCodeVerificationScreenState
    extends ConsumerState<PinCodeVerificationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController textEditingController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> handleRetryOtp() async {
    final data = {'reqId': widget.requestId, 'retryChannel': 11};
    final response = await OTPWidget.retryOTP(data);
    print(response);
  }

  Future<String> getOrCreateCustomUID() async {
    final existingUID = await secureStorage.read(key: 'custom_uid');

    if (existingUID != null) return existingUID;

    final newUID = const Uuid().v4();
    debugPrint('Generated new Id is : $newUID');

    await secureStorage.write(key: 'custom_uid', value: newUID);
    return newUID;
  }

  Future<void> handleVerifyOtp() async {
    final otp = textEditingController.text.trim();
    final data = {'reqId': widget.requestId, 'otp': otp};

    try {
      final response = await OTPWidget.verifyOTP(data);
      debugPrint("OTP Verify Response: $response");

      if (response?['type'] == 'success') {
        final uid = await getOrCreateCustomUID();
        debugPrint("Generated UID: $uid");

        final userDoc = FirebaseFirestore.instance
            .collection('user_details_phone')
            .doc(uid);

        try {
          await userDoc.set({
            'phone_number': widget.phoneNumber ?? '',
            'name': '',
            'email': '',
            'location': '',
            'photoUrl': '',
            'gender': '',
            'verified_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint("❌ Firestore save error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to save user details.")),
            );
          }
          return;
        }

        // ✅ Save login state
        await SecureStorageService.setPhoneLoggedIn(true);

        // ✅ Attempt to save FCM token safely
        try {
          await saveFcmTokenToFirestore(collection: 'user_details_phone');
        } catch (e) {
          debugPrint("❌ FCM token save error: $e");
        }

        // ✅ Proceed to user details collection screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP Verified Successfully!!")),
          );

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectUserDetailsPage(),
                ),
              );
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid OTP. Try again.")),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ OTP Verification failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong. Try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider);
    final otpNotifier = ref.read(otpProvider.notifier);

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 3.2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Lottie.asset('password.json'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Phone Number Verification',
                style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the code sent to ${widget.phoneNumber}",
                style: GoogleFonts.robotoSlab(
                  color: Colors.white,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              PinCodeTextField(
                appContext: context,
                textStyle: GoogleFonts.robotoSlab(color: Colors.white),
                pastedTextStyle: GoogleFonts.robotoSlab(
                  color: Color(0xff189d1e),
                  fontWeight: FontWeight.bold,
                ),
                length: 4,
                obscureText: true,
                obscuringCharacter: '*',
                obscuringWidget: const FlutterLogo(size: 24),
                blinkWhenObscuring: true,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(15),
                  borderWidth: 2.0,
                  errorBorderColor: Colors.red,
                  activeColor: Colors.white,
                  selectedColor: Colors.white,
                  fieldHeight: 70,
                  fieldWidth: 60,
                ),
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: false,
                errorAnimationController: otpState.errorController,
                controller: textEditingController,
                keyboardType: TextInputType.number,
                onCompleted: (_) {},
                onChanged: (value) => otpNotifier.updateText(value),
                beforeTextPaste: (text) => true,
              ),
              if (otpState.hasError)
                Text(
                  "*Please fill up all the cells properly",
                  style: GoogleFonts.robotoSlab(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code?",
                    style: GoogleFonts.robotoSlab(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () {
                      handleRetryOtp();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("OTP resend!!")),
                      );
                    },
                    child: Text(
                      "RESEND",
                      style: GoogleFonts.robotoSlab(
                        color: Color(0xFF91D3B3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE60073),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  handleVerifyOtp();
                },
                child: Text(
                  "VERIFY",
                  style: GoogleFonts.robotoSlab(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  textEditingController.clear();
                  otpNotifier.updateText('');
                },
                child: Text(
                  "Clear Fields",
                  style: GoogleFonts.robotoSlab(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
