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

  // Enhanced responsive breakpoints and calculations
  ResponsiveConfig _getResponsiveConfig(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Device categories with better breakpoints
    if (width <= 320) {
      // Very small phones (iPhone SE 1st gen, small Android)
      return ResponsiveConfig.extraSmall(width, height);
    } else if (width <= 360) {
      // Small phones (iPhone SE 2nd/3rd gen, Pixel 4a)
      return ResponsiveConfig.small(width, height);
    } else if (width <= 390) {
      // Medium phones (iPhone 12 mini, iPhone 13 mini)
      return ResponsiveConfig.medium(width, height);
    } else if (width <= 428) {
      // Large phones (iPhone 12/13/14, Pixel 6)
      return ResponsiveConfig.large(width, height);
    } else {
      // Extra large phones and small tablets
      return ResponsiveConfig.extraLarge(width, height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final isFriendAsync = ref.watch(friendshipStatusProvider(widget.userId));
    final friendsCountAsync = ref.watch(friendsCountProvider(widget.userId));
    final config = _getResponsiveConfig(context);

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
                            _buildHeader(config),
                            SizedBox(height: config.sectionSpacing),
                            // Enhanced Profile Row Section - FIXED
                            _buildProfileSection(
                              user,
                              isFriendAsync,
                              friendsCountAsync,
                              config,
                            ),
                            SizedBox(height: config.smallSpacing),
                            // Bio Section
                            _buildBioSection(user, config),
                            SizedBox(height: config.sectionSpacing),
                            // Enhanced TabBar
                            _buildTabBar(config),
                          ],
                        ),
                      ),
                    ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatsTab(user, config),
                    _buildAchievementsTab(config),
                    _buildClubsTab(config),
                  ],
                ),
              ),
            );
          },
          loading: () => _buildLoadingState(config),
          error: (e, _) => _buildErrorState(e, config),
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveConfig config) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        final clampedValue = _headerAnimation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clampedValue,
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: config.horizontalPadding,
              ),
              padding: EdgeInsets.all(config.contentPadding),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(config.borderRadius),
                  bottomRight: Radius.circular(config.borderRadius),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(config.iconPadding),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          config.smallBorderRadius,
                        ),
                        border: Border.all(color: Colors.white24, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: config.iconSize,
                      ),
                    ),
                  ),
                  SizedBox(width: config.mediumSpacing),
                  // Title section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Player Profile",
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: config.titleFontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: config.tinySpacing),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "View player details and stats",
                            style: GoogleFonts.nunito(
                              color: Colors.white70,
                              fontSize: config.subtitleFontSize,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: config.smallSpacing),
                  // Sports icon
                  Container(
                    padding: EdgeInsets.all(config.iconPadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE60073).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        config.smallBorderRadius,
                      ),
                      border: Border.all(
                        color: const Color(0xFFE60073).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.sports,
                      color: const Color(0xFFE60073),
                      size: config.iconSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // COMPLETELY REDESIGNED RESPONSIVE PROFILE SECTION
  Widget _buildProfileSection(
    UserModel user,
    AsyncValue<bool> isFriendAsync,
    AsyncValue<int> friendsCountAsync,
    ResponsiveConfig config,
  ) {
    return AnimatedBuilder(
      animation: _profileAnimation,
      builder: (context, child) {
        final clampedValue = _profileAnimation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clampedValue,
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: config.horizontalPadding,
              ),
              padding: EdgeInsets.all(config.contentPadding),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(config.borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Profile Row - Avatar, Name & Friend Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      _buildProfilePicture(user, config),

                      SizedBox(width: config.mediumSpacing),

                      // Name and basic info - takes remaining space
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Name with proper text wrapping
                            Text(
                                  user.name,
                                  style: GoogleFonts.nunito(
                                    fontSize: config.nameFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .slideX(begin: 0.3),

                            // Spacing between name and location
                            if (user.location != null)
                              SizedBox(height: config.tinySpacing),
                          ],
                        ),
                      ),

                      SizedBox(width: config.smallSpacing),

                      // Friend Button - Fixed size, always visible
                      _buildCompactFriendButton(user, isFriendAsync, config),
                    ],
                  ),

                  // Location Row - Full width, properly aligned
                  if (user.location != null) ...[
                    SizedBox(height: config.smallSpacing),
                    Row(
                      children: [
                        // Spacer to align with name (avatar width + spacing)
                        SizedBox(
                          width:
                              (config.avatarRadius * 2) +
                              config.mediumSpacing +
                              8,
                        ),
                        // Location chip - takes remaining space
                        Expanded(
                          child: _buildCompactLocationChip(
                            user.location!,
                            config,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Friends Count Row - Full width, properly aligned
                  SizedBox(height: config.mediumSpacing),
                  Row(
                    children: [
                      // Spacer to align with name
                      SizedBox(
                        width:
                            (config.avatarRadius * 2) +
                            config.mediumSpacing +
                            8,
                      ),
                      // Friends count - takes only needed space
                      _buildCompactFriendsCount(friendsCountAsync, config),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture(UserModel user, ResponsiveConfig config) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFE60073), Color(0xFFFF6B9D), Color(0xFFE60073)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE60073).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF3D1A4A),
        ),
        child: CircleAvatar(
          backgroundImage: NetworkImage(user.photoUrl ?? ''),
          radius: config.avatarRadius,
          backgroundColor: Colors.grey.shade800,
        ),
      ),
    );
  }

  // COMPACT LOCATION CHIP - Responsive and properly sized
  Widget _buildCompactLocationChip(String location, ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.chipPadding * 0.8,
        vertical: config.chipPadding * 0.5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(config.chipBorderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: const Color(0xFFE60073),
            size: config.chipIconSize,
          ),
          SizedBox(width: config.tinySpacing),
          Flexible(
            child: Text(
              location,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: config.chipFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // COMPACT FRIENDS COUNT - Properly sized for content
  Widget _buildCompactFriendsCount(
    AsyncValue<int> friendsCountAsync,
    ResponsiveConfig config,
  ) {
    return friendsCountAsync.when(
      data:
          (count) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: config.chipPadding,
              vertical: config.chipPadding * 0.6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE60073).withOpacity(0.2),
                  const Color(0xFFFF6B9D).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(config.chipBorderRadius),
              border: Border.all(
                color: const Color(0xFFE60073).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people,
                  color: const Color(0xFFE60073),
                  size: config.chipIconSize,
                ),
                SizedBox(width: config.tinySpacing),
                Text(
                  '$count Friends',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: config.chipFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      loading:
          () => Container(
            padding: EdgeInsets.all(config.chipPadding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: config.chipIconSize,
              height: config.chipIconSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      error:
          (_, __) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: config.chipPadding,
              vertical: config.chipPadding * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(config.chipBorderRadius),
            ),
            child: Text(
              "Error",
              style: GoogleFonts.nunito(
                color: Colors.redAccent,
                fontSize: config.chipFontSize,
              ),
            ),
          ),
    );
  }

  // COMPACT FRIEND BUTTON - Properly sized and responsive
  Widget _buildCompactFriendButton(
    UserModel user,
    AsyncValue<bool> isFriendAsync,
    ResponsiveConfig config,
  ) {
    return AnimatedBuilder(
      animation: _actionButtonAnimation,
      builder: (context, child) {
        final clampedValue = _actionButtonAnimation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clampedValue,
          child: Opacity(
            opacity: clampedValue,
            child: isFriendAsync.when(
              data: (isFriend) {
                if (isFriend) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: config.buttonPadding,
                      vertical: config.buttonPadding * 0.7,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.greenAccent],
                      ),
                      borderRadius: BorderRadius.circular(
                        config.buttonBorderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: config.buttonIconSize,
                        ),
                        if (config.screenWidth > 340) ...[
                          SizedBox(width: config.tinySpacing),
                          Text(
                            "Friend",
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: config.buttonFontSize,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                } else {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        config.buttonBorderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE60073).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE60073),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            config.buttonBorderRadius,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: config.buttonPadding,
                          vertical: config.buttonPadding * 0.7,
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        await sendFriendRequest(user.uid);
                        ref.invalidate(friendshipStatusProvider(user.uid));
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add, size: config.buttonIconSize),
                          if (config.screenWidth > 340) ...[
                            SizedBox(width: config.tinySpacing),
                            Text(
                              "Add",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w600,
                                fontSize: config.buttonFontSize,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
              },
              loading:
                  () => Container(
                    padding: EdgeInsets.all(config.buttonPadding * 0.8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: config.buttonIconSize,
                      height: config.buttonIconSize,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              error:
                  (_, __) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: config.buttonPadding,
                      vertical: config.buttonPadding * 0.6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        config.buttonBorderRadius,
                      ),
                    ),
                    child: Text(
                      "Error",
                      style: GoogleFonts.nunito(
                        color: Colors.redAccent,
                        fontSize: config.buttonFontSize,
                      ),
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBioSection(UserModel user, ResponsiveConfig config) {
    if (_isEditingBio && currentUser?.uid == user.uid) {
      return _buildBioEditor(user, config);
    } else {
      return _buildBioDisplay(user, config);
    }
  }

  Widget _buildBioEditor(UserModel user, ResponsiveConfig config) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: config.horizontalPadding),
      padding: EdgeInsets.all(config.contentPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                padding: EdgeInsets.all(config.iconPadding * 0.7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60073).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(config.smallBorderRadius),
                ),
                child: Icon(
                  Icons.edit,
                  color: const Color(0xFFE60073),
                  size: config.iconSize * 0.8,
                ),
              ),
              SizedBox(width: config.smallSpacing),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Edit Bio",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: config.subtitleFontSize + 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: config.mediumSpacing),
          TextField(
            controller: _bioController,
            maxLines: null,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: config.bodyFontSize,
            ),
            decoration: InputDecoration(
              hintText: "Enter your bio...",
              hintStyle: GoogleFonts.nunito(
                color: Colors.white54,
                fontSize: config.bodyFontSize,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(config.smallBorderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(config.smallBorderRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFE60073),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(config.smallBorderRadius),
              ),
              contentPadding: EdgeInsets.all(config.contentPadding),
            ),
          ),
          SizedBox(height: config.mediumSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: () => setState(() => _isEditingBio = false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: config.buttonPadding,
                      vertical: config.buttonPadding * 0.7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        config.smallBorderRadius,
                      ),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.nunito(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: config.buttonFontSize,
                    ),
                  ),
                ),
              ),
              SizedBox(width: config.smallSpacing),
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
                        .update({'bio': _bioController.text.trim()});
                    setState(() => _isEditingBio = false);
                    ref.refresh(userProfileProvider(user.uid));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: config.buttonPadding,
                      vertical: config.buttonPadding * 0.7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        config.smallBorderRadius,
                      ),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Save",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      fontSize: config.buttonFontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioDisplay(UserModel user, ResponsiveConfig config) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: config.horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(config.contentPadding),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(config.iconPadding * 0.7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(config.smallBorderRadius),
              ),
              child: Icon(
                Icons.info_outline,
                color: const Color(0xFFE60073),
                size: config.iconSize * 0.8,
              ),
            ),
            SizedBox(width: config.smallSpacing),
            Expanded(
              child: Text(
                (user.bio ?? '').isNotEmpty ? user.bio! : "No bio available.",
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontSize: config.bodyFontSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (currentUser?.uid == user.uid) ...[
              SizedBox(width: config.smallSpacing),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditingBio = true;
                    _bioController.text = user.bio ?? "";
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(config.iconPadding * 0.7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      config.smallBorderRadius,
                    ),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white70,
                    size: config.iconSize * 0.7,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.3);
  }

  Widget _buildTabBar(ResponsiveConfig config) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: config.horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(config.borderRadius + 5),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE60073), Color(0xFFFF6B9D)],
          ),
          borderRadius: BorderRadius.circular(config.borderRadius + 5),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: config.buttonFontSize,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w500,
          fontSize: config.buttonFontSize,
        ),
        padding: EdgeInsets.all(config.tinySpacing),
        tabs: const [
          Tab(text: "Stats"),
          Tab(text: "Achievements"),
          Tab(text: "Clubs"),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3);
  }

  Widget _buildLoadingState(ResponsiveConfig config) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE60073)),
          ),
          SizedBox(height: config.mediumSpacing),
          Text(
            "Loading profile...",
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontSize: config.bodyFontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, ResponsiveConfig config) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(config.contentPadding),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: config.iconSize * 2,
            ),
          ),
          SizedBox(height: config.mediumSpacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: config.horizontalPadding),
            child: Text(
              "Error: $error",
              style: GoogleFonts.nunito(
                color: Colors.redAccent,
                fontSize: config.bodyFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(UserModel user, ResponsiveConfig config) {
    return ListView(
      padding: EdgeInsets.all(config.horizontalPadding),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildStatsCard(
          user,
          config,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        SizedBox(height: config.sectionSpacing),
        _buildSportsSection(
          user,
          config,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildAchievementsTab(ResponsiveConfig config) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(config.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(config.contentPadding * 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Icon(
                Icons.emoji_events,
                color: Colors.white54,
                size: config.iconSize * 3,
              ),
            ),
            SizedBox(height: config.sectionSpacing),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Achievements coming soon!",
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontSize: config.subtitleFontSize + 2,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: config.smallSpacing),
            Text(
              "Your trophies and milestones will appear here",
              style: GoogleFonts.nunito(
                color: Colors.white54,
                fontSize: config.bodyFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildClubsTab(ResponsiveConfig config) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(config.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(config.contentPadding * 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Icon(
                Icons.groups,
                color: Colors.white54,
                size: config.iconSize * 3,
              ),
            ),
            SizedBox(height: config.sectionSpacing),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Club data coming soon!",
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontSize: config.subtitleFontSize + 2,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: config.smallSpacing),
            Text(
              "Your club memberships and activities will appear here",
              style: GoogleFonts.nunito(
                color: Colors.white54,
                fontSize: config.bodyFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildStatsCard(UserModel user, ResponsiveConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(config.borderRadius),
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
        padding: EdgeInsets.all(config.contentPadding),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(config.iconPadding),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE60073), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(
                      config.smallBorderRadius,
                    ),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: config.iconSize,
                  ),
                ),
                SizedBox(width: config.mediumSpacing),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Match Stats",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: config.subtitleFontSize + 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: config.sectionSpacing),
            // Responsive stats layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 300) {
                  // Stack vertically for very narrow spaces
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _statItem(
                              "Played",
                              user.gamesPlayed.toString(),
                              Icons.sports_soccer,
                              Colors.blue,
                              config,
                            ),
                          ),
                          SizedBox(width: config.smallSpacing),
                          Expanded(
                            child: _statItem(
                              "Won",
                              user.gamesWon.toString(),
                              Icons.emoji_events,
                              Colors.green,
                              config,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: config.smallSpacing),
                      SizedBox(
                        width: double.infinity,
                        child: _statItem(
                          "Lost",
                          (user.gamesPlayed - user.gamesWon).toString(),
                          Icons.trending_down,
                          Colors.red,
                          config,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Show horizontally for normal widths
                  return Row(
                    children: [
                      Expanded(
                        child: _statItem(
                          "Played",
                          user.gamesPlayed.toString(),
                          Icons.sports_soccer,
                          Colors.blue,
                          config,
                        ),
                      ),
                      SizedBox(width: config.smallSpacing),
                      Expanded(
                        child: _statItem(
                          "Won",
                          user.gamesWon.toString(),
                          Icons.emoji_events,
                          Colors.green,
                          config,
                        ),
                      ),
                      SizedBox(width: config.smallSpacing),
                      Expanded(
                        child: _statItem(
                          "Lost",
                          (user.gamesPlayed - user.gamesWon).toString(),
                          Icons.trending_down,
                          Colors.red,
                          config,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ResponsiveConfig config,
  ) {
    return Container(
      padding: EdgeInsets.all(config.contentPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: config.iconSize),
          SizedBox(height: config.smallSpacing),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: config.titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: config.tinySpacing),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: config.chipFontSize,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsSection(UserModel user, ResponsiveConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: config.tinySpacing),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(config.iconPadding * 0.8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60073).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(config.smallBorderRadius),
                ),
                child: Icon(
                  Icons.sports,
                  color: const Color(0xFFE60073),
                  size: config.iconSize * 0.8,
                ),
              ),
              SizedBox(width: config.smallSpacing),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sports & Player Position",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: config.subtitleFontSize + 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: config.sectionSpacing),
        // Improved responsive card layout
        SizedBox(
          height: config.cardHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: config.tinySpacing),
            children: [
              _playerCard(
                icon: Icons.sports_soccer,
                title: "Forward",
                skill: "Advanced",
                rating: 4.2,
                games: 711,
                mvps: 19,
                config: config,
              ),
              _playerCard(
                icon: Icons.sports_basketball,
                title: "Shooter",
                skill: "Intermediate",
                rating: 3.8,
                games: 420,
                mvps: 8,
                config: config,
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
    required ResponsiveConfig config,
  }) {
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
      width: config.cardWidth,
      height: config.cardHeight,
      margin: EdgeInsets.only(right: config.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(config.borderRadius),
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
        padding: EdgeInsets.all(config.contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section - Fixed height
            SizedBox(
              height: config.iconSize + config.iconPadding,
              child: Row(
                children: [
                  Container(
                    width: config.iconSize + config.iconPadding,
                    height: config.iconSize + config.iconPadding,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        config.smallBorderRadius,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: config.iconSize * 0.8,
                    ),
                  ),
                  SizedBox(width: config.smallSpacing),
                  Expanded(
                    child: Container(
                      height: config.iconSize + (config.iconPadding * 0.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: config.chipPadding,
                        vertical: config.chipPadding * 0.3,
                      ),
                      decoration: BoxDecoration(
                        color: skillColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          config.chipBorderRadius,
                        ),
                        border: Border.all(color: skillColor.withOpacity(0.5)),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            skill,
                            style: GoogleFonts.nunito(
                              color: skillColor,
                              fontSize: config.chipFontSize,
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
            SizedBox(height: config.smallSpacing),

            // Title Section - Fixed height
            SizedBox(
              height: config.bodyFontSize + 6,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: config.bodyFontSize + 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: config.smallSpacing),

            // Rating Section - Fixed height
            SizedBox(
              height: config.chipFontSize + 4,
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
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
                              colors: [Color(0xFFE60073), Color(0xFFFF6B9D)],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: config.tinySpacing),
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: config.chipFontSize,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: config.tinySpacing * 0.5),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: config.chipIconSize,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: config.smallSpacing),

            // Stats Section - Takes remaining space
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: config.chipPadding,
                  vertical: config.chipPadding * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(config.smallBorderRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        games.toString(),
                        "Games",
                        config,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: double.infinity,
                      margin: EdgeInsets.symmetric(
                        vertical: config.tinySpacing,
                      ),
                      color: Colors.white24,
                    ),
                    Expanded(
                      child: _buildStatColumn(mvps.toString(), "MVPs", config),
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

  // Helper method for stat columns with better text handling
  Widget _buildStatColumn(String value, String label, ResponsiveConfig config) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Value - takes more space and scales better
        Expanded(
          flex: 3,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: config.bodyFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Small spacing
        SizedBox(height: config.tinySpacing * 0.5),

        // Label - takes less space but ensures visibility
        Expanded(
          flex: 2,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontSize: config.chipFontSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// IMPROVED RESPONSIVE CONFIGURATION CLASS WITH BETTER SCALING
class ResponsiveConfig {
  final double screenWidth;
  final double screenHeight;

  // Spacing
  final double tinySpacing;
  final double smallSpacing;
  final double mediumSpacing;
  final double sectionSpacing;

  // Padding
  final double horizontalPadding;
  final double contentPadding;
  final double iconPadding;
  final double chipPadding;
  final double buttonPadding;

  // Border Radius
  final double borderRadius;
  final double smallBorderRadius;
  final double chipBorderRadius;
  final double buttonBorderRadius;

  // Font Sizes
  final double titleFontSize;
  final double subtitleFontSize;
  final double nameFontSize;
  final double bodyFontSize;
  final double chipFontSize;
  final double buttonFontSize;

  // Icon Sizes
  final double iconSize;
  final double chipIconSize;
  final double buttonIconSize;
  final double avatarRadius;

  // Card Dimensions
  final double cardWidth;
  final double cardHeight;

  ResponsiveConfig._({
    required this.screenWidth,
    required this.screenHeight,
    required this.tinySpacing,
    required this.smallSpacing,
    required this.mediumSpacing,
    required this.sectionSpacing,
    required this.horizontalPadding,
    required this.contentPadding,
    required this.iconPadding,
    required this.chipPadding,
    required this.buttonPadding,
    required this.borderRadius,
    required this.smallBorderRadius,
    required this.chipBorderRadius,
    required this.buttonBorderRadius,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.nameFontSize,
    required this.bodyFontSize,
    required this.chipFontSize,
    required this.buttonFontSize,
    required this.iconSize,
    required this.chipIconSize,
    required this.buttonIconSize,
    required this.avatarRadius,
    required this.cardWidth,
    required this.cardHeight,
  });

  // EXTRA SMALL DEVICES (≤320px) - iPhone SE 1st gen
  factory ResponsiveConfig.extraSmall(double width, double height) {
    return ResponsiveConfig._(
      screenWidth: width,
      screenHeight: height,
      tinySpacing: 3,
      smallSpacing: 6,
      mediumSpacing: 10,
      sectionSpacing: 14,
      horizontalPadding: 8,
      contentPadding: 8,
      iconPadding: 5,
      chipPadding: 6,
      buttonPadding: 8,
      borderRadius: 12,
      smallBorderRadius: 6,
      chipBorderRadius: 8,
      buttonBorderRadius: 10,
      titleFontSize: 16,
      subtitleFontSize: 12,
      nameFontSize: 14,
      bodyFontSize: 12,
      chipFontSize: 10,
      buttonFontSize: 10,
      iconSize: 16,
      chipIconSize: 12,
      buttonIconSize: 14,
      avatarRadius: 26,
      cardWidth: (width * 0.85).clamp(240.0, 280.0), // More flexible width
      cardHeight: 160, // Slightly increased height
    );
  }

  // SMALL DEVICES (321-360px) - iPhone SE 2nd/3rd gen, small Android
  factory ResponsiveConfig.small(double width, double height) {
    return ResponsiveConfig._(
      screenWidth: width,
      screenHeight: height,
      tinySpacing: 4,
      smallSpacing: 8,
      mediumSpacing: 12,
      sectionSpacing: 16,
      horizontalPadding: 10,
      contentPadding: 10,
      iconPadding: 6,
      chipPadding: 8,
      buttonPadding: 10,
      borderRadius: 14,
      smallBorderRadius: 7,
      chipBorderRadius: 10,
      buttonBorderRadius: 12,
      titleFontSize: 18,
      subtitleFontSize: 13,
      nameFontSize: 16,
      bodyFontSize: 13,
      chipFontSize: 11,
      buttonFontSize: 11,
      iconSize: 18,
      chipIconSize: 14,
      buttonIconSize: 16,
      avatarRadius: 30,
      cardWidth: (width * 0.8).clamp(260.0, 300.0),
      cardHeight: 170,
    );
  }

  // MEDIUM DEVICES (361-390px) - iPhone 12/13 mini
  factory ResponsiveConfig.medium(double width, double height) {
    return ResponsiveConfig._(
      screenWidth: width,
      screenHeight: height,
      tinySpacing: 5,
      smallSpacing: 10,
      mediumSpacing: 14,
      sectionSpacing: 20,
      horizontalPadding: 12,
      contentPadding: 12,
      iconPadding: 8,
      chipPadding: 10,
      buttonPadding: 12,
      borderRadius: 16,
      smallBorderRadius: 8,
      chipBorderRadius: 12,
      buttonBorderRadius: 14,
      titleFontSize: 20,
      subtitleFontSize: 14,
      nameFontSize: 18,
      bodyFontSize: 14,
      chipFontSize: 12,
      buttonFontSize: 12,
      iconSize: 20,
      chipIconSize: 16,
      buttonIconSize: 18,
      avatarRadius: 34,
      cardWidth: (width * 0.75).clamp(280.0, 320.0),
      cardHeight: 180,
    );
  }

  // LARGE DEVICES (391-428px) - iPhone 12/13/14, Pixel 6
  factory ResponsiveConfig.large(double width, double height) {
    return ResponsiveConfig._(
      screenWidth: width,
      screenHeight: height,
      tinySpacing: 6,
      smallSpacing: 12,
      mediumSpacing: 16,
      sectionSpacing: 24,
      horizontalPadding: 14,
      contentPadding: 14,
      iconPadding: 10,
      chipPadding: 12,
      buttonPadding: 14,
      borderRadius: 18,
      smallBorderRadius: 9,
      chipBorderRadius: 14,
      buttonBorderRadius: 16,
      titleFontSize: 22,
      subtitleFontSize: 15,
      nameFontSize: 20,
      bodyFontSize: 15,
      chipFontSize: 13,
      buttonFontSize: 13,
      iconSize: 22,
      chipIconSize: 18,
      buttonIconSize: 20,
      avatarRadius: 38,
      cardWidth: 300,
      cardHeight: 190,
    );
  }

  // EXTRA LARGE DEVICES (>428px) - Large phones and small tablets
  factory ResponsiveConfig.extraLarge(double width, double height) {
    return ResponsiveConfig._(
      screenWidth: width,
      screenHeight: height,
      tinySpacing: 8,
      smallSpacing: 14,
      mediumSpacing: 18,
      sectionSpacing: 28,
      horizontalPadding: 16,
      contentPadding: 16,
      iconPadding: 12,
      chipPadding: 14,
      buttonPadding: 16,
      borderRadius: 20,
      smallBorderRadius: 10,
      chipBorderRadius: 16,
      buttonBorderRadius: 18,
      titleFontSize: 24,
      subtitleFontSize: 16,
      nameFontSize: 22,
      bodyFontSize: 16,
      chipFontSize: 14,
      buttonFontSize: 14,
      iconSize: 24,
      chipIconSize: 20,
      buttonIconSize: 22,
      avatarRadius: 42,
      cardWidth: 320,
      cardHeight: 200,
    );
  }
}
