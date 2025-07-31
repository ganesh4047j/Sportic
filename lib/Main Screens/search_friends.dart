import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sports/Main%20Screens/profile_view.dart';
import '../Providers/search_friends_providers.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _searchController;
  late AnimationController _listController;
  late Animation<double> _headerAnimation;
  late Animation<double> _searchAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _searchController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _listController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  // Responsive utility methods
  double _getResponsiveWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  double _getResponsiveHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  bool _isSmallScreen(BuildContext context) {
    return _getResponsiveWidth(context) < 380;
  }

  bool _isLargeScreen(BuildContext context) {
    return _getResponsiveWidth(context) > 430;
  }

  double _getResponsivePadding(BuildContext context) {
    if (_isSmallScreen(context)) return 12.0;
    if (_isLargeScreen(context)) return 24.0;
    return 20.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = _getResponsiveWidth(context);
    if (width < 360) return baseFontSize * 0.85;
    if (width > 430) return baseFontSize * 1.1;
    return baseFontSize;
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(searchFriendsProvider);
    final screenWidth = _getResponsiveWidth(context);
    final screenHeight = _getResponsiveHeight(context);
    final isSmall = _isSmallScreen(context);
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
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Responsive Header
              AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  final clampedValue = _headerAnimation.value.clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: clampedValue,
                    child: Opacity(
                      opacity: clampedValue,
                      child: Container(
                        padding: EdgeInsets.all(responsivePadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(isSmall ? 20 : 30),
                            bottomRight: Radius.circular(isSmall ? 20 : 30),
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
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: EdgeInsets.all(isSmall ? 8 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
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
                                  size: isSmall ? 16 : 20,
                                ),
                              ),
                            ),
                            SizedBox(width: isSmall ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Search Friends',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        24,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (!isSmall)
                                    Text(
                                      'Find and connect with new friends',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white70,
                                        fontSize: _getResponsiveFontSize(
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
                              padding: EdgeInsets.all(isSmall ? 8 : 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE60073).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFE60073,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.people_alt,
                                color: const Color(0xFFE60073),
                                size: isSmall ? 20 : 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Enhanced Responsive Search Fields
              Padding(
                padding: EdgeInsets.all(responsivePadding),
                child: AnimatedBuilder(
                  animation: _searchAnimation,
                  builder: (context, child) {
                    final clampedValue = _searchAnimation.value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: clampedValue,
                      child: Opacity(
                        opacity: clampedValue,
                        child: Column(
                          children: [
                            _buildEnhancedTextField(
                              labelText: 'Search by Name',
                              hintText: 'Enter friend\'s name...',
                              icon: Icons.person_search,
                              onChanged:
                                  (value) =>
                                      ref
                                          .read(nameSearchProvider.notifier)
                                          .state = value,
                              delay: 0,
                            ),
                            SizedBox(height: isSmall ? 12 : 16),
                            _buildEnhancedTextField(
                              labelText: 'Search by Location',
                              hintText: 'Enter location...',
                              icon: Icons.location_on,
                              onChanged:
                                  (value) =>
                                      ref
                                          .read(locationSearchProvider.notifier)
                                          .state = value,
                              delay: 200,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Enhanced Responsive Results List
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _listController,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: responsivePadding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isSmall ? 20 : 25),
                          topRight: Radius.circular(isSmall ? 20 : 25),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: friendsAsync.when(
                        data: (users) {
                          if (users.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(responsivePadding),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        isSmall ? 20 : 24,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white24,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.search_off,
                                        color: Colors.white54,
                                        size: isSmall ? 40 : 48,
                                      ),
                                    ),
                                    SizedBox(height: isSmall ? 16 : 20),
                                    Text(
                                      'No users found',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white70,
                                        fontSize: _getResponsiveFontSize(
                                          context,
                                          18,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: isSmall ? 6 : 8),
                                    Text(
                                      'Try adjusting your search criteria',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white54,
                                        fontSize: _getResponsiveFontSize(
                                          context,
                                          14,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.all(isSmall ? 12 : 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return _buildEnhancedUserCard(user, index);
                            },
                          );
                        },
                        loading:
                            () => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Lottie.asset(
                                    'assets/loading_spinner.json',
                                    width: isSmall ? 100 : 120,
                                    height: isSmall ? 100 : 120,
                                  ),
                                  SizedBox(height: isSmall ? 12 : 16),
                                  Text(
                                    'Searching for friends...',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        16,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        error:
                            (error, _) => Center(
                              child: Padding(
                                padding: EdgeInsets.all(responsivePadding),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        isSmall ? 16 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.redAccent,
                                        size: isSmall ? 32 : 40,
                                      ),
                                    ),
                                    SizedBox(height: isSmall ? 12 : 16),
                                    Text(
                                      'Oops! Something went wrong',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontSize: _getResponsiveFontSize(
                                          context,
                                          18,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: isSmall ? 6 : 8),
                                    Text(
                                      'Error: $error',
                                      style: GoogleFonts.nunito(
                                        color: Colors.redAccent,
                                        fontSize: _getResponsiveFontSize(
                                          context,
                                          14,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
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
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required String labelText,
    required String hintText,
    required IconData icon,
    required Function(String) onChanged,
    required int delay,
  }) {
    final isSmall = _isSmallScreen(context);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - clampedValue)),
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: _getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
                autofocus: delay == 0,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                  labelStyle: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: _getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: GoogleFonts.nunito(
                    color: Colors.white54,
                    fontSize: _getResponsiveFontSize(context, 14),
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(isSmall ? 8 : 12),
                    padding: EdgeInsets.all(isSmall ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFFE60073),
                      size: isSmall ? 18 : 20,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFE60073),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 12 : 16,
                    vertical: isSmall ? 12 : 16,
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedUserCard(Map<String, dynamic> user, int index) {
    final requestStatus = user['requestStatus'] ?? 'none';
    final userId = user['uid'];
    final isAccepted = requestStatus == 'accepted';
    final isPending = requestStatus == 'pending';
    final isSmall = _isSmallScreen(context);

    Widget statusWidget;
    Color statusColor;
    String tooltip;

    if (isAccepted) {
      statusWidget = Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 12,
          vertical: isSmall ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: isSmall ? 14 : 16,
            ),
            SizedBox(width: isSmall ? 2 : 4),
            Text(
              'Friends',
              style: GoogleFonts.nunito(
                color: Colors.green,
                fontSize: _getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
      statusColor = Colors.green;
      tooltip = 'Already friends';
    } else if (isPending) {
      statusWidget = Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 12,
          vertical: isSmall ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top,
              color: Colors.orange,
              size: isSmall ? 14 : 16,
            ),
            SizedBox(width: isSmall ? 2 : 4),
            Text(
              'Pending',
              style: GoogleFonts.nunito(
                color: Colors.orange,
                fontSize: _getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
      statusColor = Colors.orange;
      tooltip = 'Request pending';
    } else {
      statusWidget = Container(
        padding: EdgeInsets.all(isSmall ? 6 : 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE60073), Color(0xFFFF6B9D)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE60073).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.person_add_alt_1,
          color: Colors.white,
          size: isSmall ? 18 : 20,
        ),
      );
      statusColor = const Color(0xFFE60073);
      tooltip = 'Send Friend Request';
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - clampedValue)),
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              margin: EdgeInsets.only(bottom: isSmall ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileView(userId: userId),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(isSmall ? 12 : 16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundImage:
                                user['photoUrl'] != ''
                                    ? NetworkImage(user['photoUrl'])
                                    : const NetworkImage(
                                      'https://i.pravatar.cc/150',
                                    ),
                            radius: isSmall ? 24 : 28,
                            backgroundColor: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(width: isSmall ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? '',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: _getResponsiveFontSize(context, 16),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isSmall ? 2 : 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white54,
                                    size: isSmall ? 12 : 14,
                                  ),
                                  SizedBox(width: isSmall ? 2 : 4),
                                  Expanded(
                                    child: Text(
                                      user['location'] ??
                                          'Location not specified',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white70,
                                        fontSize: _getResponsiveFontSize(
                                          context,
                                          14,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isSmall ? 8 : 12),
                        Tooltip(
                          message: tooltip,
                          child: GestureDetector(
                            onTap:
                                (isAccepted || isPending)
                                    ? null
                                    : () async {
                                      try {
                                        await ref.read(
                                          sendFriendRequestProvider(userId),
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(
                                                    width: isSmall ? 8 : 12,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      'Friend request sent to ${user['name']}',
                                                      style: GoogleFonts.nunito(
                                                        color: Colors.white,
                                                        fontSize:
                                                            _getResponsiveFontSize(
                                                              context,
                                                              14,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor:
                                                  Colors.green[600],
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: EdgeInsets.all(
                                                isSmall ? 12 : 16,
                                              ),
                                            ),
                                          );
                                          ref.invalidate(searchFriendsProvider);
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(
                                                    width: isSmall ? 8 : 12,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      'Error: $e',
                                                      style: GoogleFonts.nunito(
                                                        color: Colors.white,
                                                        fontSize:
                                                            _getResponsiveFontSize(
                                                              context,
                                                              14,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.red[400],
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: EdgeInsets.all(
                                                isSmall ? 12 : 16,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                            child: statusWidget,
                          ),
                        ),
                      ],
                    ),
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
