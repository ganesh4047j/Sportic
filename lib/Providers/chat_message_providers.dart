// chat_message_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatMessagesProvider = StreamProvider.family.autoDispose<
  List<Map<String, dynamic>>,
  ({String chatId, String myId})
>((ref, params) {
  final chatId = params.chatId;
  final myId = params.myId;

  print('🔥 Setting up stream for chatId: $chatId, myId: $myId');

  // Validate parameters
  if (chatId.isEmpty || myId.isEmpty) {
    print('🔥 Invalid parameters: chatId=$chatId, myId=$myId');
    return Stream.value(<Map<String, dynamic>>[]);
  }

  final stream =
      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy(
            'timestamp',
            descending: false,
          ) // Ascending for proper chat order
          .snapshots();

  return stream
      .map((snapshot) {
        print('🔥 Received ${snapshot.docs.length} messages for chat $chatId');

        // Handle empty snapshots
        if (snapshot.docs.isEmpty) {
          print('🔥 No messages found for chat $chatId');
          return <Map<String, dynamic>>[];
        }

        final messages = <Map<String, dynamic>>[];
        final readUpdates = <Future<void>>[];

        for (final doc in snapshot.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());

            // Add document ID for future reference
            data['id'] = doc.id;

            // Ensure required fields exist with defaults
            data['text'] = data['text'] ?? '';
            data['from'] = data['from'] ?? '';
            data['to'] = data['to'] ?? '';
            data['type'] = data['type'] ?? 'text';
            data['read'] = data['read'] ?? false;
            data['timestamp'] = data['timestamp'];

            print(
              '🔥 Processing message: ${data['id']} from ${data['from']} type ${data['type']}',
            );

            // Check if this message needs to be marked as read
            final isUnread = data['read'] == false;
            final isFromOther = data['from'].toString() != myId;

            if (isUnread && isFromOther) {
              print('🔥 Marking message ${data['id']} as read');

              // Queue the read update
              final updateFuture = doc.reference
                  .update({'read': true})
                  .catchError((error) {
                    print(
                      '🔥 Failed to mark message ${data['id']} as read: $error',
                    );
                    return null;
                  });

              readUpdates.add(updateFuture);

              // Update local data to reflect read status immediately
              data['read'] = true;
            }

            messages.add(data);
          } catch (e) {
            print('🔥 Error processing message document ${doc.id}: $e');
            // Skip malformed messages but continue processing others
            continue;
          }
        }

        // Execute all read updates concurrently (fire and forget)
        if (readUpdates.isNotEmpty) {
          Future.wait(readUpdates).catchError((error) {
            print('🔥 Some read updates failed: $error');
          });
        }

        print('🔥 Returning ${messages.length} processed messages');
        return messages;
      })
      .handleError((error) {
        print('🔥 Error in chatMessagesProvider: $error');
        if (error is FirebaseException) {
          print('🔥 Firebase error code: ${error.code}');
          print('🔥 Firebase error message: ${error.message}');
        }

        // Return empty list instead of throwing to prevent app crashes
        return <Map<String, dynamic>>[];
      });
});

// Helper provider to get unread message count
final unreadMessageCountProvider = StreamProvider.family
    .autoDispose<int, String>((ref, chatId) {
      return FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length)
          .handleError((error) {
            print('🔥 Error getting unread count: $error');
            return 0;
          });
    });

// Helper provider to check if chat exists
final chatExistsProvider = FutureProvider.family.autoDispose<bool, String>((
  ref,
  chatId,
) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    return doc.exists;
  } catch (e) {
    print('🔥 Error checking chat existence: $e');
    return false;
  }
});
