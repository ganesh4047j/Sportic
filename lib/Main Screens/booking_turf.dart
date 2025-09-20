import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_slot.dart'; // adjust the path if needed
import 'package:direct_call_plus/direct_call_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your notification provider file
import '../Providers/notification_provider.dart'; // Adjust the path as needed

class Comment {
  String username;
  String text;
  int likes;
  int dislikes;
  bool isLiked;
  bool isDisliked;
  List<Comment> replies;
  bool showReplyField;

  Comment({
    required this.username,
    required this.text,
    this.likes = 0,
    this.dislikes = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.replies = const [],
    this.showReplyField = false,
  });
}

class BookingPage extends ConsumerStatefulWidget {
  final String turfImages;
  final String turfName;
  final String location;
  final String owner_id;
  final String managerName;
  final String managerNumber;
  final String acquisition;
  final String weekdayDayTime;
  final String weekdayNightTime;
  final String weekendDayTime;
  final String weekendNightTime;

  const BookingPage({
    super.key,
    required this.turfImages,
    required this.turfName,
    required this.location,
    required this.owner_id,
    required this.managerName,
    required this.managerNumber,
    required this.acquisition,
    required this.weekdayDayTime,
    required this.weekdayNightTime,
    required this.weekendDayTime,
    required this.weekendNightTime,
  });

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  // Add animation controllers for the "No offers" animation
  late AnimationController _noOffersAnimationController;
  late Animation<double> _noOffersAnimation;

  List<Comment> comments = [
    Comment(
      username: "@godwinjeraldwilliam",
      text: "Smooth and Even Surface",
      likes: 125,
    ),
    Comment(username: "@anotheruser", text: "Great turf quality", likes: 45),
  ];

  Map<String, String>? contactInfo;

  @override
  void initState() {
    super.initState();
    fetchOwnerContact(widget.owner_id);

    // Initialize animation controller for "No offers" text
    _noOffersAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _noOffersAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _noOffersAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation
    _noOffersAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _noOffersAnimationController.dispose();
    super.dispose();
  }

  Future<void> fetchOwnerContact(String ownerId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      print('🔍 Searching for ownerId: $ownerId');

      // Check admin_details_phone
      final phoneDoc = await firestore
          .collection('admin_details_phone')
          .doc(ownerId)
          .get()
          .timeout(const Duration(seconds: 10)); // Add timeout

      if (phoneDoc.exists) {
        print('✅ Found in admin_details_phone');
        final data = phoneDoc.data();
        if (mounted) {
          // Check if widget is still mounted
          setState(() {
            contactInfo = {
              'phone_number': data?['phone_number']?.toString() ?? '',
              'alternative_phone_number':
                  data?['alternative_phone_number']?.toString() ?? '',
              'login_type': 'phone',
            };
          });
        }
        return;
      }

      // Check admin_details_email
      final emailDoc = await firestore
          .collection('admin_details_email')
          .doc(ownerId)
          .get()
          .timeout(const Duration(seconds: 10)); // Add timeout

      if (emailDoc.exists) {
        print('✅ Found in admin_details_email');
        final data = emailDoc.data();
        if (mounted) {
          // Check if widget is still mounted
          setState(() {
            contactInfo = {
              'phone_number': data?['phone_number']?.toString() ?? '',
              'alternative_phone_number':
                  data?['alternative_phone_number']?.toString() ?? '',
              'login_type': 'email',
            };
          });
        }
        return;
      }

      print('❌ Owner ID not found in any collection');
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          contactInfo = {
            'phone_number': '',
            'alternative_phone_number': '',
            'login_type': 'unknown',
          };
        });
      }
    } catch (e) {
      print('❌ Error fetching owner contact: $e');
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          contactInfo = {
            'phone_number': '',
            'alternative_phone_number': '',
            'login_type': 'error',
          };
        });
      }
    }
  }

  // Method to filter offers for current turf
  List<Map<String, dynamic>> _getOffersForCurrentTurf(
    List<Map<String, dynamic>> allOffers,
  ) {
    return allOffers.where((offer) {
      final offerScope = offer['offerScope']?.toString() ?? 'selected_turfs';
      final selectedTurfs = offer['selectedTurfs'] as List<dynamic>? ?? [];
      final ownerId = offer['ownerId']?.toString() ?? '';

      print('🎯 Checking offer: ${offer['title']}');
      print('   Offer scope: $offerScope');
      print('   Current turf owner: ${widget.owner_id}');
      print('   Offer owner: $ownerId');
      print('   Selected turfs count: ${selectedTurfs.length}');

      // Check if offer applies to current turf
      if (offerScope == 'all_turfs' && ownerId == widget.owner_id) {
        print('   ✅ Matches: All turfs from same owner');
        return true;
      }

      if (offerScope == 'selected_turfs') {
        final matchesTurf = selectedTurfs.any((turf) {
          final turfName = turf['name']?.toString() ?? '';
          final turfOwnerId = turf['ownerId']?.toString() ?? '';
          final matches =
              (turfName == widget.turfName || turfOwnerId == widget.owner_id);
          print(
            '   Checking turf: $turfName (owner: $turfOwnerId) - matches: $matches',
          );
          return matches;
        });

        if (matchesTurf) {
          print('   ✅ Matches: Selected turfs include current turf');
          return true;
        }
      }

      print('   ❌ No match for current turf');
      return false;
    }).toList();
  }

  // Build offers section widget
  Widget _buildOffersSection() {
    final offersAsync = ref.watch(activeOffersProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen information for responsive design
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth;

        // Define responsive breakpoints
        bool isSmallScreen = screenWidth <= 360; // Small phones
        bool isMediumScreen =
            screenWidth > 360 && screenWidth <= 414; // Standard phones
        bool isLargeScreen = screenWidth > 414; // Large phones/tablets

        // Calculate responsive heights
        double containerHeight;
        if (isSmallScreen) {
          containerHeight = 60.0;
        } else if (isMediumScreen) {
          containerHeight = 70.0;
        } else {
          containerHeight = 80.0;
        }

        return offersAsync.when(
          loading:
              () => Container(
                height: containerHeight,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    strokeWidth: 2,
                  ),
                ),
              ),
          error: (error, stack) {
            print('Error loading offers: $error');
            return _buildNoOffersWidget(screenWidth, availableWidth);
          },
          data: (allOffers) {
            print('📢 Total offers received: ${allOffers.length}');

            final turfOffers = _getOffersForCurrentTurf(allOffers);
            print('📢 Offers for current turf: ${turfOffers.length}');

            if (turfOffers.isEmpty) {
              return _buildNoOffersWidget(screenWidth, availableWidth);
            }

            return _buildOffersCarousel(
              turfOffers,
              screenWidth,
              availableWidth,
            );
          },
        );
      },
    );
  }

  // Build "No offers" animated widget
  Widget _buildNoOffersWidget(double screenWidth, double availableWidth) {
    // Responsive sizing
    bool isSmallScreen = screenWidth <= 360;
    bool isMediumScreen = screenWidth > 360 && screenWidth <= 414;
    bool isLargeScreen = screenWidth > 414; // Added this missing variable

    double containerHeight =
        isSmallScreen ? 60.0 : (isMediumScreen ? 70.0 : 80.0);
    double horizontalPadding =
        isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);
    double verticalPadding =
        isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 15.0);
    double fontSize = isSmallScreen ? 13.0 : (isMediumScreen ? 14.0 : 16.0);
    double iconSize = isSmallScreen ? 16.0 : (isMediumScreen ? 18.0 : 20.0);
    double spacing = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);

    // Adjust font size based on available width
    if (availableWidth < 300) {
      fontSize = 12.0;
    } else if (availableWidth < 350) {
      fontSize = 13.0;
    }

    return Container(
      height: containerHeight,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Outer padding
      child: Center(
        child: AnimatedBuilder(
          animation: _noOffersAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _noOffersAnimation.value,
              child: Transform.scale(
                scale: 0.95 + (_noOffersAnimation.value * 0.05),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 400.0 : double.infinity,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.3),
                        Colors.deepOrange.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade300,
                        size: iconSize,
                      ),
                      SizedBox(width: spacing),
                      Flexible(
                        child: Text(
                          isSmallScreen
                              ? "No Offers Available"
                              : "No Current Offers Available",
                          style: GoogleFonts.poppins(
                            color: Colors.orange.shade200,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Build offers carousel
  Widget _buildOffersCarousel(
    List<Map<String, dynamic>> offers,
    double screenWidth,
    double availableWidth,
  ) {
    // Responsive sizing
    bool isSmallScreen = screenWidth <= 360;
    bool isMediumScreen = screenWidth > 360 && screenWidth <= 414;

    double containerHeight =
        isSmallScreen ? 60.0 : (isMediumScreen ? 70.0 : 80.0);
    double cardSpacing = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);

    return Container(
      height: containerHeight,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          children:
              offers.asMap().entries.map((entry) {
                final index = entry.key;
                final offer = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == offers.length - 1 ? 0 : cardSpacing,
                  ),
                  child: _buildOfferCard(
                    offer,
                    index,
                    screenWidth,
                    availableWidth,
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  // Build individual offer card
  Widget _buildOfferCard(
    Map<String, dynamic> offer,
    int index,
    double screenWidth,
    double availableWidth,
  ) {
    final discountPercentage = (offer['discountPercentage'] ?? 0.0).toDouble();
    final title = offer['title']?.toString() ?? 'Special Offer';
    final description = offer['description']?.toString() ?? '';
    final offerType = offer['offerType']?.toString() ?? 'Booking';

    // Responsive sizing
    bool isSmallScreen = screenWidth <= 360;
    bool isMediumScreen = screenWidth > 360 && screenWidth <= 414;
    bool isLargeScreen = screenWidth > 414;

    // Calculate responsive dimensions
    double cardWidth;
    double cardPadding;
    double iconSize;
    double titleFontSize;
    double subtitleFontSize;
    double spacing;

    if (isSmallScreen) {
      cardWidth = math.min(140.0, availableWidth * 0.6);
      cardPadding = 8.0;
      iconSize = 18.0;
      titleFontSize = 11.0;
      subtitleFontSize = 9.0;
      spacing = 6.0;
    } else if (isMediumScreen) {
      cardWidth = math.min(160.0, availableWidth * 0.65);
      cardPadding = 10.0;
      iconSize = 20.0;
      titleFontSize = 12.0;
      subtitleFontSize = 10.0;
      spacing = 7.0;
    } else {
      cardWidth = math.min(180.0, availableWidth * 0.7);
      cardPadding = 12.0;
      iconSize = 22.0;
      titleFontSize = 13.0;
      subtitleFontSize = 11.0;
      spacing = 8.0;
    }

    // Ensure minimum width
    cardWidth = cardWidth.clamp(120.0, 200.0);

    // Create display text
    String displayText = '';
    String subText = '';

    if (discountPercentage > 0) {
      displayText = '${discountPercentage.toInt()}% off';
      subText = isSmallScreen ? offerType : 'On $offerType';
    } else if (title.toLowerCase().contains('flat')) {
      displayText =
          isSmallScreen && title.length > 12
              ? '${title.substring(0, 12)}...'
              : title;
      subText =
          description.isNotEmpty
              ? (isSmallScreen && description.length > 15
                  ? '${description.substring(0, 15)}...'
                  : description)
              : 'Special discount';
    } else {
      displayText =
          isSmallScreen && title.length > 12
              ? '${title.substring(0, 12)}...'
              : title;
      subText =
          description.isNotEmpty
              ? (isSmallScreen && description.length > 15
                  ? '${description.substring(0, 15)}...'
                  : description)
              : 'Limited time';
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              width: cardWidth,
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child:
                  isSmallScreen
                      ? _buildCompactOfferContent(
                        displayText,
                        subText,
                        iconSize,
                        titleFontSize,
                        subtitleFontSize,
                        spacing,
                      )
                      : _buildStandardOfferContent(
                        displayText,
                        subText,
                        iconSize,
                        titleFontSize,
                        subtitleFontSize,
                        spacing,
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactOfferContent(
    String displayText,
    String subText,
    double iconSize,
    double titleFontSize,
    double subtitleFontSize,
    double spacing,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.local_offer, size: iconSize, color: Colors.white),
        ),
        SizedBox(height: spacing * 0.5),
        Text(
          displayText,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: titleFontSize,
            height: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (subText.isNotEmpty) ...[
          SizedBox(height: spacing * 0.25),
          Text(
            subText,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: subtitleFontSize,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // Standard layout for medium and large screens
  Widget _buildStandardOfferContent(
    String displayText,
    String subText,
    double iconSize,
    double titleFontSize,
    double subtitleFontSize,
    double spacing,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.local_offer, size: iconSize, color: Colors.white),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: titleFontSize,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subText.isNotEmpty) ...[
                SizedBox(height: spacing * 0.25),
                Text(
                  subText,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: subtitleFontSize,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentTile(Comment comment, {int indentLevel = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * indentLevel, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mail_outline, size: 30, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.text,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (comment.isLiked) {
                                comment.isLiked = false;
                                comment.likes--;
                              } else {
                                comment.isLiked = true;
                                comment.likes++;
                                if (comment.isDisliked) {
                                  comment.isDisliked = false;
                                  comment.dislikes--;
                                }
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_up,
                                color:
                                    comment.isLiked
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likes}',
                                style: TextStyle(
                                  color:
                                      comment.isLiked
                                          ? Colors.white
                                          : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (comment.isDisliked) {
                                comment.isDisliked = false;
                                comment.dislikes--;
                              } else {
                                comment.isDisliked = true;
                                comment.dislikes++;
                                if (comment.isLiked) {
                                  comment.isLiked = false;
                                  comment.likes--;
                                }
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_down,
                                color:
                                    comment.isDisliked
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.dislikes}',
                                style: TextStyle(
                                  color:
                                      comment.isDisliked
                                          ? Colors.white
                                          : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              comment.showReplyField = !comment.showReplyField;
                            });
                          },
                          child: Text(
                            'reply',
                            style: GoogleFonts.cutive(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    if (comment.showReplyField)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: GoogleFonts.cutive(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Write a reply...',
                                  hintStyle: GoogleFonts.cutive(
                                    color: Colors.white70,
                                  ),
                                  border: const UnderlineInputBorder(),
                                ),
                                onSubmitted: (replyText) {
                                  if (replyText.trim().isNotEmpty) {
                                    setState(() {
                                      comment.replies.add(
                                        Comment(
                                          username: "@you",
                                          text: replyText,
                                        ),
                                      );
                                      comment.showReplyField = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Render Replies Recursively
          for (var reply in comment.replies)
            _buildCommentTile(reply, indentLevel: indentLevel + 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (contactInfo == null) {
      return Scaffold(
        body: Container(
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
            child: Lottie.asset(
              'assets/loading_spinner.json',
              height: 300,
              width: 300,
            ),
          ),
        ),
      );
    }

    final List<String> limitedImages = [widget.turfImages];
    final String phoneNumber = contactInfo?['phone_number'] ?? '';
    final String whatsappNumber =
        phoneNumber.isNotEmpty ? '91${widget.managerNumber}' : '';
    final String message = 'Hi, I need some help regarding your turf.';

    _callNumber() async {
      final number = '${widget.managerNumber ?? ''}'; //set the number here
      // print('Alt num ==> $number');
      bool? res = await DirectCallPlus.makeCall(number);
    }

    return Scaffold(
      body: Container(
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
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.turfImages.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                ),
                                child: Image.network(
                                  widget.turfImages.isNotEmpty
                                      ? widget.turfImages
                                      : 'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 30,
                          left: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              count: limitedImages.length,
                              effect: const WormEffect(
                                dotColor: Colors.white54,
                                activeDotColor: Colors.white,
                                dotHeight: 8,
                                dotWidth: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.turfName,
                            style: GoogleFonts.robotoSlab(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.location,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "4.0 [4]",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "About Turf",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              InkWell(
                                onTap: () async {
                                  final whatsappUrl = Uri.parse(
                                    "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}",
                                  );

                                  if (await canLaunchUrl(whatsappUrl)) {
                                    await launchUrl(
                                      whatsappUrl,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    print("❌ Could not launch WhatsApp");
                                  }
                                },
                                child: Container(
                                  width: 150,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.pinkAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        "Contact",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const FaIcon(
                                        FontAwesomeIcons.whatsapp,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.phone_callback,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _callNumber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // REAL-TIME OFFERS SECTION - REPLACES HARDCODED OFFERS
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Current Offers",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              _buildOffersSection(), // This replaces your hardcoded offers
                            ],
                          ),

                          const SizedBox(height: 20),
                          Text(
                            "Venue info",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5), // spacing before the card
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                      ), // adjust the value as needed
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              print("Green card tapped");
                            },
                            child: Container(
                              width: 60,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "pitch",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              ".1 Nets",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                      ), // Add left padding here
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8, width: 20),
                          Text(
                            "Artificial Turf",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Equipment Provided",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8), // space before line
                          const Divider(
                            color: Colors.white, // line color
                            thickness: 1,
                            indent: 10, // line thickness
                            endIndent: 35, // optional: line length control
                          ),
                          const SizedBox(
                            height: 8,
                          ), // space after line before new text
                          Text(
                            "Amenities provided",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ), // space before amenity list
                          // ✅ List of amenities with green icons
                          Row(
                            children: [
                              const Icon(
                                Icons.payments,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "UPI Accepted",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.atm,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Card Accepted",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.local_parking,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Free Parking",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.family_restroom,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Toilets",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Comments",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Optional: Input field to add comments
                          TextField(
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Write a comment...",
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white70,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    comments.add(
                                      Comment(
                                        username: "@currentUser",
                                        text: "New comment here",
                                      ),
                                    );
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Comment list
                          ListView.builder(
                            itemCount: comments.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return _buildCommentTile(comment);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00c180), // vivid green
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ), // pill-shaped
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TimingPage(
                            owner_id: widget.owner_id,
                            location: widget.location,
                            turfName: widget.turfName,
                            managerNumber: widget.managerNumber,
                            acquisition: widget.acquisition,
                            weekdayDayTime: widget.weekdayDayTime,
                            weekdayNightTime: widget.weekendNightTime,
                            weekendDayTime: widget.weekendDayTime,
                            weekendNightTime: widget.weekendNightTime,
                          ),
                    ),
                  );
                },
                child: Text(
                  "PROCEED TO BOOK A SLOT",
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
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
