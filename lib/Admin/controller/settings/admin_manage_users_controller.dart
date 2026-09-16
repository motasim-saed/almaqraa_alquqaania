// هذا الملف هو المتحكم (Controller) الخاص بإدارة المستخدمين من قبل المشرف (Admin).
// يقوم بالتعامل مع جلب قائمة المستخدمين، إضافة مستخدمين جدد، وتصفية البحث.

import 'package:flutter/material.dart'; // استيراد حزمة Flutter Material لتصميم واجهة المستخدم.
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والمسارات.
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن.
import '../../repository/supabase_admin_repository.dart'; // استيراد مستودع البيانات للتعامل مع Supabase.

class AdminManageUsersController extends GetxController {
  // تعريف فئة المتحكم لإدارة المستخدمين والتي ترث من GetxController لإدارة الحالة.

  final _adminRepo =
      SupabaseAdminRepository(); // إنشاء نسخة من مستودع بيانات الأدمن للوصول إلى العمليات البرمجية.

  final users = <AdminUserModel>[]
      .obs; // قائمة مراقبة (Observable) لتخزين وعرض المستخدمين بشكل تلقائي عند التغيير.
  final isLoading = false
      .obs; // متغير مراقب لمعرفة ما إذا كان النظام يقوم بتحميل البيانات حالياً.
  final isProcessing = false
      .obs; // متغير مراقب لمعرفة ما إذا كان النظام يعالج عملية إضافة مستخدم.

  var searchQuery = "".obs; // متغير مراقب لتخزين نص البحث وتحديث القائمة فوراً.
  var selectedTabRole = "all".obs; // متغير جديد لتصفية القائمة بناءً على التبويب المختار (الكل، مدراء، منسقون).

  final nameController =
      TextEditingController(); // متحكم لإدخال نص اسم المستخدم الجديد.
  final emailController =
      TextEditingController(); // متحكم لإدخال البريد الإلكتروني للمستخدم الجديد.
  final passwordController =
      TextEditingController(); // متحكم لإدخال كلمة مرور المستخدم الجديد.
  final searchInputController = 
      TextEditingController(); // متحكم لحقل البحث في الواجهة.

  var selectedRole =
      'admin'.obs; // متغير مراقب لتحديد رتبة المستخدم المختار (افتراضياً أدمن).
  var selectedGender = Gender
      .male
      .obs; // متغير مراقب لتحديد جنس المستخدم المختار (افتراضياً ذكر).

  // الحصول على معرف المستخدم الحالي المسجل دخوله
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void onInit() {
    // دالة تهيئة المتحكم التي تعمل عند استدعائه لأول مرة.
    super.onInit(); // استدعاء دالة التهيئة الأساسية في GetxController.
    fetchUsers(); // جلب قائمة المستخدمين بمجرد تشغيل المتحكم.
  }

  Future<void> fetchUsers() async {
    // دالة غير متزامنة لجلب المستخدمين من قاعدة البيانات.
    isLoading.value =
        true; // تفعيل حالة التحميل لإظهار مؤشر التحميل في الواجهة.
    try {
      // محاولة جلب المستخدمين الذين لديهم رتبة مشرف (admin) أو منسق (coordinator).
      final result = await _adminRepo.getUsersByRoles([
        'admin',
        'coordinator',
        'super_admin',
        'management',
      ]);
      users.assignAll(
        result,
      ); // تحديث قائمة المستخدمين بالنتائج القادمة من قاعدة البيانات.
    } catch (e) {
    } finally {
      isLoading.value = false; // إيقاف حالة التحميل سواء نجحت العملية أو فشلت.
    }
  }

  Future<void> refreshData() =>
      fetchUsers(); // دالة مساعدة لتحديث البيانات يدوياً.

  Future<void> addUser() async {
    // دالة غير متزامنة لإضافة مستخدم جديد للنظام.
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      // التحقق من أن جميع الحقول المطلوبة قد تم ملؤها.
      Get.snackbar(
        'error'.tr,
        'complete_all_fields'.tr,
      ); // عرض تنبيه للمستخدم في حال وجود حقول فارغة.
      return; // التوقف عن التنفيذ إذا لم تكتمل البيانات.
    }

    isProcessing.value =
        true; // تفعيل حالة المعالجة لمنع تكرار النقرات وإظهار مؤشر التقدم.
    try {
      // استدعاء دالة إنشاء المستخدم من مستودع البيانات وتمرير القيم المدخلة.
      final success = await _adminRepo.createManagementUser(
        name: nameController.text
            .trim(), // إرسال الاسم مع حذف الفراغات الزائدة.
        email: emailController.text
            .trim(), // إرسال البريد مع حذف الفراغات الزائدة.
        password: passwordController.text, // إرسال كلمة المرور.
        role: selectedRole.value, // إرسال الرتبة المختارة.
        gender: selectedGender.value == Gender.female
            ? 'female'
            : 'male', // تحديد الجنس بصيغة نصية.
      );

      if (success) {
        // إذا نجحت عملية الإضافة بنجاح.
        nameController.clear(); // مسح نص حقل الاسم.
        emailController.clear(); // مسح نص حقل البريد الإلكتروني.
        passwordController.clear(); // مسح نص حقل كلمة المرور.
        fetchUsers(); // إعادة جلب قائمة المستخدمين لتضمين المستخدم الجديد.
        Get.back(); // إغلاق نافذة الإضافة والعودة للقائمة السابقة.
      }
    } catch (e) {
    } finally {
      isProcessing.value = false; // إيقاف حالة المعالجة.
    }
  }

  Future<void> deleteUser(String id) async {
    // منع حذف المستخدم لنفسه
    if (id == currentUserId) {
      Get.snackbar(
        'تنبيه',
        'لا يمكنك حذف حسابك الشخصي الذي تستخدمه حالياً.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isProcessing.value = true;
    try {
      final success = await _adminRepo.deleteUser(id);
      if (success) {
        Get.snackbar(
          'success'.tr,
          'deleted_successfully'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchUsers();
      }
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> editUser(String id) async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      Get.snackbar('error'.tr, 'complete_all_fields'.tr);
      return;
    }

    isProcessing.value = true;
    try {
      final user = users.firstWhere((u) => u.id == id);
      final oldRole = user.role;
      final newRole = selectedRole.value;
      final newName = nameController.text.trim();

      if (oldRole != newRole && (oldRole == 'admin' || newRole == 'admin')) {
         // إذا كان التعديل يتضمن نقل المستخدم بين جدول المدراء وجدول البروفايلات
         if (newRole == 'admin') {
           // نقل من منسق إلى مدير
           try { await _adminRepo.supabase.from('profiles').delete().eq('id', id); } catch (_) {}
           await _adminRepo.supabase.from('admins').upsert({
             'id': id,
             'full_name': newName,
             'email': user.email,
             'created_at': user.joinedAt.toIso8601String(),
           });
         } else {
           // نقل من مدير إلى منسق
           try { await _adminRepo.supabase.from('admins').delete().eq('id', id); } catch (_) {}
           await _adminRepo.supabase.from('profiles').upsert({
             'id': id,
             'full_name': newName,
             'email': user.email,
             'role': newRole,
             'joined_at': user.joinedAt.toIso8601String(),
             'gender': 'male', // قيمة افتراضية
             'academic_number': 'MNG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
             'private_code': '123456', // قيمة افتراضية
           });
         }
      } else {
        // إذا كان التعديل في نفس الجدول (تحديث الاسم فقط أو تغيير نوع المنسق)
        final table = newRole == 'admin' ? 'admins' : 'profiles';
        final updates = {
          'full_name': newName,
          if (table == 'profiles') 'role': newRole,
        };
        await _adminRepo.supabase.from(table).update(updates).eq('id', id);
      }

      Get.snackbar(
        'success'.tr,
        'updated_successfully'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back(); // إغلاق نافذة التعديل
      fetchUsers();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'error_saving_data'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  void clearControllers() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
  }

  List<AdminUserModel> get filteredUsers {
    // دالة للحصول على قائمة المستخدمين بعد تصفيتها بناءً على نص البحث والتبويب.
    List<AdminUserModel> list = users;

    // 1. تصفية بناءً على الدور (التبويب)
    if (selectedTabRole.value == "admin") {
      list = list.where((u) => u.role == 'admin' || u.role == 'super_admin').toList();
    } else if (selectedTabRole.value == "coordinator") {
      list = list.where((u) => u.role == 'coordinator').toList();
    }

    // 2. تصفية بناءً على نص البحث
    if (searchQuery.value.isEmpty) {
      return list;
    }
    
    return list
        .where(
          (u) =>
              u.name.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) || // البحث في الأسماء.
              u.email.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ), // البحث في البريد الإلكتروني.
        )
        .toList(); // تحويل نتيجة التصفية إلى قائمة.
  }

  int get adminsCount => users.where((u) => u.role == 'admin' || u.role == 'super_admin').length;
  int get coordinatorsCount => users.where((u) => u.role == 'coordinator').length;

  @override
  void onClose() {
    // دالة يتم استدعاؤها عند إغلاق أو حذف المتحكم من الذاكرة.
    nameController.dispose(); // التخلص من متحكم نص الاسم لتحرير موارد الذاكرة.
    emailController.dispose(); // التخلص من متحكم نص البريد الإلكتروني.
    passwordController.dispose(); // التخلص من متحكم نص كلمة المرور.
    searchInputController.dispose();
    super.onClose(); // استدعاء دالة الإغلاق الأساسية.
  }
}
