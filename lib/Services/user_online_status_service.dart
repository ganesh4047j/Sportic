import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserOnlineStatusService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _secureStorage = FlutterSecureStorage();

  static Future<void> setOnline(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      final uid = user?.uid ?? await _secureStorage.read(key: 'custom_uid');
      if (uid == null) return;

      final emailRef = _firestore.collection('user_details_email').doc(uid);
      final phoneRef = _firestore.collection('user_details_phone').doc(uid);

      final emailSnap = await emailRef.get();
      if (emailSnap.exists) {
        await emailRef.update({'isOnline': isOnline});
        return;
      }

      final phoneSnap = await phoneRef.get();
      if (phoneSnap.exists) {
        await phoneRef.update({'isOnline': isOnline});
      }
    } catch (e) {
      print('Failed to update isOnline: $e');
    }
  }
}