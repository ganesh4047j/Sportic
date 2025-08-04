// chat_screen.dart - Cleaned version without image support
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../Providers/chat_message_providers.dart';
import '../Providers/send_message_provider.dart';

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

class _ChatPageState extends ConsumerState<ChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _sendButtonController;
  late AnimationController _messageController;
  late Animation<double> _sendButtonAnimation;
  late Animation<double> _fadeAnimation;
  String? myId;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    // Debug parameters
    print('🔥 ChatPage initialized with:');
    print('🔥 chatId: ${widget.chatId} (${widget.chatId.runtimeType})');
    print(
      '🔥 peerEmail: ${widget.peerEmail} (${widget.peerEmail.runtimeType})',
    );
    print('🔥 peerName: ${widget.peerName} (${widget.peerName.runtimeType})');
    print('🔥 peerUid: ${widget.peerUid} (${widget.peerUid.runtimeType})');

    // Validate parameters
    if (widget.chatId.isEmpty) {
      print('🚨 ERROR: Empty chatId');
    }
    if (widget.peerUid.isEmpty) {
      print('🚨 ERROR: Empty peerUid');
    }

    _initIdentifier();
    _initAnimations();
    _controller.addListener(_onTextChanged);
  }

  void _initAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _messageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageController, curve: Curves.easeInOut),
    );
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
    }
  }

  Future<void> _initIdentifier() async {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      myId = fbUser?.uid ?? await _secureStorage.read(key: 'custom_uid');

      print('🔥 ChatPage myId initialized: $myId');

      if (myId == null || myId!.isEmpty) {
        print("🚨 ERROR: myId is null or empty");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User authentication error. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('🚨 ERROR in _initIdentifier: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Initialization error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || myId == null) return;

    print('🔥 Sending message: "$text" from $myId to chat ${widget.chatId}');

    // Animate send button
    _sendButtonController.forward().then((_) {
      _sendButtonController.reverse();
    });

    // Clear input and reset typing state
    _controller.clear();
    setState(() {
      _isTyping = false;
    });

    try {
      // Use the correct provider method
      await ref
          .read(sendMessageProvider.notifier)
          .sendText(widget.chatId, text, myId!);

      print('🔥 Message sent successfully');

      // Auto-scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('🔥 Failed to send message: $e');

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _controller.text = text; // Restore the message
                setState(() {
                  _isTyping = text.isNotEmpty;
                });
              },
            ),
          ),
        );
      }
    }
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

  Widget _buildMessageBubble({
    required bool isMe,
    required String text,
    required String time,
    required bool read,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                child: Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade300,
                              Colors.pink.shade300,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isMe
                                    ? [
                                      Colors.pink.shade400,
                                      Colors.pink.shade600,
                                    ]
                                    : [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      read ? Icons.done_all : Icons.check,
                                      key: ValueKey(read),
                                      size: 16,
                                      color:
                                          read
                                              ? Colors.blue.shade200
                                              : Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade300,
                              Colors.purple.shade300,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
            children: [
              // Enhanced AppBar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade300,
                            Colors.pink.shade300,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.peerName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages Area
              Expanded(
                child:
                    myId == null
                        ? const Center(
                          child: Text(
                            "User not logged in or ID missing",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                        : messagesAsync.when(
                          data: (messages) {
                            print(
                              '🧾 Messages received in UI: ${messages.length}',
                            );
                            List<Widget> messageWidgets = [];
                            String? lastDateLabel;

                            for (int i = 0; i < messages.length; i++) {
                              try {
                                final msg = messages[i];
                                final isMe =
                                    msg['from']?.toString().trim() ==
                                    myId?.trim();
                                final text = msg['text']?.toString() ?? '';
                                final read = msg['read'] == true;
                                final timestamp = msg['timestamp'];
                                final time = _formatTime(timestamp);
                                final currentDateLabel = _getDateLabel(
                                  timestamp,
                                );

                                // Add date label if needed
                                if (lastDateLabel != currentDateLabel) {
                                  messageWidgets.add(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            currentDateLabel,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                  lastDateLabel = currentDateLabel;
                                }

                                // Add message bubble
                                messageWidgets.add(
                                  _buildMessageBubble(
                                    isMe: isMe,
                                    text: text,
                                    time: time,
                                    read: read,
                                    index: i,
                                  ),
                                );
                              } catch (e) {
                                print('🚨 Error processing message $i: $e');
                                continue; // Skip this message but continue with others
                              }
                            }

                            return ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              children: messageWidgets,
                            );
                          },
                          loading:
                              () => Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Lottie.asset(
                                    'assets/loading_spinner.json',
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ),
                          error:
                              (e, _) => Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade300,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Error loading messages',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red.shade300,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$e',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red.shade200,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ),
              ),

              // Enhanced Input Area
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                _isTyping
                                    ? Colors.pink.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          cursorColor: Colors.pink.shade300,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedBuilder(
                      animation: _sendButtonAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _sendButtonAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    _isTyping
                                        ? [
                                          Colors.pink.shade400,
                                          Colors.pink.shade600,
                                        ]
                                        : [
                                          Colors.grey.shade400,
                                          Colors.grey.shade600,
                                        ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isTyping ? Colors.pink : Colors.grey)
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: _isTyping ? _sendText : null,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
