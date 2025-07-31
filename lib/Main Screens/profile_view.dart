import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Providers/user_profile_provider.dart';
import '../Services/user_model.dart';
import '../Services/friendship_utils.dart';

class ProfileView extends ConsumerStatefulWidget {
  final String userId;
  const ProfileView({super.key, required this.userId});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late AnimationController _headerController;
  late AnimationController _profileController;
  late AnimationController _actionButtonController;
  late Animation<double> _headerAnimation;
  late Animation<double> _profileAnimation;
  late Animation<double> _actionButtonAnimation;

  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _actionButtonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _profileAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _profileController, curve: Curves.elasticOut),
    );
    _actionButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _actionButtonController, curve: Curves.bounceOut),
    );
  }

  void _startAnimations() {
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _profileController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _actionButtonController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    _profileController.dispose();
    _actionButtonController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Helper method to get responsive padding
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return const EdgeInsets.all(12);
    } else if (screenWidth < 414) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  // Helper method to get responsive font size
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375; // Base width of iPhone 6/7/8
    return (baseSize * scaleFactor).clamp(baseSize * 0.8, baseSize * 1.2);
  }

  // Helper method to get responsive avatar radius
  double _getAvatarRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 40;
    } else if (screenWidth < 414) {
      return 45;
    } else {
      return 50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final isFriendAsync = ref.watch(friendshipStatusProvider(widget.userId));
    final friendsCountAsync = ref.watch(friendsCountProvider(widget.userId));
    final responsivePadding = _getResponsivePadding(context);

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
        child: profileAsync.when(
          data: (user) {
            return SafeArea(
              child: NestedScrollView(
                headerSliverBuilder:
                    (_, __) => [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // Enhanced Header Section
                            AnimatedBuilder(
                              animation: _headerAnimation,
                              builder: (context, child) {
                                final clampedValue = _headerAnimation.value
                                    .clamp(0.0, 1.0);
                                return Transform.scale(
                                  scale: clampedValue,
                                  child: Opacity(
                                    opacity: clampedValue,
                                    child: Container(
                                      padding: responsivePadding,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: responsivePadding.left,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(30),
                                          bottomRight: Radius.circular(30),
                                        ),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white24,
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.arrow_back_ios_new,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Player Profile",
                                                  style: GoogleFonts.nunito(
                                                    color: Colors.white,
                                                    fontSize:
                                                        _getResponsiveFontSize(
                                                          context,
                                                          24,
                                                        ),
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                Text(
                                                  "View player details and stats",
                                                  style: GoogleFonts.nunito(
                                                    color: Colors.white70,
                                                    fontSize:
                                                        _getResponsiveFontSize(
                                                          context,
                                                          14,
                                                        ),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFE60073,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFE60073,
                                                ).withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.sports,
                                              color: Color(0xFFE60073),
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),

                            // Enhanced Profile Avatar Section
                            AnimatedBuilder(
                              animation: _profileAnimation,
                              builder: (context, child) {
                                final clampedValue = _profileAnimation.value
                                    .clamp(0.0, 1.0);
                                return Transform.scale(
                                  scale: clampedValue,
                                  child: Opacity(
                                    opacity: clampedValue,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
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
                                        child: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            user.photoUrl ?? '',
                                          ),
                                          radius: _getAvatarRadius(context),
                                          backgroundColor: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.025,
                            ),

                            // Enhanced Name Section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsivePadding.left,
                              ),
                              child: Text(
                                    user.name,
                                    style: GoogleFonts.nunito(
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        28,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                  .animate()
                                  .fadeIn(delay: 400.ms)
                                  .slideY(begin: 0.3),
                            ),

                            // Enhanced Bio Section
                            if (_isEditingBio && currentUser?.uid == user.uid)
                              Container(
                                margin: responsivePadding,
                                padding: responsivePadding,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFE60073,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Color(0xFFE60073),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Edit Bio",
                                            style: GoogleFonts.nunito(
                                              color: Colors.white,
                                              fontSize: _getResponsiveFontSize(
                                                context,
                                                18,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _bioController,
                                      maxLines: null,
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontSize: _getResponsiveFontSize(
                                          context,
                                          16,
                                        ),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Enter your bio...",
                                        hintStyle: GoogleFonts.nunito(
                                          color: Colors.white54,
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            14,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(
                                          0.08,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE60073),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Flexible(
                                          child: TextButton(
                                            onPressed:
                                                () => setState(
                                                  () => _isEditingBio = false,
                                                ),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.04,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              "Cancel",
                                              style: GoogleFonts.nunito(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      14,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection(
                                                    user.uid.startsWith("phone")
                                                        ? 'user_details_phone'
                                                        : 'user_details_email',
                                                  )
                                                  .doc(user.uid)
                                                  .update({
                                                    'bio':
                                                        _bioController.text
                                                            .trim(),
                                                  });
                                              setState(
                                                () => _isEditingBio = false,
                                              );
                                              ref.refresh(
                                                userProfileProvider(user.uid),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.04,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              "Save",
                                              style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      14,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                    margin: responsivePadding,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.info_outline,
                                              color: Color(0xFFE60073),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              (user.bio ?? '').isNotEmpty
                                                  ? user.bio!
                                                  : "No bio available.",
                                              style: GoogleFonts.nunito(
                                                color: Colors.white70,
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      15,
                                                    ),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          if (currentUser?.uid == user.uid)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isEditingBio = true;
                                                  _bioController.text =
                                                      user.bio ?? "";
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  color: Colors.white70,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 500.ms)
                                  .slideX(begin: -0.3),

                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),

                            // Enhanced Location Section
                            if (user.location != null)
                              Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                          0.04,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Color(0xFFE60073),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            user.location!,
                                            style: GoogleFonts.nunito(
                                              color: Colors.white70,
                                              fontSize: _getResponsiveFontSize(
                                                context,
                                                14,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 600.ms)
                                  .scale(begin: const Offset(0.8, 0.8)),

                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),

                            // Enhanced Friends Count
                            friendsCountAsync.when(
                              data:
                                  (count) => Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.05,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(
                                                0xFFE60073,
                                              ).withOpacity(0.2),
                                              const Color(
                                                0xFFFF6B9D,
                                              ).withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFE60073,
                                            ).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.people,
                                              color: Color(0xFFE60073),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$count Friends',
                                              style: GoogleFonts.nunito(
                                                color: Colors.white,
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      16,
                                                    ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(delay: 700.ms)
                                      .scale(begin: const Offset(0.8, 0.8)),
                              loading:
                                  () => Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                              error:
                                  (_, __) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                          0.04,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      "Failed to load friends",
                                      style: GoogleFonts.nunito(
                                        color: Colors.redAccent,
                                        fontSize: _getResponsiveFontSize(
                                          context,
                                          14,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),

                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.025,
                            ),

                            // Enhanced Action Button
                            AnimatedBuilder(
                              animation: _actionButtonAnimation,
                              builder: (context, child) {
                                final clampedValue = _actionButtonAnimation
                                    .value
                                    .clamp(0.0, 1.0);
                                return Transform.scale(
                                  scale: clampedValue,
                                  child: Opacity(
                                    opacity: clampedValue,
                                    child: isFriendAsync.when(
                                      data: (isFriend) {
                                        return isFriend
                                            ? Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.06,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Colors.green,
                                                    Colors.greenAccent,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.4),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Friend",
                                                    style: GoogleFonts.nunito(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize:
                                                          _getResponsiveFontSize(
                                                            context,
                                                            16,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFFE60073,
                                                    ).withOpacity(0.4),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFE60073,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          25,
                                                        ),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width *
                                                        0.06,
                                                    vertical: 12,
                                                  ),
                                                  elevation: 0,
                                                ),
                                                onPressed: () async {
                                                  await sendFriendRequest(
                                                    user.uid,
                                                  );
                                                  ref.invalidate(
                                                    friendshipStatusProvider(
                                                      user.uid,
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.person_add,
                                                  size: 20,
                                                ),
                                                label: Text(
                                                  "Add Friend",
                                                  style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:
                                                        _getResponsiveFontSize(
                                                          context,
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            );
                                      },
                                      loading:
                                          () => Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                          ),
                                      error:
                                          (_, __) => Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.05,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              "Error checking friend status",
                                              style: GoogleFonts.nunito(
                                                color: Colors.redAccent,
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      14,
                                                    ),
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),

                            // Enhanced TabBar
                            Container(
                                  margin: responsivePadding,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.white54,
                                    indicator: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE60073),
                                          Color(0xFFFF6B9D),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    labelStyle: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600,
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        14,
                                      ),
                                    ),
                                    unselectedLabelStyle: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w500,
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        14,
                                      ),
                                    ),
                                    tabs: const [
                                      Tab(text: "Stats"),
                                      Tab(text: "Achievements"),
                                      Tab(text: "Clubs"),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 800.ms)
                                .slideY(begin: 0.3),
                          ],
                        ),
                      ),
                    ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatsTab(user),
                    _buildAchievementsTab(),
                    _buildClubsTab(),
                  ],
                ),
              ),
            );
          },
          loading:
              () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE60073),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading profile...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
          error:
              (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: _getResponsivePadding(context),
                      child: Text(
                        "Error: $e",
                        style: GoogleFonts.nunito(
                          color: Colors.redAccent,
                          fontSize: _getResponsiveFontSize(context, 16),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(UserModel user) {
    final responsivePadding = _getResponsivePadding(context);
    return ListView(
      padding: responsivePadding,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildStatsCard(
          user,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        SizedBox(height: MediaQuery.of(context).size.height * 0.025),
        buildSportsSection(
          user,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    return Center(
      child: Padding(
        padding: _getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Icon(
                Icons.emoji_events,
                color: Colors.white54,
                size: MediaQuery.of(context).size.width * 0.16,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Text(
              "Achievements coming soon!",
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: _getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              "Your trophies and milestones will appear here",
              style: GoogleFonts.nunito(
                color: Colors.white54,
                fontSize: _getResponsiveFontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildClubsTab() {
    return Center(
      child: Padding(
        padding: _getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Icon(
                Icons.groups,
                color: Colors.white54,
                size: MediaQuery.of(context).size.width * 0.16,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Text(
              "Club data coming soon!",
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: _getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              "Your club memberships and activities will appear here",
              style: GoogleFonts.nunito(
                color: Colors.white54,
                fontSize: _getResponsiveFontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildStatsCard(UserModel user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = _getResponsivePadding(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: responsivePadding,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth < 360 ? 8 : 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE60073), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: screenWidth < 360 ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Match Stats",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            // Responsive stats layout
            screenWidth < 360
                ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statItem(
                            "Played",
                            user.gamesPlayed.toString(),
                            Icons.sports_soccer,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statItem(
                            "Won",
                            user.gamesWon.toString(),
                            Icons.emoji_events,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _statItem(
                        "Lost",
                        (user.gamesPlayed - user.gamesWon).toString(),
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _statItem(
                        "Played",
                        user.gamesPlayed.toString(),
                        Icons.sports_soccer,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statItem(
                        "Won",
                        user.gamesWon.toString(),
                        Icons.emoji_events,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statItem(
                        "Lost",
                        (user.gamesPlayed - user.gamesWon).toString(),
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: screenWidth < 360 ? 20 : 24),
          SizedBox(height: screenWidth < 360 ? 6 : 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: _getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 2 : 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontSize: _getResponsiveFontSize(context, 13),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildSportsSection(UserModel user) {
    final responsivePadding = _getResponsivePadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsivePadding.left),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60073).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sports,
                  color: Color(0xFFE60073),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Sports & Player Position",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.025),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: responsivePadding.left),
            children: [
              _playerCard(
                icon: Icons.sports_soccer,
                title: "Forward",
                skill: "Advanced",
                rating: 4.2,
                games: 711,
                mvps: 19,
              ),
              _playerCard(
                icon: Icons.sports_basketball,
                title: "Shooter",
                skill: "Intermediate",
                rating: 3.8,
                games: 420,
                mvps: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _playerCard({
    required IconData icon,
    required String title,
    required String skill,
    required double rating,
    required int games,
    required int mvps,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 360 ? screenWidth * 0.85 : 280.0;

    Color skillColor;
    switch (skill.toLowerCase()) {
      case 'advanced':
        skillColor = Colors.green;
        break;
      case 'intermediate':
        skillColor = Colors.orange;
        break;
      default:
        skillColor = Colors.blue;
    }

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: skillColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: skillColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    skill,
                    style: GoogleFonts.nunito(
                      color: skillColor,
                      fontSize: _getResponsiveFontSize(context, 11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth < 360 ? 8 : 12),
            Text(
              title,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth < 360 ? 6 : 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: rating / 5.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE60073), Color(0xFFFF6B9D)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: _getResponsiveFontSize(context, 14),
                  ),
                ),
                const Icon(Icons.star, color: Colors.amber, size: 16),
              ],
            ),
            SizedBox(height: screenWidth < 360 ? 8 : 12),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(screenWidth < 360 ? 8 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            games.toString(),
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: _getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Games",
                            style: GoogleFonts.nunito(
                              color: Colors.white70,
                              fontSize: _getResponsiveFontSize(context, 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 25, color: Colors.white24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mvps.toString(),
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: _getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "MVPs",
                            style: GoogleFonts.nunito(
                              color: Colors.white70,
                              fontSize: _getResponsiveFontSize(context, 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.3);
  }
}
