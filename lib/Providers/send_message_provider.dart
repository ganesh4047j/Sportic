// send_message_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Services/notification_service.dart';

final secureStorage = FlutterSecureStorage();

class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  SendMessageNotifier() : super(const AsyncValue.data(null));

  Future<void> sendText(String chatId, String text, String myId) async {
    state = const AsyncValue.loading();

    try {
      final firestore = FirebaseFirestore.instance;
      String? receiverUid;

      print('🔥 Attempting to send message to chatId: $chatId');

      // Get receiver ID from chat participants
      final chatDoc = await firestore.collection('chats').doc(chatId).get();

      if (chatDoc.exists) {
        print('🔥 Chat document exists');
        final chatData = chatDoc.data();
        final participantsData = chatData?['participants'];

        print(
          '🔥 Participants data: $participantsData (${participantsData.runtimeType})',
        );

        if (participantsData != null) {
          // Safe conversion from dynamic list to string list
          List<String> participants = [];
          if (participantsData is List) {
            participants = participantsData.map((e) => e.toString()).toList();
          }

          print('🔥 Converted participants: $participants');

          // Find receiver (the participant who is not me)
          for (final participant in participants) {
            if (participant != myId) {
              receiverUid = participant;
              break;
            }
          }
        }
      } else {
        print('🔥 Chat document does not exist, creating new chat');
        // Extract receiver ID from chatId (assuming format like "user1_user2")
        final parts = chatId.split('_');
        for (final part in parts) {
          if (part != myId) {
            receiverUid = part;
            break;
          }
        }

        if (receiverUid != null) {
          // Create new chat document
          await firestore.collection('chats').doc(chatId).set({
            'participants': [
              myId,
              receiverUid,
            ], // This creates a proper List<String>
            'lastMessage': text,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('🔥 Created new chat with participants: [$myId, $receiverUid]');
        }
      }

      if (receiverUid == null || receiverUid.isEmpty) {
        throw Exception(
          'Could not determine receiver from chatId: $chatId, myId: $myId',
        );
      }

      print('🔥 Sending message from $myId to $receiverUid');

      // Create message with consistent structure
      final messagePayload = {
        'from': myId,
        'to': receiverUid,
        'text': text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Add message to subcollection
      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messagePayload);

      print('🔥 Message added to Firestore');

      // Update chat document with last message info
      await firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageFrom': myId,
      });

      print('🔥 Chat document updated');

      // Send FCM Notification
      await _sendNotification(receiverUid, myId, text);

      state = const AsyncValue.data(null);
      print('🔥 Message sent successfully');
    } catch (e, stackTrace) {
      print('🔥 Error sending message: $e');
      print('🔥 Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> sendImage(String chatId, String imageUrl, String myId) async {
    state = const AsyncValue.loading();

    try {
      final firestore = FirebaseFirestore.instance;
      String? receiverUid;

      // Get receiver ID from chat participants
      final chatDoc = await firestore.collection('chats').doc(chatId).get();

      if (chatDoc.exists) {
        final chatData = chatDoc.data();
        final participantsData = chatData?['participants'];

        if (participantsData != null) {
          // Safe conversion from dynamic list to string list
          List<String> participants = [];
          if (participantsData is List) {
            participants = participantsData.map((e) => e.toString()).toList();
          }

          // Find receiver
          for (final participant in participants) {
            if (participant != myId) {
              receiverUid = participant;
              break;
            }
          }
        }
      }

      if (receiverUid == null || receiverUid.isEmpty) {
        throw Exception('Could not determine receiver for image message');
      }

      // Create message with consistent structure
      final messagePayload = {
        'from': myId,
        'to': receiverUid,
        'text': '',
        'type': 'image',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Add message to subcollection
      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messagePayload);

      // Update chat document
      await firestore.collection('chats').doc(chatId).update({
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageFrom': myId,
      });

      // Send FCM Notification
      await _sendNotification(receiverUid, myId, '📷 Photo');

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> _sendNotification(
    String receiverUid,
    String senderUid,
    String message,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get receiver data
      final receiverDocEmail =
          await firestore
              .collection('user_details_email')
              .doc(receiverUid)
              .get();
      final receiverDocPhone =
          await firestore
              .collection('user_details_phone')
              .doc(receiverUid)
              .get();
      final receiverData =
          receiverDocEmail.exists
              ? receiverDocEmail.data()
              : receiverDocPhone.data();

      // Get sender data
      final senderDocEmail =
          await firestore.collection('user_details_email').doc(senderUid).get();
      final senderDocPhone =
          await firestore.collection('user_details_phone').doc(senderUid).get();
      final senderName =
          senderDocEmail.data()?['name'] ??
          senderDocPhone.data()?['name'] ??
          'Someone';

      final fcmToken = receiverData?['fcm_token'];

      if (fcmToken != null && fcmToken.toString().isNotEmpty) {
        await FCMService.sendPushNotification(
          toToken: fcmToken,
          title: 'New Message from $senderName',
          body: message,
        );
      }
    } catch (e) {
      print('Failed to send notification: $e');
      // Don't throw here, notification failure shouldn't break message sending
    }
  }
}

final sendMessageProvider =
    StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>(
      (ref) => SendMessageNotifier(),
    );
