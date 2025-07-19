import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatMessagesProvider = StreamProvider.family
    .autoDispose<List<Map<String, dynamic>>, ({String chatId, String myId})>((
      ref,
      params,
    ) {
      final chatId = params.chatId;
      final myId = params.myId;

      final stream =
          FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp')
              .snapshots();

      return stream.map((snapshot) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final isUnread = data['read'] == false;
          final isFromOther = data['from'] != myId;

          if (isUnread && isFromOther) {
            doc.reference.update({'read': true});
          }
        }

        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    });
