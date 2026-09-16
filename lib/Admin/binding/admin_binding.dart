import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الاعتمادات (Dependencies)
import '../controller/admin_layout_controller.dart'; // استيراد متحكم التخطيط العام للأدمن
import '../controller/applicants/teacher_applicants_controller.dart'; // استيراد متحكم المتقدمين للتدريس
import '../controller/applicants/student_applicants_controller.dart'; // استيراد متحكم الطلاب المتقدمين
import '../controller/home/admin_home_controller.dart'; // استيراد متحكم الصفحة الرئيسية
import '../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين
import '../controller/accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين
import '../controller/quran_circles_controller.dart';
import '../controller/reports/halaqa_reports_controller.dart';
import '../controller/certificates/certificates_controller.dart';
import '../controller/settings/admin_manage_users_controller.dart';
// استيراد متحكم حلقات القرآن

// كلاس الربط (Binding) الخاص بالأدمن لتهيئة كافة المتحكمات المطلوبة عند الدخول لقسم الإدارة
class AdminBinding extends Bindings {
  @override
  void dependencies() {
    // دالة تعريف الاعتمادات والمتحكمات
    // حقن متحكم التخطيط العام فوراً ليكون متاحاً عند بناء واجهة الـ  Dashboard
    Get.put(AdminLayoutController());

    // استخدام lazyPut لحقن المتحكمات الأخرى فقط عند الحاجة إليها (لتحسين أداء الذاكرة)
    Get.lazyPut<AdminHomeController>(
      () => AdminHomeController(),
    ); // تهيئة متحكم الصفحة الرئيسية

    Get.lazyPut<TeacherApplicantsController>(
      // تهيئة متحكم طلبات المتقدمين للتدريس
      () => TeacherApplicantsController(),
    );

    Get.lazyPut<StudentApplicantsController>(
      // تهيئة متحكم طلبات الطلاب المتقدمين
      () => StudentApplicantsController(),
    );

    Get.lazyPut<AcceptedTeachersController>(() => AcceptedTeachersController());
    // تهيئة متحكم المعلمين المقبولين
    Get.lazyPut<AcceptedStudentsController>(
      () => AcceptedStudentsController(),
    ); // تهيئة متحكم الطلاب المقبولين
    Get.lazyPut<QuranCirclesController>(
      () => QuranCirclesController(),
    ); // تهيئة متحكم حلقات القرآن
    Get.lazyPut<HalaqaReportsController>(() => HalaqaReportsController());
    // تهيئة متحكم الشهادات
    Get.lazyPut<CertificatesController>(() => CertificatesController());
    
    Get.lazyPut<AdminManageUsersController>(() => AdminManageUsersController());
  }
}
