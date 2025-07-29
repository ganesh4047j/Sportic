// ignore_for_file: unused_import, avoid_web_libraries_in_flutter, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:sports/Main%20Screens/booking_turf.dart';
import 'package:sports/Main%20Screens/location.dart';
import 'package:sports/Main%20Screens/profile.dart';
import 'package:sports/Main%20Screens/turfscreen.dart';
import 'package:sports/Providers/mvp_providers.dart';
import 'package:sports/Providers/turfscreen_provider.dart';
import '../Create Team/create_team.dart';
import '../Services/privacy_policy_service.dart';
import 'category.dart';
import 'favourites.dart';
import 'live_screen.dart';
import 'mvp.dart';
import 'package:shared_preferences/shared_preferences.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

final sportsProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'image': 'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'text': 'Football'
    },
    {
      'image': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'text': 'Cricket'
    },
    {
      'image': 'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'text': 'Tennis'
    },
    {
      'image': 'https://images.unsplash.com/photo-1594736797933-d0ceeb6d2d18?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'text': 'Badminton'
    },
    {
      'image': 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'text': 'Pickle Ball'
    },
  ];
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sportsAsync = ref.watch(sportsProvider);
    final turfAsync = ref.watch(turfListProvider);

    const mainImage =
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2670&q=80';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedLocation = prefs.getString('user_location');
      if (savedLocation != null) {
        ref.read(userLocationProvider.notifier).state = savedLocation;
      }
    });

    Widget _buildSection_recent(
        String title,
        List<TurfModel> turfList,
        Color titleColor,
        ) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [titleColor, titleColor.withOpacity(0.7)],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: GoogleFonts.robotoSlab(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: turfList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final turf = turfList[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Opacity(
                            opacity: value,
                            child: Hero(
                              tag: 'turf_${turf.name}_$index',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            BookingPage(
                                              turfImages: turf.imageUrl,
                                              turfName: turf.name,
                                              location: turf.location,
                                              owner_id: turf.ownerId,
                                            ),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeInOutCubic,
                                            )),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF452152).withOpacity(0.3),
                                          const Color(0xFF3D1A4A).withOpacity(0.5),
                                          const Color(0xFF200D28).withOpacity(0.7),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: const Color(0xff979698).withOpacity(0.6),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF452152).withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      width: 320,
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: ShaderMask(
                                                shaderCallback: (bounds) => LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.1),
                                                  ],
                                                ).createShader(bounds),
                                                child: Image.network(
                                                  turf.imageUrl.isNotEmpty
                                                      ? turf.imageUrl
                                                      : 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                                                  height: 160,
                                                  width: 280,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    turf.name,
                                                    style: GoogleFonts.robotoSlab(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFFFFD700),
                                                        Color(0xFFFFA500),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '4.8',
                                                        style: GoogleFonts.robotoSlab(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF452152).withOpacity(0.3),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: Colors.white70,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    turf.location,
                                                    style: GoogleFonts.robotoSlab(
                                                      color: Colors.white70,
                                                      fontWeight: FontWeight.w500,
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
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildSection_top_rating_turf(
        String title,
        List<TurfModel> turfList,
        Color titleColor,
        ) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [titleColor, titleColor.withOpacity(0.7)],
                ).createShader(bounds),
                child: Text(
                  title,
                  style: GoogleFonts.robotoSlab(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 340,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: turfList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final turf = turfList[index];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 800 + (index * 150)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: _buildEnhancedTurfCard(context, turf, index),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildSection_nearest_turf(
        String title,
        AsyncValue<List<Map<String, String>>> sportsAsync,
        Color titleColor,
        ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [titleColor, titleColor.withOpacity(0.7)],
              ).createShader(bounds),
              child: Text(
                title,
                style: GoogleFonts.robotoSlab(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 340,
            child: sportsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF452152),
                  ),
                ),
              ),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (sports) {
                if (sports.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF452152).withOpacity(0.3),
                            const Color(0xFF3D1A4A).withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No nearest turf available for your location.',
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: sports.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final turf = sports[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: Opacity(
                            opacity: value,
                            child: _buildNearestTurfCard(context, turf, index),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildHeader(ref, context),
                    ),
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildHeroImage(mainImage),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFD1C4E9)],
                        ).createShader(bounds),
                        child: Text(
                          'Sports',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildSportsCards(sportsAsync, context),
                    ),
                    const SizedBox(height: 30),
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildStartPlayingCard(context),
                    ),
                    const SizedBox(height: 30),
                    _buildActionCards(context),
                    const SizedBox(height: 30),
                    _buildSection_recent(
                      'Recent',
                      turfAsync,
                      const Color(0xFFE1BEE7),
                    ),
                    const SizedBox(height: 20),
                    _buildSection_top_rating_turf(
                      'Top Rating Turf',
                      turfAsync,
                      const Color(0xFFCE93D8),
                    ),
                    const SizedBox(height: 20),
                    Consumer(
                      builder: (context, ref, _) {
                        final nearestTurfs = ref.watch(nearestTurfProvider);
                        final asyncTurfs = AsyncValue.data(
                          nearestTurfs
                              .map((turf) => {
                            'name': turf['name']!,
                            'imageUrl': turf['imageUrl']!,
                            'location': turf['location']!,
                            'ownerId': turf['ownerId']!,
                          })
                              .toList(),
                        );

                        return _buildSection_nearest_turf(
                          'Nearest Turf',
                          asyncTurfs,
                          const Color(0xFFBA68C8),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildFooter(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              onTap: (index) => ref.read(navIndexProvider.notifier).state = index,
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
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                  backgroundColor: Color(0xff22012c),
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
                          builder: (context) => const CenterLottieScreen(),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FollowingScreen(),
                        ),
                      );
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
    );
  }

  Widget _buildEnhancedTurfCard(BuildContext context, TurfModel turf, int index) {
    return Hero(
      tag: 'turf_top_${turf.name}_$index',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    BookingPage(
                      turfImages: turf.imageUrl,
                      turfName: turf.name,
                      location: turf.location,
                      owner_id: turf.ownerId,
                    ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6A1B9A).withOpacity(0.4),
                  const Color(0xFF4A148C).withOpacity(0.6),
                  const Color(0xFF1A0E2E).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            turf.imageUrl.isNotEmpty
                                ? turf.imageUrl
                                : 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                            height: 160,
                            width: 280,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'TOP RATED',
                              style: GoogleFonts.robotoSlab(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            turf.name,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: GoogleFonts.robotoSlab(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF452152).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            turf.location,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildNearestTurfCard(BuildContext context,Map<String, String> turf, int index) {
    final name = turf['name'] ?? 'Turf';
    final imageUrl = turf['imageUrl'] ??
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
    final location = turf['location'] ?? 'Unknown';

    return Hero(
      tag: 'turf_nearest_${name}_$index',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    BookingPage(
                      turfImages: turf['imageUrl']!,
                      turfName: turf['name']!,
                      location: turf['location']!,
                      owner_id: turf['ownerId']!,
                    ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutQuart,
                    )),
                    child: child,
                  );
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF7B1FA2).withOpacity(0.3),
                  const Color(0xFF4A148C).withOpacity(0.6),
                  const Color(0xFF1A0E2E).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF7B1FA2).withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            imageUrl,
                            height: 160,
                            width: 280,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'NEARBY',
                                  style: GoogleFonts.robotoSlab(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: GoogleFonts.robotoSlab(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
      data: (profile) {
        final globalLocation = ref.watch(userLocationProvider);
        final location = globalLocation ?? profile['location'] ?? 'Unknown';
        final imageUrl = profile['photoUrl'] ?? 'https://i.pravatar.cc/300';

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                      const LocationInputScreen(shouldRedirectToHome: true),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          )),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your location",
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFFE91E63),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFD700).withOpacity(0.3),
                                const Color(0xFFFFA500).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                  const MvpPage(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return ScaleTransition(
                                      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                                        CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                                      ),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  RotationTransition(
                                    turns: _rotationAnimation,
                                    child: const Icon(
                                      Icons.emoji_events,
                                      color: Color(0xFFFFD700),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final points = ref.watch(mvpPointsProvider);
                                      return Text(
                                        '$points pts',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                          const ProfileScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOutCubic,
                                )),
                                child: child,
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE91E63),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroImage(String imageUrl) {
    return Container(
      height: 220,
      child: Stack(
        children: [
          Card(
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF452152),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.error, color: Colors.white));
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME TO SPORTIC',
                          style: GoogleFonts.robotoSlab(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your ultimate sports community platform',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.robotoSlab(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

  Widget _buildSportsCards(
      AsyncValue<List<Map<String, String>>> sportsAsync,
      BuildContext context,
      ) {
    final List<List<Color>> cardGradients = [
      [const Color(0xFFE1BEE7), const Color(0xFFCE93D8)],
      [const Color(0xFFFFCC80), const Color(0xFFFF8A65)],
      [const Color(0xFF81D4FA), const Color(0xFF4FC3F7)],
      [const Color(0xFFC8E6C9), const Color(0xFF81C784)],
      [const Color(0xFFD1C4E9), const Color(0xFFBA68C8)],
    ];

    return SizedBox(
      height: 180,
      child: sportsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF452152)),
          ),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (sports) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: sports.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 800 + (index * 200)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(50 * (1 - value), 0),
                    child: Transform.scale(
                      scale: 0.85 + (0.15 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2.5,
                          margin: const EdgeInsets.only(right: 16),
                          child: Hero(
                            tag: 'sport_${sports[index]['text']}_$index',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                      const HomePage(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                                              CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: cardGradients[index % cardGradients.length],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cardGradients[index % cardGradients.length][0].withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Background Image with Parallax Effect
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: TweenAnimationBuilder<double>(
                                            duration: Duration(milliseconds: 1000 + (index * 100)),
                                            tween: Tween(begin: 1.2, end: 1.0),
                                            builder: (context, scaleValue, child) {
                                              return Transform.scale(
                                                scale: scaleValue,
                                                child: Image.network(
                                                  sports[index]['image']!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: cardGradients[index % cardGradients.length],
                                                          ),
                                                          borderRadius: BorderRadius.circular(24),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.sports,
                                                            color: Colors.white,
                                                            size: 40,
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      // Gradient Overlay
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(24),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.3),
                                                Colors.black.withOpacity(0.7),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Animated Content
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: TweenAnimationBuilder<double>(
                                          duration: Duration(milliseconds: 1200 + (index * 150)),
                                          tween: Tween(begin: 50.0, end: 0.0),
                                          builder: (context, translateValue, child) {
                                            return Transform.translate(
                                              offset: Offset(0, translateValue),
                                              child: Container(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Sport Icon with Bounce Animation
                                                    TweenAnimationBuilder<double>(
                                                      duration: Duration(milliseconds: 1500 + (index * 100)),
                                                      tween: Tween(begin: 0.0, end: 1.0),
                                                      curve: Curves.elasticOut,
                                                      builder: (context, bounceValue, child) {
                                                        return Transform.scale(
                                                          scale: bounceValue,
                                                          child: Container(
                                                            padding: const EdgeInsets.all(12),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withOpacity(0.9),
                                                              borderRadius: BorderRadius.circular(16),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors.black.withOpacity(0.2),
                                                                  blurRadius: 8,
                                                                  offset: const Offset(0, 4),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Icon(
                                                              _getSportIcon(sports[index]['text']!),
                                                              color: cardGradients[index % cardGradients.length][1],
                                                              size: 32,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(height: 12),
                                                    // Text with Fade Animation
                                                    TweenAnimationBuilder<double>(
                                                      duration: Duration(milliseconds: 1000 + (index * 200)),
                                                      tween: Tween(begin: 0.0, end: 1.0),
                                                      builder: (context, fadeValue, child) {
                                                        return Opacity(
                                                          opacity: fadeValue,
                                                          child: Text(
                                                            sports[index]['text']!,
                                                            style: GoogleFonts.poppins(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                              shadows: [
                                                                Shadow(
                                                                  color: Colors.black.withOpacity(0.5),
                                                                  blurRadius: 4,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      // Shimmer Effect on Hover
                                      Positioned.fill(
                                        child: TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 2000),
                                          tween: Tween(begin: -1.0, end: 1.0),
                                          curve: Curves.easeInOut,
                                          builder: (context, shimmerValue, child) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(24),
                                                gradient: LinearGradient(
                                                  begin: Alignment(-1.0 + shimmerValue, -1.0 + shimmerValue),
                                                  end: Alignment(1.0 + shimmerValue, 1.0 + shimmerValue),
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.white.withOpacity(0.1),
                                                    Colors.transparent,
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
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
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'cricket':
        return Icons.sports_cricket;
      case 'tennis':
        return Icons.sports_tennis;
      case 'badminton':
        return Icons.sports_kabaddi;
      case 'pickle ball':
        return Icons.sports_baseball;
      default:
        return Icons.sports;
    }
  }

  Widget _buildStartPlayingCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7B1FA2).withOpacity(0.3),
                    const Color(0xFF4A148C).withOpacity(0.5),
                    const Color(0xFF1A0E2E).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF7B1FA2).withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B1FA2).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'START PLAYING!',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invent A Game',
                                style: GoogleFonts.robotoSlab(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your schedule is currently empty.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                  const CreateTeamScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 1.0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOutBack,
                                      )),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Create',
                                  style: GoogleFonts.robotoSlab(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'See My Schedule',
                              style: GoogleFonts.robotoSlab(
                                fontSize: 14,
                                color: Colors.white70,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildActionCards(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Play',
                    'Discover players and join their games',
                    Icons.people,
                    const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                    ),
                        () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                        const HomePage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                              ),
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Book',
                    'Book your slots in venues nearby you',
                    Icons.book_online,
                    const LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
                    ),
                        () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                        const TurfHomeScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            )),
                            child: child,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Gradient gradient,
      VoidCallback onTap,
      ) {
    return Hero(
      tag: 'action_$title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
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

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7B1FA2).withOpacity(0.3),
                        const Color(0xFF4A148C).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Follow us on',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 18,
                          color: const Color(0xFFE1BEE7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          _buildSocialButton(
                            FontAwesomeIcons.instagram,
                            const Color(0xFFE91E63),
                                () {},
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildSocialButton(
                            FontAwesomeIcons.facebook,
                            const Color(0xFF3F51B5),
                                () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7B1FA2).withOpacity(0.4),
                const Color(0xFF4A148C).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
                ).createShader(bounds),
                child: Text(
                  'SPORTIC',
                  style: GoogleFonts.robotoSerif(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'THE FIELD AWAITS',
                style: GoogleFonts.robotoSlab(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE1BEE7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Your Sports Community app',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFFBBA3C3),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const PrivacyTermsPopup(),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Privacy Policy  •  Terms of Service',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Image.asset(
                  'assets/images/sportsman.png',
                  height: 180,
                  width: 160,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7B1FA2).withOpacity(0.3),
                          const Color(0xFF4A148C).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.sports,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: FaIcon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }
}