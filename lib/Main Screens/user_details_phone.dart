import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sports/Main%20Screens/location.dart';
import '../Providers/user_details_phone_provider.dart';

class CollectUserDetailsPage extends ConsumerStatefulWidget {
  const CollectUserDetailsPage({super.key});

  @override
  ConsumerState<CollectUserDetailsPage> createState() =>
      _CollectUserDetailsPageState();
}

class _CollectUserDetailsPageState extends ConsumerState<CollectUserDetailsPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false;
  late TextEditingController nameController;
  late TextEditingController emailController;
  final _secureStorage = const FlutterSecureStorage();
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
    nameController = TextEditingController(text: ref.read(nameProvider));
    emailController = TextEditingController(text: ref.read(emailProvider));
    nameController.addListener(_validateForm);
    emailController.addListener(_validateForm);

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
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final gender = ref.read(genderProvider);
    final name = nameController.text.trim();
    setState(() {
      _isFormValid = name.isNotEmpty && gender != null;
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

  Future<void> _updateDetailsToFirestore() async {
    final uid = await _secureStorage.read(key: 'custom_uid');
    if (uid == null) {
      debugPrint("❌ UID not found in secure storage");
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('user_details_phone')
        .doc(uid);

    try {
      await docRef.update({
        'name': ref.read(nameProvider),
        'email': ref.read(emailProvider),
        'gender': ref.read(genderProvider),
        'photoUrl': currentPhotoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ Firestore update failed: $e");
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Compact Welcome Section
                          SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                children: [
                                  // Compact Lottie Animation
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.pinkAccent.withOpacity(
                                            0.15,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Lottie.asset(
                                      'assets/welcome_1.json',
                                      height: safeAreaHeight * 0.1,
                                      // Reduced from 0.2
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  SizedBox(height: safeAreaHeight * 0.01),
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
                                        // Reduced from 0.08
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: safeAreaHeight * 0.005),
                                  Text(
                                    'Please fill in your details',
                                    style: GoogleFonts.cutive(
                                      color: Colors.white70,
                                      fontSize:
                                          screenWidth *
                                          0.032, // Reduced from 0.04
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: safeAreaHeight * 0.025),

                          // Compact Avatar Section
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              children: [
                                // Compact Avatar Display
                                Container(
                                  padding: const EdgeInsets.all(3),
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
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    transitionBuilder:
                                        (child, animation) => ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                    child: CircleAvatar(
                                      key: ValueKey(currentPhotoUrl),
                                      radius: screenWidth * 0.08,
                                      // Reduced from 0.12
                                      backgroundImage:
                                          currentPhotoUrl != null
                                              ? NetworkImage(currentPhotoUrl!)
                                              : null,
                                      child:
                                          currentPhotoUrl == null
                                              ? Icon(
                                                Icons.person,
                                                size: screenWidth * 0.08,
                                                color: Colors.white70,
                                              )
                                              : null,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ),

                                SizedBox(height: safeAreaHeight * 0.01),

                                // Compact Choose Avatar Button
                                GestureDetector(
                                  onTap: pickAvatar,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.pinkAccent,
                                          Colors.purpleAccent,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.pinkAccent.withOpacity(
                                            0.3,
                                          ),
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
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Choose Avatar',
                                          style: GoogleFonts.cutive(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
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
                                // Compact Gender Selection
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth * 0.9,
                                  ),
                                  padding: const EdgeInsets.all(4),
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
                                      _buildCompactGenderCard(
                                        'Male',
                                        selectedGender,
                                        screenWidth,
                                      ),
                                      const SizedBox(width: 4),
                                      _buildCompactGenderCard(
                                        'Female',
                                        selectedGender,
                                        screenWidth,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: safeAreaHeight * 0.02),

                                // Compact Name Field
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth * 0.9,
                                  ),
                                  child: _buildCompactTextField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    keyboardType: TextInputType.name,
                                    validator: (value) {
                                      if (value!.isEmpty)
                                        return 'Enter your name';
                                      return null;
                                    },
                                    onChanged: (val) {
                                      ref.read(nameProvider.notifier).state =
                                          val;
                                      _validateForm();
                                    },
                                  ),
                                ),

                                SizedBox(height: safeAreaHeight * 0.015),

                                // Compact Email Field
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth * 0.9,
                                  ),
                                  child: _buildCompactTextField(
                                    controller: emailController,
                                    label: 'Email (Optional)',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (val) {
                                      ref.read(emailProvider.notifier).state =
                                          val;
                                    },
                                  ),
                                ),

                                SizedBox(height: safeAreaHeight * 0.025),

                                // Compact Next Button
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth * 0.9,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 44, // Reduced from 56
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          _isFormValid
                                              ? () async {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  await _updateDetailsToFirestore();
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
                                              : null,
                                      child: Container(
                                        width: double.infinity,
                                        height: 44,
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
                                            22,
                                          ),
                                          boxShadow:
                                              _isFormValid
                                                  ? [
                                                    BoxShadow(
                                                      color: Colors.pinkAccent
                                                          .withOpacity(0.3),
                                                      blurRadius: 12,
                                                      spreadRadius: 1,
                                                      offset: const Offset(
                                                        0,
                                                        3,
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
                                                  fontSize: 15,
                                                  // Reduced from 18
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 16, // Reduced from 20
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
                        ],
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

  Widget _buildCompactGenderCard(
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
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
          // Reduced from 0.035
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
            borderRadius: BorderRadius.circular(10), // Reduced from 16
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
                padding: const EdgeInsets.all(4), // Reduced from 8
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                ),
                child: Icon(
                  gender == 'Male' ? Icons.male : Icons.female,
                  size: screenWidth * 0.055, // Reduced from 0.08
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3), // Reduced from 8
              Text(
                gender,
                style: GoogleFonts.cutive(
                  color: Colors.white,
                  fontSize: screenWidth * 0.03, // Reduced from 0.04
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10), // Reduced from 16
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
        style: GoogleFonts.cutive(color: Colors.white, fontSize: 14),
        // Reduced font size
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cutive(color: Colors.white70, fontSize: 12),
          // Reduced
          prefixIcon: Icon(icon, color: Colors.white70, size: 18),
          // Reduced from 22
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
            horizontal: 12, // Reduced from 16
            vertical: 12, // Reduced from 18
          ),
          isDense: true,
        ),
      ),
    );
  }
}
