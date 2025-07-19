// // ✅ Updated sendMessageProvider to support UID or Email based login
//
// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:uuid/uuid.dart';
//
// final sendMessageProvider = Provider((ref) {
//   return SendMessageService();
// });
//
// class SendMessageService {
//   final _uuid = const Uuid();
//
//   Future<void> _ensureChatExists(String chatId) async {
//     final docRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
//     final doc = await docRef.get();
//     if (!doc.exists) {
//       final participants = chatId.split('_');
//       await docRef.set({
//         'participants': participants,
//         'createdAt': FieldValue.serverTimestamp(),
//         'lastUpdated': FieldValue.serverTimestamp(),
//       });
//     } else {
//       await docRef.update({'lastUpdated': FieldValue.serverTimestamp()});
//     }
//   }
//
//   Future<void> sendText(String chatId, String text, String fromId) async {
//     if (fromId.isEmpty) return;
//
//     await _ensureChatExists(chatId);
//
//     await FirebaseFirestore.instance
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .add({
//           'text': text,
//           'from': fromId,
//           'type': 'text',
//           'timestamp': FieldValue.serverTimestamp(),
//           'read': false,
//         });
//   }
//
//   Future<void> sendImage(String chatId, File imageFile, String fromId) async {
//     if (fromId.isEmpty) {
//       debugPrint("❌ sendImage failed: fromId is empty");
//       return;
//     }
//
//     await _ensureChatExists(chatId);
//
//     try {
//       final fileId = _uuid.v4();
//       final storageRef = FirebaseStorage.instance.ref().child(
//         'chat_images/$chatId/$fileId.jpg',
//       );
//
//       await storageRef.putFile(imageFile);
//       final imageUrl = await storageRef.getDownloadURL();
//       debugPrint("✅ Uploaded image. URL: $imageUrl");
//
//       await FirebaseFirestore.instance
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .add({
//             'imageUrl': imageUrl,
//             'from': fromId,
//             'type': 'image',
//             'timestamp': FieldValue.serverTimestamp(),
//             'read': false,
//           });
//
//       debugPrint("✅ Image message sent to chat");
//     } catch (e) {
//       debugPrint("❌ Error in sendImage: $e");
//     }
//   }
// }

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Services/notification_service.dart'; // Create this to share _getUserData logic

final secureStorage = FlutterSecureStorage();

final sendMessageProvider = Provider.family<Future<void>, Map<String, dynamic>>(
  (ref, data) async {
    final firestore = FirebaseFirestore.instance;

    final chatId = data['chatId'];
    final message = data['message'];
    final receiverUid = data['receiverUid'];

    final senderUid =
        FirebaseAuth.instance.currentUser?.uid ??
        await secureStorage.read(key: 'custom_uid');

    if (senderUid == null ||
        chatId == null ||
        receiverUid == null ||
        message == null) {
      throw 'Missing data';
    }

    final messagePayload = {
      'senderId': senderUid,
      'receiverId': receiverUid,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messagePayload);

    // 🔔 Send FCM Notification
    final receiverDocEmail =
        await firestore.collection('user_details_email').doc(receiverUid).get();
    final receiverDocPhone =
        await firestore.collection('user_details_phone').doc(receiverUid).get();
    final receiverData =
        receiverDocEmail.exists
            ? receiverDocEmail.data()
            : receiverDocPhone.data();

    final fcmToken = receiverData?['fcm_token'];
    final senderDocEmail =
        await firestore.collection('user_details_email').doc(senderUid).get();
    final senderDocPhone =
        await firestore.collection('user_details_phone').doc(senderUid).get();
    final senderName =
        senderDocEmail.data()?['name'] ??
        senderDocPhone.data()?['name'] ??
        'Someone';

    if (fcmToken != null && fcmToken.toString().isNotEmpty) {
      await FCMService.sendPushNotification(
        toToken: fcmToken,
        title: 'New Message',
        body: '$senderName: $message',
      );
    }
  },
);
