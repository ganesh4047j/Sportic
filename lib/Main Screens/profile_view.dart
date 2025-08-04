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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive height based on screen size
    double sectionHeight;
    if (screenWidth <= 320) {
      sectionHeight = 170;
    } else if (screenWidth <= 360) {
      sectionHeight = 180;
    } else if (screenWidth <= 375) {
      sectionHeight = 190;
    } else if (screenWidth <= 414) {
      sectionHeight = 200;
    } else {
      sectionHeight = 210;
    }

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

        // Fixed height container with responsive height
        SizedBox(
          height: sectionHeight,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Ultra responsive calculations based on actual screen size
        double cardWidth;
        double cardHeight;
        double padding;
        double headerHeight;
        double titleHeight;
        double ratingHeight;
        double statsHeight;
        double iconSize;
        double titleFontSize;
        double skillFontSize;
        double ratingFontSize;
        double statsFontSize;
        double statsLabelFontSize;

        // Define breakpoints for different device sizes
        if (screenWidth <= 320) {
          // iPhone SE 1st gen and very small phones
          cardWidth = screenWidth - 40;
          cardHeight = 160;
          padding = 8;
          headerHeight = 32;
          titleHeight = 20;
          ratingHeight = 16;
          statsHeight = 60;
          iconSize = 16;
          titleFontSize = 14;
          skillFontSize = 9;
          ratingFontSize = 11;
          statsFontSize = 13;
          statsLabelFontSize = 9;
        } else if (screenWidth <= 360) {
          // iPhone SE 2nd/3rd gen, small Android phones
          cardWidth = screenWidth - 50;
          cardHeight = 170;
          padding = 10;
          headerHeight = 35;
          titleHeight = 22;
          ratingHeight = 18;
          statsHeight = 65;
          iconSize = 18;
          titleFontSize = 15;
          skillFontSize = 10;
          ratingFontSize = 12;
          statsFontSize = 14;
          statsLabelFontSize = 10;
        } else if (screenWidth <= 375) {
          // iPhone 6/7/8, iPhone 12 mini
          cardWidth = screenWidth - 60;
          cardHeight = 180;
          padding = 12;
          headerHeight = 38;
          titleHeight = 24;
          ratingHeight = 20;
          statsHeight = 70;
          iconSize = 20;
          titleFontSize = 16;
          skillFontSize = 10;
          ratingFontSize = 13;
          statsFontSize = 15;
          statsLabelFontSize = 10;
        } else if (screenWidth <= 414) {
          // iPhone 6+/7+/8+, iPhone XR/11
          cardWidth = screenWidth - 70;
          cardHeight = 190;
          padding = 14;
          headerHeight = 40;
          titleHeight = 26;
          ratingHeight = 22;
          statsHeight = 75;
          iconSize = 22;
          titleFontSize = 17;
          skillFontSize = 11;
          ratingFontSize = 14;
          statsFontSize = 16;
          statsLabelFontSize = 11;
        } else {
          // Large phones and tablets
          cardWidth = 320;
          cardHeight = 200;
          padding = 16;
          headerHeight = 42;
          titleHeight = 28;
          ratingHeight = 24;
          statsHeight = 80;
          iconSize = 24;
          titleFontSize = 18;
          skillFontSize = 11;
          ratingFontSize = 14;
          statsFontSize = 16;
          statsLabelFontSize = 11;
        }

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
          height: cardHeight,
          margin: EdgeInsets.only(right: padding),
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
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section - Fixed Height
                SizedBox(
                  height: headerHeight,
                  child: Row(
                    children: [
                      Container(
                        width: headerHeight,
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: iconSize),
                      ),
                      SizedBox(width: padding),
                      Expanded(
                        child: Container(
                          height: headerHeight * 0.8,
                          padding: EdgeInsets.symmetric(
                            horizontal: padding * 0.8,
                            vertical: padding * 0.3,
                          ),
                          decoration: BoxDecoration(
                            color: skillColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: skillColor.withOpacity(0.5),
                            ),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                skill,
                                style: GoogleFonts.nunito(
                                  color: skillColor,
                                  fontSize: skillFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: padding * 0.5),

                // Title Section - Fixed Height
                SizedBox(
                  height: titleHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: padding * 0.4),

                // Rating Section - Fixed Height
                SizedBox(
                  height: ratingHeight,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (rating / 5.0).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE60073),
                                    Color(0xFFFF6B9D),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: padding * 0.5),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: ratingFontSize,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: ratingFontSize + 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: padding * 0.5),

                // Stats Section - Fixed Height with guaranteed space
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(padding * 0.6),
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
                              Flexible(
                                flex: 2,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    games.toString(),
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: statsFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2),
                              Flexible(
                                flex: 1,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Games",
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: statsLabelFontSize,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: statsHeight * 0.6,
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                flex: 2,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    mvps.toString(),
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: statsFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2),
                              Flexible(
                                flex: 1,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "MVPs",
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: statsLabelFontSize,
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
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.3);
      },
    );
  }
}
