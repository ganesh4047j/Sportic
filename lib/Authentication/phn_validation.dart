import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Main Screens/home.dart';
import '../Main Screens/user_details_google.dart';
import '../Providers/secure_storage_service.dart';
import '../Providers/validation_provider.dart';
import '../Services/fcm_token.dart';
import '../Services/privacy_policy_service.dart';
import 'otp_verification.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  // final String widgetId = '35646c647a66363638303333';
  // final String authToken = '446617Ts2bJlY8z67f9ee70P1';

  final String widgetId = '3568616a6b6a303036303836'; // Your widgetId
  final String authToken = '462773THelKRh4S3688c93d9P1'; // Your authToken
  late final AnimationController _controller;
  String? _requestId;
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    OTPWidget.initializeWidget(widgetId, authToken);
    _controller = AnimationController(vsync: this);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("Google sign-in cancelled");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('user_details_email')
            .doc(user.uid);

        await userDoc.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'phone_number': '',
          'location': '',
          'gender': '',
          'verified_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await SecureStorageService.saveUid(user.uid);
        await SecureStorageService.setPhoneLoggedIn(false);

        /// ✅ Save FCM token now
        await saveFcmTokenToFirestore(collection: 'user_details_email');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CollectUserDetailsPage1()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Signed in as ${user.displayName}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Google sign-in error: $e');
      debugPrintStack(stackTrace: stack);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google sign-in failed. $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> handleSendOtp() async {
    final controller = ref.read(phoneControllerProvider);
    final phone = controller.text.trim();
    final agreedToTerms = ref.read(agreedToTermsProvider);

    if (!agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must agree to the terms and conditions."),
        ),
      );
      return;
    }

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10-digit phone number"),
        ),
      );
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('user_details_phone')
              .where('phone_number', isEqualTo: phone)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final existingDoc = querySnapshot.docs.first;
        final uid = existingDoc.id;
        debugPrint('Existing UID : $uid');
        debugPrint('Existing UID : $existingDoc');

        // ✅ Restore UID in secure storage for profile screen
        await SecureStorageService.saveUid(uid);
        await SecureStorageService.setPhoneLoggedIn(true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logged-in."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        return;
      }

      final data = {'identifier': '91$phone'};
      final response = await OTPWidget.sendOTP(data);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("OTP Generated")));

      if (response != null && response.containsKey("message")) {
        setState(() {
          _requestId = response["message"];
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PinCodeVerificationScreen(
                  phoneNumber: phone,
                  requestId: _requestId,
                ),
          ),
        );
      } else {
        debugPrint("Request ID not found in the response.");
      }
    } catch (e) {
      debugPrint("Error during OTP flow: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneController = ref.watch(phoneControllerProvider);
    final agreedToTerms = ref.watch(agreedToTermsProvider);

    return Stack(
      children: [
        Scaffold(
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
                horizontal: 24.0,
                vertical: 78.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Your Phone Number",
                    style: GoogleFonts.robotoSlab(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Lottie.asset(
                      'assets/football.json',
                      controller: _controller,
                      onLoaded: (composition) {
                        _controller.duration = composition.duration;
                        _controller.repeat();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff522961),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Text(
                          '+91',
                          style: GoogleFonts.robotoSlab(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Image.network(
                          'https://th.bing.com/th/id/OIP.3cv7kHxG_V0AvYNc8bUg9wHaE8?w=280&h=187&c=7&r=0&o=5&dpr=1.3&pid=1.7',
                          height: 25,
                          width: 25,
                        ),
                        const SizedBox(width: 8.0),
                        const Text(
                          '│',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                            decoration: InputDecoration(
                              hintText: 'Phone Number',
                              hintStyle: GoogleFonts.robotoSlab(
                                color: Colors.white54,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Checkbox(
                        value: agreedToTerms,
                        onChanged:
                            (value) =>
                                ref.read(agreedToTermsProvider.notifier).state =
                                    value ?? false,
                        checkColor: Colors.white,
                        activeColor: Colors.pink,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const PrivacyTermsPopup(),
                            );
                          },
                          child: Text(
                            "I agree to the terms and conditions",
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE60073),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(15.0),
                    ),
                    child: Text(
                      "Next",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "OR",
                          style: GoogleFonts.robotoSlab(color: Colors.white),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "By signing up, you agree to the\nTerms Of Service and Privacy Policy",
                    style: GoogleFonts.robotoSlab(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    // onPressed: signInWithGoogle,
                    onPressed: () {
                      // signInWithGoogle();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 22,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, color: Colors.white),
                        SizedBox(width: 20),
                        Text(
                          'Continue With Google',
                          style: GoogleFonts.robotoSlab(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/loading_spinner.json',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
