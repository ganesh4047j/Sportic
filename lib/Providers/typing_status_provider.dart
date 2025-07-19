import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔁 Watch the peer's typing status (stream of true/false)
final peerTypingStatusProvider = StreamProvider.family.autoDispose<bool, String>((ref, chatId) {
  final myEmail = FirebaseAuth.instance.currentUser?.email;

  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((doc) {
    final data = doc.data();
    if (data == null) return false;
    final typingMap = data['typing'] as Map<String, dynamic>? ?? {};
    return typingMap.entries.any((entry) => entry.key != myEmail && entry.value == true);
  });
});

/// 📤 Used to trigger typing updates (start/stop) from current user
final typingStatusProvider = StateNotifierProvider.family.autoDispose<TypingStatusNotifier, bool, String>((ref, chatId) {
  return TypingStatusNotifier(chatId);
});

class TypingStatusNotifier extends StateNotifier<bool> {
  final String chatId;
  Timer? _timer;

  TypingStatusNotifier(this.chatId) : super(false);

  void startTyping() {
    if (!state) {
      _setTyping(true);
    }
    _resetTimer();
  }

  void stopTyping() {
    _timer?.cancel();
    _setTyping(false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), stopTyping);
  }

  void _setTyping(bool isTyping) {
    state = isTyping;
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'typing': {
          email: isTyping,
        }
      }, SetOptions(merge: true));
    }
  }

  @override
  void dispose() {
    stopTyping();
    super.dispose();
  }
}