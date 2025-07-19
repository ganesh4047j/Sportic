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

class _CollectUserDetailsPageState
    extends ConsumerState<CollectUserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false;
  late TextEditingController nameController;
  late TextEditingController emailController;
  final _secureStorage = const FlutterSecureStorage();
  String? currentPhotoUrl;
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
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: CircleAvatar(
                          key: ValueKey(currentPhotoUrl),
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
                      ),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 20, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
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
                        controller: nameController,
                        style: GoogleFonts.cutive(color: Colors.white),
                        keyboardType: TextInputType.name,
                        decoration: _buildInputDecoration('Full Name'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter your name';
                          return null;
                        },
                        onChanged: (val) {
                          ref.read(nameProvider.notifier).state = val;
                          _validateForm();
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: emailController,
                        style: GoogleFonts.cutive(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          'Email Address (Optional)',
                        ),
                        onChanged: (val) {
                          ref.read(emailProvider.notifier).state = val;
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid
                              ? Colors.pinkAccent
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isFormValid
                            ? () async {
                                if (_formKey.currentState!.validate()) {
                                  await _updateDetailsToFirestore();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LocationInputScreen(),
                                    ),
                                  );
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
