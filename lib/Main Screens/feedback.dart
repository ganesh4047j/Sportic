import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Providers/feedback_providers.dart';

class FeedbackPage extends ConsumerWidget {
  const FeedbackPage({super.key});

  final List<String> emojis = const ["😞", "😐", "😕", "😊", "😄"];
  final List<String> selectableOptions = const [
    "Select topic",
    "Something wrong in this app",
    "Something wrong with network",
    "Others",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackProvider);
    final notifier = ref.read(feedbackProvider.notifier);

    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title:  Text(
            "Feedback",
            style: GoogleFonts.robotoSlab(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://th.bing.com/th/id/OIP.TKWeda6AKzB2yP68mEDWJQHaD6?w=332&h=180&c=7&r=0&o=7&dpr=1.3&pid=1.7&rm=3",
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => Text(
                      "Failed to load image",
                      style: GoogleFonts.outfit(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                 Text(
                  "Share Your Feedback",
                  style: GoogleFonts.cutive(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "please select a topic and let us\nknow about your concern",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cutive(color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // Emojis
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(emojis.length, (index) {
                    return GestureDetector(
                      onTap: () => notifier.selectEmoji(index),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.selectedEmoji == index
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                        ),
                        child: Text(
                          emojis[index],
                          style: TextStyle(
                            fontSize: 32,
                            color: state.selectedEmoji == index
                                ? Colors.yellow
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Options
                Column(
                  children: selectableOptions.map((option) {
                    final isSelected = state.selectedOption == option;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => notifier.selectOption(option),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green : Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                // Submit
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (!notifier.isComplete) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please complete your feedback."),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Feedback submitted successfully."),
                          ),
                        );
                      }
                    },
                    child: const Text("Submit",
                        style: TextStyle(fontSize: 20, color: Colors.white)),
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