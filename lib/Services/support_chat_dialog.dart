import 'package:flutter/material.dart';

class SupportChatDialog extends StatefulWidget {
  const SupportChatDialog({super.key});

  @override
  State<SupportChatDialog> createState() => _SupportChatDialogState();
}

class _SupportChatDialogState extends State<SupportChatDialog>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> messages = [
    {"sender": "bot", "text": "Hi there! 👋 How can I assist you today?"},
  ];

  final TextEditingController _controller = TextEditingController();
  final List<String> quickReplies = [
    "💳 Payment failure",
    "💰 Refund issues",
    "📍Venue-related queries",
    "📅 Booking slots",
    "📈 Pricing info",
    "⚙️ App issues",
    "🧾 My bookings",
    "🔙 Cancel booking",
    "📍 Location help",
    "👥 Group booking",
    "✍️ Others",
  ];

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add({"sender": "user", "text": text});
      messages.add({"sender": "bot", "text": getBotReply(text)});
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Text(
                  '🤖 Sportic Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isBot = msg["sender"] == "bot";
                      return Container(
                        alignment:
                            isBot
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isBot ? Colors.black45 : Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg["text"]!,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12.0,
                  children:
                      quickReplies.map((query) {
                        return ActionChip(
                          backgroundColor: Colors.black,
                          label: Text(
                            query,
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () => _sendMessage(query),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          hintText: 'Type your query...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.purple),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ],
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
      return "We accept UPI and online payments. You'll see the available options on the payment screen.";
    }

    if (message.contains("book") ||
        message.contains("booking") ||
        message.contains("reserve") ||
        message.contains("slot")) {
      return "You can book a turf by selecting your desired location, date, and time slot from the Home screen.";
    }

    if (message.contains("price") ||
        message.contains("cost") ||
        message.contains("rate") ||
        message.contains("charges")) {
      return "Turf prices vary by location and time. You can view the exact pricing by selecting a turf and choosing a time slot.";
    }

    if (message.contains("offer") ||
        message.contains("discount") ||
        message.contains("coupon") ||
        message.contains("promo")) {
      return "If there are any active offers or promo codes, you'll see them on the payment screen before confirming your booking.";
    }

    if (message.contains("refund") || message.contains("return money")) {
      return "Refunds are processed based on our cancellation policy. Please share your booking ID to assist you further.";
    }

    if (message.contains("cancel") || message.contains("cancellation")) {
      return "You can cancel a booking from your 'My Bookings' section. Refunds depend on how early you cancel.";
    }

    if (message.contains("confirmation") ||
        message.contains("confirm booking")) {
      return "You'll receive a confirmation message and email once your payment is successful.";
    }

    if (message.contains("available") ||
        message.contains("availability") ||
        message.contains("check slot")) {
      return "To check availability, go to the Home screen, select a turf and choose a date to see open time slots.";
    }

    if (message.contains("light") ||
        message.contains("indoor") ||
        message.contains("outdoor") ||
        message.contains("ground") ||
        message.contains("facility")) {
      return "Each turf lists its features (indoor/outdoor, lighting, amenities) in the details section.";
    }

    if (message.contains("help") ||
        message.contains("support") ||
        message.contains("assist") ||
        message.contains("customer care")) {
      return "We're here to help! You can ask your query here or reach out through the app's Support section.";
    }

    if (message.contains("login") ||
        message.contains("sign in") ||
        message.contains("signup") ||
        message.contains("register") ||
        message.contains("account")) {
      return "You can login or register using your phone number or email from the app's welcome screen.";
    }

    if (message.contains("app not working") ||
        message.contains("crash") ||
        message.contains("bug") ||
        message.contains("error") ||
        message.contains("slow")) {
      return "Sorry to hear that. Please make sure you're on the latest version. Try restarting the app or reinstalling it.";
    }

    if (message.contains("group booking") ||
        message.contains("multiple") ||
        message.contains("team")) {
      return "Yes, you can book for teams or groups by selecting enough slots or sharing your plan with turf management.";
    }

    if (message.contains("washroom") ||
        message.contains("toilet") ||
        message.contains("parking") ||
        message.contains("water")) {
      return "Most turfs provide basic facilities like parking, washrooms, and drinking water. Check turf details to confirm.";
    }

    if (message.contains("location") ||
        message.contains("direction") ||
        message.contains("map") ||
        message.contains("where")) {
      return "Location is shown on the turf detail page. Tap the map icon to open directions in Google Maps.";
    }

    if (message.contains("review") ||
        message.contains("feedback") ||
        message.contains("rating")) {
      return "You can read and give reviews on the turf detail page after your booking is completed.";
    }

    if (message.contains("history") ||
        message.contains("my bookings") ||
        message.contains("previous") ||
        message.contains("past bookings")) {
      return "Go to the 'My Bookings' section from the menu to view your past and upcoming bookings.";
    }

    if (message.contains("terms") ||
        message.contains("policy") ||
        message.contains("rules") ||
        message.contains("conditions")) {
      return "Our terms and conditions are available in the Profile section under Terms & Privacy Policy.";
    }

    if (message.contains("update") || message.contains("version")) {
      return "Make sure you're using the latest version of the app for the best experience. Check the Play Store for updates.";
    }

    if (message.contains("hello") ||
        message.contains("hi") ||
        message.contains("hey")) {
      return "Hi there! 👋 How can I assist you today?";
    }

    return "I'm sorry, I didn't understand that. Can you please rephrase or ask a different question?";
  }
}
