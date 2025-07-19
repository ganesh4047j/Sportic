import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sports/Main%20Screens/home.dart';
import 'package:sports/Providers/turfscreen_provider.dart';

class LocationInputScreen extends ConsumerWidget {
  final bool shouldRedirectToHome;
  const LocationInputScreen({super.key, this.shouldRedirectToHome = true});

  Future<void> _updateLocationToFirestore(String location) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String? uid;
    String? loginMethod;
    const storage = FlutterSecureStorage();

    if (firebaseUser != null) {
      uid = firebaseUser.uid;
      loginMethod = "email";
    } else {
      uid = await storage.read(key: 'custom_uid');
      loginMethod = "phone";
    }

    if (uid == null || loginMethod == null) {
      debugPrint("❌ UID or login method not found");
      return;
    }

    final collectionName = loginMethod == "email"
        ? "user_details_email"
        : "user_details_phone";

    final docRef = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(uid);

    try {
      await docRef.update({
        'location': location,
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Location updated successfully in $collectionName/$uid");
    } on FirebaseException catch (e) {
      debugPrint("❌ FirebaseException: ${e.message}");
    } catch (e) {
      debugPrint("❌ Error updating location: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(userLocationProvider);

    final List<String> trichyLocations = [
      "Ariyamangalam",
      "BHEL Township",
      "Cantonment",
      "Edamalaipatti Pudur",
      "Golden Rock",
      "K.K. Nagar",
      "Karumandapam",
      "Palakkarai",
      "Sangillyandapuram",
      "Srirangam",
      "Tennur",
      "Thillai Nagar",
      "Tiruverumbur",
      "TVS Tollgate",
      "Woraiyur",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          children: [
            Lottie.asset(
              'assets/location.json',
              fit: BoxFit.fill,
              height: double.infinity,
              width: double.infinity,
              repeat: true,
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Animate(
                    effects: [
                      FadeEffect(duration: 500.ms),
                      SlideEffect(duration: 500.ms),
                    ],
                    child: Card(
                      elevation: 20,
                      color: Colors.white.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "📍 Select Your Location",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ).animate().fadeIn().slideY(),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value:
                                  (currentLocation != null &&
                                      currentLocation.isNotEmpty)
                                  ? currentLocation
                                  : null,
                              items: trichyLocations.map((location) {
                                return DropdownMenuItem(
                                  value: location,
                                  child: Text(
                                    location,
                                    style: GoogleFonts.cutive(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  ref
                                          .read(userLocationProvider.notifier)
                                          .state =
                                      value;
                                }
                              },
                              decoration: InputDecoration(
                                labelText: "Choose Area",
                                labelStyle: GoogleFonts.cutive(),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ).animate().fadeIn(duration: 600.ms),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final selected = ref.read(userLocationProvider);
                                if (selected != null && selected.isNotEmpty) {
                                  await _updateLocationToFirestore(selected);

                                  // ✅ Update global location provider
                                  ref
                                          .read(userLocationProvider.notifier)
                                          .state =
                                      selected;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Location saved: $selected",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  if (shouldRedirectToHome) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HomeScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  } else {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              icon: const Icon(Icons.save, color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              label: Text(
                                "Save Location",
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ).animate().fadeIn(duration: 700.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
