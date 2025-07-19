import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sports/Main%20Screens/profile_view.dart';
import '../Providers/search_friends_providers.dart';

class FriendsPage extends ConsumerWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(searchFriendsProvider);

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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    Text(
                      'Search Friends',
                      style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  style: GoogleFonts.poppins(color: Colors.white),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: GoogleFonts.poppins(color: Colors.white),
                    prefixIcon: const Icon(
                      Icons.person_search,
                      color: Colors.white,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (value) =>
                      ref.read(nameSearchProvider.notifier).state = value,
                ),
                const SizedBox(height: 12),
                TextField(
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Location',
                    labelStyle: GoogleFonts.poppins(color: Colors.white),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (value) =>
                      ref.read(locationSearchProvider.notifier).state = value,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: friendsAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'No users found',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final requestStatus = user['requestStatus'] ?? 'none';
                          final userId = user['uid'];
                          final isAccepted = requestStatus == 'accepted';
                          final isPending = requestStatus == 'pending';

                          Icon icon;
                          String tooltip;

                          if (isAccepted) {
                            icon = const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            );
                            tooltip = 'Already friends';
                          } else if (isPending) {
                            icon = const Icon(
                              Icons.hourglass_top,
                              color: Colors.orange,
                            );
                            tooltip = 'Request pending';
                          } else {
                            icon = const Icon(
                              Icons.person_add_alt_1,
                              color: Colors.blue,
                            );
                            tooltip = 'Send Friend Request';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileView(userId: userId),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user['photoUrl'] != ''
                                    ? NetworkImage(user['photoUrl'])
                                    : const NetworkImage(
                                        'https://i.pravatar.cc/150',
                                      ),
                                radius: 25,
                              ),
                              title: Text(
                                user['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                user['location'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                              trailing: IconButton(
                                icon: icon,
                                tooltip: tooltip,
                                onPressed: (isAccepted || isPending)
                                    ? null
                                    : () async {
                                        try {
                                          await ref.read(
                                            sendFriendRequestProvider(userId),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Friend request sent to ${user['name']}',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor:
                                                  Colors.green[600],
                                            ),
                                          );
                                          ref.invalidate(searchFriendsProvider);
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.red[400],
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => Center(
                      child: Lottie.asset(
                        'assets/loading_spinner.json',
                        width: 100,
                        height: 100,
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
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
