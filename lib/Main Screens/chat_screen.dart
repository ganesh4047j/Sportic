// chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../Providers/chat_message_providers.dart';
import '../Providers/send_message_provider.dart';
import '../Services/images_preview.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatId;
  final String peerEmail;
  final String peerName;
  final String peerUid;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.peerEmail,
    required this.peerName,
    required this.peerUid,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? myId;

  @override
  void initState() {
    super.initState();
    _initIdentifier();
  }

  Future<void> _initIdentifier() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    myId = fbUser?.uid ?? await _secureStorage.read(key: 'custom_uid');
    if (myId == null) debugPrint("Error: myId is null");
    setState(() {});
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || myId == null) return;
    _controller.clear();
    await ref
        .read(sendMessageProvider as ProviderListenable)
        .sendText(widget.chatId, text, myId!);
  }

  String _formatTime(dynamic timestamp) {
    try {
      if (timestamp == null || timestamp is! Timestamp) return '';
      return DateFormat('hh:mm a').format(timestamp.toDate());
    } catch (_) {
      return '';
    }
  }

  String _getDateLabel(dynamic timestamp) {
    try {
      if (timestamp == null || timestamp is! Timestamp) return '';
      final msgDate = timestamp.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final messageDay = DateTime(msgDate.year, msgDate.month, msgDate.day);

      if (messageDay == today) return 'Today';
      if (messageDay == yesterday) return 'Yesterday';
      return DateFormat('dd MMM yyyy').format(msgDate);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        myId == null
            ? const AsyncValue.loading()
            : ref.watch(
              chatMessagesProvider((chatId: widget.chatId, myId: myId!)),
            );

    return Scaffold(
      backgroundColor: const Color(0xFF43325C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF43325C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 10),
            Text(
              widget.peerName,
              style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ),
      body:
          myId == null
              ? const Center(child: Text("User not logged in or ID missing"))
              : Column(
                children: [
                  Expanded(
                    child: messagesAsync.when(
                      data: (messages) {
                        print('🧾 Messages received in UI: ${messages.length}');
                        List<Widget> messageWidgets = [];
                        String? lastDateLabel;
                        final imageUrls =
                            messages
                                .where(
                                  (m) =>
                                      m['type'] == 'image' &&
                                      m['imageUrl'] != null,
                                )
                                .map((m) => m['imageUrl'] as String)
                                .toList();

                        for (int i = 0; i < messages.length; i++) {
                          final msg = messages[i];
                          final isMe =
                              msg['from']?.toString().trim() == myId?.trim();
                          final isImage = msg['type'] == 'image';
                          final imageUrl = msg['imageUrl'];
                          final text = msg['text'] ?? '';
                          final read = msg['read'] == true;
                          final timestamp = msg['timestamp'];
                          final time = _formatTime(timestamp);
                          final currentDateLabel = _getDateLabel(timestamp);

                          if (lastDateLabel != currentDateLabel) {
                            messageWidgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      currentDateLabel,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                            lastDateLabel = currentDateLabel;
                          }

                          messageWidgets.add(
                            Align(
                              alignment:
                                  isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.pink : Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isImage && imageUrl != null)
                                      GestureDetector(
                                        onTap: () {
                                          final index = imageUrls.indexOf(
                                            imageUrl,
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => ImagePreviewPage(
                                                    imageUrls: imageUrls,
                                                    initialIndex: index,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            width: 200,
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        text,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                        softWrap: true,
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          time,
                                          style: GoogleFonts.cutive(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMe &&
                                            i == messages.length - 1) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            read ? Icons.done_all : Icons.check,
                                            size: 14,
                                            color:
                                                read
                                                    ? Colors.blue
                                                    : Colors.white,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.all(10),
                          children: messageWidgets,
                        );
                      },
                      loading:
                          () => Center(
                            child: Lottie.asset('assets/loading_spinner.json'),
                          ),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF584173),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _controller,
                              style: GoogleFonts.poppins(color: Colors.white),
                              cursorColor: Colors.white,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.white54,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.pink,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
