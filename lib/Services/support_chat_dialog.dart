import 'package:flutter/material.dart';

class SupportChatDialog extends StatefulWidget {
  const SupportChatDialog({super.key});

  @override
  State<SupportChatDialog> createState() => _SupportChatDialogState();
}

class _SupportChatDialogState extends State<SupportChatDialog>
    with TickerProviderStateMixin {
  final List<Map<String, String>> messages = [
    {"sender": "bot", "text": "Hi there! 👋 How can I assist you today?"},
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<Map<String, String>> quickReplies = [
    {"icon": "💳", "text": "Payment failure"},
    {"icon": "💰", "text": "Refund issues"},
    {"icon": "📍", "text": "Venue-related queries"},
    {"icon": "📅", "text": "Booking slots"},
    {"icon": "📈", "text": "Pricing info"},
    {"icon": "⚙️", "text": "App issues"},
    {"icon": "🧾", "text": "My bookings"},
    {"icon": "🔙", "text": "Cancel booking"},
    {"icon": "📍", "text": "Location help"},
    {"icon": "👥", "text": "Group booking"},
    {"icon": "✍️", "text": "Others"},
  ];

  late AnimationController _dialogController;
  late AnimationController _messageController;
  late AnimationController _typingController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _dialogController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.elasticOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _dialogController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _messageController,
      curve: Curves.easeInOut,
    );

    _dialogController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dialogController.dispose();
    _messageController.dispose();
    _typingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": text});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();
    _typingController.repeat();

    // Simulate bot typing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isTyping = false;
      messages.add({"sender": "bot", "text": getBotReply(text)});
    });

    _typingController.stop();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(Map<String, String> message, int index) {
    final isBot = message["sender"] == "bot";

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment:
                  isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBot) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A4C93), Color(0xFF9B59B6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy,
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
                      gradient:
                          isBot
                              ? LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              )
                              : const LinearGradient(
                                colors: [Color(0xFF6A4C93), Color(0xFF9B59B6)],
                              ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isBot ? 4 : 20),
                        bottomRight: Radius.circular(isBot ? 20 : 4),
                      ),
                      border:
                          isBot
                              ? Border.all(color: Colors.white.withOpacity(0.1))
                              : null,
                      boxShadow: [
                        BoxShadow(
                          color: (isBot ? Colors.black : Colors.purple)
                              .withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (!isBot) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
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
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isTyping) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A4C93), Color(0xFF9B59B6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(
                  3,
                  (index) => AnimatedBuilder(
                    animation: _typingController,
                    builder: (context, child) {
                      final delay = index * 0.3;
                      final value = (_typingController.value + delay) % 1.0;
                      return Container(
                        margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            -10 * (0.5 - (value - 0.5).abs()) * 2,
                          ),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReply(Map<String, String> reply) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => _sendMessage(reply["text"]!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reply["icon"]!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reply["text"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16,
        vertical: 40,
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: screenHeight - 80 - keyboardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6A4C93),
                  Color(0xFF452152),
                  Color(0xFF3D1A4A),
                  Color(0xFF200D28),
                  Color(0xFF1B0723),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 8),
                  blurRadius: 32,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A4C93), Color(0xFF9B59B6)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sportic Assistant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Online • Ready to help',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < messages.length) {
                        return _buildMessage(messages[index], index);
                      } else {
                        return _buildTypingIndicator();
                      }
                    },
                  ),
                ),

                // Quick Replies
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickReplies.map(_buildQuickReply).toList(),
                    ),
                  ),
                ),

                // Input Area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.emoji_emotions_outlined,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                onPressed: () {},
                              ),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A4C93), Color(0xFF9B59B6)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _sendMessage(_controller.text),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getBotReply(String message) {
    message = message.toLowerCase();

    if (message.contains("payment") ||
        message.contains("pay") ||
        message.contains("upi") ||
        message.contains("transaction") ||
        message.contains("payment methods") ||
        message.contains("how to pay")) {
      return "We accept UPI and online payments. You'll see the available options on the payment screen. 💳";
    }

    if (message.contains("book") ||
        message.contains("booking") ||
        message.contains("reserve") ||
        message.contains("slot")) {
      return "You can book a turf by selecting your desired location, date, and time slot from the Home screen. 📅";
    }

    if (message.contains("price") ||
        message.contains("cost") ||
        message.contains("rate") ||
        message.contains("charges")) {
      return "Turf prices vary by location and time. You can view the exact pricing by selecting a turf and choosing a time slot. 💰";
    }

    if (message.contains("offer") ||
        message.contains("discount") ||
        message.contains("coupon") ||
        message.contains("promo")) {
      return "If there are any active offers or promo codes, you'll see them on the payment screen before confirming your booking. 🎉";
    }

    if (message.contains("refund") || message.contains("return money")) {
      return "Refunds are processed based on our cancellation policy. Please share your booking ID to assist you further. 💸";
    }

    if (message.contains("cancel") || message.contains("cancellation")) {
      return "You can cancel a booking from your 'My Bookings' section. Refunds depend on how early you cancel. ❌";
    }

    if (message.contains("confirmation") ||
        message.contains("confirm booking")) {
      return "You'll receive a confirmation message and email once your payment is successful. ✅";
    }

    if (message.contains("available") ||
        message.contains("availability") ||
        message.contains("check slot")) {
      return "To check availability, go to the Home screen, select a turf and choose a date to see open time slots. 🔍";
    }

    if (message.contains("light") ||
        message.contains("indoor") ||
        message.contains("outdoor") ||
        message.contains("ground") ||
        message.contains("facility")) {
      return "Each turf lists its features (indoor/outdoor, lighting, amenities) in the details section. 🏟️";
    }

    if (message.contains("help") ||
        message.contains("support") ||
        message.contains("assist") ||
        message.contains("customer care")) {
      return "We're here to help! You can ask your query here or reach out through the app's Support section. 🤝";
    }

    if (message.contains("login") ||
        message.contains("sign in") ||
        message.contains("signup") ||
        message.contains("register") ||
        message.contains("account")) {
      return "You can login or register using your phone number or email from the app's welcome screen. 👤";
    }

    if (message.contains("app not working") ||
        message.contains("crash") ||
        message.contains("bug") ||
        message.contains("error") ||
        message.contains("slow")) {
      return "Sorry to hear that. Please make sure you're on the latest version. Try restarting the app or reinstalling it. 🔧";
    }

    if (message.contains("group booking") ||
        message.contains("multiple") ||
        message.contains("team")) {
      return "Yes, you can book for teams or groups by selecting enough slots or sharing your plan with turf management. 👥";
    }

    if (message.contains("washroom") ||
        message.contains("toilet") ||
        message.contains("parking") ||
        message.contains("water")) {
      return "Most turfs provide basic facilities like parking, washrooms, and drinking water. Check turf details to confirm. 🚽";
    }

    if (message.contains("location") ||
        message.contains("direction") ||
        message.contains("map") ||
        message.contains("where")) {
      return "Location is shown on the turf detail page. Tap the map icon to open directions in Google Maps. 📍";
    }

    if (message.contains("review") ||
        message.contains("feedback") ||
        message.contains("rating")) {
      return "You can read and give reviews on the turf detail page after your booking is completed. ⭐";
    }

    if (message.contains("history") ||
        message.contains("my bookings") ||
        message.contains("previous") ||
        message.contains("past bookings")) {
      return "Go to the 'My Bookings' section from the menu to view your past and upcoming bookings. 📋";
    }

    if (message.contains("terms") ||
        message.contains("policy") ||
        message.contains("rules") ||
        message.contains("conditions")) {
      return "Our terms and conditions are available in the Profile section under Terms & Privacy Policy. 📄";
    }

    if (message.contains("update") || message.contains("version")) {
      return "Make sure you're using the latest version of the app for the best experience. Check the Play Store for updates. 🔄";
    }

    if (message.contains("hello") ||
        message.contains("hi") ||
        message.contains("hey")) {
      return "Hi there! 👋 How can I assist you today?";
    }

    return "I'm sorry, I didn't understand that. Can you please rephrase or ask a different question? 🤔";
  }
}
