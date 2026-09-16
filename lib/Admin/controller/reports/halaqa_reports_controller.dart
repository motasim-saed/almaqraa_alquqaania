import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import 'package:al_maqraa/Admin/models/admin_models.dart'; // استيراد نماذج بيانات الإدارة مثل حلقات القرآن
import 'package:al_maqraa/Student/models/student_models.dart'; // استيراد نماذج بيانات الطلاب مثل الخطط والسجلات
import 'package:al_maqraa/core/services/file_export_service.dart'; // استيراد خدمة تصدير الملفات إلى Excel
import 'package:al_maqraa/Admin/repository/admin_repository.dart'; // استيراد الواجهة البرمجية لمستودع بيانات الإدارة
import 'package:al_maqraa/Admin/repository/supabase_admin_repository.dart'; // استيراد تنفيذ المستودع باستخدام Supabase
import 'package:al_maqraa/Teacher/models/daily_attendance_record_model.dart'; // استيراد نموذج سجل الحضور اليومي
import 'package:al_maqraa/Teacher/models/monthly_exam_model.dart'; // استيراد نموذج سجل الاختبارات الشهرية
import 'package:al_maqraa/Teacher/models/monthly_record_model.dart'; // استيراد نموذج السجل الشهري للدرجات
import 'package:al_maqraa/Admin/models/yearly_record_model.dart'; // استيراد نموذج السجل السنوي للدرجات

// كلاس التحكم في تقارير الحلقات والطلاب للأدمن (HalaqaReportsController)
class HalaqaReportsController extends GetxController {
  // إنشاء نسخة من مستودع بيانات الإدارة للوصول إلى قاعدة بيانات Supabase
  final AdminRepository repository = SupabaseAdminRepository();

  // قائمة مراقبة (Observable) لتخزين حلقات القرآن الكريم المجلوبة
  final RxList<QuranCircleModel> quranCircles = <QuranCircleModel>[].obs;
  // متغير لمراقبة حالة تحميل قائمة الحلقات (true أثناء التحميل)
  final RxBool isLoadingCircles = false.obs;

  // خاصية للحصول على إجمالي عدد الحلقات الموجودة في القائمة
  int get totalCirclesCount => quranCircles.length; 
  // خاصية للحصول على عدد حلقات البنين (طلاب)
  int get maleCirclesCount =>
      quranCircles.where((c) => c.gender == Gender.male).length; 
  // خاصية للحصول على عدد حلقات البنات (طالبات)
  int get femaleCirclesCount =>
      quranCircles.where((c) => c.gender == Gender.female).length; 

  // قائمة مراقبة لتخزين سجلات الحضور اليومية
  final RxList<DailyAttendanceRecord> attendanceRecords =
      <DailyAttendanceRecord>[].obs; 
  // قائمة مراقبة لتخزين السجلات الشهرية للطلاب
  final RxList<MonthlyRecord> monthlyRecords = <MonthlyRecord>[].obs; 
  // قائمة مراقبة لتخزين السجلات السنوية للطلاب
  final RxList<YearlyRecord> yearlyRecords = <YearlyRecord>[].obs; 
  // قائمة مراقبة لتخزين سجلات الاختبارات الشهرية
  final RxList<MonthlyExamRecord> monthlyExams = <MonthlyExamRecord>[].obs; 
  
  // قائمة لتخزين الخطط السنوية لطالب معين عند عرض تفاصيله
  final RxList<AnnualPlanModel> selectedStudentAnnualPlans = <AnnualPlanModel>[].obs;
  // قائمة لتخزين الخطط الشهرية لطالب معين
  final RxList<MonthlyPlanModel> selectedStudentMonthlyPlans = <MonthlyPlanModel>[].obs;
  // قائمة لتخزين السجلات اليومية (التسميع) لطالب معين
  final RxList<DailyRecordModel> selectedStudentDailyRecords = <DailyRecordModel>[].obs;

  // متغير لمراقبة حالة تحميل التقارير (الحضور، الدرجات، الاختبارات)
  final RxBool isLoadingReports = false.obs;
  // متغير لمراقبة حالة تحميل البيانات التفصيلية للطالب
  final RxBool isLoadingStudentDetails = false.obs;

  // متغير مراقبة لنص البحث المستخدم لتصفية الحلقات
  final searchQuery = ''.obs; 
  // متغير مراقبة لفلتر الجنس المستخدم لتصفية الحلقات (بنين/بنات/الكل)
  final selectedGenderFilter = Gender.all.obs; 
  // متغير مراقبة لفلتر السنة لجميع التقارير
  final selectedYear = DateTime.now().year.obs;

  @override
  // دالة تهيئة المتحكم عند استدعائه لأول مرة
  void onInit() { 
    super.onInit(); // استدعاء دالة الأب
    fetchQuranCircles(); // جلب حلقات القرآن من السيرفر فور البدء
  }

  // دالة لجلب قائمة كافة حلقات القرآن الكريم من المستودع
  Future<void> fetchQuranCircles() async {
    try {
      isLoadingCircles.value = true; // بدء إظهار مؤشر التحميل الخاص بالحلقات
      final circles = await repository.getQuranCircles(); // طلب البيانات من السيرفر
      quranCircles.assignAll(circles); // تحديث القائمة المحلية بالبيانات المجلوبة
    } finally {
      isLoadingCircles.value = false; // إخفاء مؤشر التحميل بعد الانتهاء
    }
  }

  // دالة مساعدة لإعادة جلب حلقات القرآن يدوياً
  void refreshCircles() => fetchQuranCircles();

  // دالة لجلب سجلات حضور طلاب حلقة معينة بناءً على الشهر والسنة
  Future<void> fetchCircleAttendance(String circleId, {int? month, int? year}) async {
    try {
      isLoadingReports.value = true; // بدء إظهار مؤشر تحميل التقارير
      final records = await repository.getCircleAttendance(
        circleId, 
        month: month, 
        year: year,
        onRefresh: (freshRecords) {
          attendanceRecords.assignAll(freshRecords); // التحديث التلقائي الصامت للواجهة
        },
      ); 
      attendanceRecords.assignAll(records); // عرض بيانات الكاش الفوري إن وجدت
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_fetch_attendance'.tr); // عرض تنبيه في حال حدوث خطأ
    } finally {
      isLoadingReports.value = false; // إخفاء مؤشر التحميل
    }
  }

  // دالة لجلب نتائج اختبارات طلاب حلقة معينة لشهر وسنة محددين
  Future<void> fetchCircleExams(String circleId, {int? month, int? year}) async {
    try {
      isLoadingReports.value = true; // تفعيل حالة التحميل
      final records = await repository.getCircleExams(circleId, month: month, year: year); // طلب بيانات الاختبارات
      monthlyExams.assignAll(records); // تحديث قائمة الاختبارات المجلوبة
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_fetch_exams'.tr); // عرض تنبيه بالفشل
    } finally {
      isLoadingReports.value = false; // إيقاف حالة التحميل
    }
  }

  // دالة لجلب الدرجات والتقييمات الشهرية لطلاب حلقة معينة
  Future<void> fetchCircleMonthlyGrades(String circleId, {int? month, int? year}) async {
    try {
      isLoadingReports.value = true; // بدء التحميل
      final records = await repository.getCircleMonthlyGrades(
        circleId, 
        month: month, 
        year: year,
        onRefresh: (freshRecords) {
          monthlyRecords.assignAll(freshRecords); // التحديث التلقائي الصامت للواجهة
        },
      ); 
      monthlyRecords.assignAll(records); // عرض بيانات الكاش الفوري إن وجدت
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_fetch_monthly_grades'.tr); // عرض رسالة خطأ
    } finally {
      isLoadingReports.value = false; // إنهاء التحميل
    }
  }

  // دالة لتحديث البيانات العامة (إعادة جلب الحلقات)
  Future<void> refreshData() async {
    await fetchQuranCircles(); // استدعاء دالة جلب الحلقات وانتظارها
  }

  // دالة لجلب الدرجات السنوية التراكمية لطلاب حلقة معينة في سنة محددة
  Future<void> fetchCircleYearlyGrades(String circleId, {int? year}) async {
    try {
      isLoadingReports.value = true; // تفعيل مؤشر التحميل
      final records = await repository.getCircleYearlyGrades(circleId, year: year); // طلب السجلات السنوية
      yearlyRecords.assignAll(records); // تحديث قائمة السجلات السنوية
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_fetch_yearly_grades'.tr); // إظهار تنبيه عند الفشل
    } finally {
      isLoadingReports.value = false; // إيقاف التحميل
    }
  }

  // دالة لتصدير التقرير الشهري الحالي للحلقة إلى ملف Excel
  void exportMonthlyReport(String circleName) {
    FileExportService.exportMonthlyReportToExcel(circleName, monthlyRecords.toList()); // استدعاء خدمة التصدير
  }

  // دالة لتصدير التقرير السنوي الحالي للحلقة إلى ملف Excel
  void exportYearlyReport(String circleName) {
    FileExportService.exportYearlyReportToExcel(circleName, yearlyRecords.toList()); // تنفيذ عملية تصدير السجل السنوي
  }

  // دالة لتصدير نتائج الاختبارات الحالية للحلقة إلى ملف Excel
  void exportExamsReport(String circleName) {
    FileExportService.exportExamsToExcel(circleName, monthlyExams.toList()); // استدعاء خدمة التصدير للاختبارات
  }

  // دالة لجلب التفاصيل الكاملة (خطط وسجلات) لطالب معين بواسطة معرفه
  Future<void> fetchStudentDetails(String studentId) async {
    try {
      isLoadingStudentDetails.value = true; // تفعيل مؤشر تحميل تفاصيل الطالب
      // تنفيذ ثلاثة طلبات في وقت واحد (توازي) لتحسين السرعة
      final results = await Future.wait([
        repository.getStudentAnnualPlans(studentId), // جلب الخطط السنوية
        repository.getStudentMonthlyPlans(studentId), // جلب الخطط الشهرية
        repository.getStudentDailyRecords(studentId), // جلب السجلات اليومية (التسميع)
      ]);

      // توزيع النتائج المجلوبة على القوائم المخصصة لها
      selectedStudentAnnualPlans.assignAll(results[0] as List<AnnualPlanModel>); // تحديث الخطط السنوية
      selectedStudentMonthlyPlans.assignAll(results[1] as List<MonthlyPlanModel>); // تحديث الخطط الشهرية
      selectedStudentDailyRecords.assignAll(results[2] as List<DailyRecordModel>); // تحديث السجلات اليومية
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_fetch_student_details'.tr); // عرض خطأ في حال فشل الجلب
    } finally {
      isLoadingStudentDetails.value = false; // إيقاف مؤشر تحميل التفاصيل
    }
  }
}
