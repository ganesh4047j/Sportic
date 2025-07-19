import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final fbUser = FirebaseAuth.instance.currentUser;
  if (fbUser != null) {
    return fbUser.uid;
  }

  const storage = FlutterSecureStorage();
  final customUid = await storage.read(key: 'custom_uid');
  return customUid;
});

Future<Map<String, dynamic>> getUserData(String uid) async {
  final firestore = FirebaseFirestore.instance;

  final emailDoc =
      await firestore.collection('user_details_email').doc(uid).get();
  if (emailDoc.exists) return emailDoc.data()!;

  final phoneDoc =
      await firestore.collection('user_details_phone').doc(uid).get();
  if (phoneDoc.exists) return phoneDoc.data()!;

  return {};
}
