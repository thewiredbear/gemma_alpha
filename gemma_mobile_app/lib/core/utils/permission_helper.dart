import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestStoragePermission() async {
    // Only request permissions on Android
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      } else {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
    }
    // iOS doesn't need these permissions for app documents directory
    return true;
  }
}