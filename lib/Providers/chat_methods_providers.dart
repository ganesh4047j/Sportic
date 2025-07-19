import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'current_user_id_provider.dart';

final secureStorage = FlutterSecureStorage();

final chatHelperProvider = Provider((ref) => ChatHelper(ref));

class ChatHelper {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatHelper(this.ref);

  /// 🔐 Get current user identifier using the provider
  Future<String> _getCurrentUserId() async {
    final id = await ref.read(currentUserIdProvider.future);
    if (id == null) throw Exception("User not logged in");
    return id;
  }

  /// 🧠 Gets or creates chatId using peerEmail or peerUID
  Future<String> getOrCreateChatId(String peerId, String generatedId) async {
    final docRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(generatedId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'participants': generatedId.split('_'),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    return generatedId;
  }
}
