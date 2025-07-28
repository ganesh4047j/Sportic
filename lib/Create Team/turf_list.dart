import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'book_and_create_team.dart';

// TurfModel
class TurfModel {
  final String id;
  final String name;
  final String imageUrl;
  final String sport;
  final String startTime;
  final String endTime;
  final String location;
  final String ownerId;

  TurfModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sport,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.ownerId,
  });
}

// Providers
final turfListProvider =
    StateNotifierProvider<TurfListNotifier, List<TurfModel>>((ref) {
      return TurfListNotifier();
    });

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedSportProvider = StateProvider<String>((ref) => 'All sports');

class TurfListNotifier extends StateNotifier<List<TurfModel>> {
  TurfListNotifier() : super([]) {
    fetchTurfs();
  }

  Future<void> fetchTurfs() async {
    final List<TurfModel> allTurfs = [];
    final firestore = FirebaseFirestore.instance;

    try {
      final multiSnapshot = await firestore.collection('multi_variant').get();
      for (var doc in multiSnapshot.docs) {
        final data = doc.data();
        final dynamic sportField = data['sports'] ?? data['sport'];
        final List<String> sports =
            sportField is List
                ? List<String>.from(sportField)
                : [sportField?.toString() ?? ''];

        for (final sport in sports) {
          final turf = TurfModel(
            id: 'multi_${doc.id}_$sport',
            name: data['turf_name'] ?? '',
            imageUrl:
                (data['images'] as List?)?.first ??
                'https://th.bing.com/th/id/OIP.QcSOTe7jIu4fP31CaetEUQHaDa?w=332&h=161&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3',
            sport: sport,
            startTime: data['start_time'] ?? '',
            endTime: data['end_time'] ?? '',
            location: data['location'] ?? 'Unknown',
            ownerId: data['ownerId'] ?? '',
          );
          allTurfs.add(turf);
        }
      }

      state = allTurfs;
    } catch (e) {
      print('🔥 Error fetching turfs: $e');
      state = [];
    }
  }

  void refreshTurfs() {
    fetchTurfs();
  }
}

// Filtered turfs provider
final filteredTurfsProvider = Provider<List<TurfModel>>((ref) {
  final turfs = ref.watch(turfListProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final selectedSport = ref.watch(selectedSportProvider);

  return turfs.where((turf) {
    final matchesSearch =
        turf.name.toLowerCase().contains(searchQuery) ||
        turf.location.toLowerCase().contains(searchQuery);
    final matchesSport =
        selectedSport == 'All sports' || turf.sport == selectedSport;
    return matchesSearch && matchesSport;
  }).toList();
});

// Available sports provider
final availableSportsProvider = Provider<List<String>>((ref) {
  final turfs = ref.watch(turfListProvider);
  final sports = turfs.map((turf) => turf.sport).toSet().toList();
  return ['All sports', ...sports];
});

class TurfListingScreen extends ConsumerStatefulWidget {
  final String creatorName;
  final int totalPlayers;
  final int needPlayers;

  const TurfListingScreen({
    Key? key,
    required this.creatorName,
    required this.totalPlayers,
    required this.needPlayers,
  }) : super(key: key);

  @override
  ConsumerState<TurfListingScreen> createState() => _TurfListingScreenState();
}

class _TurfListingScreenState extends ConsumerState<TurfListingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Navigate to BookingPage with team details
  void _navigateToBooking(TurfModel turf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingPage(
              turfName: turf.name,
              location: turf.location,
              owner_id: turf.ownerId,
              // Pass additional team details
              creatorName: widget.creatorName,
              totalPlayers: widget.totalPlayers,
              needPlayers: widget.needPlayers,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTurfs = ref.watch(filteredTurfsProvider);
    final availableSports = ref.watch(availableSportsProvider);
    final selectedSport = ref.watch(selectedSportProvider);

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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header with team info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Back button and title
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Select Turf',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Team info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
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
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.group,
                                      color: Colors.greenAccent,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Team Details',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTeamInfoRow('Creator', widget.creatorName),
                              _buildTeamInfoRow(
                                'Total Players',
                                '${widget.totalPlayers}',
                              ),
                              _buildTeamInfoRow(
                                'Need Players',
                                '${widget.needPlayers}',
                              ),
                            ],
                          ),
                        ),

                        // Search bar
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  onChanged: (value) {
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .state = value;
                                  },
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: "Search your 'games' || 'turfs'",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Title and Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Available Turfs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${filteredTurfs.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Filter Chips
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: availableSports.length,
                            itemBuilder: (context, index) {
                              final sport = availableSports[index];
                              final isSelected = sport == selectedSport;

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  child: FilterChip(
                                    label: Text(
                                      sport,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.black
                                                : Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      ref
                                          .read(selectedSportProvider.notifier)
                                          .state = sport;
                                    },
                                    backgroundColor: Colors.transparent,
                                    selectedColor: Colors.greenAccent,
                                    side: BorderSide(
                                      color:
                                          isSelected
                                              ? Colors.greenAccent
                                              : Colors.white.withOpacity(0.3),
                                    ),
                                    checkmarkColor: Colors.black,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Turf List
                  Expanded(
                    child:
                        filteredTurfs.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sports_soccer,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No turfs found',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search or sport filter',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              backgroundColor: Colors.white,
                              color: const Color(0xFF452152),
                              onRefresh: () async {
                                ref
                                    .read(turfListProvider.notifier)
                                    .refreshTurfs();
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredTurfs.length,
                                itemBuilder: (context, index) {
                                  final turf = filteredTurfs[index];
                                  return TurfCard(
                                    turf: turf,
                                    index: index,
                                    onTap: () => _navigateToBooking(turf),
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TurfCard extends StatefulWidget {
  final TurfModel turf;
  final int index;
  final VoidCallback onTap;

  const TurfCard({
    Key? key,
    required this.turf,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  State<TurfCard> createState() => _TurfCardState();
}

class _TurfCardState extends State<TurfCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Stack(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(widget.turf.imageUrl),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Handle image loading error
                                  print('Error loading image: $exception');
                                },
                              ),
                            ),
                            child:
                                widget.turf.imageUrl.isEmpty
                                    ? Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.sports_soccer,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.turf.sport,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                '${widget.turf.startTime} - ${widget.turf.endTime}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Content Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.turf.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.greenAccent.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Book Now',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.turf.location,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
  }
}
