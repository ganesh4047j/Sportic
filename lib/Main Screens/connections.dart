// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../Providers/current_user_id_provider.dart';
import '../Providers/message_preview_provider.dart';
import '../Providers/connection_provider.dart';
import '../Services/chat_utils.dart';
import 'chat_screen.dart';

final connectionsSearchProvider = StateProvider<String>((ref) => '');
final secureStorage = FlutterSecureStorage();

class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({super.key});
  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _searchAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _searchAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Fixed: Using easeOutBack for header to prevent overflow
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve:
            Curves.easeOutCubic, // Changed from easeOutBack to prevent overflow
      ),
    );

    // Fixed: Using easeOutCubic instead of elasticOut to prevent opacity > 1.0
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve:
            Curves.easeOutCubic, // Changed from elasticOut to prevent overflow
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _searchAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _searchAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  // Helper method to get responsive dimensions
  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return screenWidth * 0.95; // Very small screens
    if (screenWidth < 411) return screenWidth * 0.92; // Small screens
    if (screenWidth < 600) return screenWidth * 0.90; // Medium screens
    return screenWidth * 0.85; // Large screens/tablets
  }

  double getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 12.0;
    if (screenWidth < 411) return 16.0;
    if (screenWidth < 600) return 20.0;
    return 24.0;
  }

  double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 411; // Using iPhone 11 Pro as base
    return (baseSize * scaleFactor).clamp(baseSize * 0.8, baseSize * 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(connectionsSearchProvider).toLowerCase();
    final previewsAsync = ref.watch(messagePreviewProvider);
    final connectionsAsync = ref.watch(connectionsProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isSmallScreen = screenSize.width < 360;
    final responsivePadding = getResponsivePadding(context);

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
              // Enhanced Header with Animation - Fixed opacity clamping
              AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  // Clamp animation values to prevent opacity overflow
                  final clampedScale = _headerAnimation.value.clamp(0.0, 1.0);
                  final clampedOpacity = _headerAnimation.value.clamp(0.0, 1.0);

                  return Transform.scale(
                    scale: clampedScale,
                    child: Opacity(
                      opacity: clampedOpacity,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: responsivePadding,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: responsivePadding,
                          vertical: isTablet ? 16 : (isSmallScreen ? 10 : 12),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: BackButton(
                                color: Colors.white,
                                style: ButtonStyle(
                                  iconSize: MaterialStateProperty.all(
                                    isSmallScreen ? 20 : 24,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isTablet ? 16 : (isSmallScreen ? 8 : 12),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Connections",
                                    style: GoogleFonts.robotoSlab(
                                      color: Colors.white,
                                      fontSize: getResponsiveFontSize(
                                        context,
                                        isTablet ? 24 : 20,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    "Stay connected with your network",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: getResponsiveFontSize(
                                        context,
                                        isTablet ? 14 : 12,
                                      ),
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6B73FF),
                                    const Color(0xFF9068BE),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6B73FF,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.people_outline,
                                color: Colors.white,
                                size: isTablet ? 24 : (isSmallScreen ? 18 : 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Enhanced Search Bar with Animation - Fixed opacity clamping
              AnimatedBuilder(
                animation: _searchAnimation,
                builder: (context, child) {
                  // Clamp animation values to prevent opacity overflow
                  final clampedScale = _searchAnimation.value.clamp(0.0, 1.0);
                  final clampedOpacity = _searchAnimation.value.clamp(0.0, 1.0);

                  return Transform.scale(
                    scale: clampedScale,
                    child: Opacity(
                      opacity: clampedOpacity,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: responsivePadding,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: getResponsiveFontSize(
                                context,
                                isTablet ? 16 : 14,
                              ),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search by name...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: getResponsiveFontSize(
                                  context,
                                  isTablet ? 16 : 14,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              prefixIcon: Container(
                                margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6B73FF).withOpacity(0.8),
                                      const Color(0xFF9068BE).withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                              suffixIcon:
                                  searchQuery.isNotEmpty
                                      ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.white54,
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(
                                                connectionsSearchProvider
                                                    .notifier,
                                              )
                                              .state = '';
                                        },
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: responsivePadding,
                                vertical:
                                    isTablet ? 16 : (isSmallScreen ? 10 : 12),
                              ),
                            ),
                            onChanged:
                                (value) =>
                                    ref
                                        .read(
                                          connectionsSearchProvider.notifier,
                                        )
                                        .state = value,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: isSmallScreen ? 4 : 8),

              // Enhanced List with Animation
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _listAnimationController,
                    child: Container(
                      width: double.infinity,
                      child: previewsAsync.when(
                        data: (chats) {
                          final chatMap = {
                            for (var chat in chats) chat['peerEmail']: chat,
                          };

                          return connectionsAsync.when(
                            data: (connections) {
                              final filtered =
                                  connections.where((user) {
                                    final name =
                                        (user['name'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                    return name.contains(searchQuery);
                                  }).toList();

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          isSmallScreen ? 20 : 24,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.1),
                                              Colors.white.withOpacity(0.05),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.people_outline,
                                          size:
                                              isTablet
                                                  ? 64
                                                  : (isSmallScreen ? 36 : 48),
                                          color: Colors.white54,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 12 : 16),
                                      Text(
                                        'No connections found',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: getResponsiveFontSize(
                                            context,
                                            isTablet ? 18 : 16,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 6 : 8),
                                      Text(
                                        searchQuery.isNotEmpty
                                            ? 'Try a different search term'
                                            : 'Start building your network',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white54,
                                          fontSize: getResponsiveFontSize(
                                            context,
                                            isTablet ? 14 : 12,
                                          ),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsivePadding,
                                  vertical: isSmallScreen ? 6 : 8,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder:
                                    (_, __) => SizedBox(
                                      height:
                                          isTablet
                                              ? 12
                                              : (isSmallScreen ? 6 : 8),
                                    ),
                                itemBuilder: (context, index) {
                                  final user = filtered[index];
                                  final peerId =
                                      user['email'] ?? user['uid'] ?? '';
                                  final peerName = user['name'] ?? peerId;
                                  final photoUrl = user['photoUrl'] ?? '';
                                  final location = user['location'] ?? '';

                                  final chat = chatMap[peerId];
                                  final lastMsg =
                                      chat != null
                                          ? (chat['lastMsg'] ?? '')
                                          : '';

                                  return TweenAnimationBuilder(
                                    duration: Duration(
                                      milliseconds: 300 + (index * 100),
                                    ),
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    curve:
                                        Curves
                                            .easeOutCubic, // Changed from elasticOut
                                    builder: (context, double value, child) {
                                      // Clamp the animation value to prevent overflow
                                      final clampedValue = value.clamp(
                                        0.0,
                                        1.0,
                                      );

                                      return Transform.scale(
                                        scale: clampedValue,
                                        child: Opacity(
                                          opacity: clampedValue,
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              bottom: isSmallScreen ? 2 : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withOpacity(
                                                    0.12,
                                                  ),
                                                  Colors.white.withOpacity(
                                                    0.06,
                                                  ),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.15,
                                                ),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                onTap: () async {
                                                  try {
                                                    final currentUserUid =
                                                        await ref.read(
                                                          currentUserIdProvider
                                                              .future,
                                                        );
                                                    final peerUid = user['uid'];

                                                    if (peerUid == null) {
                                                      throw Exception(
                                                        'Missing user IDs',
                                                      );
                                                    }

                                                    final resolvedChatId =
                                                        generateChatId(
                                                          peerUid,
                                                          currentUserUid,
                                                        );

                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) => ChatPage(
                                                              chatId:
                                                                  resolvedChatId,
                                                              peerUid: peerUid,
                                                              peerName:
                                                                  user['name'] ??
                                                                  '',
                                                              peerEmail: '',
                                                            ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Failed to open chat: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                    isTablet
                                                        ? 20
                                                        : (isSmallScreen
                                                            ? 12
                                                            : 16),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      // Enhanced Avatar - Responsive
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          gradient:
                                                              LinearGradient(
                                                                colors: [
                                                                  const Color(
                                                                    0xFF6B73FF,
                                                                  ).withOpacity(
                                                                    0.3,
                                                                  ),
                                                                  const Color(
                                                                    0xFF9068BE,
                                                                  ).withOpacity(
                                                                    0.3,
                                                                  ),
                                                                ],
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color:
                                                                  const Color(
                                                                    0xFF6B73FF,
                                                                  ).withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              3,
                                                            ),
                                                        child: CircleAvatar(
                                                          radius:
                                                              isTablet
                                                                  ? 28
                                                                  : (isSmallScreen
                                                                      ? 20
                                                                      : 24),
                                                          backgroundImage:
                                                              photoUrl.isNotEmpty
                                                                  ? NetworkImage(
                                                                    photoUrl,
                                                                  )
                                                                  : const NetworkImage(
                                                                    'https://i.pravatar.cc/150',
                                                                  ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            isTablet
                                                                ? 20
                                                                : (isSmallScreen
                                                                    ? 12
                                                                    : 16),
                                                      ),

                                                      // Enhanced Content - Responsive
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              peerName,
                                                              style: GoogleFonts.poppins(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize:
                                                                    getResponsiveFontSize(
                                                                      context,
                                                                      isTablet
                                                                          ? 18
                                                                          : 16,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                letterSpacing:
                                                                    0.3,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  isSmallScreen
                                                                      ? 2
                                                                      : 4,
                                                            ),
                                                            if (location
                                                                    .isNotEmpty ||
                                                                lastMsg
                                                                    .isNotEmpty)
                                                              Container(
                                                                padding: EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      isSmallScreen
                                                                          ? 6
                                                                          : 8,
                                                                  vertical:
                                                                      isSmallScreen
                                                                          ? 2
                                                                          : 4,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                        0.1,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        8,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  location.isNotEmpty
                                                                      ? location
                                                                      : lastMsg,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: GoogleFonts.poppins(
                                                                    color:
                                                                        Colors
                                                                            .white70,
                                                                    fontSize: getResponsiveFontSize(
                                                                      context,
                                                                      isTablet
                                                                          ? 14
                                                                          : 12,
                                                                    ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Enhanced Message Button - Responsive
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                                colors: [
                                                                  const Color(
                                                                    0xFF6B73FF,
                                                                  ),
                                                                  const Color(
                                                                    0xFF9068BE,
                                                                  ),
                                                                ],
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color:
                                                                  const Color(
                                                                    0xFF6B73FF,
                                                                  ).withOpacity(
                                                                    0.4,
                                                                  ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Material(
                                                          color:
                                                              Colors
                                                                  .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  15,
                                                                ),
                                                            onTap: () async {
                                                              try {
                                                                final currentUserUid =
                                                                    await ref.read(
                                                                      currentUserIdProvider
                                                                          .future,
                                                                    );
                                                                final peerUid =
                                                                    user['uid'];

                                                                if (peerUid ==
                                                                    null) {
                                                                  throw Exception(
                                                                    'Missing user IDs',
                                                                  );
                                                                }

                                                                final resolvedChatId =
                                                                    generateChatId(
                                                                      peerUid,
                                                                      currentUserUid,
                                                                    );

                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (
                                                                          _,
                                                                        ) => ChatPage(
                                                                          chatId:
                                                                              resolvedChatId,
                                                                          peerUid:
                                                                              peerUid,
                                                                          peerName:
                                                                              user['name'] ??
                                                                              '',
                                                                          peerEmail:
                                                                              '',
                                                                        ),
                                                                  ),
                                                                );
                                                              } catch (e) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'Failed to open chat: $e',
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            child: Padding(
                                                              padding: EdgeInsets.all(
                                                                isTablet
                                                                    ? 12
                                                                    : (isSmallScreen
                                                                        ? 8
                                                                        : 10),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .message_rounded,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                size:
                                                                    isTablet
                                                                        ? 24
                                                                        : (isSmallScreen
                                                                            ? 18
                                                                            : 20),
                                                              ),
                                                            ),
                                                          ),
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
                                },
                              );
                            },
                            loading:
                                () => Container(
                                  width: double.infinity,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                            isSmallScreen ? 16 : 20,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.1),
                                                Colors.white.withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Lottie.asset(
                                            'assets/loading_spinner.json',
                                            width:
                                                isTablet
                                                    ? 80
                                                    : (isSmallScreen ? 50 : 60),
                                            height:
                                                isTablet
                                                    ? 80
                                                    : (isSmallScreen ? 50 : 60),
                                          ),
                                        ),
                                        SizedBox(
                                          height: isSmallScreen ? 12 : 16,
                                        ),
                                        Text(
                                          'Loading connections...',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: getResponsiveFontSize(
                                              context,
                                              isTablet ? 16 : 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            error:
                                (e, _) => Container(
                                  width: double.infinity,
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isTablet
                                            ? 32
                                            : (isSmallScreen ? 20 : 24),
                                      ),
                                      margin: EdgeInsets.symmetric(
                                        horizontal:
                                            isTablet
                                                ? 40
                                                : (isSmallScreen ? 20 : 24),
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red.withOpacity(0.1),
                                            Colors.red.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red.shade300,
                                            size:
                                                isTablet
                                                    ? 48
                                                    : (isSmallScreen ? 30 : 36),
                                          ),
                                          SizedBox(
                                            height: isSmallScreen ? 12 : 16,
                                          ),
                                          Text(
                                            'Error loading connections',
                                            style: GoogleFonts.poppins(
                                              color: Colors.red.shade300,
                                              fontSize: getResponsiveFontSize(
                                                context,
                                                isTablet ? 18 : 16,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(
                                            height: isSmallScreen ? 6 : 8,
                                          ),
                                          Text(
                                            '$e',
                                            style: GoogleFonts.poppins(
                                              color: Colors.red.shade200,
                                              fontSize: getResponsiveFontSize(
                                                context,
                                                isTablet ? 14 : 12,
                                              ),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                          );
                        },
                        loading:
                            () => Container(
                              width: double.infinity,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        isSmallScreen ? 16 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.1),
                                            Colors.white.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Lottie.asset(
                                        'assets/loading_spinner.json',
                                        width:
                                            isTablet
                                                ? 80
                                                : (isSmallScreen ? 50 : 60),
                                        height:
                                            isTablet
                                                ? 80
                                                : (isSmallScreen ? 50 : 60),
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 12 : 16),
                                    Text(
                                      'Loading previews...',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: getResponsiveFontSize(
                                          context,
                                          isTablet ? 16 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        error:
                            (e, _) => Container(
                              width: double.infinity,
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isTablet ? 32 : (isSmallScreen ? 20 : 24),
                                  ),
                                  margin: EdgeInsets.symmetric(
                                    horizontal:
                                        isTablet
                                            ? 40
                                            : (isSmallScreen ? 20 : 24),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.withOpacity(0.1),
                                        Colors.red.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade300,
                                        size:
                                            isTablet
                                                ? 48
                                                : (isSmallScreen ? 30 : 36),
                                      ),
                                      SizedBox(height: isSmallScreen ? 12 : 16),
                                      Text(
                                        'Error loading previews',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red.shade300,
                                          fontSize: getResponsiveFontSize(
                                            context,
                                            isTablet ? 18 : 16,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 6 : 8),
                                      Text(
                                        '$e',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red.shade200,
                                          fontSize: getResponsiveFontSize(
                                            context,
                                            isTablet ? 14 : 12,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
