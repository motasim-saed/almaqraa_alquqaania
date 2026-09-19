import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../Teacher/models/monthly_rating_model.dart';
import '../../models/admin_models.dart';
import '../../../core/controllers/global_batch_controller.dart';

/// عنصر موحّد للعرض: طالب + حلقته + تقييمه للشهر المختار
class RatedStudent {
  final StudentModel student;
  final String? ratingKey;
  RatedStudent({required this.student, this.ratingKey});

  MonthlyRatingLevel? get level =>
      ratingKey == null ? null : MonthlyRatingLevel.fromKey(ratingKey);
}

/// متحكم شاشة تقييمات الإدارة:
/// فلترة (جنس/حلقة/تقييم/شهر/بحث) + إرسال رسائل لأصحاب تقييم محدد + سجل الرسائل
class AdminRatingsController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();

  // البيانات الخام
  final RxList<StudentModel> students = <StudentModel>[].obs;
  final RxList<QuranCircleModel> circles = <QuranCircleModel>[].obs;
  final RxMap<String, String> ratingsByStudent = <String, String>{}.obs;

  // الفلاتر
  final RxString genderFilter = 'all'.obs; // all | male | female
  final RxString circleFilter = 'all'.obs; // all | circleId
  final RxString ratingFilter = 'all'.obs; // all | rating key | 'unrated'
  // فلترة الدفعة من الشريط العلوي (مثل بقية الشاشات) عبر GlobalBatchController
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxInt selectedYear = DateTime.now().year.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;

  // تبويب الشاشة: 0 النتائج، 1 إرسال رسالة، 2 السجل
  final RxInt tabIndex = 0.obs;

  // نموذج الرسالة
  final RxString messageRating = 'excellent'.obs;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  // سجل الرسائل المرسلة
  final RxList<Map<String, dynamic>> messageHistory = <Map<String, dynamic>>[].obs;
  final RxBool isHistoryLoading = false.obs;

  /// حلقات مستنتجة من عضويات الطلاب الفعلية (id -> name)
  /// تُستخدم كاحتياط: أي حلقة لديها طلاب ستظهر في الفلتر حتى لو تعذّرت قراءة جدول الحلقات
  final Map<String, String> _memberCircleNames = {};

  int? get _globalBatch {
    if (Get.isRegistered<GlobalBatchController>()) {
      return Get.find<GlobalBatchController>().selectedBatch.value;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    // لا توجد رسالة افتراضية: يبدأ العنوان والنص فارغين ويكتبهما المشرف يدوياً
    titleController.clear();
    bodyController.clear();
    // إعادة بناء القوائم فور تطبيق فلترة الدفعة من الشريط العلوي
    if (Get.isRegistered<GlobalBatchController>()) {
      ever(Get.find<GlobalBatchController>().selectedBatch,
          (_) => students.refresh());
    }
    loadAll();
    loadHistory();
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    super.onClose();
  }

  void setGenderFilter(String v) {
    genderFilter.value = v;
    _resetCircleIfHidden();
  }

  void setRatingFilter(String v) {
    ratingFilter.value = v;
    _resetCircleIfHidden();
  }

  void _resetCircleIfHidden() {
    // إظهار الحلقات يعتمد على فلتر الجنس والتقييم: إن لم تعد الحلقة المختارة ظاهرة نعيدها للكل
    final visible = visibleCircles.map((e) => e.id).toSet();
    if (circleFilter.value != 'all' && !visible.contains(circleFilter.value)) {
      circleFilter.value = 'all';
    }
  }

  /// جنس الحلقة الفعلي: إن كان مسجلاً نعتمده، وإلا نستنتجه من جنس طلابها
  Gender _resolvedCircleGender(String circleId, Gender stored) {
    if (stored == Gender.male || stored == Gender.female) return stored;
    bool hasMale = false;
    bool hasFemale = false;
    for (final s in students) {
      if ((s.circleId ?? '') != circleId) continue;
      if (s.gender == Gender.male) hasMale = true;
      if (s.gender == Gender.female) hasFemale = true;
      if (hasMale && hasFemale) break;
    }
    if (hasMale && !hasFemale) return Gender.male;
    if (hasFemale && !hasMale) return Gender.female;
    return Gender.all;
  }

  /// هل يطابق الطالب فلاتر الجنس والدفعة (بدون الحلقة والتقييم)؟
  bool _matchesGenderBatch(StudentModel s) {
    if (genderFilter.value == 'male' && s.gender != Gender.male) return false;
    if (genderFilter.value == 'female' && s.gender != Gender.female) {
      return false;
    }
    final batch = _globalBatch;
    if (batch != null && s.batchNumber != batch) return false;
    return true;
  }

  /// الحلقات الظاهرة تبعاً لفلاتر الأعلى: الجنس + الدفعة + التقييم
  /// مثال: ممتاز + ذكر = الحلقات التي لديها طلاب ذكور بتقييم ممتاز فقط
  List<QuranCircleModel> get visibleCircles {
    return circles.where((c) {
      // فلترة الدفعة للحلقات إن كانت الحلقة تحمل رقم دفعة
      final batch = _globalBatch;
      if (batch != null &&
          c.batchNumber != null &&
          c.batchNumber != batch) {
        return false;
      }
      // فلتر الجنس على مستوى الحلقة (مع استنتاج المجهول من طلابها)
      if (genderFilter.value == 'male') {
        final g = _resolvedCircleGender(c.id, c.gender);
        if (g != Gender.male && g != Gender.all) return false;
      }
      if (genderFilter.value == 'female') {
        final g = _resolvedCircleGender(c.id, c.gender);
        if (g != Gender.female && g != Gender.all) return false;
      }
      // فلتر التقييم: الحلقة تظهر فقط إذا لديها طالب مطابق (جنس+دفعة+تقييم)
      final rf = ratingFilter.value;
      if (rf != 'all') {
        final hasMatch = students.any((s) {
          if ((s.circleId ?? '') != c.id) return false;
          if (!_matchesGenderBatch(s)) return false;
          final r = ratingsByStudent[s.id];
          if (rf == 'unrated') return r == null;
          return r == rf;
        });
        if (!hasMatch) return false;
      } else if (genderFilter.value != 'all' || batch != null) {
        // حتى بدون فلتر تقييم: إخفاء الحلقات الفارغة تماماً من الطلاب المطابقين
        final hasAny = students.any((s) {
          if ((s.circleId ?? '') != c.id) return false;
          return _matchesGenderBatch(s);
        });
        // نُبقي الحلقة إن لم نعرف طلابها (بيانات غير محملة بعد) لتفادي الاختفاء المفاجئ
        if (students.isNotEmpty && !hasAny) {
          // تحقق: هل الحلقة لديها أي طالب أصلاً؟ إن كان لديها طلاب لكن لا يطابقون الفلتر تُخفى
          final hasStudentsAtAll =
              students.any((s) => (s.circleId ?? '') == c.id);
          if (hasStudentsAtAll) return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadStudents(),
        _loadCircles(),
      ]);
      await _loadRatings();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadStudents() async {
    try {
      // الطلاب المقبولون مع بروفايلاتهم (الجنس + الدفعة)
      final res = await _supabase
          .from('profiles')
          .select('id, full_name, email, phone, gender, batch_number, avatar_url, students(hifz_level, is_distributed)')
          .eq('role', 'student')
          .limit(2000);
      final List<StudentModel> list = [];
      for (final row in (res as List)) {
        final m = Map<String, dynamic>.from(row);
        final s = m['students'];
        Map<String, dynamic>? sMap;
        if (s is List && s.isNotEmpty) {
          sMap = Map<String, dynamic>.from(s.first);
        } else if (s is Map) {
          sMap = Map<String, dynamic>.from(s);
        }
        list.add(StudentModel.fromJson({
          ...m,
          'hifz_level': sMap?['hifz_level'] ?? '',
          'is_distributed': sMap?['is_distributed'] ?? false,
          'status': 'accepted',
        }));
      }
      // إرفاق الحلقة لكل طالب + تجميع أسماء الحلقات من العضويات الفعلية
      try {
        final members = await _supabase
            .from('circle_members')
            .select('student_id, circle_id, circles(id, name)')
            .limit(5000);
        final Map<String, Map<String, String>> circleOf = {};
        _memberCircleNames.clear();
        for (final r in (members as List)) {
          final sid = r['student_id']?.toString() ?? '';
          final c = r['circles'];
          if (sid.isEmpty) continue;
          if (c is Map) {
            final cid = c['id']?.toString() ?? r['circle_id']?.toString() ?? '';
            final cname = c['name']?.toString() ?? '';
            circleOf[sid] = {'id': cid, 'name': cname};
            if (cid.isNotEmpty && cname.isNotEmpty) {
              _memberCircleNames[cid] = cname;
            }
          } else {
            final cid = r['circle_id']?.toString() ?? '';
            circleOf[sid] = {'id': cid, 'name': ''};
          }
        }
        students.assignAll(list.map((s) {
          final c = circleOf[s.id];
          if (c == null) return s;
          return s.copyWith(circleId: c['id'], circleName: c['name']);
        }).toList());
        // دمج الحلقات المستنتجة في قائمة الفلتر فوراً (حتى قبل اكتمال _loadCircles)
        _mergeMemberCircles();
      } catch (e) {
        debugPrint('[AdminRatings] circle_members failed: $e');
        students.assignAll(list);
      }
    } catch (e) {
      debugPrint('[AdminRatings] load students failed: $e');
    }
  }

  Future<void> _loadCircles() async {
    try {
      final res = await _supabase
          .from('circles')
          .select('id, name, gender, teacher_id')
          .order('name')
          .limit(1000);
      circles.assignAll((res as List).map((e) {
        final m = Map<String, dynamic>.from(e);
        return QuranCircleModel(
          id: m['id']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          teacherIds: [m['teacher_id']?.toString() ?? ''],
          teacherNames: const [],
          gender: m['gender'] == 'female' ? Gender.female : Gender.male,
          studentIds: const [],
          studentNames: const [],
          createdAt: DateTime.now(),
        );
      }).toList());
    } catch (e) {
      debugPrint('[AdminRatings] load circles failed: $e');
    } finally {
      // دائماً: أضف أي حلقة لديها طلاب فعلياً حتى لو غابت عن جدول الحلقات
      _mergeMemberCircles();
    }
  }

  /// دمج الحلقات المستنتجة من العضويات في قائمة الفلتر (بدون تكرار)
  void _mergeMemberCircles() {
    if (_memberCircleNames.isEmpty) return;
    final existingIds = circles.map((c) => c.id).toSet();
    final missing = _memberCircleNames.entries
        .where((e) => !existingIds.contains(e.key))
        .map((e) => QuranCircleModel(
              id: e.key,
              name: e.value,
              teacherIds: const [],
              teacherNames: const [],
              gender: Gender.all, // الجنس غير معروف من العضوية — يُعرض الاسم فقط
              studentIds: const [],
              studentNames: const [],
              createdAt: DateTime.now(),
            ))
        .toList();
    if (missing.isNotEmpty) {
      circles.addAll(missing);
      circles.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  Future<void> _loadRatings() async {
    try {
      ratingsByStudent.clear();
      final res = await _supabase
          .from('monthly_ratings')
          .select('student_id, rating')
          .eq('month', selectedMonth.value)
          .eq('year', selectedYear.value)
          .limit(5000);
      for (final r in (res as List)) {
        final sid = r['student_id']?.toString() ?? '';
        final key = r['rating']?.toString() ?? '';
        if (sid.isNotEmpty && key.isNotEmpty) ratingsByStudent[sid] = key;
      }
    } catch (_) {
      // الجدول غير موجود بعد — تبقى القائمة بدون تقييمات مع رسالة تنبيه في الواجهة
    }
  }

  Future<void> changeMonthYear(int month, int year) async {
    selectedMonth.value = month;
    selectedYear.value = year;
    isLoading.value = true;
    try {
      await _loadRatings();
    } finally {
      isLoading.value = false;
    }
  }

  bool _matchesCommonFilters(StudentModel s) {
    if (!_matchesGenderBatch(s)) return false;
    if (circleFilter.value != 'all' && (s.circleId ?? '') != circleFilter.value) {
      return false;
    }
    return true;
  }

  /// القائمة المفلترة (جنس + حلقة + دفعة + تقييم) — بدون بحث
  List<RatedStudent> get filtered {
    return students.where((s) {
      if (!_matchesCommonFilters(s)) return false;
      final r = ratingsByStudent[s.id];
      if (ratingFilter.value == 'unrated' && r != null) return false;
      if (ratingFilter.value != 'all' &&
          ratingFilter.value != 'unrated' &&
          r != ratingFilter.value) {
        return false;
      }
      return true;
    }).map((s) => RatedStudent(student: s, ratingKey: ratingsByStudent[s.id])).toList()
      ..sort((a, b) => a.student.name.compareTo(b.student.name));
  }

  /// إحصائيات التقييمات للشهر المختار (ضمن فلتر الجنس/الحلقة/الدفعة الحالي)
  Map<String, int> get stats {
    final Map<String, int> m = {
      for (final lv in MonthlyRatingLevel.values) lv.key: 0,
      'unrated': 0,
    };
    for (final s in students) {
      if (!_matchesCommonFilters(s)) continue;
      final r = ratingsByStudent[s.id];
      if (r == null) {
        m['unrated'] = (m['unrated'] ?? 0) + 1;
      } else {
        m[r] = (m[r] ?? 0) + 1;
      }
    }
    return m;
  }

  /// المستهدفون برسالة التقييم المختار (مع احترام فلتر الجنس/الحلقة/الدفعة)
  /// اختر genderFilter = all للكل، أو male / female لجنس محدد
  List<RatedStudent> targetsForMessage() {
    return students.where((s) {
      if (ratingsByStudent[s.id] != messageRating.value) return false;
      if (!_matchesCommonFilters(s)) return false;
      return true;
    }).map((s) => RatedStudent(student: s, ratingKey: ratingsByStudent[s.id])).toList();
  }

  /// وصف نصي للاستهداف الحالي (يُعرض فوق زر الإرسال)
  /// genderFilter = all للكل، أو male / female لجنس محدد — مع الدفعة العلوية والحلقة
  String targetsDescription() {
    final gender = genderFilter.value == 'male'
        ? 'male'.tr
        : genderFilter.value == 'female'
            ? 'female'.tr
            : 'all'.tr;
    final globalBatch = _globalBatch;
    final batch =
        globalBatch == null ? 'all'.tr : '${'batch'.tr} $globalBatch';
    final circle = circleFilter.value == 'all'
        ? 'all'.tr
        : circleNameOf(circleFilter.value);
    return '$gender • $batch • $circle';
  }

  /// إرسال رسالة لأصحاب تقييم محدد:
  /// صف واحد في notifications مع target_user_ids + توثيق في rating_messages
  Future<bool> sendRatingMessage() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      Get.snackbar('warning'.tr, 'please_enter_title_and_body'.tr,
          backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return false;
    }
    final targets = targetsForMessage();
    if (targets.isEmpty) {
      Get.snackbar('alert'.tr, 'no_targets_for_rating'.tr,
          backgroundColor: Colors.orange.shade800, colorText: Colors.white);
      return false;
    }
    if (isSending.value) return false;
    isSending.value = true;
    try {
      final ids = targets.map((e) => e.student.id).toList();
      final adminId = _supabase.auth.currentUser?.id;

      // 1) إشعار موجّه لأصحاب التقييم فقط (يتطلب عمود target_user_ids من الـ migration)
      // نميّز رسالة التقييم بحقول category/rating ليحفظها الطالب ويعرضها بشكل خاص
      // في شاشة الإشعارات، مع fallback تلقائي إذا لم توجد الأعمدة بعد.
      try {
        try {
          await _supabase.from('notifications').insert({
            'title': title,
            'body': body,
            'target_role': 'student',
            'target_user_ids': ids,
            'sender_id': adminId,
            'created_at': DateTime.now().toIso8601String(),
            'category': 'rating',
            'rating': messageRating.value,
          });
        } catch (_) {
          await _supabase.from('notifications').insert({
            'title': title,
            'body': body,
            'target_role': 'student',
            'target_user_ids': ids,
            'sender_id': adminId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        // غالباً عمود target_user_ids غير موجود بعد — نرشد الإدارة لتطبيق الـ migration
        Get.snackbar('error'.tr, 'rating_notifications_migration_required'.tr,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            duration: const Duration(seconds: 5));
        return false;
      }

      // 2) توثيق الرسالة في سجل rating_messages (لتبويب السجل)
      try {
        try {
          await _supabase.from('rating_messages').insert({
            'rating': messageRating.value,
            'title': title,
            'body': body,
            'gender_filter': genderFilter.value,
            'circle_id': circleFilter.value == 'all' ? null : circleFilter.value,
            'batch_number': _globalBatch,
            'month': selectedMonth.value,
            'year': selectedYear.value,
            'target_count': ids.length,
            'target_ids': ids,
            'created_by': adminId,
          });
        } catch (_) {
          // توافق مع الجداول القديمة بدون عمود batch_number
          await _supabase.from('rating_messages').insert({
            'rating': messageRating.value,
            'title': title,
            'body': body,
            'gender_filter': genderFilter.value,
            'circle_id': circleFilter.value == 'all' ? null : circleFilter.value,
            'month': selectedMonth.value,
            'year': selectedYear.value,
            'target_count': ids.length,
            'target_ids': ids,
            'created_by': adminId,
          });
        }
      } catch (_) {
        // السجل اختياري — يكفي نجاح الإشعار، ونحفظ نسخة محلية
        final local = List<Map<String, dynamic>>.from(
            _storage.read('rating_messages_local') ?? []);
        local.insert(0, {
          'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
          'rating': messageRating.value,
          'title': title,
          'body': body,
          'gender_filter': genderFilter.value,
          'circle_id': circleFilter.value,
          'batch_number': _globalBatch,
          'month': selectedMonth.value,
          'year': selectedYear.value,
          'target_count': ids.length,
          'created_at': DateTime.now().toIso8601String(),
        });
        _storage.write('rating_messages_local', local.take(50).toList());
      }
      // تفريغ الحقول بعد الإرسال الناجح (لا رسالة افتراضية)
      titleController.clear();
      bodyController.clear();

      Get.snackbar(
        'success'.tr,
        'rating_message_sent'.trParams({'count': ids.length.toString()}),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await loadHistory();
      tabIndex.value = 2;
      return true;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> loadHistory() async {
    isHistoryLoading.value = true;
    try {
      final res = await _supabase
          .from('rating_messages')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      messageHistory.assignAll(
          (res as List).map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {
      final local = _storage.read('rating_messages_local');
      if (local != null && local is List) {
        messageHistory.assignAll(
            local.map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } finally {
      isHistoryLoading.value = false;
    }
  }

  String circleNameOf(String? circleId) {
    if (circleId == null || circleId.isEmpty) return '—';
    return circles.firstWhereOrNull((c) => c.id == circleId)?.name ?? '—';
  }

  /// تعديل رسالة تقييم (العنوان والنص) — Supabase أو التخزين المحلي
  Future<bool> updateRatingMessage(
      String id, String title, String body) async {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      Get.snackbar('warning'.tr, 'please_enter_title_and_body'.tr,
          backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return false;
    }
    // سجل محلي
    if (id.startsWith('local_')) {
      final local = List<Map<String, dynamic>>.from(
          _storage.read('rating_messages_local') ?? []);
      final i = local.indexWhere((e) => e['id']?.toString() == id);
      if (i != -1) {
        local[i]['title'] = title.trim();
        local[i]['body'] = body.trim();
        _storage.write('rating_messages_local', local);
        messageHistory[i]['title'] = title.trim();
        messageHistory[i]['body'] = body.trim();
        messageHistory.refresh();
        Get.snackbar('success'.tr, 'rating_message_updated'.tr,
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      }
      return false;
    }
    try {
      await _supabase
          .from('rating_messages')
          .update({'title': title.trim(), 'body': body.trim()}).eq('id', id);
      final i = messageHistory.indexWhere((e) => e['id']?.toString() == id);
      if (i != -1) {
        messageHistory[i]['title'] = title.trim();
        messageHistory[i]['body'] = body.trim();
        messageHistory.refresh();
      }
      Get.snackbar('success'.tr, 'rating_message_updated'.tr,
          backgroundColor: Colors.green, colorText: Colors.white);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, 'error_occurred'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  /// حذف رسالة تقييم — Supabase أو التخزين المحلي
  Future<bool> deleteRatingMessage(String id) async {
    if (id.startsWith('local_')) {
      final local = List<Map<String, dynamic>>.from(
          _storage.read('rating_messages_local') ?? []);
      local.removeWhere((e) => e['id']?.toString() == id);
      _storage.write('rating_messages_local', local);
      messageHistory.removeWhere((e) => e['id']?.toString() == id);
      Get.snackbar('success'.tr, 'rating_message_deleted'.tr,
          backgroundColor: Colors.green, colorText: Colors.white);
      return true;
    }
    try {
      await _supabase.from('rating_messages').delete().eq('id', id);
      messageHistory.removeWhere((e) => e['id']?.toString() == id);
      Get.snackbar('success'.tr, 'rating_message_deleted'.tr,
          backgroundColor: Colors.green, colorText: Colors.white);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, 'error_occurred'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }
}
