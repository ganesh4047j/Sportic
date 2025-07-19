import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../Providers/connection_provider.dart';
import '../Providers/search_friends_providers.dart';
import '../Providers/view_request_provider.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(viewRequestsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Friend Requests',
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        //centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
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
          ),
          // Body content
          Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight + 16),
            child: requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      'No pending requests',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white24),
                  itemBuilder: (context, index) {
                    final user = requests[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1A4A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage:
                                  (user['photoUrl'] ?? '').isNotEmpty
                                  ? NetworkImage(user['photoUrl'])
                                  : const NetworkImage(
                                      'https://i.pravatar.cc/150',
                                    ),
                              radius: 25,
                            ),
                            title: Text(
                              user['name'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              user['location'] ?? '',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                            trailing: Text(
                              user['email'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  await ref.read(
                                    acceptRequestProvider(user['uid']),
                                  );
                                  ref.invalidate(viewRequestsProvider);
                                  ref.invalidate(searchFriendsProvider);
                                  ref.invalidate(connectionsProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Friend request accepted',
                                        style: GoogleFonts.cutive(
                                          fontSize: 12,
                                          color: Colors.white38,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                label: Text(
                                  'Accept',
                                  style: GoogleFonts.nunito(
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: () async {
                                  await ref.read(
                                    rejectRequestProvider(user['uid']),
                                  );
                                  ref.invalidate(viewRequestsProvider);
                                  ref.invalidate(searchFriendsProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Friend request rejected',
                                        style: GoogleFonts.cutive(
                                          fontSize: 12,
                                          color: Colors.white38,
                                        ),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                label: Text(
                                  'Reject',
                                  style: GoogleFonts.nunito(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => Center(
                child: Lottie.asset(
                  'assets/loading_spinner.json',
                  width: 120,
                  height: 120,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: GoogleFonts.cutive(
                    color: Colors.redAccent,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
