import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;

class FCMService {
  static Future<void> sendPushNotification({
    required String toToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Load service account credentials
    final serviceAccount = await rootBundle.loadString(
      'assets/firebase_service_account.json',
    );
    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);

    // Define Firebase Messaging scope
    const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // Authenticate
    final authClient = await clientViaServiceAccount(credentials, scopes);

    // Your Firebase project ID
    const projectId = 'sporticturfs';

    // FCM v1 endpoint
    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    // Construct the payload
    final message = {
      "message": {
        "token": toToken,
        "notification": {"title": title, "body": body},
        if (data != null) "data": data,
        "android": {
          "priority": "high",
          "notification": {"click_action": "FLUTTER_NOTIFICATION_CLICK"},
        },
        "apns": {
          "headers": {"apns-priority": "10"},
          "payload": {
            "aps": {
              "alert": {"title": title, "body": body},
              "sound": "default",
              "category": "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        },
      },
    };

    // Send request
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('[FCM] ✅ Push sent successfully!');
    } else {
      print('[FCM] ❌ Failed to send push: ${response.body}');
    }

    authClient.close();
  }
}
