// import 'package:flutter/material.dart'; 
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والتنقل
import '../../models/admin_models.dart'; // استيراد نماذج البيانات (TeacherModel, StudentModel)
import '../../repository/admin_repository.dart'; // استيراد الواجهة البرمجية للمستودع
import '../../repository/supabase_admin_repository.dart'; // استيراد تنفيذ المستودع باستخدام Supabase

/// المتحكم المسؤول عن إدارة عرض وعمليات المعلمين والطلاب المقبولين.
/// يتم استخدامه في شاشات الإدارة لعرض القوائم، تصفيتها، وحذف المستخدمين.
class AcceptedController extends GetxController {
  
  // تعريف المستودع للتعامل مع عمليات قاعدة البيانات
  final AdminRepository _repository = SupabaseAdminRepository();

  // ---------------------------------------------------------
  // المتغيرات القابلة للملاحظة (Observable Variables)
  // ---------------------------------------------------------
  
  // قوائم البيانات الأصلية المجلوبة من قاعدة البيانات
  var acceptedTeachers = <TeacherModel>[].obs; // قائمة المعلمين المقبولين
  var acceptedStudents = <StudentModel>[].obs; // قائمة الطلاب المقبولين
  
  // حالة التحميل لإظهار مؤشر الانتظار في الواجهة
  var isLoading = false.obs; 

  // --- فلاتر المعلمين ---
  var teacherGenderFilter = Gender.all.obs; // فلتر الجنس (ذكر/أنثى/الكل)
  var teacherSponsorshipFilter = 'all'.obs; // فلتر الكفالة (يحتاج/لا يحتاج/الكل)

  // --- فلاتر الطلاب ---
  var studentGenderFilter = Gender.all.obs; // فلتر الجنس (ذكر/أنثى/الكل)
  var studentDistributionFilter = 'all'.obs; // فلتر التوزيع على الحلقات (موزع/غير موزع/الكل)

  // ---------------------------------------------------------
  // دورة حياة المتحكم (Lifecycle)
  // ---------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    // عند تشغيل المتحكم لأول مرة، نقوم بجلب البيانات مباشرة
    fetchAcceptedUsers();
  }

  // ---------------------------------------------------------
  // العمليات (Actions)
  // ---------------------------------------------------------

  /// جلب كافة المعلمين والطلاب الذين تم قبولهم (status == 'accepted')
  void fetchAcceptedUsers() async {
    isLoading.value = true; // بدء التحميل
    try {
      // جلب المعلمين وتحديث القائمة
      var teachers = await _repository.getTeachers(status: 'accepted');
      acceptedTeachers.assignAll(teachers);

      // جلب الطلاب وتحديث القائمة
      var students = await _repository.getStudents(status: 'accepted');
      acceptedStudents.assignAll(students);
    } finally {
      isLoading.value = false; // إيقاف التحميل مهما كانت النتيجة
    }
  }

  /// حذف مستخدم (معلم أو طالب) من النظام نهائياً
  /// [id] معرف المستخدم في قاعدة البيانات
  /// [isTeacher] true إذا كان معلماً، false إذا كان طالباً
  void removeUser(String id, bool isTeacher) async {
    // تنفيذ الحذف من خلال المستودع
    bool success = isTeacher
        ? await _repository.deleteTeacher(id)
        : await _repository.deleteStudent(id);

    if (success) {
      // إظهار تنبيه للمستخدم بنجاح العملية
      Get.snackbar(
        'alert'.tr,
        isTeacher ? 'teacher_deleted'.tr : 'student_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      // إعادة تحديث القوائم من قاعدة البيانات لتعكس الحذف في الواجهة
      fetchAcceptedUsers();
    }
  }

  // ---------------------------------------------------------
  // الخصائص المشتقة (Getters for Filtered Lists)
  // ---------------------------------------------------------
  // ملاحظة: هذه الخصائص هي التي يتم عرضها في الواجهة (ListView)
  // وهي تقوم بتصفية القوائم الأصلية بناءً على خيارات المستخدم الحالية.

  /// الحصول على قائمة المعلمين بعد تطبيق فلاتر البحث
  List<TeacherModel> get filteredTeachers {
    return acceptedTeachers.where((t) {
      // شرط مطابقة الجنس
      bool genderMatch =
          teacherGenderFilter.value == Gender.all ||
          t.gender == teacherGenderFilter.value;
      
      // شرط مطابقة حالة الكفالة
      bool sponsorshipMatch =
          teacherSponsorshipFilter.value == 'all' ||
          (teacherSponsorshipFilter.value == 'needed' && !t.canCoverBalance) ||
          (teacherSponsorshipFilter.value == 'not_needed' && t.canCoverBalance);
          
      return genderMatch && sponsorshipMatch;
    }).toList();
  }

  /// الحصول على قائمة الطلاب بعد تطبيق فلاتر البحث
  List<StudentModel> get filteredStudents {
    return acceptedStudents.where((s) {
      // شرط مطابقة الجنس
      bool genderMatch =
          studentGenderFilter.value == Gender.all ||
          s.gender == studentGenderFilter.value;

      // شرط مطابقة حالة التوزيع (هل هو مضاف لحلقة أم لا)
      bool distributionMatch =
          studentDistributionFilter.value == 'all' ||
          (studentDistributionFilter.value == 'distributed' && s.isDistributed) ||
          (studentDistributionFilter.value == 'not_distributed' && !s.isDistributed);

      return genderMatch && distributionMatch;
    }).toList();
  }
}
