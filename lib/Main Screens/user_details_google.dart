import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../Providers/user_details_google_providers.dart';
import 'location.dart';

class CollectUserDetailsPage1 extends ConsumerStatefulWidget {
  const CollectUserDetailsPage1({super.key});

  @override
  ConsumerState<CollectUserDetailsPage1> createState() =>
      _CollectUserDetailsPage1State();
}

class _CollectUserDetailsPage1State
    extends ConsumerState<CollectUserDetailsPage1>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController phoneController;
  bool _isFormValid = false;
  String? currentPhotoUrl;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final avatarUrls = List.generate(
    10,
    (index) => 'https://api.dicebear.com/7.x/micah/png?seed=avatar${index + 1}',
  );

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: ref.read(phoneProvider));
    phoneController.addListener(_validateForm);

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final gender = ref.read(genderProvider);
    final isValid = gender != null;

    setState(() {
      _isFormValid = isValid;
    });
  }

  Future<void> pickAvatar() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose Your Avatar',
                      style: GoogleFonts.cutive(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.maxFinite,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: avatarUrls.length + 1,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 400 ? 5 : 4,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                        ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                setState(() => currentPhotoUrl = null);
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade400,
                                      Colors.red.shade600,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            final avatarUrl = avatarUrls[index - 1];
                            return GestureDetector(
                              onTap: () {
                                setState(() => currentPhotoUrl = avatarUrl);
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pinkAccent.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(avatarUrl),
                                  radius: 30,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _saveDetailsToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('user_details_email')
          .doc(user.uid);

      try {
        await docRef.update({
          'phone_number': phoneController.text.trim(),
          'gender': ref.read(genderProvider),
          'photoUrl': currentPhotoUrl ?? '',
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("❌ Failed to update Firestore: $e");
      }
    } else {
      debugPrint("❌ No logged-in user found.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGender = ref.watch(genderProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaHeight =
        screenHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Minimal top spacing
                            SizedBox(height: 100),

                            // Compact Welcome Section
                            SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Column(
                                  children: [
                                    // Much smaller Lottie Animation
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.pinkAccent
                                                .withOpacity(0.15),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Lottie.asset(
                                        'assets/welcome_1.json',
                                        height: safeAreaHeight * 0.1,
                                        // Further reduced
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ShaderMask(
                                      shaderCallback:
                                          (bounds) => const LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.pinkAccent,
                                            ],
                                          ).createShader(bounds),
                                      child: Text(
                                        'Welcome!',
                                        style: GoogleFonts.cutive(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.06,
                                          // Further reduced
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Please fill in your details',
                                      style: GoogleFonts.cutive(
                                        color: Colors.white70,
                                        fontSize:
                                            screenWidth *
                                            0.032, // Further reduced
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: safeAreaHeight * 0.025),

                            // Ultra Compact Avatar Section
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                children: [
                                  // Smaller Avatar Display
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors:
                                            currentPhotoUrl != null
                                                ? [
                                                  Colors.pinkAccent,
                                                  Colors.purpleAccent,
                                                ]
                                                : [
                                                  Colors.grey.shade600,
                                                  Colors.grey.shade800,
                                                ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (currentPhotoUrl != null
                                                  ? Colors.pinkAccent
                                                  : Colors.grey)
                                              .withOpacity(0.25),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      transitionBuilder:
                                          (child, animation) => ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                      child: CircleAvatar(
                                        key: ValueKey(currentPhotoUrl),
                                        radius: screenWidth * 0.075,
                                        // Further reduced
                                        backgroundImage:
                                            currentPhotoUrl != null
                                                ? NetworkImage(currentPhotoUrl!)
                                                : null,
                                        child:
                                            currentPhotoUrl == null
                                                ? Icon(
                                                  Icons.person,
                                                  size: screenWidth * 0.075,
                                                  color: Colors.white70,
                                                )
                                                : null,
                                        backgroundColor: Colors.transparent,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Ultra Compact Choose Avatar Button
                                  GestureDetector(
                                    onTap: pickAvatar,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.pinkAccent,
                                            Colors.purpleAccent,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.pinkAccent
                                                .withOpacity(0.25),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.photo_camera_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Choose Avatar',
                                            style: GoogleFonts.cutive(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: safeAreaHeight * 0.03),

                            // Compact Form Section
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Ultra Compact Gender Selection
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
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
                                    ),
                                    child: Row(
                                      children: [
                                        _buildUltraCompactGenderCard(
                                          'Male',
                                          selectedGender,
                                          screenWidth,
                                        ),
                                        const SizedBox(width: 3),
                                        _buildUltraCompactGenderCard(
                                          'Female',
                                          selectedGender,
                                          screenWidth,
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: safeAreaHeight * 0.02),

                                  // Ultra Compact Phone Number Field
                                  _buildUltraCompactTextField(
                                    controller: phoneController,
                                    label: 'Phone (Optional)',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    onChanged: (val) {
                                      ref.read(phoneProvider.notifier).state =
                                          val;
                                      _validateForm();
                                    },
                                  ),

                                  SizedBox(height: safeAreaHeight * 0.025),

                                  // Ultra Compact Next Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 42, // Further reduced
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            21,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          _isFormValid
                                              ? () async {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  await _saveDetailsToFirestore();
                                                  if (mounted) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                const LocationInputScreen(),
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                              : null,
                                      child: Container(
                                        width: double.infinity,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient:
                                              _isFormValid
                                                  ? const LinearGradient(
                                                    colors: [
                                                      Colors.pinkAccent,
                                                      Colors.purpleAccent,
                                                    ],
                                                  )
                                                  : LinearGradient(
                                                    colors: [
                                                      Colors.grey.shade600,
                                                      Colors.grey.shade800,
                                                    ],
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            21,
                                          ),
                                          boxShadow:
                                              _isFormValid
                                                  ? [
                                                    BoxShadow(
                                                      color: Colors.pinkAccent
                                                          .withOpacity(0.25),
                                                      blurRadius: 10,
                                                      spreadRadius: 1,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ]
                                                  : [],
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Next",
                                                style: GoogleFonts.nunito(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 16,
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

                            // Flexible bottom spacing to fill remaining space
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUltraCompactGenderCard(
    String gender,
    String? selectedGender,
    double screenWidth,
  ) {
    final isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(genderProvider.notifier).state = gender;
          _validateForm();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.018),
          // Further reduced
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(
                      colors: [Colors.pinkAccent, Colors.purpleAccent],
                    )
                    : LinearGradient(
                      colors: [
                        const Color(0xFF3D1A4A).withOpacity(0.8),
                        const Color(0xFF452152).withOpacity(0.6),
                      ],
                    ),
            borderRadius: BorderRadius.circular(10), // Further reduced
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                    : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3), // Further reduced
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                ),
                child: Icon(
                  gender == 'Male' ? Icons.male : Icons.female,
                  size: screenWidth * 0.05, // Further reduced
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2), // Further reduced
              Text(
                gender,
                style: GoogleFonts.cutive(
                  color: Colors.white,
                  fontSize: screenWidth * 0.03, // Further reduced
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltraCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.cutive(color: Colors.white, fontSize: 13),
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cutive(color: Colors.white70, fontSize: 11),
          counterStyle: GoogleFonts.cutive(color: Colors.white54, fontSize: 8),
          prefixIcon: Icon(icon, color: Colors.white70, size: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
