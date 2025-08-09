import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Providers/connection_provider.dart';
import '../Providers/search_friends_providers.dart';
import '../Providers/view_request_provider.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(viewRequestsProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFE1BEE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: Text(
            'Friend Requests',
            style: GoogleFonts.robotoSlab(
              color: Colors.white,
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Enhanced gradient background with subtle animation
          AnimatedContainer(
            duration: const Duration(seconds: 3),
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
          ),
          // Floating orbs for visual enhancement
          Positioned(
            top: screenHeight * 0.1,
            right: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.purple.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.2,
            left: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.pink.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 16,
              ),
              child: Column(
                children: [
                  // Header section with stats
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.02,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: requestsAsync.when(
                      data:
                          (requests) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: Colors.white.withOpacity(0.8),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${requests.length} Pending ${requests.length == 1 ? 'Request' : 'Requests'}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      loading:
                          () => Text(
                            'Loading requests...',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                      error:
                          (error, _) => Text(
                            'Error loading requests',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent.withOpacity(0.8),
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                    ),
                  ),
                  // Requests list
                  Expanded(
                    child: requestsAsync.when(
                      data: (requests) {
                        if (requests.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.people_outline,
                                    size: 60,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No pending requests',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All caught up! 🎉',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: requests.length,
                          separatorBuilder:
                              (_, __) => SizedBox(height: screenHeight * 0.015),
                          itemBuilder: (context, index) {
                            final user = requests[index];

                            // Safely extract user data with null safety
                            final userName =
                                user['name']?.toString() ?? 'Unknown User';
                            final userEmail = user['email']?.toString() ?? '';
                            final userLocation =
                                user['location']?.toString() ?? '';
                            final userPhotoUrl =
                                user['photoUrl']?.toString() ?? '';
                            final userUid = user['uid']?.toString() ?? '';

                            if (userUid.isEmpty) {
                              // Skip this item if no valid UID
                              return const SizedBox.shrink();
                            }

                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 300 + (index * 100),
                              ),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.15),
                                            Colors.white.withOpacity(0.08),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            screenWidth * 0.04,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  // Enhanced avatar with glow effect
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.purple
                                                              .withOpacity(0.3),
                                                          blurRadius: 10,
                                                          spreadRadius: 2,
                                                        ),
                                                      ],
                                                    ),
                                                    child: CircleAvatar(
                                                      backgroundImage:
                                                          userPhotoUrl
                                                                  .isNotEmpty
                                                              ? NetworkImage(
                                                                userPhotoUrl,
                                                              )
                                                              : const NetworkImage(
                                                                'https://i.pravatar.cc/150',
                                                              ),
                                                      radius:
                                                          screenWidth * 0.07,
                                                      backgroundColor: Colors
                                                          .white
                                                          .withOpacity(0.1),
                                                      onBackgroundImageError: (
                                                        _,
                                                        __,
                                                      ) {
                                                        // Handle image loading errors
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  // User info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          userName,
                                                          style:
                                                              GoogleFonts.poppins(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize:
                                                                    screenWidth *
                                                                    0.045,
                                                              ),
                                                        ),
                                                        if (userLocation
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .location_on_outlined,
                                                                size: 14,
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.7,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  userLocation,
                                                                  style: GoogleFonts.poppins(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.7,
                                                                        ),
                                                                    fontSize:
                                                                        screenWidth *
                                                                        0.035,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        if (userEmail
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .email_outlined,
                                                                size: 14,
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.6,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  userEmail,
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        screenWidth *
                                                                        0.03,
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.6,
                                                                        ),
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.02,
                                              ),
                                              // Enhanced action buttons
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildActionButton(
                                                      context: context,
                                                      ref: ref,
                                                      screenWidth: screenWidth,
                                                      userUid: userUid,
                                                      userName: userName,
                                                      isAccept: true,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: _buildActionButton(
                                                      context: context,
                                                      ref: ref,
                                                      screenWidth: screenWidth,
                                                      userUid: userUid,
                                                      userName: userName,
                                                      isAccept: false,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                          () => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Use CircularProgressIndicator if Lottie asset is not available
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading friend requests...',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      error:
                          (e, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 50,
                                    color: Colors.redAccent.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Oops! Something went wrong',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    e.toString(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.redAccent.withOpacity(0.7),
                                      fontSize: screenWidth * 0.035,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.refresh(viewRequestsProvider);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required double screenWidth,
    required String userUid,
    required String userName,
    required bool isAccept,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isAccept
                  ? [
                    Colors.green.withOpacity(0.8),
                    Colors.green.withOpacity(0.6),
                  ]
                  : [Colors.red.withOpacity(0.8), Colors.red.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isAccept ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            try {
              if (isAccept) {
                await ref.read(acceptRequestProvider(userUid));
                _showSnackBar(
                  context,
                  'Friend request accepted',
                  Icons.check_circle,
                  Colors.green,
                );
              } else {
                await ref.read(rejectRequestProvider(userUid));
                _showSnackBar(
                  context,
                  'Friend request rejected',
                  Icons.cancel,
                  Colors.redAccent,
                );
              }

              // Refresh providers
              ref.invalidate(viewRequestsProvider);
              ref.invalidate(searchFriendsProvider);
              if (isAccept) {
                ref.invalidate(connectionsProvider);
              }
            } catch (e) {
              _showSnackBar(
                context,
                'Failed to ${isAccept ? 'accept' : 'reject'} request: ${e.toString()}',
                Icons.error,
                Colors.redAccent,
              );
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAccept ? Icons.check : Icons.close,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAccept ? 'Accept' : 'Reject',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.038,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
