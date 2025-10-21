import 'dart:io';
import 'package:flutter/material.dart' show VoidCallback;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestPhotoPermission({
    VoidCallback? onDenied,
  }) async {
    if (!Platform.isIOS) return true;

    final status = await Permission.photos
        .onDeniedCallback(onDenied ?? () {})
        .onPermanentlyDeniedCallback(onDenied ?? () {})
        .request();

    return status.isGranted || status.isLimited;
  }
}
