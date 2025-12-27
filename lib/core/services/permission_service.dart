import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

// Handles camera permission flow and related checks.
class PermissionService {
  Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      debugPrint(
        'PermissionService.checkCameraPermission - status: $status',
      );
      return status.isGranted;
    } catch (e, stackTrace) {
      debugPrint('Error checking camera permission: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  Future<bool> requestCameraPermission() async {
    try {
      debugPrint(
        'PermissionService.requestCameraPermission - requesting permission',
      );
      final status = await Permission.camera.request();
      debugPrint(
        'PermissionService.requestCameraPermission - result: $status',
      );
      return status.isGranted;
    } catch (e, stackTrace) {
      debugPrint('Error requesting camera permission: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  Future<bool> isCameraPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.camera.status;
      debugPrint(
        'PermissionService.isCameraPermissionPermanentlyDenied - status: $status',
      );
      return status.isPermanentlyDenied;
    } catch (e, stackTrace) {
      debugPrint('Error checking permanent denial: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  // Opens system settings so the user can grant permission manually.
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e, stackTrace) {
      debugPrint('Error opening app settings: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
