import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:sports/Main%20Screens/booking_turf.dart';

import '../Main Screens/category.dart';
import '../Main Screens/favourites.dart';
import '../Main Screens/home.dart';
import '../Main Screens/live_screen.dart';
import '../Main Screens/location.dart';
import '../Main Screens/profile.dart';
import '../Providers/notification_provider.dart';
import '../Providers/turfscreen_provider.dart';

class TurfHomeScreen extends ConsumerStatefulWidget {
  const TurfHomeScreen({super.key});

  @override
  ConsumerState<TurfHomeScreen> createState() => _TurfHomeScreenState();
}

class _TurfHomeScreenState extends ConsumerState<TurfHomeScreen>
    with TickerProviderStateMixin {
  final selectedDate = ValueNotifier<DateTime>(DateTime.now());
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Set<String> _loadingFavorites = <String>{};

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Widget _buildFavoriteButton(TurfModel turf, bool isSmallScreen) {
    final isLoading = _loadingFavorites.contains(turf.id);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.3),
      ),
      child: IconButton(
        icon:
            isLoading
                ? SizedBox(
                  width: isSmallScreen ? 16 : 20,
                  height: isSmallScreen ? 16 : 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
                : Icon(
                  turf.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: isSmallScreen ? 20 : 24,
                ),
        onPressed:
            isLoading
                ? null
                : () async {
                  // Add turf ID to loading set
                  setState(() {
                    _loadingFavorites.add(turf.id);
                  });

                  try {
                    // Call the async toggleFavorite method
                    await ref
                        .read(turfListProvider.notifier)
                        .toggleFavorite(turf.id);

                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            turf.isFavorite
                                ? 'Removed from favorites'
                                : 'Added to favorites',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor:
                              turf.isFavorite
                                  ? Colors.red.withOpacity(0.8)
                                  : Colors.green.withOpacity(0.8),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // Show error message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update favorites: $e',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red.withOpacity(0.8),
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } finally {
                    // Remove turf ID from loading set
                    if (mounted) {
                      setState(() {
                        _loadingFavorites.remove(turf.id);
                      });
                    }
                  }
                },
      ),
    );
  }

  Widget _buildAnimatedCard({
    required Widget child,
    required int index,
    double? delay,
  }) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final delayValue = delay ?? index * 0.1;
        final rawValue = (_staggerController.value - delayValue).clamp(
          0.0,
          1.0,
        );
        final animationValue = Curves.easeOutBack
            .transform(rawValue)
            .clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(opacity: animationValue.clamp(0.0, 1.0), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 500;

    final turfList = ref.watch(filteredTurfListProvider);
    final navIndex = ref.watch(turfNavIndexProvider);
    final query = ref.watch(searchTurfProvider).toLowerCase();

    final filteredTurfs =
        query.isEmpty
            ? turfList
            : turfList
                .where((turf) => turf.name.toLowerCase().contains(query))
                .toList();

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section with Animation
                    _buildAnimatedCard(
                      index: 0,
                      child: _buildHeaderSection(screenSize),
                    ),

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Search Bar with Animation
                    _buildAnimatedCard(
                      index: 1,
                      child: _buildSearchBar(isSmallScreen),
                    ),

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Filter Header with Animation
                    _buildAnimatedCard(
                      index: 2,
                      child: _buildFilterHeader(isSmallScreen),
                    ),

                    SizedBox(height: isSmallScreen ? 6 : 8),

                    // Date Picker and Filters with Animation
                    _buildAnimatedCard(
                      index: 3,
                      child: _buildDatePickerAndFilters(screenSize),
                    ),

                    SizedBox(height: isSmallScreen ? 20 : 26),

                    // Turf List with Staggered Animation
                    Expanded(child: _buildTurfList(filteredTurfs, screenSize)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeaderSection(Size screenSize) {
    final isSmallScreen = screenSize.width < 360;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final userProfileAsync = ref.watch(userProfileProvider);

          return userProfileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
            data: (profile) {
              final globalLocation = ref.watch(userLocationProvider);
              final location =
                  globalLocation ?? profile['location'] ?? 'Unknown';
              final imageUrl =
                  profile['photoUrl'] ?? 'https://i.pravatar.cc/300';

              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const LocationInputScreen(
                                  shouldRedirectToHome: false,
                                ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your location",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.pink,
                                size: isSmallScreen ? 16 : 18,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.pink, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: isSmallScreen ? 20 : 24,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          ref.read(searchTurfProvider.notifier).state = val;
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: "Search your 'Turfs'",
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 14 : 16,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.pink),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchTurfProvider.notifier).state = '';
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
            horizontal: 16,
          ),
        ),
        style: TextStyle(
          color: Colors.black,
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
    );
  }

  Widget _buildFilterHeader(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        "All Turfs",
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDatePickerAndFilters(Size screenSize) {
    final isSmallScreen = screenSize.width < 360;

    return Row(
      children: [
        ValueListenableBuilder<DateTime>(
          valueListenable: selectedDate,
          builder: (context, value, _) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE60073),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 12,
                    horizontal: isSmallScreen ? 8 : 16,
                  ),
                ),
                onPressed: () => _showDatePicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.day}-${value.month}-${value.year}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 8),
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: isSmallScreen ? 14 : 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
          child: Container(
            height: 20,
            width: 1,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: isSmallScreen ? 35 : 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                final labels = [
                  'All Sports',
                  'Cricket',
                  'Football',
                  'Tennis',
                  'Badminton',
                ];
                final label = labels[index];
                final isSelected = ref.watch(selectedFilterProvider) == label;

                return Padding(
                  padding: EdgeInsets.only(
                    right: isSmallScreen ? 6 : 8,
                    left: index == 0 ? 4 : 0,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: FilterChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected:
                          (_) =>
                              ref.read(selectedFilterProvider.notifier).state =
                                  label,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: Colors.green,
                      side: BorderSide(
                        color: isSelected ? Colors.green : Colors.transparent,
                        width: 1,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTurfList(List filteredTurfs, Size screenSize) {
    final isSmallScreen = screenSize.width < 360;

    if (filteredTurfs.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Lottie.asset(
                'assets/empty.json',
                height: screenSize.height * 0.25,
                width: screenSize.height * 0.25,
              ),
              const SizedBox(height: 16),
              Text(
                'No turfs found for your search.',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 12 : 16),
      itemCount: filteredTurfs.length,
      itemBuilder: (context, index) {
        final turf = filteredTurfs[index];
        return _buildAnimatedCard(
          index: index + 4,
          delay: (index * 0.1) + 0.4,
          child: _buildTurfCard(turf, screenSize, index),
        );
      },
    );
  }

  Widget _buildTurfCard(dynamic turf, Size screenSize, int index) {
    final isSmallScreen = screenSize.width < 360;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => BookingPage(
                      turfImages: turf.imageUrl,
                      turfName: turf.name,
                      location: turf.location,
                      owner_id: turf.ownerId,
                      managerName: turf.managerName,
                      managerNumber: turf.managerNumber,
                      acquisition: turf.acquisition,
                      weekdayDayTime: turf.weekdayDayTime,
                      weekdayNightTime: turf.weekdayNightTime,
                      weekendDayTime: turf.weekendDayTime,
                      weekendNightTime: turf.weekendNightTime,
                    ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        turf.name,
                        style: GoogleFonts.robotoSlab(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 16 : 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.yellow.withOpacity(0.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: isSmallScreen ? 14 : 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '4.8',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          Text(
                            '[4]',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 8 : 12),

                // Image Section
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: isSmallScreen ? 100 : 120,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Image.network(
                          turf.imageUrl.isNotEmpty
                              ? turf.imageUrl
                              : 'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white54,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildFavoriteButton(
                        turf,
                        isSmallScreen,
                      ), // Use the new method
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 8 : 12),

                // Footer Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.green.withOpacity(0.2),
                        ),
                        child: Text(
                          turf.sport,
                          style: GoogleFonts.poppins(
                            color: Colors.green[300],
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed:
                            () => _showOffersPopup(
                              context,
                              turf.id,
                              turf.name,
                              screenSize,
                            ),
                        icon: Icon(
                          Icons.local_offer_outlined,
                          color: Colors.orange,
                          size: isSmallScreen ? 16 : 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOffersPopup(
    BuildContext context,
    String turfId,
    String turfName,
    Size screenSize,
  ) {
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 500;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Offers",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Container();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: const Color(0xFF2D1B3D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width:
                    screenSize.width *
                    (isSmallScreen
                        ? 0.9
                        : isMediumScreen
                        ? 0.85
                        : 0.8),
                constraints: BoxConstraints(
                  maxHeight: screenSize.height * 0.7,
                  minHeight: screenSize.height * 0.3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.8),
                            Colors.orange.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Current Offers",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  turfName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Flexible(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final offersAsync = ref.watch(
                            turfSpecificOffersProvider(turfId),
                          );
                          return offersAsync.when(
                            loading:
                                () => Container(
                                  padding: EdgeInsets.all(
                                    isSmallScreen ? 30 : 40,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Colors.orange,
                                          strokeWidth: 2,
                                        ),
                                        SizedBox(
                                          height: isSmallScreen ? 12 : 16,
                                        ),
                                        Text(
                                          "Loading offers...",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            error:
                                (error, stack) => Container(
                                  padding: EdgeInsets.all(
                                    isSmallScreen ? 20 : 30,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: isSmallScreen ? 40 : 50,
                                        ),
                                        SizedBox(
                                          height: isSmallScreen ? 8 : 12,
                                        ),
                                        Text(
                                          "Error loading offers",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Please try again later",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            data: (offers) {
                              if (offers.isEmpty) {
                                return Container(
                                  padding: EdgeInsets.all(
                                    isSmallScreen ? 20 : 30,
                                  ),
                                  child: Center(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.8 + (0.2 * value),
                                          child: Opacity(
                                            opacity: value,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(
                                                    isSmallScreen ? 12 : 16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.grey
                                                        .withOpacity(0.2),
                                                  ),
                                                  child: Icon(
                                                    Icons.local_offer_outlined,
                                                    color: Colors.grey,
                                                    size:
                                                        isSmallScreen ? 30 : 40,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height:
                                                      isSmallScreen ? 12 : 16,
                                                ),
                                                Text(
                                                  "No Current Offers Available",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isSmallScreen ? 14 : 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(
                                                  height: isSmallScreen ? 4 : 8,
                                                ),
                                                Text(
                                                  "Check back later for exciting deals!",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white70,
                                                    fontSize:
                                                        isSmallScreen ? 11 : 13,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.all(
                                  isSmallScreen ? 12 : 16,
                                ),
                                itemCount: offers.length,
                                separatorBuilder:
                                    (context, index) => SizedBox(
                                      height: isSmallScreen ? 8 : 12,
                                    ),
                                itemBuilder: (context, index) {
                                  final offer = offers[index];
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds: 300 + (index * 100),
                                    ),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              isSmallScreen ? 12 : 16,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                  Colors.orange.withOpacity(
                                                    0.1,
                                                  ),
                                                ],
                                              ),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                isSmallScreen
                                                                    ? 8
                                                                    : 10,
                                                            vertical:
                                                                isSmallScreen
                                                                    ? 4
                                                                    : 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        color: Colors.orange,
                                                      ),
                                                      child: Text(
                                                        "${offer['discountPercentage'].toInt()}% OFF",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  isSmallScreen
                                                                      ? 10
                                                                      : 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Icon(
                                                      Icons.access_time,
                                                      color: Colors.white70,
                                                      size:
                                                          isSmallScreen
                                                              ? 14
                                                              : 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "${offer['startTime']} - ${offer['endTime']}",
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color:
                                                                Colors.white70,
                                                            fontSize:
                                                                isSmallScreen
                                                                    ? 10
                                                                    : 12,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height:
                                                      isSmallScreen ? 8 : 10,
                                                ),
                                                Text(
                                                  offer['title'],
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isSmallScreen ? 14 : 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (offer['description'] !=
                                                        null &&
                                                    offer['description']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  SizedBox(
                                                    height:
                                                        isSmallScreen ? 4 : 6,
                                                  ),
                                                  Text(
                                                    offer['description'],
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white70,
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 11
                                                              : 13,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                SizedBox(
                                                  height: isSmallScreen ? 6 : 8,
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        isSmallScreen ? 6 : 8,
                                                    vertical:
                                                        isSmallScreen ? 2 : 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    color: Colors.green
                                                        .withOpacity(0.2),
                                                  ),
                                                  child: Text(
                                                    offer['offerType'],
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.green[300],
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 10
                                                              : 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Date",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ScrollDatePicker(
                  selectedDate: selectedDate.value,
                  minimumDate: DateTime(DateTime.now().year),
                  maximumDate: DateTime(DateTime.now().year + 10),
                  locale: const Locale('en'),
                  onDateTimeChanged: (date) => selectedDate.value = date,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE60073),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Done",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  Widget _buildBottomNavigationBar() {
    final navIndex = ref.watch(turfNavIndexProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff22012c),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.shifting,
        currentIndex: navIndex,
        onTap: (index) => ref.read(turfNavIndexProvider.notifier).state = index,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.white,
        selectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        items: [
          BottomNavigationBarItem(
            icon: IconButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  ),
              icon: const Icon(Icons.home),
            ),
            label: 'Home',
            backgroundColor: const Color(0xff22012c),
          ),
          BottomNavigationBarItem(
            icon: IconButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  ),
              icon: const Icon(Icons.videogame_asset),
            ),
            label: 'Games',
            backgroundColor: const Color(0xff22012c),
          ),
          BottomNavigationBarItem(
            icon: IconButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LiveScreen()),
                  ),
              icon: const Icon(Icons.live_tv),
            ),
            label: 'Live',
            backgroundColor: const Color(0xff22012c),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_soccer),
            label: 'Turf',
            backgroundColor: const Color(0xff22012c),
          ),
          BottomNavigationBarItem(
            icon: IconButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FollowingScreen(),
                    ),
                  ),
              icon: const Icon(Icons.favorite),
            ),
            label: 'Fav',
            backgroundColor: const Color(0xff22012c),
          ),
        ],
      ),
    );
  }
}
