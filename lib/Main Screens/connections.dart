import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../Providers/current_user_id_provider.dart';
import '../Providers/message_preview_provider.dart';
import '../Providers/connection_provider.dart';
import '../Services/chat_utils.dart';
import 'chat_screen.dart';

final connectionsSearchProvider = StateProvider<String>((ref) => '');
final secureStorage = FlutterSecureStorage();

class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({super.key});
  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(connectionsSearchProvider).toLowerCase();
    final previewsAsync = ref.watch(messagePreviewProvider);
    final connectionsAsync = ref.watch(connectionsProvider);

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const BackButton(color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "Connections",
                      style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: GoogleFonts.cutive(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF30023C),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) =>
                      ref.read(connectionsSearchProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: previewsAsync.when(
                  data: (chats) {
                    final chatMap = {
                      for (var chat in chats) chat['peerEmail']: chat,
                    };

                    return connectionsAsync.when(
                      data: (connections) {
                        final filtered = connections.where((user) {
                          final name = (user['name'] ?? '')
                              .toString()
                              .toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'No connections found',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white24),
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            final peerId = user['email'] ?? user['uid'] ?? '';
                            final peerName = user['name'] ?? peerId;
                            final photoUrl = user['photoUrl'] ?? '';
                            final location = user['location'] ?? '';

                            final chat = chatMap[peerId];
                            final chatId = chat != null ? chat['chatId'] : null;
                            final unread = chat != null
                                ? (chat['unread'] ?? 0)
                                : 0;
                            final lastMsg = chat != null
                                ? (chat['lastMsg'] ?? '')
                                : '';

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : const NetworkImage(
                                        'https://i.pravatar.cc/150',
                                      ),
                              ),
                              title: Text(
                                peerName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                location.isNotEmpty ? location : lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.message,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  try {
                                    final fbUser =
                                        FirebaseAuth.instance.currentUser;
                                    final currentUserUid = await ref.read(
                                      currentUserIdProvider.future,
                                    );
                                    final peerUid = user['uid'];

                                    if (currentUserUid == null ||
                                        peerUid == null) {
                                      throw Exception('Missing user IDs');
                                    }

                                    final resolvedChatId = generateChatId(
                                      peerUid,
                                      currentUserUid,
                                    );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          chatId: resolvedChatId,
                                          peerUid: peerUid,
                                          peerName: user['name'] ?? '',
                                          peerEmail: '',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to open chat: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => Center(
                        child: Lottie.asset('assets/loading_spinner.json'),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  },
                  loading: () => Center(
                    child: Lottie.asset('assets/loading_spinner.json'),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
