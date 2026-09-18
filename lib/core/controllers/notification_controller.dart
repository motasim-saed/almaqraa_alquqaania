import 'dart:io' show Platform; // استيراد مكتبة IO للتعامل مع خصائص النظام مثل نوع المنصة (أندرويد/iOS)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية للواجهات والألوان

import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والتنقل
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة Supabase للتعامل مع قاعدة البيانات السحابية
import 'package:get_storage/get_storage.dart'; // استيراد مكتبة تخزين البيانات المحلية البسيطة
import 'package:app_badge_plus/app_badge_plus.dart'; // استيراد مكتبة التحكم في شارة التطبيق (الرقم على الأيقونة)
import '../models/notification_model.dart'; // استيراد نموذج بيانات الإشعارات
import '../services/notification_service.dart'; // استيراد خدمة الإشعارات المحلية للنظام
import '../../Admin/controller/chat_controller.dart'; // استيراد متحكم الدردشة الخاص بالأدمن لضمان المزامنة

class NotificationController extends GetxController with WidgetsBindingObserver {
  // تعريف عميل Supabase للقيام بالعمليات على قاعدة البيانات
  final SupabaseClient _supabase = Supabase.instance.client;
  // تعريف مخزن البيانات المحلي (GetStorage) لعمل كاش للإشعارات
  final _storage = GetStorage();

  // متغيرات مراقبة (Observable) تتحدث تلقائياً في الواجهة عند تغير قيمتها:
  var notifications = <NotificationModel>[].obs; // قائمة الإشعارات المعروضة
  var unreadCount = 0.obs; // عداد الرسائل غير المقروءة
  var unreadNotificationsCount = 0.obs; // عداد الإشعارات الإدارية غير المقروءة
  var isLoading = false.obs; // حالة التحميل (لتوضيح مؤشر الانتظار)
  var currentUserRole =
      ''.obs; // دور المستخدم الحالي (طالب، معلم، مدير) لتصفية الإشعارات

  static const String _lastSeenNotificationKey = 'last_seen_notification_id';

  @override
  void onInit() {
    super.onInit();
    // إضافة مراقب لحالة التطبيق لمزامنة البيانات عند العودة من الخلفية (Lifecycle)
    WidgetsBinding.instance.addObserver(this);
    
    // مراقبة حالة تسجيل الدخول: عند الدخول نبدأ العمل، وعند الخروج ننظف البيانات
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession) {
        _initialize(); // بدء التهيئة عند وجود جلسة نشطة
      } else if (event == AuthChangeEvent.signedOut) {
        notifications.clear(); // مسح الإشعارات عند الخروج
        currentUserRole.value = ''; // إعادة تعيين الدور
        _supabase.removeAllChannels(); // إغلاق كافة قنوات الاستماع اللحظي
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // إزالة المراقب عند إغلاق المتحكم
    super.onClose();
  }

  // معالجة تغيير حالة التطبيق (مثل العودة من الخلفية)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // عند عودة المستخدم للتطبيق، نقوم بتحديث كل البيانات لضمان عدم ضياع أي إشعار وصل في الخلفية عبر Firebase
      refreshData();
    }
  }

  // دالة شاملة لتحديث كافة البيانات (الإشعارات، العدادات، الأدوار)
  // تحسين أداء الخيط الرئيسي: تشغيل الاستعلامات المستقلة بالتوازي بدل التسلسل
  Future<void> refreshData() async {
    await _fetchUserRole();
    await Future.wait([fetchNotifications(), updateUnreadCount()]);
  }

  // دالة التهيئة الاحترافية: تجمع بين جلب البيانات الأولي وتفعيل الاستماع اللحظي
  // تُؤجل لما بعد أول إطار لتجنب Skipped frames عند بدء التشغيل
  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await refreshData();
    // تفعيل Realtime لتحديث الواجهة لحظياً أثناء استخدام التطبيق
    _listenToMessageChanges();
    _listenToNewNotifications();
  }

  // قائمة معرفات المحادثات الخاصة بالمستخدم (لتحسين أداء التنبيهات والعداد)
  final RxList<String> _myChatIds = <String>[].obs;

  // دالة لتحديث عداد الرسائل غير المقروءة
  Future<void> updateUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. جلب كافة المحادثات التي يشارك فيها المستخدم
      final List<String> myCircleIds = [];
      try {
        final circleMembers = await _supabase
            .from('circle_members')
            .select('circle_id')
            .eq('student_id', userId);
        myCircleIds.addAll(
          (circleMembers as List)
              .map((m) => m['circle_id'].toString())
              .toList(),
        );

        final teacherCircles = await _supabase
            .from('circles')
            .select('id')
            .eq('teacher_id', userId);
        myCircleIds.addAll(
          (teacherCircles as List).map((c) => c['id'].toString()).toList(),
        );
      } catch (e) {}

      // 2. تجميع كافة معرفات المحادثات المرتبطة بالمستخدم
      try {
        String chatFilter = 'student_id.eq.$userId,teacher_id.eq.$userId';
        if (myCircleIds.isNotEmpty) {
          chatFilter += ',circle_id.in.(${myCircleIds.join(",")})';
        }

        final chatsResp = await _supabase
            .from('chats')
            .select('id')
            .or(chatFilter);
        final List<String> fetchedIds = (chatsResp as List)
            .map((c) => c['id'].toString())
            .toList();

        _myChatIds.assignAll(fetchedIds);
      } catch (e) {}

      // 3. حساب الرسائل غير المقروءة مباشرة من قاعدة البيانات
      if (_myChatIds.isNotEmpty) {
        final response = await _supabase
            .from('messages')
            .select('id')
            .filter('chat_id', 'in', _myChatIds)
            .neq('sender_id', userId)
            .filter('read_at', 'is', null);

        unreadCount.value = (response as List).length;
      } else {
        unreadCount.value = 0;
      }

      _syncCountsWithOtherControllers();
      _updateAppBadge();
    } catch (e) {}
  }

  void _syncCountsWithOtherControllers() {
    try {
      if (Get.isRegistered<AdminChatController>(tag: 'student')) {
        Get.find<AdminChatController>(tag: 'student').fetchChats();
      }
      if (Get.isRegistered<AdminChatController>(tag: 'teacher')) {
        Get.find<AdminChatController>(tag: 'teacher').fetchChats();
      }
    } catch (_) {}
  }

  void _updateAppBadge() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      if (unreadCount.value > 0) {
        AppBadgePlus.updateBadge(unreadCount.value);
      } else {
        AppBadgePlus.updateBadge(0);
      }
    } catch (_) {}
  }

  // استماع Realtime لتحديث عدادات الرسائل لحظياً (بدون إظهار تنبيهات للنظام لتجنب التكرار مع Firebase)
  void _listenToMessageChanges() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .channel('public:messages_realtime_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            // تحديث العدادات فوراً في الواجهة عند أي تغيير في الرسائل
            updateUnreadCount();
            
            // ملاحظة: لا نستدعي NotificationService هنا لأن Firebase سيتولى إظهار التنبيه
            // Realtime هنا وظيفته فقط جعل التطبيق يبدو "حياً" وسريعاً في تحديث الأرقام
          },
        )
        .subscribe();
  }

  Future<void> _fetchUserRole() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUserId)
          .maybeSingle();

      if (response != null) {
        currentUserRole.value = response['role'] ?? '';
      }
    } catch (e) {}
  }

  Future<void> fetchNotifications() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (currentUserRole.value.isEmpty) {
        await _fetchUserRole();
      }
      
      final role = currentUserRole.value;
      if (role.isEmpty) return;

      var query = _supabase
          .from('notifications')
          .select()
          .or('target_role.eq.$role,target_role.eq.all');
      
      if (userId != null) {
        query = query.neq('sender_id', userId);
      }

      final response = await query.order('created_at', ascending: false).limit(50);

      final fetched = (response as List)
          .map((data) => NotificationModel.fromJson(data))
          .toList();

      notifications.assignAll(fetched);
      _updateUnreadNotificationsCount();
      _storage.write(
        'notifications_cache',
        fetched.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      final cached = _storage.read('notifications_cache');
      if (cached != null && cached is List) {
        notifications.assignAll(
          cached.map((data) => NotificationModel.fromJson(data)).toList(),
        );
        _updateUnreadNotificationsCount();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _updateUnreadNotificationsCount() {
    if (notifications.isEmpty) {
      unreadNotificationsCount.value = 0;
      return;
    }

    final lastSeenId = _storage.read(_lastSeenNotificationKey);
    if (lastSeenId == null) {
      unreadNotificationsCount.value = notifications.length;
    } else {
      int count = 0;
      for (var n in notifications) {
        if (n.id == lastSeenId.toString()) break;
        count++;
      }
      unreadNotificationsCount.value = count;
    }
  }

  void markNotificationsAsSeen() {
    if (notifications.isNotEmpty) {
      _storage.write(_lastSeenNotificationKey, notifications.first.id);
      unreadNotificationsCount.value = 0;
    }
  }

  // استماع Realtime لتحديث قائمة إشعارات الإدارة لحظياً أثناء فتح التطبيق
  void _listenToNewNotifications() {
    final role = currentUserRole.value;
    if (role.isEmpty) return;

    _supabase
        .channel('public:notifications_realtime_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final currentRole = currentUserRole.value;
            final currentUserId = _supabase.auth.currentUser?.id;

            if (payload.eventType == PostgresChangeEvent.insert) {
              final newNotification = NotificationModel.fromJson(payload.newRecord);
              if (newNotification.senderId == currentUserId) return;

              if (newNotification.targetRole == currentRole || newNotification.targetRole == 'all') {
                // إضافة الإشعار للقائمة فوراً دون انتظار Firebase
                if (!notifications.any((n) => n.id == newNotification.id)) {
                  notifications.insert(0, newNotification);
                  _updateUnreadNotificationsCount();
                }
              }
            } else if (payload.eventType == PostgresChangeEvent.delete) {
               final deletedId = payload.oldRecord['id'].toString();
               notifications.removeWhere((n) => n.id == deletedId);
            }
          },
        )
        .subscribe();
  }
}
