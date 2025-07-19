import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final currentUserIdProvider = FutureProvider<String>((ref) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser != null) {
    print('[currentUserIdProvider] Firebase user found: ${firebaseUser.uid}');
    return firebaseUser.uid;
  }

  final storage = FlutterSecureStorage();
  final customUid = await storage.read(key: 'custom_uid');

  if (customUid != null && customUid.isNotEmpty) {
    print(
      '[currentUserIdProvider] Using custom UID from secure storage: $customUid',
    );
    return customUid;
  }

  print('[currentUserIdProvider] No valid user ID found.');
  throw Exception('User is not logged in or UID is missing.');
});
