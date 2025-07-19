import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports/Main%20Screens/mvp_vote.dart';
import 'leaderboard.dart';

class MvpPage extends StatefulWidget {
  const MvpPage({super.key});

  @override
  State<MvpPage> createState() => _MvpPageState();
}

class _MvpPageState extends State<MvpPage> {
  String selectedTab = 'recent';

  final TextEditingController turfController = TextEditingController(
    text: 'Sportic',
  );
  String? selectedGame;
  String? selectedPosition;

  final List<String> games = [
    'Cricket',
    'Football',
    'Badminton',
    'Volleyball',
    'Basketball',
  ];

  final List<String> positions = [
    'Batsman',
    'Striker',
    'Goalkeeper',
    'Bowler',
    'Wicket Keeper',
  ];

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "MVP",
                          style: GoogleFonts.robotoSlab(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade400,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.6),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "Leaderboard",
                          style: GoogleFonts.robotoSlab(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// Profile
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/300',
                        ),
                        backgroundColor: Colors.white24,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Hariharan S",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "MVP points = +250 🪙",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Info Card
                Card(
                  color: const Color(0xFF452152),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.white38),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                                height: 24,
                                width: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Get MVP points",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  "    to play &",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  "vote teammate",
                                  style: GoogleFonts.cutive(
                                    color: Colors.white,
                                    fontSize: 20,
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

                const SizedBox(height: 20),

                /// Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: selectedTab == 'recent'
                            ? Color(0xff8a23ea)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedTab = 'recent';
                        });
                      },
                      child: Text(
                        "Recent match",
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 30, color: Color(0xffffffff)),
                    const SizedBox(width: 12),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: selectedTab == 'previous'
                            ? Color(0xff8a23ea)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedTab = 'previous';
                        });
                      },
                      child: Text(
                        "Previous match",
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.white,
                ),

                const SizedBox(height: 20),

                selectedTab == 'recent'
                    ? buildRecentMatchForm()
                    : buildPreviousMatchCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget for Previous Match UI
  Widget buildPreviousMatchCards() {
    final matches = [
      {
        'image': 'https://img.icons8.com/color/2x/soccer-field.png',
        'title': 'Js brothers turf',
        'slot': 'Dec 12, 7pm - 9pm',
      },
      {
        'image': 'https://img.icons8.com/color/2x/basketball.png',
        'title': 'Spotic turf',
        'slot': 'Dec 12, 8pm - 9pm',
      },
      {
        'image': 'https://img.icons8.com/color/2x/football2.png',
        'title': 'Champion turf',
        'slot': 'Dec 12, 6pm - 9pm',
      },
      {
        'image': 'https://img.icons8.com/color/2x/volleyball.png',
        'title': 'Turf hub',
        'slot': 'Dec 12, 7pm - 10pm',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Previous game",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 10),
        ...matches.map((match) {
          return Card(
            color: const Color(0xff311e3e),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.white38),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(match['image']!),
              ),
              title: Text(
                match['title']!,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              subtitle: Text(
                'Slot: ${match['slot']}',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  "View",
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Widget for Recent Match Form
  Widget buildRecentMatchForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose Player",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        /// Card with form
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 60),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                /// Main Form Card
                Card(
                  color: const Color(0xFF2E1440),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white38),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Turf Name
                        TextField(
                          controller: turfController,
                          keyboardType: TextInputType.text,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Turf name',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF3A1C4D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              // explicitly remove underline
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              // also remove on focus
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        /// Game Type Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedGame ?? 'Cricket',
                          dropdownColor: const Color(0xFF3A1C4D),
                          decoration: InputDecoration(
                            labelText: 'Game type',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF3A1C4D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          iconEnabledColor: Colors.white,
                          style: GoogleFonts.poppins(color: Colors.white),
                          items: games.map((String game) {
                            return DropdownMenuItem<String>(
                              value: game,
                              child: Text(game),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedGame = value;
                            });
                          },
                        ),

                        const SizedBox(height: 15),

                        /// Best Player Position Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedPosition,
                          dropdownColor: const Color(0xFF3A1C4D),
                          decoration: InputDecoration(
                            labelText: 'Best player position',
                            labelStyle: GoogleFonts.inter(color: Colors.white),
                            filled: true,
                            fillColor: const Color(0xFF3A1C4D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(color: Colors.white),
                          items: positions.map((String pos) {
                            return DropdownMenuItem<String>(
                              value: pos,
                              child: Text(pos),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedPosition = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        /// Turf Rating Row
                        Row(
                          children: [
                            Text(
                              "Turf rating:",
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.star, color: Color(0xffffd537)),
                            Icon(Icons.star, color: Color(0xffffd537)),
                            Icon(Icons.star, color: Color(0xffffd537)),
                            Icon(Icons.star, color: Color(0xffffd537)),
                            Icon(Icons.star_border, color: Color(0xffffd537)),
                            SizedBox(width: 10),
                            Text("4.0", style: TextStyle(color: Colors.amber)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                /// Floating Continue Button
                Positioned(
                  bottom: -20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // Continue logic here
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Mvp_VotePage(),
                            ),
                          );
                        },
                        child: Text(
                          "Continue",
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
