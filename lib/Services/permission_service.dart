// Create: lib/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static Future<bool> requestCameraAndMicrophonePermissions() async {
    // Request multiple permissions at once
    Map<Permission, PermissionStatus> permissions =
        await [
          Permission.camera,
          Permission.microphone,
          Permission.storage,
        ].request();

    // Check if all permissions are granted
    bool allPermissionsGranted =
        permissions[Permission.camera]?.isGranted == true &&
        permissions[Permission.microphone]?.isGranted == true &&
        permissions[Permission.storage]?.isGranted == true;

    return allPermissionsGranted;
  }

  static Future<bool> checkPermissions() async {
    bool cameraGranted = await Permission.camera.isGranted;
    bool microphoneGranted = await Permission.microphone.isGranted;
    bool storageGranted = await Permission.storage.isGranted;

    return cameraGranted && microphoneGranted && storageGranted;
  }

  static void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'This app needs camera and microphone permissions to stream live videos. '
              'Please grant permissions in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Settings'),
              ),
            ],
          ),
    );
  }
}
