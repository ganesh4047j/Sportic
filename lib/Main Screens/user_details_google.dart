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
    extends ConsumerState<CollectUserDetailsPage1> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController phoneController;
  bool _isFormValid = false;
  String? currentPhotoUrl;
  final avatarUrls = List.generate(
    10,
    (index) => 'https://api.dicebear.com/7.x/micah/png?seed=avatar${index + 1}',
  );

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: ref.read(phoneProvider));
    phoneController.addListener(_validateForm);
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
      builder:
          (context) => AlertDialog(
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
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    );
                  }
                },
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Lottie.asset('assets/welcome_1.json', height: 200),
                const SizedBox(height: 10),
                Text(
                  'Welcome!',
                  style: GoogleFonts.cutive(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please fill in your details',
                  style: GoogleFonts.cutive(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            currentPhotoUrl != null
                                ? NetworkImage(currentPhotoUrl!)
                                : null,
                        child:
                            currentPhotoUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white70,
                                )
                                : null,
                        backgroundColor: Colors.grey.shade800,
                      ),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 18, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildGenderCard('Male', selectedGender),
                          const SizedBox(width: 15),
                          _buildGenderCard('Female', selectedGender),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: phoneController,
                        maxLength: 10,
                        style: GoogleFonts.cutive(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          'Phone Number (Optional)',
                        ),
                        onChanged: (val) {
                          ref.read(phoneProvider.notifier).state = val;
                          _validateForm();
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isFormValid ? Colors.pinkAccent : Colors.grey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed:
                            _isFormValid
                                ? () async {
                                  if (_formKey.currentState!.validate()) {
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
                        child: Text(
                          "Next",
                          style: GoogleFonts.nunito(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard(String gender, String? selectedGender) {
    final isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(genderProvider.notifier).state = gender;
          _validateForm();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.pinkAccent : const Color(0xFF3D1A4A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white24,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                gender == 'Male' ? Icons.male : Icons.female,
                size: 36,
                color: Colors.white,
              ),
              const SizedBox(height: 6),
              Text(
                gender,
                style: GoogleFonts.cutive(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cutive(color: Colors.white),
      counterStyle: GoogleFonts.cutive(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white54),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
