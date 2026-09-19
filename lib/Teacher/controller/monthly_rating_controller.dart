import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monthly_rating_model.dart';

/// متحكم التقييم الشهري للطلاب:
/// - المعلم يحفظ تقييماً (اختيار من 5 مستويات) لكل طالب/شهر/سنة
/// - الطالب يقرأ تقييماته (آخر تقييم + سجل السنة)
/// - يعمل مع جدول `monthly_ratings` في Supabase مع كاش محلي كاحتياط
///   حتى لو لم يُطبَّق الـ migration بعد.
class MonthlyRatingController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();

  /// آخر تقييم لكل طالب: studentId -> MonthlyRating
  final RxMap<String, MonthlyRating> latestByStudent = <String, MonthlyRating>{}.obs;

  /// سجل تقييمات طالب واحد (يُستخدم في ملف الطالب)
  final RxList<MonthlyRating> studentRatings = <MonthlyRating>[].obs;

  final RxBool isSaving = false.obs;
  final RxBool isLoading = false.obs;

  DateTime? _lastBatchFetch;
  String _lastBatchKey = '';

  String _cacheKey(String studentId) => 'monthly_ratings_$studentId';

  /// جلب آخر تقييم لمجموعة طلاب (لوحة المعلم) — يجمع بين الكاش والسيرفر
  Future<void> fetchLatestForStudents(List<String> studentIds) async {
    if (studentIds.isEmpty) return;
    // حماية من الاستدعاء المتكرر لنفس المجموعة (Obx قد يعيد البناء)
    final key = (List<String>.from(studentIds)..sort()).join(',');
    final now = DateTime.now();
    if (key == _lastBatchKey && _lastBatchFetch != null && now.difference(_lastBatchFetch!).inSeconds < 10) {
      return;
    }
    _lastBatchKey = key;
    _lastBatchFetch = now;
    // 1) كاش فوري
    for (final id in studentIds) {
      final cached = _storage.read(_cacheKey(id));
      if (cached != null && cached is List && cached.isNotEmpty) {
        try {
          final list =
              cached.map((e) => MonthlyRating.fromJson(Map<String, dynamic>.from(e))).toList();
          list.sort((a, b) => (b.year * 100 + b.month).compareTo(a.year * 100 + a.month));
          latestByStudent[id] = list.first;
        } catch (_) {}
      }
    }
    // 2) سيرفر
    try {
      final res = await _supabase
          .from('monthly_ratings')
          .select()
          .filter('student_id', 'in', studentIds)
          .order('year', ascending: false)
          .order('month', ascending: false);
      final Map<String, MonthlyRating> newest = {};
      for (final row in (res as List)) {
        final r = MonthlyRating.fromJson(Map<String, dynamic>.from(row));
        newest.putIfAbsent(r.studentId, () => r);
      }
      latestByStudent.addAll(newest);
      // تحديث الكاش لكل طالب
      for (final id in studentIds) {
        final mine = (res as List)
            .where((e) => (e['student_id']?.toString() ?? '') == id)
            .map((e) => MonthlyRating.fromJson(Map<String, dynamic>.from(e)).toJson())
            .toList();
        if (mine.isNotEmpty) _storage.write(_cacheKey(id), mine);
      }
    } catch (_) {
      // الجدول قد لا يكون موجوداً بعد — نكتفي بالكاش المحلي
    }
  }

  /// جلب سجل تقييمات طالب واحد (لشاشة الملف الشخصي للطالب)
  Future<void> fetchStudentRatings(String studentId) async {
    isLoading.value = true;
    try {
      final cached = _storage.read(_cacheKey(studentId));
      if (cached != null && cached is List) {
        studentRatings.assignAll(
          cached.map((e) => MonthlyRating.fromJson(Map<String, dynamic>.from(e))).toList(),
        );
      }
      final res = await _supabase
          .from('monthly_ratings')
          .select()
          .eq('student_id', studentId)
          .order('year', ascending: false)
          .order('month', ascending: false);
      final list = (res as List)
          .map((e) => MonthlyRating.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      studentRatings.assignAll(list);
      if (list.isNotEmpty) {
        latestByStudent[studentId] = list.first;
        _storage.write(_cacheKey(studentId), list.map((e) => e.toJson()).toList());
      }
    } catch (_) {
      // بدون سيرفر: يبقى الكاش المعروض
    } finally {
      isLoading.value = false;
    }
  }

  /// حفظ/تحديث تقييم شهري (upsert على student_id+month+year)
  Future<bool> saveRating({
    required String studentId,
    required String ratingKey,
    required int month,
    required int year,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final teacherId = _supabase.auth.currentUser?.id;
      final payload = {
        'student_id': studentId,
        if (teacherId != null) 'teacher_id': teacherId,
        'month': month,
        'year': year,
        'rating': ratingKey,
      };
      MonthlyRating saved = MonthlyRating(
        studentId: studentId,
        teacherId: teacherId,
        month: month,
        year: year,
        rating: ratingKey,
      );
      bool serverOk = false;
      String? serverError;
      try {
        final res = await _supabase
            .from('monthly_ratings')
            .upsert(payload, onConflict: 'student_id, month, year')
            .select()
            .maybeSingle();
        if (res != null) {
          saved = MonthlyRating.fromJson(Map<String, dynamic>.from(res));
          serverOk = true;
        } else {
          // تحقق إضافي: أعد قراءة الصف للتأكد من وصول الكتابة للسيرفر
          final verify = await _supabase
              .from('monthly_ratings')
              .select()
              .eq('student_id', studentId)
              .eq('month', month)
              .eq('year', year)
              .maybeSingle();
          if (verify != null) {
            saved = MonthlyRating.fromJson(Map<String, dynamic>.from(verify));
            serverOk = true;
          } else {
            serverError = 'empty_response';
          }
        }
      } catch (e) {
        // لا نبتلع الخطأ بصمت: نحفظ محلياً لكن نبلّغ المعلم أن السيرفر لم يستقبل
        serverError = e.toString();
      }
      latestByStudent[studentId] = saved;
      // تحديث الكاش: ادمج مع الموجود
      final List existing = (_storage.read(_cacheKey(studentId)) as List?) ?? [];
      final List<Map<String, dynamic>> merged = existing
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => !(e['month'] == month && e['year'] == year))
          .toList();
      merged.add(saved.toJson());
      _storage.write(_cacheKey(studentId), merged);
      // حدّث قائمة الطالب إن كانت معروضة
      if (studentRatings.isNotEmpty || studentId == _supabase.auth.currentUser?.id) {
        await fetchStudentRatings(studentId);
      }
      if (serverOk) {
        Get.snackbar(
          'success'.tr,
          'rating_saved_success'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // تنبيه صريح: حُفظ محلياً فقط ولم يصل للسيرفر (غالباً سياسة RLS أو جدول مفقود)
        Get.snackbar(
          'warning'.tr,
          'rating_saved_local_only'.tr,
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        debugPrint('[MonthlyRating] server save failed: $serverError');
      }
      return true;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_save'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// آخر تقييم لطالب (للعرض السريع في البطاقات)
  MonthlyRating? latestFor(String studentId) => latestByStudent[studentId];

  /// تقييم شهر محدد من قائمة الطالب المحملة
  MonthlyRating? ratingForMonth(int month, int year) {
    return studentRatings.firstWhereOrNull((r) => r.month == month && r.year == year);
  }
}
