// // lib/category.dart
// // ignore_for_file: avoid_print, unused_element, unused_local_variable
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:sportic/Main%20Screens/favourites.dart';
//
// import 'package:sportic/Main%20Screens/turfscreen.dart';
// import '../Providers/category_providers.dart';
// import 'create_team.dart';
// import 'join_team.dart';
// import 'package:sportic/Main%20Screens/live_screen.dart';
//
// final navIndexProvider = StateProvider<int>((ref) => 3);
//
// class HomePage extends ConsumerWidget {
//   const HomePage({super.key});
//
//   final List<String> imageUrls = const [
//     "https://th.bing.com/th/id/OIP.e2P3ReDBMC5G87UnoHrt3wHaEM?w=280&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
//     "https://th.bing.com/th/id/OIP.J6biGVVwvFxtGztUncZmqgHaEo?w=290&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
//     "https://th.bing.com/th/id/OIP.ij1w9viY0dwNTdrLg6IlVwHaE7?w=289&h=192&c=7&r=0&o=5&dpr=1.3&pid=1.7",
//     "https://th.bing.com/th/id/OIP.GFp3tlXRClkjYMCUvUSenwHaEK?w=286&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
//     "https://th.bing.com/th/id/OIP.4HrBm_oZDCClrJzwvT9GaAHaEJ?w=312&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
//   ];
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final selectedIndex = ref.watch(selectedIndexProvider);
//     final matchDetails = ref.watch(matchDetailsProvider);
//
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFF452152),
//               Color(0xFF3D1A4A),
//               Color(0xFF200D28),
//               Color(0xFF1B0723),
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(
//                       Icons.arrow_back,
//                       color: Colors.white,
//                       size: 26,
//                     ),
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     "Games",
//                     style: GoogleFonts.robotoSlab(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 22,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: imageUrls.length,
//                 itemBuilder: (context, index) {
//                   return Column(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(25.0),
//                         child: SizedBox(
//                           height: 180,
//                           width: double.infinity,
//                           child: Card(
//                             elevation: 5,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(40),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(40),
//                               child: Image.network(
//                                 imageUrls[index],
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       _DropdownCardSection(
//                         cardIndex: index,
//                         details: matchDetails[index],
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Container(
//         decoration: const BoxDecoration(
//           color: Color(0xff22012c),
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(30),
//             topRight: Radius.circular(30),
//           ),
//         ),
//         child: BottomNavigationBar(
//           backgroundColor: Colors.transparent,
//           type: BottomNavigationBarType.shifting,
//           currentIndex: ref.watch(navIndexProvider),
//           onTap: (index) => ref.read(navIndexProvider.notifier).state = index,
//           selectedItemColor: Colors.pink,
//           unselectedItemColor: Colors.white,
//
//           selectedLabelStyle: GoogleFonts.outfit(
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//           unselectedLabelStyle: GoogleFonts.outfit(
//             fontWeight: FontWeight.normal,
//             fontSize: 12,
//           ),
//
//           items: [
//             const BottomNavigationBarItem(
//               icon: Icon(Icons.home),
//               label: 'Home',
//               backgroundColor: Color(0xff22012c),
//             ),
//             BottomNavigationBarItem(
//               icon: IconButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const TurfHomeScreen(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.sports_soccer),
//               ),
//               label: 'Turf',
//               backgroundColor: const Color(0xff22012c),
//             ),
//             BottomNavigationBarItem(
//               icon: IconButton(
//                 onPressed: () {
//                   print('Live button clicked');
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CenterLottieScreen(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.live_tv),
//               ),
//               label: 'Live',
//               backgroundColor: const Color(0xff22012c),
//             ),
//             BottomNavigationBarItem(
//               icon: IconButton(
//                 onPressed: () {
//                   print('Games button clicked');
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const HomePage()),
//                   );
//                 },
//                 icon: const Icon(Icons.videogame_asset),
//               ),
//               label: 'Games',
//               backgroundColor: const Color(0xff22012c),
//             ),
//             BottomNavigationBarItem(
//               icon: IconButton(
//                 onPressed: () {
//                   print('Fav button clicked');
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const FollowingScreen(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.favorite),
//               ),
//               label: 'Fav',
//               backgroundColor: const Color(0xff22012c),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavItem(
//     WidgetRef ref,
//     BuildContext context,
//     IconData icon,
//     String label,
//     int index,
//     int selectedIndex,
//   ) {
//     final isSelected = selectedIndex == index;
//     final color = isSelected ? Colors.orange : Colors.white;
//
//     return GestureDetector(
//       onTap: () {
//         if (index == 1) {
//           //Navigator.push(
//           //context,
//           //MaterialPageRoute(builder: (context) => BookingPage()),
//           //);
//         } else {
//           ref.read(selectedIndexProvider.notifier).state = index;
//         }
//       },
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: GoogleFonts.poppins(
//               color: color,
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _DropdownCardSection extends ConsumerWidget {
//   final int cardIndex;
//   final Map<String, String> details;
//
//   const _DropdownCardSection({required this.cardIndex, required this.details});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final isExpanded = ref.watch(cardExpansionProvider(cardIndex));
//
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 18.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const JoinTeamPage(),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xffD72664),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 10,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: Text(
//                   "Join Team",
//                   style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CreateTeamScreen(),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xff6624b5),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 10,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: Text(
//                   "Create Team",
//                   style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         IconButton(
//           onPressed: () {
//             final current = ref.read(cardExpansionProvider(cardIndex));
//             ref.read(cardExpansionProvider(cardIndex).notifier).state =
//                 !current;
//           },
//           icon: Icon(
//             isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//             color: Colors.white,
//             size: 30,
//           ),
//         ),
//         if (isExpanded)
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 20.0,
//               vertical: 8.0,
//             ),
//             child: Card(
//               color: Color(0xFF452152),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: Text(
//                         "(${details['sport']})",
//                         style: GoogleFonts.poppins(
//                           fontStyle: FontStyle.italic,
//                           fontSize: 16,
//                           color: Color(0xffffffff),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       "Turf name: ${details['turfName']}",
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 18,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "Slot timing: ${details['timing']}",
//                       style: GoogleFonts.poppins(
//                         fontSize: 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Text(
//                       "Creator name: ${details['creator']}",
//                       style: GoogleFonts.poppins(
//                         fontSize: 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Text(
//                       "Need players: ${details['players']}",
//                       style: GoogleFonts.poppins(
//                         fontSize: 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// lib/category.dart
// ignore_for_file: avoid_print, unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports/Main%20Screens/favourites.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sports/Main%20Screens/home.dart';
import 'package:sports/Main%20Screens/turfscreen.dart';
import '../Providers/category_providers.dart';
import 'create_team.dart';
import 'join_team.dart';
import 'package:sports/Main%20Screens/live_screen.dart';

final navIndexProvider = StateProvider<int>((ref) => 3);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  final List<String> imageUrls = const [
    "https://th.bing.com/th/id/OIP.e2P3ReDBMC5G87UnoHrt3wHaEM?w=280&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
    "https://th.bing.com/th/id/OIP.J6biGVVwvFxtGztUncZmqgHaEo?w=290&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
    "https://th.bing.com/th/id/OIP.ij1w9viY0dwNTdrLg6IlVwHaE7?w=289&h=192&c=7&r=0&o=5&dpr=1.3&pid=1.7",
    "https://th.bing.com/th/id/OIP.GFp3tlXRClkjYMCUvUSenwHaEK?w=286&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
    "https://th.bing.com/th/id/OIP.4HrBm_oZDCClrJzwvT9GaAHaEJ?w=312&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final matchDetails = ref.watch(matchDetailsProvider);

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Games",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                      ScaleEffect(),
                    ],
                    child: Column(
                      children: [
                        Container(
                          height: 190,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(
                              image: NetworkImage(imageUrls[index]),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.2),
                                BlendMode.darken,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        Animate(
                          effects: [SlideEffect(duration: 300.ms)],
                          child: _DropdownCardSection(
                            cardIndex: index,
                            details: matchDetails[index],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
            BottomNavigationBarItem(
                icon: IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen())),
                  icon: Icon(Icons.home),
                ),
                label: 'Home',
                backgroundColor: const Color(0xff22012c)),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TurfHomeScreen(),
                      ),
                    ),
                icon: const Icon(Icons.sports_soccer),
              ),
              label: 'Turf',
              backgroundColor: const Color(0xff22012c),
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed:
                    () => Navigator.push(
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
              //icon: IconButton(
               // onPressed:
               //     () => Navigator.push(
                //      context,
                //      MaterialPageRoute(builder: (context) => const HomePage()),
               //     ),
                icon: const Icon(Icons.videogame_asset),
              //),
              label: 'Games',
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
      ),
    );
  }
}

class _DropdownCardSection extends ConsumerWidget {
  final int cardIndex;
  final Map<String, String> details;

  const _DropdownCardSection({required this.cardIndex, required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(cardExpansionProvider(cardIndex));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinTeamPage(),
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffD72664),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.group, color: Colors.white),
              label: Text(
                "Join Team",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTeamScreen(),
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6624b5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: Text(
                "Create Team",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        IconButton(
          onPressed:
              () =>
                  ref.read(cardExpansionProvider(cardIndex).notifier).state =
                      !isExpanded,
          icon: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 28,
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Card(
              color: const Color(0xFF3D1A4A),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "(${details['sport']})",
                        style: GoogleFonts.poppins(
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Turf name: ${details['turfName']}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Slot timing: ${details['timing']}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Creator name: ${details['creator']}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Need players: ${details['players']}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
