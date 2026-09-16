import 'dart:async'; // استيراد مكتبة العمليات المتزامنة لإدارة الاشتراكات والمؤقتات
import 'package:al_maqraa/core/services/connectivity_service.dart'; // استيراد خدمة مراقبة حالة الاتصال بالإنترنت
import 'package:al_maqraa/core/services/local_database_service.dart'; // استيراد خدمة قاعدة البيانات المحلية (SQLite)
import 'package:al_maqraa/Student/repository/supabase_student_repository.dart'; // استيراد مستودع بيانات الطالب للتعامل مع Supabase
import 'package:al_maqraa/Student/repository/supabase_chat_repository.dart'; // استيراد مستودع المحادثات للرفع
import 'package:al_maqraa/Admin/models/admin_models.dart'; // استيراد نموذج الرسائل
import 'package:al_maqraa/Student/models/student_models.dart'; // استيراد نماذج بيانات الطالب (السجل والخطط)
import 'package:flutter/material.dart'; // لاستخدام الألوان والأيقونات
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة GetX لإدارة الخدمات والحالة والترجمة

/// شرح عمل الملف:
/// خدمة المزامنة الخلفية (BackgroundSyncService) المحدثة لضمان شمولية كافة بيانات التطبيق.
/// تقوم الخدمة بمراقبة الإنترنت والقيام بمزامنة آلية لكافة الجداول المحلية (الرسائل، السجلات، الخطط).
/// تم تحديثها لإظهار رسائل للمستخدم بدلاً من الطباعة في الكونسول.

class BackgroundSyncService extends GetxService {
  final _connectivity = Get.find<ConnectivityService>();
  final _localDb = Get.find<LocalDatabaseService>();
  final _studentRepo = SupabaseStudentRepository();
  final _chatRepo = SupabaseChatRepository();

  late StreamSubscription _subscription;

  /// تهيئة الخدمة والبدء في مراقبة حالة الإنترنت
  Future<BackgroundSyncService> init() async {
    _subscription = _connectivity.isConnected.listen((connected) {
      if (connected) {
        syncAll(silent: true); // مزامنة صامتة عند عودة الإنترنت تلقائياً
      }
    });
    return this;
  }

  /// الدالة الشاملة لبدء مزامنة كافة الأقسام
  /// [silent] إذا كانت true لن تظهر رسائل تنبيهية عند البدء (تستخدم في الخلفية)
  Future<void> syncAll({bool silent = false}) async {
    if (!silent) {
      _showSyncStatus('sync_started'.tr, Colors.blue);
    }

    try {
      // 1. مزامنة البيانات المحلية (رفع التعديلات)
      await syncMessages();
      await syncDailyRecords();
      await syncPlans();

      // 2. تحديث البيانات المحلية من السيرفر (سحب التعديلات)
      await pullAll();

      if (!silent) {
        _showSyncStatus('sync_success'.tr, Colors.green);
      }
    } catch (e) {
      if (!silent) {
        _showSyncStatus('sync_error'.tr, Colors.red);
      }
    }
  }

  /// تحديث كافة البيانات من السيرفر (Pull Sync)
  Future<void> pullAll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. تحديث الملف الشخصي
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null) {
        await _localDb.saveProfile(profile);

        final role = profile['role']?.toString().toLowerCase();

        // 2. تحديث الحلقات بناءً على الدور
        if (role == 'student') {
          await _pullStudentCircles(user.id);
        } else if (role == 'teacher' || role == 'examiner') {
          await _pullTeacherCircles(user.id);
        } else if (role == 'coordinator' || role == 'admin') {
          await _pullAllCircles(); // المنسق يرى كل الحلقات غالباً
        }
      }
    } catch (e) {
    }
  }

  Future<void> _pullStudentCircles(String studentId) async {
    final response = await Supabase.instance.client
        .from('circle_members')
        .select('circles(*)')
        .eq('student_id', studentId);

    for (var item in (response as List)) {
      if (item['circles'] != null) {
        await _localDb.saveCircle(item['circles']);
      }
    }
  }

  Future<void> _pullTeacherCircles(String teacherId) async {
    final response = await Supabase.instance.client
        .from('circles')
        .select()
        .or('teacher_id.eq.$teacherId,examiner_id.eq.$teacherId');

    for (var circle in (response as List)) {
      await _localDb.saveCircle(circle);
    }
  }

  Future<void> _pullAllCircles() async {
    final response = await Supabase.instance.client
        .from('circles')
        .select()
        .limit(50); // جلب عينة من آخر الحلقات للمنسق

    for (var circle in (response as List)) {
      await _localDb.saveCircle(circle);
    }
  }

  /// إظهار رسالة منبثقة (Snackbar) بحالة المزامنة
  void _showSyncStatus(String message, Color color) {
    Get.snackbar(
      'sync_status'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.sync, color: Colors.white),
      margin: const EdgeInsets.all(15),
    );
  }

  /// --- 1. مزامنة الرسائل ---
  Future<void> syncMessages() async {
    final unsynced = await _localDb.getUnsyncedRecords('messages');
    if (unsynced.isEmpty) return;

    for (var data in unsynced) {
      try {
        final message = MessageModel.fromJson(data);
        await _chatRepo.sendMessage(message.toMap());
        await _localDb.markAsSynced('messages', message.id);
      } catch (e) {
        continue;
      }
    }
  }

  /// --- 2. مزامنة السجلات اليومية ---
  Future<void> syncDailyRecords() async {
    final unsynced = await _localDb.getUnsyncedRecords('daily_records');
    if (unsynced.isEmpty) return;

    for (var data in unsynced) {
      try {
        final record = DailyRecordModel.fromJson(data);
        await _studentRepo.saveDailyRecord(record);
        await _localDb.markAsSynced('daily_records', record.id);
      } catch (e) {
        continue;
      }
    }
  }

  /// --- 3. مزامنة الخطط الدراسية ---
  Future<void> syncPlans() async {
    final unsynced = await _localDb.getUnsyncedRecords('plans');
    if (unsynced.isEmpty) return;

    for (var data in unsynced) {
      try {
        final type = data['type'];
        if (type == 'annual') {
          await _studentRepo.saveAnnualPlan(AnnualPlanModel.fromJson(data));
        } else if (type == 'monthly') {
          await _studentRepo.saveMonthlyPlan(MonthlyPlanModel.fromJson(data));
        }
        await _localDb.markAsSynced('plans', data['id'].toString());
      } catch (e) {
        continue;
      }
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
