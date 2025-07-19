// 📄 edit_profile.dart
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

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
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
  final avatarUrls = List.generate(
    10,
    (index) => 'https://api.dicebear.com/7.x/micah/png?seed=avatar${index + 1}',
  );

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String? uid;
    DocumentSnapshot<Map<String, dynamic>>? userDoc;

    if (firebaseUser != null) {
      loginType = "email";
      uid = firebaseUser.uid;
      userDoc = await FirebaseFirestore.instance
          .collection('user_details_email')
          .doc(uid)
          .get();
    } else {
      uid = await secureStorage.read(key: 'custom_uid');
      loginType = "phone";
      if (uid != null) {
        userDoc = await FirebaseFirestore.instance
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
  }

  String _generateAvatarFromName(String name) {
    final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'https://api.dicebear.com/7.x/avataaars/png?seed=$clean';
  }

  Future<void> pickAvatar() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: avatarUrls.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () {
                    setState(() => currentPhotoUrl = null);
                    Navigator.pop(context);
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                );
              } else {
                final avatarUrl = avatarUrls[index - 1];
                return GestureDetector(
                  onTap: () {
                    setState(() => currentPhotoUrl = avatarUrl);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> saveProfile() async {
    if (userId == null) return;
    setState(() => isLoading = true);

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
      final collection = loginType == "email"
          ? 'user_details_email'
          : 'user_details_phone';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        // ✅ Update the global location provider
        ref.read(userLocationProvider.notifier).state = locationController.text
            .trim();

        // ✅ Invalidate the profile provider to refresh in other screens
        ref.invalidate(userProfileProvider(userId!));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("❌ Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    } finally {
      setState(() => isLoading = false);
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
        child: isLoading
            ? Center(child: Lottie.asset('assets/loading_spinner.json'))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView(
                    children: [
                      Text(
                        "Edit Profile",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: pickAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundImage: currentPhotoUrl != null
                                    ? NetworkImage(currentPhotoUrl!)
                                    : null,
                                child: currentPhotoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white70,
                                      )
                                    : null,
                                backgroundColor: Colors.grey.shade800,
                              ),
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField("Name", nameController, Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField("Email", emailController, Icons.email),
                      const SizedBox(height: 12),
                      _buildTextField("Phone", phoneController, Icons.phone),
                      const SizedBox(height: 12),
                      _buildTextField(
                        "Location",
                        locationController,
                        Icons.location_on,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField("Gender", genderController, Icons.male),
                      const SizedBox(height: 12),
                      _buildTextField("Bio", bioController, Icons.info),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 30,
                        child: ElevatedButton(
                          onPressed: saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE60073),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            "Save Changes",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    final isBio = label.toLowerCase() == 'bio';
    return TextField(
      controller: controller,
      maxLines: isBio ? 2 : 1,
      maxLength: isBio ? 120 : null,
      keyboardType: isBio ? TextInputType.multiline : TextInputType.text,
      style: GoogleFonts.cutive(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cutive(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        counterStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.purple, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
