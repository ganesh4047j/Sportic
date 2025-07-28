import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sports/Main%20Screens/connections.dart';
import 'package:sports/Main%20Screens/request_view.dart';
import 'package:sports/Main%20Screens/search_friends.dart';
import '../Authentication/phn_validation.dart';
import '../Services/support_chat_dialog.dart';
import 'edit_profile.dart';

final FlutterSecureStorage secureStorage = FlutterSecureStorage();

Future<Map<String, dynamic>> getUserProfile() async {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser != null) {
    final emailDoc =
        await FirebaseFirestore.instance
            .collection('user_details_email')
            .doc(firebaseUser.uid)
            .get();

    if (emailDoc.exists) {
      final profile = emailDoc.data()!;
      return {
        'uid': firebaseUser.uid,
        'loginType': 'email',
        'name': profile['name'],
        'gender': profile['gender'],
        'email': profile['email'],
        'phone_number': profile['phone_number'],
        'location': profile['location'],
        'photoUrl': profile['photoUrl'],
      };
    }
  }

  final customUid = await secureStorage.read(key: 'custom_uid');

  if (customUid != null) {
    final phoneDoc =
        await FirebaseFirestore.instance
            .collection('user_details_phone')
            .doc(customUid)
            .get();

    if (phoneDoc.exists) {
      final profile = phoneDoc.data()!;
      return {
        'uid': customUid,
        'loginType': 'phone',
        'name': profile['name'],
        'gender': profile['gender'],
        'email': profile['email'],
        'phone_number': profile['phone_number'],
        'location': profile['location'],
        'photoUrl': profile['photoUrl'],
      };
    }
  }

  throw Exception("User not authenticated or profile not found.");
}

final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await getUserProfile();
});

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? loginType;
  String? userId;

  @override
  void initState() {
    super.initState();
    determineLoginType();
  }

  Future<void> determineLoginType() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      loginType = 'email';
      userId = firebaseUser.uid;
    } else {
      loginType = 'phone';
      userId = await secureStorage.read(key: 'custom_uid');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null || loginType == null) {
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
          child: Center(child: Lottie.asset('assets/loading_spinner.json')),
        ),
      );
    }

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
          child: StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection(
                      loginType == 'email'
                          ? 'user_details_email'
                          : 'user_details_phone',
                    )
                    .doc(userId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Lottie.asset('assets/loading_spinner.json'),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;

              if (data == null) {
                return Center(
                  child: Text(
                    "No profile data found.",
                    style: GoogleFonts.cutive(color: Colors.white),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25.0,
                  vertical: 12,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Text(
                            'My Profile',
                            style: GoogleFonts.robotoSlab(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: NetworkImage(
                              data['photoUrl'] ??
                                  data['photoUrl'] ??
                                  'https://i.pravatar.cc/300',
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                (data['name'] ?? '').isNotEmpty
                                    ? data['name']
                                    : 'Name',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                (data['email'] ?? '').isNotEmpty
                                    ? data['email']
                                    : 'Email Address',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                (data['phone_number'] ?? '').isNotEmpty
                                    ? data['phone_number']
                                    : 'Phone Number',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                (data['location'] ?? '').isNotEmpty
                                    ? data['location']
                                    : 'Location',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const EditProfilePage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFFE60073),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  'edit profile',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Divider(
                        color: Colors.white,
                        thickness: 3,
                        indent: 10,
                        endIndent: 15,
                      ),
                      _ProfileTile(icon: Icons.group, title: 'Search Friend'),
                      _ProfileTile(
                        icon: Icons.group_outlined,
                        title: 'Connections',
                      ),
                      _ProfileTile(
                        icon: Icons.contact_support_sharp,
                        title: 'Support',
                      ),
                      _ProfileTile(icon: Icons.share, title: 'Request'),
                      _ProfileTile(icon: Icons.logout, title: 'Logout'),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ProfileTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        if (title == 'Logout') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return Animate(
                effects: [
                  FadeEffect(duration: 300.ms),
                  ScaleEffect(curve: Curves.easeOutBack),
                ],
                child: AlertDialog(
                  backgroundColor: const Color(0xFF2A163A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Confirm Logout',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to logout?',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), // dismiss dialog
                      child: Text(
                        'No',
                        style: GoogleFonts.poppins(color: Colors.pink),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhoneLoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Yes',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else if (title == 'Search Friend') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendsPage()),
          );
        } else if (title == 'Connections') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConnectionsPage()),
          );
        } else if (title == 'Request') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
          );
        } else if (title == 'Support') {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel:
                MaterialLocalizations.of(context).modalBarrierDismissLabel,
            barrierColor: Colors.black.withOpacity(0.5), // Background overlay
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) {
              return const SizedBox.shrink(); // Required but unused
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return Transform.scale(
                scale: animation.value,
                child: Opacity(
                  opacity: animation.value,
                  child: Center(child: const SupportChatDialog()),
                ),
              );
            },
          );
        }
      },
    );
  }
}
