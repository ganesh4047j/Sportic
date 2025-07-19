// ✅ Updated edit_profile_provider.dart
// edit_profile_provider.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileState {
  final String name;
  final String email;
  final String number;
  final String photoUrl;

  ProfileState({
    required this.name,
    required this.email,
    required this.number,
    required this.photoUrl,
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? number,
    String? photoUrl,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      number: number ?? this.number,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ProfileNotifier()
    : super(ProfileState(name: '', email: '', number: '', photoUrl: '')) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Firebase login (Google)
      final snap =
          await _firestore.collection('user_details_email').doc(user.uid).get();
      if (snap.exists) {
        final data = snap.data()!;
        state = state.copyWith(
          name: data['name'] ?? '',
          email: user.email ?? '',
          number: data['number'] ?? '',
          photoUrl: data['photoUrl'] ?? user.photoURL ?? '',
        );
      }
    } else {
      // Phone login
      final uid = await _secureStorage.read(key: 'uid');
      if (uid != null) {
        final snap =
            await _firestore.collection('user_details_phone').doc(uid).get();
        if (snap.exists) {
          final data = snap.data()!;
          state = state.copyWith(
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            number: data['number'] ?? '',
            photoUrl: data['photoUrl'] ?? '',
          );
        }
      }
    }
  }

  void updateName(String newName) {
    state = state.copyWith(name: newName);
  }

  void updateEmail(String newEmail) {
    state = state.copyWith(email: newEmail);
  }

  void updateNumber(String newNumber) {
    state = state.copyWith(number: newNumber);
  }

  Future<void> pickImageAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) {
      debugPrint('ℹ️ No image selected.');
      return;
    }

    final file = File(picked.path);
    if (!file.existsSync()) {
      debugPrint('❌ File does not exist at: ${file.path}');
      return;
    }

    final user = _auth.currentUser;
    final uid = user?.uid ?? await _secureStorage.read(key: 'custom_uid');

    if (uid == null || uid.isEmpty) {
      debugPrint("❌ UID is null or empty. Cannot upload.");
      return;
    }

    debugPrint("📌 UID used for storage: $uid");

    // Extract actual file extension
    final extension = picked.path.split('.').last;
    final ref = FirebaseStorage.instance.ref().child(
      'profile_pics/$uid.$extension',
    );

    try {
      final uploadTask = await ref.putFile(file);
      if (uploadTask.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        debugPrint("✅ Upload successful: $url");
        state = state.copyWith(photoUrl: url);
      } else {
        debugPrint("❌ Upload failed with state: ${uploadTask.state}");
      }
    } catch (e) {
      debugPrint("❌ Upload exception: $e");
    }
  }

  Future<void> saveProfile() async {
    final user = _auth.currentUser;
    final data = {
      'name': state.name,
      'email': state.email,
      'number': state.number,
      'photoUrl': state.photoUrl,
    };

    if (user != null) {
      await _firestore
          .collection('user_details_email')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
    } else {
      final uid = await _secureStorage.read(key: 'uid');
      if (uid != null) {
        await _firestore
            .collection('user_details_phone')
            .doc(uid)
            .set(data, SetOptions(merge: true));
      }
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('user_details_email').doc(user.uid).delete();
      await user.delete();
    } else {
      final uid = await _secureStorage.read(key: 'uid');
      if (uid != null) {
        await _firestore.collection('user_details_phone').doc(uid).delete();
        await _secureStorage.delete(key: 'uid');
      }
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier();
});
