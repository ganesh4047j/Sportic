// 📄 edit_profile.dart - Enhanced UI Version
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sports/Providers/turfscreen_provider.dart';

import '../Providers/user_profile_provider.dart'; // ✅ Added import

final secureStorage = FlutterSecureStorage();

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with TickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final bioController = TextEditingController();
  String? currentPhotoUrl;
  String? loginType;
  String? userId;
  bool isLoading = true;
  bool isSaving = false;

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
    _initAnimations();
    loadProfileData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> loadProfileData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String? uid;
    DocumentSnapshot<Map<String, dynamic>>? userDoc;

    if (firebaseUser != null) {
      loginType = "email";
      uid = firebaseUser.uid;
      userDoc =
          await FirebaseFirestore.instance
              .collection('user_details_email')
              .doc(uid)
              .get();
    } else {
      uid = await secureStorage.read(key: 'custom_uid');
      loginType = "phone";
      if (uid != null) {
        userDoc =
            await FirebaseFirestore.instance
                .collection('user_details_phone')
                .doc(uid)
                .get();
      }
    }

    if (userDoc != null && userDoc.exists) {
      final data = userDoc.data()!;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      locationController.text = data['location'] ?? '';
      phoneController.text = data['phone_number'] ?? '';
      genderController.text = data['gender'] ?? '';
      bioController.text = data['bio'] ?? '';
      currentPhotoUrl =
          data['photoUrl'] ?? _generateAvatarFromName(data['name'] ?? 'user');
      userId = uid;
    }

    setState(() => isLoading = false);

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  String _generateAvatarFromName(String name) {
    final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'https://api.dicebear.com/7.x/avataaars/png?seed=$clean';
  }

  Future<void> pickAvatar() async {
    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF452152),
                    Color(0xFF3D1A4A),
                    Color(0xFF200D28),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose Avatar',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.maxFinite,
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: avatarUrls.length + 1,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
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
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
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
                                  border: Border.all(
                                    color:
                                        currentPhotoUrl == avatarUrl
                                            ? const Color(0xFFE60073)
                                            : Colors.white24,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(avatarUrl),
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

  Future<void> saveProfile() async {
    if (userId == null) return;
    setState(() => isSaving = true);

    final data = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'location': locationController.text.trim(),
      'phone_number': phoneController.text.trim(),
      'photoUrl':
          currentPhotoUrl ??
          _generateAvatarFromName(nameController.text.trim()),
      'gender': genderController.text.trim(),
      'bio': bioController.text.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    try {
      final collection =
          loginType == "email" ? 'user_details_email' : 'user_details_phone';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        // ✅ Update the global location provider
        ref.read(userLocationProvider.notifier).state =
            locationController.text.trim();

        // ✅ Invalidate the profile provider to refresh in other screens
        ref.invalidate(userProfileProvider(userId!));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  "Profile updated successfully",
                  style: GoogleFonts.nunito(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("❌ Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  "Failed to update profile",
                  style: GoogleFonts.nunito(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
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
        child:
            isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/loading_spinner.json',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Loading your profile...",
                        style: GoogleFonts.nunito(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Header with back button
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Edit Profile",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 48,
                                ), // Balance the back button
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Profile Avatar Section
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Center(
                                child: GestureDetector(
                                  onTap: pickAvatar,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE60073),
                                          Color(0xFFFF6B9D),
                                          Color(0xFFE60073),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFE60073,
                                          ).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF3D1A4A),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          CircleAvatar(
                                            radius: 55,
                                            backgroundImage:
                                                currentPhotoUrl != null
                                                    ? NetworkImage(
                                                      currentPhotoUrl!,
                                                    )
                                                    : null,
                                            child:
                                                currentPhotoUrl == null
                                                    ? const Icon(
                                                      Icons.person,
                                                      size: 50,
                                                      color: Colors.white70,
                                                    )
                                                    : null,
                                            backgroundColor:
                                                Colors.grey.shade800,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Colors.grey,
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              size: 18,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Form Fields with Staggered Animation
                            _buildAnimatedTextField(
                              "Name",
                              nameController,
                              Icons.person,
                              0,
                            ),
                            const SizedBox(height: 16),
                            _buildAnimatedTextField(
                              "Email",
                              emailController,
                              Icons.email,
                              100,
                            ),
                            const SizedBox(height: 16),
                            _buildAnimatedTextField(
                              "Phone",
                              phoneController,
                              Icons.phone,
                              200,
                            ),
                            const SizedBox(height: 16),
                            _buildAnimatedTextField(
                              "Location",
                              locationController,
                              Icons.location_on,
                              300,
                            ),
                            const SizedBox(height: 16),
                            _buildAnimatedTextField(
                              "Gender",
                              genderController,
                              Icons.male,
                              400,
                            ),
                            const SizedBox(height: 16),
                            _buildAnimatedTextField(
                              "Bio",
                              bioController,
                              Icons.info,
                              500,
                            ),
                            const SizedBox(height: 40),

                            // Save Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE60073,
                                    ).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isSaving ? null : saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE60073),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  elevation: 0,
                                ),
                                child:
                                    isSaving
                                        ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              "Saving Changes...",
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                        : Text(
                                          "Save Changes",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildAnimatedTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    int delay,
  ) {
    final isBio = label.toLowerCase() == 'bio';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        // Clamp the value to ensure it stays within valid range
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - clampedValue)),
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                maxLines: isBio ? 3 : 1,
                maxLength: isBio ? 120 : null,
                keyboardType:
                    isBio ? TextInputType.multiline : TextInputType.text,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFFE60073), size: 20),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  counterStyle: GoogleFonts.nunito(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFE60073),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
