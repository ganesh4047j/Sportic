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
import '../Providers/turfscreen_provider.dart';

class TurfHomeScreen extends ConsumerStatefulWidget {
  const TurfHomeScreen({super.key});

  @override
  ConsumerState<TurfHomeScreen> createState() => _TurfHomeScreenState();
}

class _TurfHomeScreenState extends ConsumerState<TurfHomeScreen> {
  final selectedDate = ValueNotifier<DateTime>(DateTime.now());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final turfList = ref.watch(turfListProvider);
    final turfList = ref.watch(filteredTurfListProvider);

    final navIndex = ref.watch(turfNavIndexProvider);
    final query = ref.watch(searchTurfProvider).toLowerCase();

    final filteredTurfs = query.isEmpty
        ? turfList
        : turfList
              .where((turf) => turf.name.toLowerCase().contains(query))
              .toList();
    // final turfListState = ref.watch(filteredTurfListProvider);
    // final selectedFilter = ref.watch(selectedFilterProvider);
    // final query = ref.watch(searchTurfProvider);
    //
    // final filteredTurfs = turfListState.when(
    //   data: (turfs) {
    //     final queryLower = query.trim().toLowerCase();
    //     final filterLower = selectedFilter.trim().toLowerCase();
    //
    //     return turfs.where((turf) {
    //       final matchesFilter = filterLower == 'all sports' ||
    //           turf.sports.any((sport) => sport.toLowerCase() == filterLower);
    //
    //       final matchesSearch = turf.name.toLowerCase().contains(queryLower);
    //
    //       return matchesFilter && matchesSearch;
    //     }).toList();
    //   },
    //   loading: () => [],
    //   error: (_, __) => [],
    // );
    //


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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final userProfileAsync = ref.watch(userProfileProvider);

                        return userProfileAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                          data: (profile) {
                            final globalLocation = ref.watch(
                              userLocationProvider,
                            );
                            final location =
                                globalLocation ??
                                profile['location'] ??
                                'Unknown';
                            final imageUrl =
                                profile['photoUrl'] ??
                                'https://i.pravatar.cc/300';

                            return Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LocationInputScreen(
                                                shouldRedirectToHome: false,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Your location",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                          ),
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
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ProfileScreen(),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(imageUrl),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(searchTurfProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Search your 'Turfs'",
                    hintStyle: GoogleFonts.cutive(color: Colors.black),
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 16),

                // Filter header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "All Turfs",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(Icons.tune, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),

                // Date picker and filter chips
                Row(
                  children: [
                    ValueListenableBuilder<DateTime>(
                      valueListenable: selectedDate,
                      builder: (context, value, _) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE60073),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) {
                                return SizedBox(
                                  height: 300,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          "Select Date",
                                          style: GoogleFonts.cutive(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ScrollDatePicker(
                                          selectedDate: selectedDate.value,
                                          minimumDate: DateTime(
                                            DateTime.now().year,
                                          ),
                                          maximumDate: DateTime(
                                            DateTime.now().year + 10,
                                          ),
                                          locale: const Locale('en'),
                                          onDateTimeChanged: (date) =>
                                              selectedDate.value = date,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          "Done",
                                          style: GoogleFonts.cutive(
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                '${value.day}-${value.month}-${value.year}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('|', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final label in [
                              'All Sports',
                              'Cricket',
                              'Football',
                              'Tennis',
                              'Badminton',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(
                                    label,
                                    style: TextStyle(
                                      color:
                                          ref.watch(selectedFilterProvider) ==
                                              label
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selected:
                                      ref.watch(selectedFilterProvider) ==
                                      label,
                                  onSelected: (_) =>
                                      ref
                                              .read(
                                                selectedFilterProvider.notifier,
                                              )
                                              .state =
                                          label,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: Colors.white,
                                  selectedColor: Colors.green,
                                  side: const BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Turf list
                Expanded(
                  child: filteredTurfs.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Lottie.asset(
                                  'assets/empty.json',
                                  height: 300,
                                  width: 300,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No turfs found for your search.',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemCount: filteredTurfs.length,
                          itemBuilder: (context, index) {
                            final turf = filteredTurfs[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BookingPage(),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        turf.name,
                                        style: GoogleFonts.robotoSlab(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.yellow,
                                            size: 20,
                                          ),
                                          Text(
                                            '4.8',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            '[4]',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          turf.imageUrl,
                                          width: double.infinity,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          icon: Icon(
                                            turf.isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => ref
                                              .read(turfListProvider.notifier)
                                              .toggleFavorite(turf.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        turf.sport,
                                        style: GoogleFonts.cutive(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.local_offer_outlined,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
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

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
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
          onTap: (index) =>
              ref.read(turfNavIndexProvider.notifier).state = index,
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                ),
                icon: const Icon(Icons.home),
              ),
              label: 'Home',
              backgroundColor: const Color(0xff22012c),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.sports_soccer),
              label: 'Turf',
              backgroundColor: const Color(0xff22012c),
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CenterLottieScreen(),
                  ),
                ),
                icon: const Icon(Icons.live_tv),
              ),
              label: 'Live',
              backgroundColor: const Color(0xff22012c),
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed: () => Navigator.push(
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
                onPressed: () => Navigator.push(
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
      ),
    );
  }
}
