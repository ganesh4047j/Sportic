import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> saveFcmTokenToFirestore({required String collection}) async {
  const storage = FlutterSecureStorage();
  final uid = await storage.read(key: 'custom_uid');

  if (uid == null) {
    print('[FCM] UID missing');
    return;
  }

  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) {
    print('[FCM] Token fetch failed');
    return;
  }

  final docRef = FirebaseFirestore.instance.collection(collection).doc(uid);

  try {
    await docRef.set({'fcm_token': token}, SetOptions(merge: true));
    print('[FCM] Token saved to $collection/$uid');
  } catch (e) {
    print('[FCM] Firestore save failed: $e');
  }

  print('[FCM] Token: $token');
}
