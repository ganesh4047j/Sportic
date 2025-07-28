import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Providers/user_profile_provider.dart';
import '../Services/user_model.dart';
import '../Services/friendship_utils.dart';

class ProfileView extends ConsumerStatefulWidget {
  final String userId;
  const ProfileView({super.key, required this.userId});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final isFriendAsync = ref.watch(friendshipStatusProvider(widget.userId));
    final friendsCountAsync = ref.watch(friendsCountProvider(widget.userId));

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
        child: profileAsync.when(
          data: (user) {
            return SafeArea(
              child: NestedScrollView(
                headerSliverBuilder:
                    (_, __) => [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 30),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Text(
                                  "Player Profile",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                user.photoUrl ?? '',
                              ),
                              radius: 50,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              user.name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            // ✅ Bio Card
                            if (_isEditingBio && currentUser?.uid == user.uid)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Edit Bio",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _bioController,
                                      maxLines: null,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Enter your bio...",
                                        hintStyle: const TextStyle(
                                          color: Colors.white54,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white10,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed:
                                              () => setState(
                                                () => _isEditingBio = false,
                                              ),
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection(
                                                  user.uid.startsWith("phone")
                                                      ? 'user_details_phone'
                                                      : 'user_details_email',
                                                )
                                                .doc(user.uid)
                                                .update({
                                                  'bio':
                                                      _bioController.text
                                                          .trim(),
                                                });
                                            setState(
                                              () => _isEditingBio = false,
                                            );
                                            // ref.refresh(
                                            //   userProfileProvider(user.uid),
                                            // );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text("Save"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 10,
                                ),
                                child: Card(
                                  color: Colors.white10,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (user.bio ?? '').isNotEmpty
                                                ? user.bio!
                                                : "No bio available.",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (currentUser?.uid == user.uid)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.white70,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isEditingBio = true;
                                                _bioController.text =
                                                    user.bio ?? "";
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),
                            if (user.location != null)
                              Text(
                                user.location!,
                                style: const TextStyle(color: Colors.white54),
                              ),

                            const SizedBox(height: 10),
                            friendsCountAsync.when(
                              data:
                                  (count) => Text(
                                    '$count Friends',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                  ),
                              loading:
                                  () => const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                              error:
                                  (_, __) => const Text(
                                    "Failed to load friends",
                                    style: TextStyle(color: Colors.red),
                                  ),
                            ),
                            const SizedBox(height: 10),
                            isFriendAsync.when(
                              data: (isFriend) {
                                return isFriend
                                    ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "Friend",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                    : ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await sendFriendRequest(user.uid);
                                        ref.invalidate(
                                          friendshipStatusProvider(user.uid),
                                        );
                                      },
                                      icon: const Icon(Icons.person_add),
                                      label: const Text("Add Friend"),
                                    );
                              },
                              loading: () => const CircularProgressIndicator(),
                              error:
                                  (_, __) => const Text(
                                    "Error checking friend status",
                                  ),
                            ),
                            const SizedBox(height: 20),
                            TabBar(
                              controller: _tabController,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white38,
                              indicatorColor: Colors.white,
                              tabs: const [
                                Tab(text: "Stats"),
                                Tab(text: "Achievements"),
                                Tab(text: "Clubs"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatsTab(user),
                    _buildAchievementsTab(),
                    _buildClubsTab(),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => Center(
                child: Text(
                  "Error: $e",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
        ),
      ),
    );
  }

  // ... (same _buildStatsTab, _buildAchievementsTab, _buildClubsTab, etc.)

  Widget _buildStatsTab(UserModel user) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatsCard(user),
        const SizedBox(height: 20),
        buildSportsSection(user),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    return Center(
      child: Text(
        "Achievements coming soon!",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildClubsTab() {
    return Center(
      child: Text(
        "Club data coming soon!",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildStatsCard(UserModel user) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12),
        child: Column(
          children: [
            Text(
              "Match Stats",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem("Played", user.gamesPlayed.toString()),
                _statItem("Won", user.gamesWon.toString()),
                _statItem(
                  "Lost",
                  (user.gamesPlayed - user.gamesWon).toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget buildSportsSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sports & Player Position",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _playerCard(
                icon: Icons.sports_soccer,
                title: "Forward",
                skill: "Advanced",
                rating: 4.2,
                games: 711,
                mvps: 19,
              ),
              _playerCard(
                icon: Icons.sports_basketball,
                title: "Shooter",
                skill: "Intermediate",
                rating: 3.8,
                games: 420,
                mvps: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _playerCard({
    required IconData icon,
    required String title,
    required String skill,
    required double rating,
    required int games,
    required int mvps,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: rating / 5.0,
                  backgroundColor: Colors.white24,
                  color: Colors.purpleAccent,
                  minHeight: 5,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$games Games  •  $mvps MVPs",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.3);
  }
}
