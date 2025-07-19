import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sports/Main%20Screens/request_view.dart';
import 'package:sports/splash_screen.dart';
import 'Main Screens/chat_screen.dart';
import 'Services/fcm_token.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Handle FCM token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint('FCM token refreshed: $newToken');

    final firebaseUser = FirebaseAuth.instance.currentUser;
    String? uid = firebaseUser?.uid;

    if (uid == null) {
      const storage = FlutterSecureStorage();
      uid = await storage.read(key: 'custom_uid');
    }

    if (uid != null) {
      final firestore = FirebaseFirestore.instance;
      final emailDoc =
          await firestore.collection('user_details_email').doc(uid).get();

      if (emailDoc.exists) {
        await saveFcmTokenToFirestore(collection: 'user_details_email');
      } else {
        await saveFcmTokenToFirestore(collection: 'user_details_phone');
      }
    } else {
      debugPrint('[FCM] No UID found. Cannot save token.');
    }
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // Always start with splash
    );
  }
}

/// ✅ FCM Navigation Setup (friend request, chat tap handling)
void setupFCMNotificationListeners(BuildContext context) async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleNotificationNavigation(context, initialMessage);
  }

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationNavigation(context, message);
  });
}

void _handleNotificationNavigation(
  BuildContext context,
  RemoteMessage message,
) {
  final data = message.data;
  final type = data['type'];

  if (type == 'friend_request') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
    );
  } else if (type == 'chat') {
    final chatId = data['chatId'];
    final peerUid = data['from'];
    final peerName = data['fromName'];

    if (chatId != null && peerUid != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChatPage(
                chatId: chatId,
                peerUid: peerUid,
                peerName: peerName ?? '',
                peerEmail: '',
              ),
        ),
      );
    }
  }
}
