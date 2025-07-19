import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 📱 Phone number controller provider
final phoneControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// ✅ Checkbox state (agreed to terms)
final agreedToTermsProvider = StateProvider<bool>((ref) => false);

/// 🔐 MSG91 credentials provider from Firestore
final msg91CredentialsProvider =
FutureProvider<({String widgetId, String authToken})>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('credentials')
      .doc('otpcredentials')
      .get();

  if (!doc.exists) {
    throw Exception("OtpService document does not exist.");
  }

  final data = doc.data()!;
  // Debug log (optional):
  debugPrint("OtpService Firestore Data: $data");

  if (!data.containsKey('widgetId') || !data.containsKey('authToken')) {
    throw Exception("Missing 'widgetId' or 'widgetToken' in OtpService.");
  }

  return (
  widgetId: data['widgetId'] as String,
  authToken: data['authToken'] as String,
  );
});

/// 🧠 UID retriever from phone number (used for re-login after reinstall)
Future<String?> getUidFromPhone(String phoneNumber) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('user_details_phone')
      .where('phone_number', isEqualTo: phoneNumber)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.id; // UID is the doc ID
  }
  return null;
}