import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// ينسخ نصاً إلى الحافظة مع إظهار تنبيه خفيف.
/// يستخدم في تطبيق الإدارة لنسخ بيانات المستخدمين (البريد، الهاتف، ...).
Future<void> copyToClipboard(String? text, {String? label}) async {
  final value = (text ?? '').trim();

  if (value.isEmpty || value == '-') {
    Get.snackbar(
      'copy'.tr,
      'nothing_to_copy'.tr,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    );
    return;
  }

  await Clipboard.setData(ClipboardData(text: value));

  final message = (label != null && label.trim().isNotEmpty)
      ? '${label.trim()} ✓'
      : 'copy_success'.tr;

  Get.snackbar(
    'copied'.tr,
    message,
    backgroundColor: Colors.green,
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 2),
    margin: const EdgeInsets.all(16),
  );
}
