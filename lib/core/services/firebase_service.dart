import 'package:firebase_core/firebase_core.dart'; // استيراد مكتبة فيربيز الأساسية لبدء الخدمات
import 'package:firebase_messaging/firebase_messaging.dart'; // استيراد مكتبة رسائل فيربيز لإدارة الإشعارات
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد مكتبة سوبابيس لربط البيانات بالسيرفر
import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية للألوان والواجهات
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة والرسائل المنبثقة
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // إضافة مكتبة الإشعارات المحلية لإنشاء القنوات
import 'notification_service.dart'; // استيراد خدمة التنبيهات المحلية لعرض الإشعارات في النظام
import 'chat_cache_service.dart';
import '../../Admin/models/admin_models.dart';
import '../../Admin/controller/chat_controller.dart';

/// خدمة فيربيز المحدثة لضمان وصول الإشعارات في كافة حالات التطبيق
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> init() async {
    // 1. إنشاء قناة الإشعارات للأندرويد برمجياً لضمان ظهور الإشعارات المنبثقة (Head-up)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id مطابق للموجود في AndroidManifest والسيرفر
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. طلب الإذن وتجهيز القنوات للأندرويد
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 3. تحديث التوكن عند تسجيل الدخول
      _supabase.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.initialSession) {
          await saveTokenToSupabase();
        }
      });

      // 4. تحديث التوكن عند تجدده من جوجل
      _messaging.onTokenRefresh.listen((newToken) {
        _updateTokenInSupabase(newToken);
      });

      // 5. معالجة الرسالة عند النقر عليها والتطبيق مغلق تماماً (Terminated)
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          handleNotificationTap(message.data);
        }
      });

      // 6. معالجة الرسالة عند النقر عليها والتطبيق في الخلفية (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        handleNotificationTap(message.data);
      });

      // 7. استقبال الإشعارات والتطبيق مفتوح (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        handleIncomingMessage(message);
      });
    }
  }

  static void handleIncomingMessage(RemoteMessage message) {
    // استخراج البيانات من الإشعار سواء كان Notification أو Data Payload
    String title = message.notification?.title ?? message.data['title'] ?? 'new_notification'.tr;
    String body = message.notification?.body ?? message.data['body'] ?? '';
    
    if (body.isNotEmpty) {
      // استخدام معرف مخصص بحسب المحادثة أو الحدث لدمج الإشعارات المتكررة في إشعار واحد محدّث
      final dynamic groupKey = message.data['chatId'] ??
          message.data['senderId'] ??
          message.data['studentId'] ??
          message.data['recordId'] ??
          message.data['id'] ??
          message.messageId;
      final int notifId = groupKey.hashCode;

      // عرض إشعار محلي ليظهر في ستارة الإشعارات
      NotificationService().showNotification(
        id: notifId,
        title: title,
        body: body,
        data: message.data,
      );

      // إذا كان الإشعار يتعلق بمحادثة، نقوم بتخزينه وتحديث الواجهات
      if (message.data['type'] == 'chat') {
        _saveMessageLocally(message.data, body);
      }
    }
  }

  /// التوجيه التلقائي للمكان المناسب عند النقر على الإشعار
  static void handleNotificationTap(Map<String, dynamic> data) {
    NotificationService.handleRouting(data);
  }

  static Future<void> _saveMessageLocally(Map<String, dynamic> data, String body) async {
    try {
      final String? chatId = data['chatId']?.toString();
      final String? senderId = data['senderId']?.toString();

      if (chatId != null && chatId.isNotEmpty && senderId != null && senderId.isNotEmpty) {
        DateTime parsedDate = DateTime.now();
        if (data['created_at'] != null) {
          parsedDate = DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now();
        }

        final newMessage = MessageModel(
          id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          chatID: chatId,
          senderId: senderId,
          text: data['text']?.toString() ?? body,
          createdAt: parsedDate,
          receiverId: Supabase.instance.client.auth.currentUser?.id,
        );

        if (Get.isRegistered<ChatCacheService>()) {
          await Get.find<ChatCacheService>().saveMessages([newMessage]);
        }
        
        // تحديث القوائم المفتوحة للمسؤول/المنسق
        if (Get.isRegistered<AdminChatController>()) {
          Get.find<AdminChatController>().fetchChats();
        }
      }
    } catch (e) {
      Get.log("Error saving message locally: $e");
    }
  }

  Future<void> saveTokenToSupabase() async {
    try {
      String? token;
      // في حالة الويندوز لا يوجد FCM token حالياً بشكل رسمي مباشر مثل الأندرويد
      try {
        token = await _messaging.getToken();
      } catch (e) {}
      
      if (token != null) {
        await _updateTokenInSupabase(token);
      }
    } catch (e) {}
  }

  Future<void> _updateTokenInSupabase(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase.from('profiles').update({'fcm_token': token}).eq('id', userId);
      } catch (e) {}
    }
  }
}
