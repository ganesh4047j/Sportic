import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys
  static const _keyUid = 'custom_uid';
  static const _keyPhoneLoggedIn = 'phone_logged_in';
  static const _keyGoogleLoggedIn = 'google_logged_in';

  // 🔐 Save UID
  static Future<void> saveUid(String uid) async {
    await _storage.write(key: _keyUid, value: uid);
  }

  // 🔐 Get UID
  static Future<String?> getUid() async {
    return await _storage.read(key: _keyUid);
  }

  // 📱 Mark Phone Login
  static Future<void> setPhoneLoggedIn(bool value) async {
    await _storage.write(key: _keyPhoneLoggedIn, value: value.toString());
  }

  // 📱 Check if phone user is logged in
  static Future<bool> isPhoneLoggedIn() async {
    final value = await _storage.read(key: _keyPhoneLoggedIn);
    return value == 'true';
  }

  // 📧 Mark Google Login
  static Future<void> setGoogleLoggedIn(bool value) async {
    await _storage.write(key: _keyGoogleLoggedIn, value: value.toString());
  }

  // 📧 Check if Google user is logged in
  static Future<bool> isGoogleLoggedIn() async {
    final value = await _storage.read(key: _keyGoogleLoggedIn);
    return value == 'true';
  }

  // 🚫 Clear all stored values (used on logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
