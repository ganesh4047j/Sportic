import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const String _uidKey = 'uid';
  static const String _phoneLoginKey = 'phone_login';

  static Future<void> setUid(String uid) async {
    await _storage.write(key: _uidKey, value: uid);
  }

  static Future<void> saveUid(String uid) async {
    await _storage.write(key: 'custom_uid', value: uid);
  }

  static Future<String?> getUid() async {
    return await _storage.read(key: _uidKey);
  }

  static Future<void> deleteUid() async {
    await _storage.delete(key: _uidKey);
  }

  static Future<void> setPhoneLoggedIn(bool isLoggedIn) async {
    await _storage.write(key: _phoneLoginKey, value: isLoggedIn.toString());
  }

  static Future<bool> isPhoneLoggedIn() async {
    final val = await _storage.read(key: _phoneLoginKey);
    return val == 'true';
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// 🔍 Retrieve UID from Firestore based on phone number
  static Future<String?> getUidFromPhone(String phoneNumber) async {
    final query =
        await FirebaseFirestore.instance
            .collection('user_details_phone')
            .where('phone_number', isEqualTo: phoneNumber)
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id; // UID is the document ID
    }
    return null;
  }
}
