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

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  String? loginType;
  String? userId;
  late AnimationController _headerController;
  late AnimationController _profileController;
  late AnimationController _menuController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    determineLoginType();
    _startAnimations();
  }

  void _startAnimations() {
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _profileController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _menuController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _profileController.dispose();
    _menuController.dispose();
    super.dispose();
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
          child: Center(
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
                  'Loading Profile...',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
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
                        'Loading Profile...',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;

              if (data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white70,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No profile data found.",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _headerController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'My Profile',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 24,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Profile Card Section
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _profileController,
                        curve: Curves.elasticOut,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Avatar with Glow Effect
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE60073,
                                    ).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(
                                    data['photoUrl'] ??
                                        'https://i.pravatar.cc/300',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name
                            Text(
                              (data['name'] ?? '').isNotEmpty
                                  ? data['name']
                                  : 'Name',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE60073).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFFE60073,
                                  ).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00FF88),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Active',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Info Cards
                            _buildInfoCard(
                              Icons.email_outlined,
                              (data['email'] ?? '').isNotEmpty
                                  ? data['email']
                                  : 'Email Address',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              Icons.phone_outlined,
                              (data['phone_number'] ?? '').isNotEmpty
                                  ? data['phone_number']
                                  : 'Phone Number',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              Icons.location_on_outlined,
                              (data['location'] ?? '').isNotEmpty
                                  ? data['location']
                                  : 'Location',
                            ),
                            const SizedBox(height: 24),

                            // Edit Profile Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE60073),
                                    Color(0xFFFF1493),
                                  ],
                                ),
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
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edit Profile',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Menu Section
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _menuController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildEnhancedProfileTile(
                              icon: Icons.search,
                              title: 'Search Friend',
                              subtitle: 'Find and connect with friends',
                              color: const Color(0xFF4CAF50),
                              delay: 0,
                            ),
                            _buildDivider(),
                            _buildEnhancedProfileTile(
                              icon: Icons.people_outline,
                              title: 'Connections',
                              subtitle: 'View your friend connections',
                              color: const Color(0xFF2196F3),
                              delay: 100,
                            ),
                            _buildDivider(),
                            _buildEnhancedProfileTile(
                              icon: Icons.mail_outline,
                              title: 'Requests',
                              subtitle: 'Manage friend requests',
                              color: const Color(0xFFFF9800),
                              delay: 200,
                            ),
                            _buildDivider(),
                            _buildEnhancedProfileTile(
                              icon: Icons.support_agent,
                              title: 'Support',
                              subtitle: 'Get help and assistance',
                              color: const Color(0xFF9C27B0),
                              delay: 300,
                            ),
                            _buildDivider(),
                            _buildEnhancedProfileTile(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              subtitle: 'Sign out of your account',
                              color: const Color(0xFFF44336),
                              delay: 400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
  }) {
    return Animate(
      effects: [
        SlideEffect(
          begin: const Offset(1, 0),
          duration: Duration(milliseconds: 600 + delay),
          curve: Curves.easeOutBack,
        ),
        FadeEffect(duration: Duration(milliseconds: 400 + delay)),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTileTap(title),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTileTap(String title) {
    switch (title) {
      case 'Logout':
        _showLogoutDialog();
        break;
      case 'Search Friend':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FriendsPage()),
        );
        break;
      case 'Connections':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConnectionsPage()),
        );
        break;
      case 'Requests':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
        );
        break;
      case 'Support':
        _showSupportDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Animate(
          effects: [
            ScaleEffect(
              begin: const Offset(0.8, 0.8),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            ),
            FadeEffect(duration: 200.ms),
          ],
          child: AlertDialog(
            backgroundColor: const Color(0xFF2A163A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFF44336),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Confirm Logout',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to logout from your account?',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneLoginScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSupportDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: Opacity(
            opacity: animation.value,
            child: const Center(child: SupportChatDialog()),
          ),
        );
      },
    );
  }
}
