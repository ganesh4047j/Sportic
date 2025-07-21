// ignore_for_file: unused_import, avoid_web_libraries_in_flutter, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:sports/Main%20Screens/booking_turf.dart';
import 'package:sports/Main%20Screens/create_team.dart';
import 'package:sports/Main%20Screens/location.dart';
import 'package:sports/Main%20Screens/profile.dart';
import 'package:sports/Main%20Screens/turfscreen.dart';
import 'package:sports/Providers/mvp_providers.dart';
import 'package:sports/Providers/turfscreen_provider.dart';
import '../Services/privacy_policy_service.dart';
import 'category.dart';
import 'favourites.dart';
import 'live_screen.dart';
import 'mvp.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

final sportsProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {'image': 'assets/images/football_pic.png', 'text': 'Football'},
    {'image': 'assets/images/cricket_pic.png', 'text': 'Cricket'},
    {'image': 'assets/images/tennis_pic.png', 'text': 'Tennis'},
    {'image': '/images/badminton.png', 'text': 'Badminton'},
    {'image': '/images/pickleball.png', 'text': 'Pickle Ball'},
  ];
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsAsync = ref.watch(sportsProvider);
    const mainImage =
        'https://static.vecteezy.com/system/resources/previews/044/547/673/non_2x/lawn-on-a-football-field-photo.jpeg';

    Widget _buildSection_recent(
      String title,
      AsyncValue<List<Map<String, String>>> sportsAsync,
      Color titleColor,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: GoogleFonts.robotoSlab(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ),
          SizedBox(
            height: 320,
            child: sportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (sports) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sports.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xff979698), // border color
                        width: 3.5, // border width
                      ),
                      borderRadius: BorderRadius.circular(30), // optional
                    ),
                    child: SizedBox(
                      width: 320,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            children: [
                              Image.network(
                                'https://th.bing.com/th/id/OIP.aas8P8RzXE8VGyo-cHSuNwHaEK?w=316&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7',
                                height: 150,
                                width: 260,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Turf 1',
                                    style: GoogleFonts.robotoSlab(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.yellow,
                                        size: 20,
                                      ),
                                      Text(
                                        '4.8',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                      Text(
                                        '(30)',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.location_on_outlined,
                                    ),
                                    color: Colors.white,
                                    iconSize: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {},
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                      ),
                                      child: Text(
                                        '2/11, Madurai \n main road, Lalgudi',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                },
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildSection_top_rating_turf(
      String title,
      AsyncValue<List<Map<String, String>>> sportsAsync,
      Color titleColor,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: GoogleFonts.robotoSlab(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ),
          SizedBox(
            height: 320,
            child: sportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (sports) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sports.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xff979698), // border color
                        width: 3.5, // border width
                      ),
                      borderRadius: BorderRadius.circular(30), // optional
                    ),
                    child: SizedBox(
                      width: 320,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            children: [
                              Image.network(
                                'https://th.bing.com/th/id/OIP.aas8P8RzXE8VGyo-cHSuNwHaEK?w=316&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7',
                                height: 150,
                                width: 260,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Turf 2',
                                    style: GoogleFonts.robotoSlab(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.yellow,
                                        size: 20,
                                      ),
                                      Text(
                                        '4.8',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                      Text(
                                        '(30)',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.location_on_outlined,
                                    ),
                                    color: Colors.white,
                                    iconSize: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {},
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                      ),
                                      child: Text(
                                        '2/11, Madurai \n main road, Lalgudi',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                },
              ),
            ),
          ),
        ],
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
            child: Text(
              title,
              style: GoogleFonts.robotoSlab(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ),
          SizedBox(
            height: 320,
            child: sportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (sports) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sports.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xff979698), // border color
                        width: 3.5, // border width
                      ),
                      borderRadius: BorderRadius.circular(30), // optional
                    ),
                    child: SizedBox(
                      width: 320,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            children: [
                              Image.network(
                                'https://th.bing.com/th/id/OIP.aas8P8RzXE8VGyo-cHSuNwHaEK?w=316&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7',
                                height: 150,
                                width: 260,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Turf 3',
                                    style: GoogleFonts.robotoSlab(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.yellow,
                                        size: 20,
                                      ),
                                      Text(
                                        '4.8',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                      Text(
                                        '(30)',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.location_on_outlined,
                                    ),
                                    color: Colors.white,
                                    iconSize: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {},
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                      ),
                                      child: Text(
                                        '2/11, Madurai \n main road, Lalgudi',
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                },
              ),
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
                padding: const EdgeInsets.all(16),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(ref, context),
                      const SizedBox(height: 16),
                      _buildHeroImage(mainImage),
                      const SizedBox(height: 16),
                      Text(
                        'Sports',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffffffff),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSportsCards(sportsAsync, context),
                      const SizedBox(height: 20),
                      _buildStartPlayingCard(context),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            },
                            child: SizedBox(
                              height: 180,
                              width: 150,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      'https://th.bing.com/th/id/OIP.jWV8UcJ8QTKvgJabvhwnDQHaE8?w=281&h=188&c=7&r=0&o=5&dpr=1.3&pid=1.7',
                                      height: 80,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 60, // Slightly below the image
                                    child: Container(
                                      height: 120,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        color: const Color(0xff400d53),
                                        borderRadius: BorderRadius.circular(
                                          20.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Play',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Discover players and join their games',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Color(0xffb1b1b1),
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
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TurfHomeScreen(),
                                ),
                              );
                            },
                            child: SizedBox(
                              height: 180,
                              width: 150,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      'https://th.bing.com/th/id/OIP.jWV8UcJ8QTKvgJabvhwnDQHaE8?w=281&h=188&c=7&r=0&o=5&dpr=1.3&pid=1.7',
                                      height: 80,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 60, // Slightly below the image
                                    child: Container(
                                      height: 120,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        color: const Color(0xff400d53),
                                        borderRadius: BorderRadius.circular(
                                          20.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Book',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Book your slots in venues nearby you',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Color(0xffb1b1b1),
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
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingPage(),
                            ),
                          );
                        },
                        child: _buildSection_recent(
                          'Recent',
                          sportsAsync,
                          const Color(0xff9b9a9a),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingPage(),
                            ),
                          );
                        },
                        child: _buildSection_top_rating_turf(
                          'Top Rating Turf',
                          sportsAsync,
                          const Color(0xffadacac),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingPage(),
                            ),
                          );
                        },
                        child: _buildSection_nearest_turf(
                          'Nearest Turf',
                          sportsAsync,
                          const Color(0xffb0aeae),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFooter(context),
                    ],
                  ),
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
              onTap: (index) =>
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
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                  backgroundColor: Color(0xff22012c),
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

  Widget _buildHeader(WidgetRef ref, BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox(),
      data: (profile) {
        final globalLocation = ref.watch(userLocationProvider);
        final location = globalLocation ?? profile['location'] ?? 'Unknown';
        //final location = ref.watch(userLocationProvider) ?? 'Unknown';

        final imageUrl = profile['photoUrl'] ?? 'https://i.pravatar.cc/300';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LocationInputScreen(shouldRedirectToHome: true),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your location",
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  Text(
                    location,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MvpPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.emoji_events,
                        color: Colors.yellow,
                        size: 22,
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final points = ref.watch(mvpPointsProvider);
                        return Text(
                          '$points pts',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: CircleAvatar(backgroundImage: NetworkImage(imageUrl)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroImage(String imageUrl) {
    return SizedBox(
      height: 200,
      child: Card(
        color: Colors.transparent,
        elevation: 14,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSportsCards(
    AsyncValue<List<Map<String, String>>> sportsAsync,
    BuildContext context,
  ) {
    final List<Color> cardColors = [
      const Color(0xffd9bce1),
      const Color(0xfff7c59f),
      const Color(0xff9ad0ec),
      const Color(0xffc1fba4),
      const Color(0xfff2a2e8),
      const Color(0xffffd6a5),
    ];
    return SizedBox(
      height: 126,
      child: sportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (sports) {
          double cardWidth =
              MediaQuery.of(context).size.width / 3; // 3 cards per view

          return SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sports.length,
              itemBuilder: (context, index) {
                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    },
                    child: Card(
                      color: cardColors[index % cardColors.length],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sports[index]['text']!,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Image.asset(
                            sports[index]['image']!,
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartPlayingCard(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0x346f228c),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 150,
                child: Card(
                  color: const Color(0x5ddcdcdc),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: Color(0x98dcdcdc),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Center(
                      child: Text(
                        'START PLAYING!',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 14,
                          color: Color(0xffd2cdcd),
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invent A Game',
                  style: GoogleFonts.robotoSlab(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    shadowColor: const Color(0xffababab),
                    backgroundColor: const Color(0xffD72664),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateTeamScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Create',
                    style: GoogleFonts.robotoSlab(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your schedule is currently empty.',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                ),
                SizedBox(height: 4),
                Divider(
                  color: Colors.white,
                  thickness: 1,
                  indent: 6,
                  endIndent: 6,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'See My Schedule',
                style: GoogleFonts.robotoSlab(
                  fontSize: 14,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 280,
              child: Card(
                color: const Color(0x809f489f),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Follow us on',
                          style: GoogleFonts.robotoSlab(
                            fontSize: 20,
                            color: Color(0xffbc9ec4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.instagram,
                          color: Colors.pink,
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '.',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.facebook,
                          color: Colors.blue,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: SizedBox(
              width: 280,
              child: Card(
                color: const Color(0x809f489f),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SPORTIC',
                          style: GoogleFonts.robotoSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffbc9ec4),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'THE FIELD AWAITS',
                          style: GoogleFonts.robotoSlab(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffbc9ec4),
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
        Center(
          child: Text(
            'Your Sports Community app',
            style: GoogleFonts.poppins(fontSize: 14, color: Color(0xffbbaac3)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const PrivacyTermsPopup(),
              );
            },
            child: Text(
              'Privacy Policy      .      Terms of Service',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Image.asset(
            'assets/images/sportsman.png',
            height: 180,
            width: 160,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.error)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
