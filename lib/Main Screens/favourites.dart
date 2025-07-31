import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports/Main%20Screens/home.dart';
import 'package:sports/Main%20Screens/turfscreen.dart';
import '../Providers/following_turf_providers.dart';
import 'category.dart';
import 'live_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final navIndexProvider = StateProvider<int>((ref) => 4);

class FollowingScreen extends ConsumerStatefulWidget {
  const FollowingScreen({super.key});

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turfs = ref.watch(turfProvider);
    final query = ref.watch(searchQueryProvider).toLowerCase();
    final filteredTurfs =
        query.isEmpty
            ? turfs
            : turfs
                .where((turf) => turf.name.toLowerCase().contains(query))
                .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF2C003E),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Enhanced Header with glass morphism effect
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
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
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.pink.withOpacity(0.3),
                                Colors.purple.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback:
                                    (bounds) => const LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.pink,
                                        Colors.purple,
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  'Favourites',
                                  style: GoogleFonts.robotoSlab(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Your loved turfs',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.pink.withOpacity(0.3),
                                Colors.purple.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.pink,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Enhanced Search Bar with animated container
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.95),
                            Colors.white.withOpacity(0.9),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ShaderMask(
                              shaderCallback:
                                  (bounds) => const LinearGradient(
                                    colors: [Colors.pink, Colors.purple],
                                  ).createShader(bounds),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                ref.read(searchQueryProvider.notifier).state =
                                    val;
                              },
                              style: GoogleFonts.cutive(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search your favourite turf...",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pink.withOpacity(0.1),
                                  Colors.purple.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.filter_list,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Enhanced Animated Text with container
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.03),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: DefaultTextStyle(
                      style: GoogleFonts.poppins(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TyperAnimatedText(
                            '⚽ Explore your favorite turfs...',
                            speed: const Duration(milliseconds: 80),
                          ),
                          TyperAnimatedText(
                            '🏆 Join your team now...',
                            speed: const Duration(milliseconds: 80),
                          ),
                          TyperAnimatedText(
                            '🔥 Start a match anytime!',
                            speed: const Duration(milliseconds: 80),
                          ),
                        ],
                        repeatForever: true,
                        pause: const Duration(milliseconds: 1000),
                      ),
                    ),
                  ),
                ),

                // Enhanced List with staggered animations
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredTurfs.length,
                    itemBuilder: (context, index) {
                      final turf = filteredTurfs[index];
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        curve: Curves.easeOutCubic,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xff330849).withOpacity(0.9),
                                  const Color(0xff2a0639).withOpacity(0.7),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  // Navigate to turf details
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Enhanced Avatar with gradient border
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.pink.withOpacity(0.8),
                                              Colors.purple.withOpacity(0.8),
                                              Colors.blue.withOpacity(0.6),
                                            ],
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xff330849),
                                          ),
                                          child: CircleAvatar(
                                            radius: 24,
                                            backgroundImage:
                                                CachedNetworkImageProvider(
                                                  turf.imageUrl,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Enhanced Text Section
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              turf.name,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Enhanced Action Buttons
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.green.withOpacity(0.2),
                                                  Colors.green.withOpacity(0.1),
                                                ],
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.call,
                                              color: Colors.green,
                                              size: 18,
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
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Navigation Bar (Original Design)
                Container(
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
                    currentIndex: ref.watch(navIndexProvider),
                    onTap:
                        (index) =>
                            ref.read(navIndexProvider.notifier).state = index,
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.home),
                        ),
                        label: 'Home',
                        backgroundColor: const Color(0xff22012c),
                      ),
                      BottomNavigationBarItem(
                        icon: IconButton(
                          onPressed: () {
                            print('Games button clicked');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.videogame_asset),
                        ),
                        label: 'Games',
                        backgroundColor: const Color(0xff22012c),
                      ),
                      BottomNavigationBarItem(
                        icon: IconButton(
                          onPressed: () {
                            print('Live button clicked');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const CenterLottieScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.live_tv),
                        ),
                        label: 'Live',
                        backgroundColor: const Color(0xff22012c),
                      ),
                      BottomNavigationBarItem(
                        icon: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TurfHomeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sports_soccer),
                        ),
                        label: 'Turf',
                        backgroundColor: const Color(0xff22012c),
                      ),
                      BottomNavigationBarItem(
                        icon: IconButton(
                          onPressed: () {
                            print('Fav button clicked');
                          },
                          icon: const Icon(Icons.favorite),
                        ),
                        label: 'Fav',
                        backgroundColor: const Color(0xff22012c),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
