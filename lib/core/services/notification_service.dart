import 'dart:convert'; // استيراد مكتبة التحويل لمعالجة بيانات الـ Payload
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // مكتبة الإشعارات المحلية
import 'package:timezone/data/latest.dart' as tz; // بيانات المناطق الزمنية
// import 'package:timezone/timezone.dart' as tz; // مكتبة الوقت
import 'package:get/get.dart'; // مكتبة GetX للتنقل والترجمة
import 'package:flutter/foundation.dart';

import 'package:al_maqraa/Student/pages/chat_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // تعطيل الإشعارات للويب ولنظام ويندوز
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;
    
    tz.initializeTimeZones();

    // إعداد أيقونة التطبيق لنظام أندرويد
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات نظام iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        // هذه الدالة تنفذ عند النقر على الإشعار
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
    } catch (e) {
      Get.log("${"notification_init_error".tr}: $e");
    }
  }

  /// دالة معالجة النقر على الإشعار والتوجيه الذكي
  void _onNotificationTap(NotificationResponse response) {
    // حذف الإشعار فور النقر عليه لضمان عدم بقائه في الشريط
    if (response.id != null) {
      _notificationsPlugin.cancel(response.id!);
    }

    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        handleRouting(data);
      } catch (e) {
        Get.log("Error parsing notification payload: $e");
      }
    }
  }

  /// التوجيه المركزي للشاشة المستهدفة بناءً على نوع وبيانات الإشعار
  static void handleRouting(Map<String, dynamic> data) {
    try {
      final String type = data['type']?.toString() ?? 'chat';
      final String? senderId = data['senderId']?.toString();
      final String? senderName = data['senderName']?.toString() ?? data['title']?.toString();
      final String? senderRole = data['senderRole']?.toString();

      if (type == 'chat' && senderId != null && senderId.isNotEmpty) {
        // فتح شاشة الدردشة مباشرة مع الطرف المرسل
        Get.to(
          () => ChatScreen(
            otherUserId: senderId,
            otherUserName: senderName ?? 'chat'.tr,
            otherUserRole: senderRole ?? 'student',
          ),
        );
      } else if (type == 'achievement' || type == 'review' || type == 'report') {
        // عند النقر على إشعار إنجاز أو تقييم، التوجه للصفحة الرئيسية أو الإشعارات
        try {
          Get.toNamed('/home');
        } catch (_) {}
      } else {
        Get.log("Handling general notification tap: $type");
      }
    } catch (e) {
      Get.log("Error in handleRouting: $e");
    }
  }

  /// عرض إشعار فوري
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>?
    data, // استقبال البيانات كـ Map بدلاً من String لسهولة التعامل
  }) async {
    // تعطيل الإشعارات للويب ولنظام ويندوز
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    // تحويل البيانات لنص JSON ليتم حفظها في الـ Payload
    final String? payload = data != null ? jsonEncode(data) : null;

    const platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'app_notifications',
        channelDescription: 'app_notifications_desc',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        fullScreenIntent: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        id,
        title, // العنوان (يصل مترجماً)
        body, // النص (يصل مترجماً)
        platformChannelSpecifics,
        payload: payload, // تمرير البيانات لكي تُستخدم عند النقر
      );
    } catch (e) {
      Get.log("${"notification_show_error".tr}: $e");
    }
  }

  /// حذف الإشعار الخاص بمحادثة معينة برمجياً
  Future<void> dismissNotification(String chatId) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;
    await _notificationsPlugin.cancel(chatId.hashCode);
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;
    await _notificationsPlugin.cancelAll();
  }
}
