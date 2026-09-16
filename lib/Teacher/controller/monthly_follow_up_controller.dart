import 'package:al_maqraa/Admin/repository/modules/reports_module.dart'; // استيراد وحدة التقارير لتوحيد الحسابات والمزامنة مع الإدارة
import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية للواجهات والألوان
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والانتقالات والترجمة
import 'package:get_storage/get_storage.dart'; // استيراد مكتبة GetStorage لعمل كاش محلي للبيانات (أوفلاين)
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة Supabase للتعامل مع قاعدة البيانات السحابية
import '../models/monthly_record_model.dart'; // استيراد نموذج سجل المتابعة الشهري المتكامل
import '../../core/utils/app_constants.dart'; // استيراد الثوابت العامة للتطبيق مثل أسماء الشهور
import '../models/daily_attendance_record_model.dart'; // استيراد نموذج سجل الحضور اليومي للطالب

/// متحكم إدارة المتابعة الشهرية المطور مع نظام حساب دقيق وتكامل للبيانات التاريخية والكاش
class MonthlyFollowUpController extends GetxController with ReportsModule {
  // تفعيل عميل سوبابيس للقيام بالعمليات البرمجية على السيرفر
  @override
  SupabaseClient get supabase => Supabase.instance.client; 
  
  // تعريف أداة التخزين المحلي لضمان سرعة عرض البيانات بدون إنترنت
  final GetStorage _storage = GetStorage();
  // قائمة تحتوي على أسماء الشهور الميلادية المترجمة من ملف الثوابت
  final List<String> months = AppConstants.gregorianMonths;

  // مراقب تفاعلي لحالة التحميل للتحكم في ظهور مؤشر الانتظار
  final RxBool isLoading = true.obs;
  // مراقب تفاعلي لفهرس الشهر المختار (يبدأ تلقائياً من الشهر الحالي للنظام)
  final RxInt selectedMonthIndex = (DateTime.now().month - 1).obs;
  // قائمة تفاعلية تحتوي على سجلات المتابعة المتكاملة (حضور، غياب، إجازات، درجات)
  final RxList<MonthlyRecord> monthData = <MonthlyRecord>[].obs;
  // متحكم التمرير لشريط الشهور لتوسيط الشهر المختار
  final ScrollController monthScrollController = ScrollController();

  @override // إعادة تعريف دالة التهيئة للمتحكم
  void onInit() {
    super.onInit(); // استدعاء دالة التهيئة للأب
    _navigateToCurrentMonth(); // ضبط الشهر تلقائياً ليوافق تاريخ اليوم عند فتح الصفحة
    loadFollowUpData(); // البدء في تحميل البيانات من الكاش المحلي ثم السيرفر
  }

  @override
  void onReady() {
    super.onReady();
    // توسيط الشهر المختار بعد بناء الواجهة
    Future.delayed(const Duration(milliseconds: 300), () => scrollToSelectedMonth());
  }

  /// توسيط الشهر المختار في شريط الشهور
  void scrollToSelectedMonth() {
    if (monthScrollController.hasClients) {
      // حساب الإزاحة المطلوبة لتوسيط العنصر (عرض العنصر 110 + الهامش 8)
      double offset = (selectedMonthIndex.value * 118.0) - (Get.width / 2) + 59;
      if (offset < 0) offset = 0;
      if (offset > monthScrollController.position.maxScrollExtent) offset = monthScrollController.position.maxScrollExtent;
      
      monthScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// دالة لضبط فهرس الشهر ليتوافق مع التاريخ الحالي لجهاز المستخدم
  void _navigateToCurrentMonth() {
    selectedMonthIndex.value = DateTime.now().month - 1; // تعيين قيمة الشهر الحالي
  }

  /// جلب البيانات مع تطبيق منطق "التكامل التاريخي" لضمان دقة الإحصائيات للأيام الماضية فقط
  void loadFollowUpData() async {
    try { // محاولة تنفيذ عملية جلب البيانات
      if (monthData.isEmpty) {
        isLoading.value = true; // تفعيل حالة التحميل فقط في حال عدم وجود بيانات كاش
      }
      final String? teacherId = supabase.auth.currentUser?.id; // جلب معرف المعلم المسجل حالياً
      if (teacherId == null) return; // الخروج في حال عدم وجود معلم مسجل دخول

      int year = DateTime.now().year; // تحديد السنة الحالية للبحث
      int month = selectedMonthIndex.value + 1; // تحديد رقم الشهر المختار (زيادة 1 لأن الفهرس يبدأ من 0)

      // 1. تحميل وعرض بيانات الكاش المحلي فوراً لسرعة استجابة التطبيق
      _loadFromCache(teacherId, year, month);

      // 2. جلب الحلقات التابعة لهذا المعلم من قاعدة البيانات السحابية
      final circles = await supabase.from('circles').select('id').eq('teacher_id', teacherId);
      // تحويل نتائج البحث إلى قائمة من المعرفات النصية
      final circleIds = (circles as List).map((c) => c['id']?.toString()).whereType<String>().toList();

      List<MonthlyRecord> integratedRecords = []; // قائمة مؤقتة لتجميع السجلات المحدثة

      if (circleIds.isNotEmpty) { // إذا وجد للمعلم حلقات مسجلة
        final now = DateTime.now(); // الحصول على الوقت الحالي للمقارنة
        final today = DateTime(now.year, now.month, now.day); // تحديد تاريخ اليوم الحالي (بدون الساعات)

        for (var circleId in circleIds) { // المرور على كل حلقة لجلب طلابها وإحصائياتهم
          // جلب سجلات الحضور اليومية التفصيلية من وحدة التقارير (ReportsModule)
          final List<DailyAttendanceRecord> attendanceDetails = await getCircleAttendance(
            circleId,
            month: month,
            year: year,
          );

          // جلب سجلات الاختبارات الشهرية والدرجات لكل طالب في هذه الحلقة
          final examGrades = await getCircleExams(circleId, month: month, year: year);

          for (var detail in attendanceDetails) { // معالجة سجل كل طالب على حدة لحساب التكامل
            int present = 0; int absent = 0; int excused = 0; int holiday = 0;

            // تطبيق منطق "التكامل التاريخي": نحسب الحالات فقط للأيام التي مرت فعلياً أو هي اليوم الحالي
            for (int i = 0; i < detail.dailyStatuses.length; i++) {
              final checkDate = DateTime(year, month, i + 1); // بناء تاريخ اليوم المراد فحصه
              
              if (year == now.year && month == now.month) { // إذا كان الشهر المختار هو الشهر الحالي
                if (checkDate.isAfter(today)) break; // التوقف عن الحساب إذا كان التاريخ في المستقبل
              }

              final status = detail.dailyStatuses[i]; // الحصول على حالة الحضور لليوم المحدد
              if (status == AttendanceStatus.present) {
                present++; // زيادة عداد الحضور
              } else if (status == AttendanceStatus.absent) absent++; // زيادة عداد الغياب
              else if (status == AttendanceStatus.excused) excused++; // زيادة عداد الاستئذان
              else if (status == AttendanceStatus.holiday) holiday++; // زيادة عداد الإجازات
            }

            // البحث عن درجات الاختبار الخاصة بهذا الطالب من نتائج السيرفر
            final studentExam = examGrades.firstWhereOrNull((e) => e.studentId == detail.studentId);

            // بناء كائن السجل الشهري المتكامل بالبيانات الدقيقة
            integratedRecords.add(MonthlyRecord(
              studentId: detail.studentId, // معرف الطالب
              studentName: detail.studentName, // اسم الطالب للعرض
              attendanceDays: present, // إجمالي أيام الحضور المحسوبة
              absenceDays: absent, // إجمالي أيام الغياب المحسوبة
              excusedDays: excused, // إجمالي أيام الاستئذان المحسوبة
              holidayDays: holiday, // إجمالي أيام الإجازات المسجلة
              monthlyGrade: studentExam?.totalScore.toInt() ?? 0, // إجمالي درجة الاختبار
              hifzScore: studentExam?.hifzScore ?? 0, // درجة الحفظ
              tajweedScore: studentExam?.tajweedScore ?? 0, // درجة التجويد
              tilawahScore: studentExam?.tilawahScore ?? 0, // درجة التلاوة
            ));
          }
        }
      }

      // تحديث القائمة التفاعلية بالبيانات الجديدة المجلوبة من السيرفر
      monthData.assignAll(integratedRecords);
      // تحديث الكاش المحلي بالبيانات الجديدة لضمان توفرها المرة القادمة بدون إنترنت
      _saveToCache(teacherId, year, month);
      
    } catch (e) { // الإمساك بالأخطاء في حال حدوثها أثناء الاتصال
    } finally { // كود ينفذ دائماً عند الانتهاء
      isLoading.value = false; // إيقاف مؤشر التحميل
    }
  }

  /// قراءة بيانات الكاش من التخزين المحلي للجهاز لسرعة العرض
  void _loadFromCache(String teacherId, int year, int month) {
    // إنشاء مفتاح فريد للكاش يربط المعلم بالتاريخ المختار
    final String key = 'followup_cache_${teacherId}_${year}_$month';
    // قراءة البيانات من ملف التخزين المحلي
    final cached = _storage.read(key);
    if (cached != null) { // إذا وجدت بيانات مخزنة مسبقاً
      final List<dynamic> list = cached as List; // تحويل البيانات لقائمة
      // تحويل الـ JSON لكائنات برمجية وعرضها فوراً في الواجهة
      monthData.assignAll(list.map((item) => MonthlyRecord.fromJson(item)).toList());
      isLoading.value = false; // إخفاء مؤشر التحميل لأن البيانات ظهرت
    }
  }

  /// حفظ البيانات المحدثة في الكاش المحلي لضمان المزامنة
  void _saveToCache(String teacherId, int year, int month) {
    final String key = 'followup_cache_${teacherId}_${year}_$month'; // المفتاح الفريد
    // كتابة قائمة البيانات في التخزين المحلي بعد تحويلها لـ JSON
    _storage.write(key, monthData.map((e) => e.toJson()).toList());
  }

  /// اختيار شهر جديد من قبل المعلم وإعادة تحميل بياناته بدقة
  void selectMonth(int index) {
    selectedMonthIndex.value = index; // تحديث فهرس الشهر المختار
    loadFollowUpData(); // إعادة تشغيل دالة التحميل الذكية للشهر الجديد
    scrollToSelectedMonth(); // توسيط الشهر الجديد
  }

  /// حفظ بيانات المتابعة الشهرية ومزامنتها مع السيرفر مع إصلاح أخطاء الأعمدة
  Future<void> saveMonthData() async {
    try { // محاولة تنفيذ عملية الحفظ
      if (monthData.isEmpty) return; // التوقف إذا لم توجد بيانات لحفظها
      int year = DateTime.now().year; // الحصول على السنة الحالية
      int month = selectedMonthIndex.value + 1; // الحصول على الشهر الحالي

      // تجهيز قائمة البيانات للحفظ وتنظيفها من الحقول غير الموجودة في جدول قاعدة البيانات
      List<Map<String, dynamic>> dataToSave = monthData.map((record) {
        final json = record.toJson(); // تحويل السجل لصيغة JSON
        json.remove('student_name'); // حذف حقل الاسم لأنه غير موجود في جدول المتابعة (PGRST204)
        json.remove('holiday_days'); // حذف حقل الإجازات لأنه حقل عرض فقط وليس للحفظ المباشر
        json['month'] = month; // تعيين رقم الشهر بدقة
        json['year'] = year; // تعيين السنة بدقة
        return json; // العودة بالبيانات المنظفة
      }).toList();

      // تنفيذ عملية الحفظ أو التحديث (UPSERT) في جدول سجلات المتابعة الشهرية
      await supabase.from('monthly_records').upsert(dataToSave, onConflict: 'student_id, month, year');

      // تحديث الكاش المحلي بالبيانات التي تم حفظها للتو
      final String? teacherId = supabase.auth.currentUser?.id;
      if (teacherId != null) _saveToCache(teacherId, year, month);

      // إظهار رسالة نجاح منبثقة مترجمة للمعلم
      Get.snackbar('save'.tr, '${'saved_successfully'.tr} (${months[selectedMonthIndex.value].tr})', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) { // التعامل مع أخطاء الحفظ (مثل انقطاع الإنترنت أو خطأ في السكيمة)
      // إظهار رسالة خطأ منبثقة مترجمة للمستخدم
      Get.snackbar('error'.tr, 'failed_to_save'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
} // نهاية كلاس متحكم المتابعة الشهرية المطور كلياً
