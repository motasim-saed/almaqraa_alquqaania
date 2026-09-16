import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية للواجهات
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والانتقالات
import 'package:get_storage/get_storage.dart'; // استيراد حزمة GetStorage للتخزين المحلي (الكاش)
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة Supabase للتعامل مع قاعدة البيانات
import '../models/monthly_exam_model.dart'; // استيراد نموذج سجل الاختبار الشهري
import '../../core/utils/app_constants.dart'; // استيراد الثوابت العامة مثل أسماء الشهور

/// متحكم إدارة درجات الاختبارات الشهرية مع دعم الكاش المحلي والأتمتة
class MonthlyExamController extends GetxController {
  // تعريف عميل سوبابيس للقيام بالعمليات البرمجية على السيرفر
  final SupabaseClient _supabase = Supabase.instance.client;
  // تعريف كائن التخزين المحلي لعمل كاش للبيانات
  final GetStorage _storage = GetStorage();

  // قائمة تحتوي على أسماء الشهور الميلادية المترجمة
  final List<String> months = AppConstants.gregorianMonths;

  // مراقب تفاعلي لحالة التحميل للتحكم في ظهور مؤشر الانتظار
  final RxBool isLoading = true.obs;
  // مراقب تفاعلي لفهرس الشهر المختار (يبدأ تلقائياً من الشهر الحالي)
  final RxInt selectedMonthIndex = (DateTime.now().month - 1).obs;
  // قائمة تفاعلية تحتوي على سجلات اختبارات الطلاب المجلوبة
  final RxList<MonthlyExamRecord> examRecords = <MonthlyExamRecord>[].obs;
  final ScrollController monthScrollController = ScrollController();

  @override
  void onInit() {
    // استدعاء دالة التهيئة الأصلية لـ GetX
    super.onInit();
    // ضبط الشهر المختار ليكون الشهر الحالي عند فتح الصفحة
    selectedMonthIndex.value = DateTime.now().month - 1;
    // البدء في تحميل البيانات من الكاش ثم من السيرفر
    loadExamData();
  }

  @override
  void onReady() {
    super.onReady();
    // توسيط الشهر المختار بعد بناء الواجهة
    Future.delayed(
      const Duration(milliseconds: 300),
      () => scrollToSelectedMonth(),
    );
  }

  /// توسيط الشهر المختار في شريط الشهور
  void scrollToSelectedMonth() {
    if (monthScrollController.hasClients) {
      // حساب الإزاحة المطلوبة لتوسيط العنصر (عرض العنصر 110 + الهامش 8)
      double offset = (selectedMonthIndex.value * 118.0) - (Get.width / 2) + 59;
      if (offset < 0) offset = 0;
      if (offset > monthScrollController.position.maxScrollExtent)
        offset = monthScrollController.position.maxScrollExtent;

      monthScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// جلب بيانات الاختبارات الشهرية مع ميزة الكاش والتحديث التلقائي
  void loadExamData() async {
    try {
      // تفعيل حالة التحميل فقط إذا لم تكن هناك بيانات معروضة مسبقاً
      if (examRecords.isEmpty) {
        isLoading.value = true;
      }

      // الحصول على معرف المعلم المسجل حالياً في النظام
      final String? teacherId = _supabase.auth.currentUser?.id;
      // التحقق من وجود المعلم، وإلا يتم الخروج من الدالة
      if (teacherId == null) return;

      // تحديد السنة الحالية ورقم الشهر المختار للبحث
      int year = DateTime.now().year;
      int month = selectedMonthIndex.value + 1;

      // 1. تحميل البيانات من الكاش المحلي أولاً لعرضها فوراً للمستخدم
      _loadFromCache(teacherId, year, month);

      // 2. جلب الحلقات التابعة لهذا المعلم من قاعدة البيانات
      final circles = await _supabase
          .from('circles')
          .select('id')
          .eq('teacher_id', teacherId);

      // استخراج معرفات الحلقات في قائمة واحدة
      final circleIds = (circles as List).map((c) => c['id']).toList();

      // قائمة مؤقتة لتخزين سجلات الطلاب قبل عرضها
      List<MonthlyExamRecord> students = [];

      if (circleIds.isNotEmpty) {
        // 3. جلب جميع الطلاب المنضمين لهذه الحلقات وأسماؤهم
        final members = await _supabase
            .from('circle_members')
            .select('student_id, student:profiles(full_name)')
            .filter('circle_id', 'in', circleIds);

        // استخراج معرفات الطلاب في قائمة واحدة للبحث عن درجاتهم
        final List<String> studentIds = (members as List)
            .map((m) => m['student_id'].toString())
            .toList();

        // 4. جلب سجلات الاختبارات الموجودة مسبقاً لهذا الشهر والسنة
        final recordsResponse = await _supabase
            .from('monthly_exams')
            .select()
            .filter('student_id', 'in', studentIds)
            .eq('month', month)
            .eq('year', year);

        // تنظيم السجلات المجلوبة في خريطة (Map) للوصول السريع بمعرف الطالب
        final Map<String, dynamic> recordsByStudent = {
          for (var r in (recordsResponse as List)) r['student_id']: r,
        };

        // بناء قائمة الطلاب النهائية مع دمج درجاتهم المسجلة أو وضع أصفار
        for (var member in members) {
          // جلب معرف الطالب
          final studentId = member['student_id']?.toString() ?? '';
          // جلب اسم الطالب أو وضع قيمة افتراضية في حال عدم وجوده
          final studentName =
              member['student']?['full_name'] ?? 'role_student'.tr;

          if (recordsByStudent.containsKey(studentId)) {
            // إذا كان للطالب سجل اختبار سابق، يتم تحويله لنموذج وإضافته
            students.add(
              MonthlyExamRecord.fromJson({
                ...recordsByStudent[studentId],
                'studentName': studentName,
              }),
            );
          } else {
            // إذا لم يختبر الطالب بعد، يتم إنشاء سجل جديد فارغ (أصفار)
            students.add(
              MonthlyExamRecord(
                studentId: studentId,
                studentName: studentName,
                hifzScore: 0.0,
                tajweedScore: 0.0,
                tilawahScore: 0.0,
              ),
            );
          }
        }
      }
      // تحديث القائمة التفاعلية بالبيانات الجديدة المجلوبة من السيرفر
      examRecords.assignAll(students);
      // تحديث الكاش المحلي بالبيانات الجديدة لاستخدامها مستقبلاً بدون إنترنت
      _saveToCache(teacherId, year, month);
    } catch (e) {
      // تسجيل الخطأ في حال حدوثه أثناء عملية الجلب
      // debugPrint('Error loading exam data: $e');
    } finally {
      // إيقاف حالة التحميل بعد انتهاء المحاولة (نجاح أو فشل)
      isLoading.value = false;
    }
  }

  /// قراءة بيانات الاختبارات من الكاش المحلي بناءً على المعلم والتاريخ
  void _loadFromCache(String teacherId, int year, int month) {
    // إنشاء مفتاح فريد للكاش يربط المعلم بالسنة والشهر
    final String key = 'exam_cache_${teacherId}_${year}_$month';
    // محاولة قراءة البيانات المخزنة محلياً
    final cached = _storage.read(key);

    // إذا وجدت بيانات مخزنة مسبقاً
    if (cached != null) {
      // تحويل البيانات من JSON إلى قائمة سجلات اختبارات
      final List<dynamic> list = cached as List;
      // تحديث القائمة التفاعلية بالبيانات المحملة من الكاش لسرعة العرض
      examRecords.assignAll(
        list.map((item) => MonthlyExamRecord.fromJson(item)).toList(),
      );
      // إخفاء مؤشر التحميل لأن البيانات أصبحت معروضة للمستخدم
      isLoading.value = false;
    }
  }

  /// حفظ البيانات الحالية في الكاش المحلي (التخزين المؤقت بالجهاز)
  void _saveToCache(String teacherId, int year, int month) {
    // إنشاء المفتاح الفريد لضمان الكتابة في المكان الصحيح
    final String key = 'exam_cache_${teacherId}_${year}_$month';
    // تحويل سجلات الاختبارات الحالية إلى JSON وحفظها في الذاكرة المحلية
    _storage.write(key, examRecords.map((e) => e.toJson()).toList());
  }

  /// اختيار شهر محدد من واجهة المستخدم لتحميل بياناته
  void selectMonth(int index) {
    // تعيين فهرس الشهر المختار
    selectedMonthIndex.value = index;
    // إعادة تحميل البيانات (كاش + سيرفر) للشهر الجديد
    loadExamData();
    // توسيط الشهر الجديد
    scrollToSelectedMonth();
  }

  /// تحديث علامة معينة للطالب مع تطبيق قيود الدرجات (الأتمتة والحدود القصوى)
  void updateScore(int studentIndex, String type, double value) {
    // التأكد من أن القيمة المدخلة ليست سالبة
    if (value < 0) value = 0;

    if (type == 'hifz') {
      // تطبيق الحد الأقصى لدرجة الحفظ (50 درجة)
      if (value > 50) value = 50;
      // تحديث درجة الحفظ في السجل
      examRecords[studentIndex].hifzScore = value;
    } else if (type == 'tajweed') {
      // تطبيق الحد الأقصى لدرجة التجويد (30 درجة)
      if (value > 30) value = 30;
      // تحديث درجة التجويد في السجل
      examRecords[studentIndex].tajweedScore = value;
    } else if (type == 'tilawah') {
      // تطبيق الحد الأقصى لدرجة التلاوة (20 درجة)
      if (value > 20) value = 20;
      // تحديث درجة التلاوة في السجل
      examRecords[studentIndex].tilawahScore = value;
    }

    // طلب إعادة بناء الواجهات المرتبطة بالقائمة لتعكس التعديلات والحدود القصوى
    examRecords.refresh();
  }

  /// حفظ كافة بيانات الاختبارات ومزامنتها بدقة مع سجل المتابعة الشهري (Monthly Records)
  Future<void> saveMonthData() async {
    try {
      // التوقف عن الحفظ في حال عدم وجود بيانات
      if (examRecords.isEmpty) return;

      // تحديد السنة الحالية ورقم الشهر المستهدف للحفظ
      int year = DateTime.now().year;
      int month = selectedMonthIndex.value + 1;

      // تحضير قائمة البيانات للحفظ في جدول الاختبارات الشهرية (monthly_exams)
      List<Map<String, dynamic>> dataToSave = examRecords.map((record) {
        final json = record.toJson();
        // تصحيح الخطأ: حذف حقل 'student_name' لأنه غير موجود في جدول قاعدة البيانات
        json.remove('student_name');
        json['month'] = month; // إضافة الشهر
        json['year'] = year; // إضافة السنة
        return json;
      }).toList();

      // 1. تنفيذ عملية الحفظ أو التحديث (Upsert) في جدول الاختبارات الشهرية
      await _supabase
          .from('monthly_exams')
          .upsert(dataToSave, onConflict: 'student_id, month, year');

      // 2. المزامنة مع جدول السجلات الشهرية (monthly_records) لضمان دقة التقارير والحضور
      final List<String> studentIds = examRecords
          .map((r) => r.studentId)
          .toList();

      // جلب السجلات الشهرية الحالية للحفاظ على بيانات الحضور والغياب (دقة الحفظ)
      final existingMonthlyRes = await _supabase
          .from('monthly_records')
          .select()
          .filter('student_id', 'in', studentIds)
          .eq('month', month)
          .eq('year', year);

      // تنظيم السجلات الموجودة في خريطة للوصول إليها أثناء المزامنة
      final Map<String, dynamic> existingMap = {
        for (var r in (existingMonthlyRes as List)) r['student_id']: r,
      };

      // بناء قائمة المزامنة النهائية التي تدمج الدرجات الجديدة مع إحصائيات الحضور السابقة
      List<Map<String, dynamic>> monitoringSync = examRecords.map((record) {
        // جلب البيانات المخزنة مسبقاً لهذا الطالب (إذا وجدت)
        final existing = existingMap[record.studentId] ?? {};
        return {
          'student_id': record.studentId, // معرف الطالب
          'month': month, // الشهر
          'year': year, // السنة
          'monthly_grade': record.totalScore
              .toInt(), // إجمالي الدرجة (حفظ + تجويد + تلاوة)
          'hifz_score': record.hifzScore, // درجة الحفظ
          'tajweed_score': record.tajweedScore, // درجة التجويد
          'tilawah_score': record.tilawahScore, // درجة التلاوة
          // الحفاظ على أيام الحضور والغياب الأصلية وعدم تصفيرها عند حفظ الدرجات
          'attendance_days': existing['attendance_days'] ?? 0,
          'absence_days': existing['absence_days'] ?? 0,
          'excused_days': existing['excused_days'] ?? 0,
        };
      }).toList();

      // تحديث أو إدراج سجل المتابعة الشهري المدمج (UPSERT) لضمان اتساق البيانات
      await _supabase
          .from('monthly_records')
          .upsert(monitoringSync, onConflict: 'student_id, month, year');

      // 3. تحديث الكاش المحلي بالبيانات الجديدة المحفوظة
      final String? teacherId = _supabase.auth.currentUser?.id;
      if (teacherId != null) _saveToCache(teacherId, year, month);

      // استخراج اسم الشهر الحالي لعرضه في رسالة النجاح
      String currentMonth = months[selectedMonthIndex.value].tr;
      // إظهار تنبيه بنجاح عملية الحفظ والمزامنة
      Get.snackbar(
        'save'.tr, // عنوان التنبيه (حفظ)
        '${'saved_successfully'.tr} ($currentMonth)', // رسالة النجاح مع اسم الشهر
        snackPosition: SnackPosition.BOTTOM, // موقع التنبيه في الأسفل
        backgroundColor: Colors.green, // لون الخلفية أخضر للنجاح
        colorText: Colors.white, // لون النص أبيض
      );
    } catch (e) {
      // إظهار رسالة خطأ في حال فشل الاتصال بالسيرفر أو الحفظ
      Get.snackbar(
        'error'.tr, // عنوان التنبيه (خطأ)
        'error_saving_data'.tr, // نص رسالة الخطأ المترجمة
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red, // لون الخلفية أحمر للفشل
        colorText: Colors.white,
      );
      // طباعة الخطأ في وحدة التحكم لتسهيل عملية التصحيح
      // debugPrint('Error saving month data: $e');
    }
  }
} // نهاية كلاس متحكم الاختبارات الشهرية
