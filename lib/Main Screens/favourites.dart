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

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  final TextEditingController _searchController = TextEditingController();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Favourites',
                      style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar (no mic)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                          style: GoogleFonts.cutive(
                            // 👈 font for user input
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Search your ‘turf’",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  "See My team",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: DefaultTextStyle(
                  style: GoogleFonts.poppins(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText('Explore your favorite turfs...'),
                      TyperAnimatedText('Join your team now...'),
                      TyperAnimatedText('Start a match anytime!'),
                    ],
                    repeatForever: true,
                    pause: const Duration(milliseconds: 800),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredTurfs.length,
                  itemBuilder: (context, index) {
                    final turf = filteredTurfs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xff330849),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: CachedNetworkImageProvider(
                                turf.imageUrl,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                turf.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap:
                                  () => debugPrint(
                                    "Tapped chat with ${turf.name}",
                                  ),
                              child: const AnimatedScale(
                                scale: 1.1,
                                duration: Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation Bar
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
                        icon: Icon(Icons.home),
                      ),
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
    );
  }
}
