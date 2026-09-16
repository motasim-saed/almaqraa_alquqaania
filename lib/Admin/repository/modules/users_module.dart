import 'dart:convert'; // استيراد مكتبة التحويل للتعامل مع نصوص JSON
import 'package:al_maqraa/core/utils/app_constants.dart'; // استيراد الثوابت العامة مثل روابط الـ API
import 'package:http/http.dart'
    as http; // استيراد حزمة HTTP لإرسال الطلبات للخادم
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيس للتعامل مع قاعدة البيانات
import '../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن
import '../../../core/config/supabase_config.dart'; // استيراد إعدادات سوبابيس لجلب روابط الصور
import 'package:get/get.dart'; // استيراد GetX لإدارة الحالة والترجمة والتنبيهات
import 'package:flutter/material.dart'; // استيراد مكتبة Flutter لواجهات المستخدم والألوان
import '../../../core/controllers/global_batch_controller.dart'; // استيراد متحكم الدفعات العام للوصول للدفعة المختارة

mixin UsersModule {
  // تعريف ميكسين لإدارة وظائف المستخدمين (معلمين وطلاب)
  SupabaseClient get supabase =>
      Supabase.instance.client; // الحصول على عميل سوبابيس لتنفيذ الاستعلامات

  Future<List<TeacherModel>> getTeachers({
    // دالة لجلب قائمة المعلمين بناءً على حالتهم
    required String
    status, // المعامل المطلوب: حالة المعلم (pending أو accepted)
  }) async {
    // بداية الدالة غير المتزامنة
    try {
      // بدء كتلة المحاولة لمعالجة الأخطاء
      int? batchFilter; // تعريف متغير لتخزين رقم الدفعة المراد الفلترة بها
      if (Get.isRegistered<GlobalBatchController>()) {
        // التحقق مما إذا كان متحكم الدفعات مسجلاً في النظام
        batchFilter = Get.find<GlobalBatchController>()
            .selectedBatch
            .value; // جلب قيمة الدفعة المختارة حالياً
      } // نهاية التحقق من المتحكم

      if (status == 'pending') {
        // إذا كانت الحالة المطلوبة هي "معلق" (طلبات تسجيل جديدة)
        var query =
            supabase // بدء بناء استعلام سوبابيس
                .from('registration_requests') // من جدول طلبات التسجيل
                .select() // اختيار كل الحقول
                .eq('role', 'teacher') // تصفية النتائج لتشمل المعلمين فقط
                .eq(
                  'status',
                  'pending',
                ); // تصفية النتائج لتشمل الطلبات المعلقة فقط

        if (batchFilter != null) {
          // إذا كان هناك رقم دفعة مختار
          query = query.eq(
            'batch_number',
            batchFilter,
          ); // إضافة شرط تصفية برقم الدفعة
        } // نهاية تصفية الدفعة

        final response = await query; // تنفيذ الاستعلام وانتظار النتيجة

        return (response as List).map((data) {
          // تحويل قائمة البيانات المستلمة إلى كائنات TeacherModel
          if (data['eligibility_proof'] != null) {
            // إذا كان هناك ملف إثبات أهلية (شهادة)
            data['eligibility_proof'] = SupabaseConfig.getImageUrl(
              // تحويل مسار الملف إلى رابط كامل قابل للعرض
              SupabaseConfig.bucketPledges, // باستخدام حاوية التخزين المخصصة
              data['eligibility_proof'], // مسار الملف المخزن
            ); // نهاية تعيين الرابط
          } // نهاية التحقق من الملف
          return TeacherModel.fromJson(
            data,
          ); // إنشاء وإرجاع كائن النموذج من البيانات
        }).toList(); // تحويل نتيجة الـ map إلى قائمة فعيلة
      } else {
        // إذا كانت الحالة المطلوبة هي "مقبول" (معلمين نشطين)
        var query =
            supabase // بدء بناء استعلام من جدول الملفات الشخصية
                .from('profiles') // جدول البروفايلات الأساسي
                .select(
                  '*, teachers(*)',
                ) // جلب بيانات البروفايل مع بيانات جدول المعلمين المرتبط
                .eq('role', 'teacher'); // تصفية النتائج للمعلمين فقط

        if (batchFilter != null) {
          // تصفية النتائج بناءً على الدفعة المختارة
          query = query.eq('batch_number', batchFilter); // إضافة شرط رقم الدفعة
        } // نهاية تصفية الدفعة

        final response = await query; // تنفيذ الاستعلام

        return (response as List).map((data) {
          // معالجة كل سجل مستلم من قاعدة البيانات
          final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
            data as Map,
          ); // تحويل البيانات لخريطة
          dynamic teacherJson =
              dataMap['teachers']; // استخراج البيانات القادمة من جدول المعلمين
          Map<String, dynamic> teacherData =
              <String, dynamic>{}; // تهيئة خريطة فارغة لبيانات المعلم

          if (teacherJson != null) {
            // التحقق من وجود بيانات إضافية في جدول المعلمين
            if (teacherJson is List && teacherJson.isNotEmpty) {
              // إذا كانت البيانات قائمة (علاقة 1 لـ 1 أحياناً تعود كقائمة)
              teacherData = Map<String, dynamic>.from(
                teacherJson[0] as Map,
              ); // أخذ أول عنصر في القائمة
            } else if (teacherJson is Map) {
              // إذا كانت البيانات خريطة مباشرة
              teacherData = Map<String, dynamic>.from(
                teacherJson,
              ); // استخدام الخريطة مباشرة
            } // نهاية التحقق من النوع
          } // نهاية التحقق من البيانات

          final combinedData = {
            // دمج بيانات البروفايل مع بيانات جدول المعلم في خريطة واحدة
            ...dataMap, // بيانات البروفايل (الاسم، الجوال، إلخ)
            ...teacherData, // بيانات المعلم (التخصص، الراتب، إلخ)
            'status': 'accepted', // تعيين الحالة يدوياً كمقبول
          }; // نهاية الدمج

          if (combinedData['eligibility_proof'] != null) {
            // معالجة رابط ملف الأهلية في البيانات المدمجة
            combinedData['eligibility_proof'] = SupabaseConfig.getImageUrl(
              // الحصول على الرابط الكامل
              SupabaseConfig.bucketPledges, // من الحاوية الصحيحة
              combinedData['eligibility_proof'], // المسار المخزن
            ); // نهاية التعيين
          } // نهاية التحقق
          return TeacherModel.fromJson(
            combinedData,
          ); // إرجاع كائن المعلم المكتمل
        }).toList(); // تحويل النتائج لقائمة
      } // نهاية شرط الحالة
    } catch (e) {
      // معالجة الأخطاء في حال حدوثها
      Get.snackbar(
        // إظهار رسالة تنبيه للمستخدم
        'error'.tr, // عنوان التنبيه (مترجم)
        'failed_load_circles'.tr, // نص الخطأ (مترجم)
        backgroundColor: Colors.redAccent, // لون الخامية (أحمر للخطأ)
        colorText: Colors.white, // لون النص
      ); // نهاية التنبيه
      return []; // إرجاع قائمة فارغة لتجنب تعطل التطبيق
    } // نهاية كتلة الخطأ
  } // نهاية دالة جلب المعلمين

  Future<List<StudentModel>> getStudents({
    // دالة لجلب قائمة الطلاب بنفس المنطق
    required String status, // حالة الطالب (pending أو accepted)
  }) async {
    // دالة غير متزامنة
    try {
      // بدء محاولة التنفيذ
      int? batchFilter; // متغير لتخزين فلتر الدفعة
      if (Get.isRegistered<GlobalBatchController>()) {
        // الوصول للمتحكم العام للدفعات
        batchFilter = Get.find<GlobalBatchController>()
            .selectedBatch
            .value; // جلب الدفعة المختارة
      } // نهاية الوصول للمتحكم

      if (status == 'pending') {
        // حالة الطلاب المتقدمين بطلبات تسجيل
        var query =
            supabase // بناء الاستعلام
                .from('registration_requests') // من جدول الطلبات
                .select() // اختيار الحقول
                .eq('role', 'student') // تصفية للطلاب فقط
                .eq('status', 'pending'); // تصفية للمعلقين فقط

        if (batchFilter != null) {
          // إذا وجدت دفعة مختارة
          query = query.eq(
            'batch_number',
            batchFilter,
          ); // تصفية الطلبات حسب الدفعة
        } // نهاية تصفية الدفعة

        final response = await query; // تنفيذ الطلب

        return (response as List).map((data) {
          // تحويل البيانات لنماذج StudentModel
          if (data['pledge_file_url'] != null) {
            // التحقق من وجود ملف التعهد
            data['pledge_file_url'] = SupabaseConfig.getImageUrl(
              // بناء الرابط الكامل للملف
              SupabaseConfig.bucketPledges, // من الحاوية المخصصة
              data['pledge_file_url'], // المسار
            ); // نهاية البناء
          } // نهاية التحقق
          return StudentModel.fromJson(data); // إرجاع كائن الطالب
        }).toList(); // تحويل النتائج لقائمة
      } else {
        // حالة الطلاب المقبولين والمسجلين في الحلقات
        // تحسين جذري: جلب قائمة المدراء أولاً لاستبعادهم من قائمة الطلاب
        final adminResponse = await supabase.from('admins').select('id');
        final adminIds = (adminResponse as List).map((a) => a['id'].toString()).toList();

        var query =
            supabase // استعلام مركب من عدة جداول
                .from('profiles') // من جدول البروفايلات
                .select(
                  '*, students(*), circle_members(circles(name))',
                ) // جلب بيانات الطالب واسم حلقته
                .eq('role', 'student'); // تصفية أولية للطلاب

        if (batchFilter != null) {
          // تصفية حسب الدفعة المختارة
          query = query.eq('batch_number', batchFilter); // إضافة شرط الدفعة
        } // نهاية تصفية الدفعة

        final response = await query; // تنفيذ الاستعلام

        return (response as List)
            .where((data) => !adminIds.contains(data['id'].toString())) // استبعاد المدراء حتى لو كانت رتبتهم student في البروفايل
            .map((data) {
          // معالجة البيانات المستلمة لكل طالب
          final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
            data as Map,
          ); // تحويل البيانات لخريطة
          final studentsRaw = dataMap['students']; // استخراج بيانات جدول الطلاب
          Map<String, dynamic> studentDataRaw =
              {}; // تهيئة خريطة للبيانات الإضافية

          if (studentsRaw is List && studentsRaw.isNotEmpty) {
            // معالجة البيانات إذا كانت قائمة
            studentDataRaw = Map<String, dynamic>.from(
              studentsRaw[0] as Map,
            ); // أخذ العنصر الأول
          } else if (studentsRaw is Map) {
            // معالجة البيانات إذا كانت خريطة
            studentDataRaw = Map<String, dynamic>.from(
              studentsRaw,
            ); // استخدامها مباشرة
          } // نهاية المعالجة

          String? circleName; // متغير لتخزين اسم الحلقة
          final circleMembers =
              dataMap['circle_members'] as List?; // جلب عضوية الحلقات
          if (circleMembers != null && circleMembers.isNotEmpty) {
            // إذا كان الطالب منضماً لحلقة
            final firstMember = circleMembers[0] as Map?; // أخذ أول عضوية
            circleName =
                firstMember?['circles']?['name']; // استخراج اسم الحلقة من الجدول المرتبط
          } // نهاية استخراج الاسم

          final combinedData = {
            // دمج كل البيانات لمعالجتها في نموذج الطالب
            ...dataMap, // بيانات البروفايل
            ...studentDataRaw, // بيانات جدول الطالب
            'is_distributed':
                circleName !=
                null, // تحديد ما إذا كان الطالب موزعاً على حلقة أم لا
            'circle_name': circleName, // تعيين اسم الحلقة
            'status': 'accepted', // تعيين الحالة كمقبول
          }; // نهاية الدمج

          if (combinedData['pledge_file_url'] != null) {
            // معالجة رابط ملف التعهد للطلاب المقبولين
            combinedData['pledge_file_url'] = SupabaseConfig.getImageUrl(
              // الحصول على الرابط الكامل
              SupabaseConfig.bucketPledges, // الحاوية
              combinedData['pledge_file_url'], // المسار
            ); // نهاية التعيين
          } // نهاية التحقق
          return StudentModel.fromJson(
            combinedData,
          ); // إرجاع كائن الطالب المكتمل
        }).toList(); // تحويل النتائج لقائمة
      } // نهاية شرط الحالة
    } catch (e) {
      // الإمساك بالأخطاء
      Get.snackbar(
        // إظهار تنبيه بالخطأ
        'error'.tr, // العنوان
        'failed_load_students'.tr, // الرسالة
        backgroundColor: Colors.redAccent, // اللون
        colorText: Colors.white, // لون النص
      ); // نهاية التنبيه
      return []; // إرجاع قائمة فارغة
    } // نهاية كتلة الخطأ
  } // نهاية دالة جلب الطلاب

  Future<bool> deleteUser(String id) async {
    // دالة عامة لحذف مستخدم من النظام نهائياً
    try {
      // حماية: منع حذف المستخدم لنفسه (سواء كان في قائمة الطلاب أو الإدارة)
      final currentUserId = supabase.auth.currentUser?.id;
      if (id == currentUserId) {
         Get.snackbar(
          'تنبيه',
          'لا يمكنك حذف حسابك الشخصي الذي تستخدمه حالياً.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      // حذف من جدول المدراء أولاً
      try {
        await supabase.from('admins').delete().eq('id', id);
      } catch (_) {} 
      
      // حذف من جدول المعلمين
      try {
        await supabase.from('teachers').delete().eq('user_id', id);
      } catch (_) {}

      // حذف من جدول الطلاب
      try {
        await supabase.from('students').delete().eq('user_id', id);
      } catch (_) {}

      // حذف من جدول البروفايلات
      try {
        await supabase.from('profiles').delete().eq('id', id);
      } catch (_) {}

      // استدعاء وظيفة قاعدة بيانات لحذف المستخدم من Auth (إذا كانت متوفرة)
      try {
        await supabase.rpc(
          'delete_user_by_admin',
          params: {'user_id': id},
        ); 
      } catch (e) {
      }

      // حذف أي طلب تسجيل مرتبط
      try {
        await supabase
            .from('registration_requests')
            .delete()
            .eq('id', id); 
      } catch (_) {}

      return true; // إرجاع نجاح العملية
    } catch (e) {
      // في حال فشل الحذف
      Get.snackbar(
        // إظهار رسالة خطأ
        'error'.tr, // العنوان
        'error_saving_data'.tr, // الرسالة
        backgroundColor: Colors.redAccent, // اللون
        colorText: Colors.white, // لون النص
      ); // نهاية التنبيه
      return false; // إرجاع فشل العملية
    } // نهاية الخطأ
  } // نهاية دالة حذف المستخدم

  Future<bool> deleteTeacher(String id) async {
    // دالة مخصصة لحذف معلم مع إشعار
    final success = await deleteUser(id); // استدعاء الدالة العامة للحذف
    if (success) {
      // إذا نجح الحذف
      Get.snackbar(
        'success'.tr,
        'teacher_deleted'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      ); // إشعار نجاح
    } // نهاية التحقق
    return success; // إرجاع النتيجة
  } // نهاية حذف المعلم

  Future<bool> deleteStudent(String id) async {
    // دالة مخصصة لحذف طالب مع إشعار
    final success = await deleteUser(id); // استدعاء الدالة العامة للحذف
    if (success) {
      // إذا نجح الحذف
      Get.snackbar(
        'success'.tr,
        'student_deleted'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      ); // إشعار نجاح
    } // نهاية التحقق
    return success; // إرجاع النتيجة
  } // نهاية حذف الطالب

  Future<bool> updateTeacherSponsorship(
    String id,
    bool canCover, {
    double? amount,
    String? package,
  }) async {
    // دالة لتحديث بيانات كفالة المعلم
    try {
      // بدء المحاولة
      await supabase // تحديث جدول المعلمين
          .from('teachers') // جدول المعلمين
          .update({
            'can_cover_balance': canCover,
            'sponsorship_amount': amount,
            'package_type': package,
          }) // الحقول الجديدة
          .eq('user_id', id); // تصفية حسب معرف المستخدم
      Get.snackbar(
        'success'.tr,
        'sponsorship_status_updated'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      ); // إشعار نجاح
      return true; // نجاح
    } catch (e) {
      // فشل
      Get.snackbar(
        'error'.tr,
        'error_saving_data'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      ); // إشعار فشل
      return false; // فشل
    } // نهاية الخطأ
  } // نهاية دالة تحديث الكفالة

  Future<bool> updateUserBatch(String id, int batchNumber) async {
    try {
      await supabase
          .from('profiles')
          .update({'batch_number': batchNumber})
          .eq('id', id);
      Get.snackbar(
        'success'.tr,
        'batch_updated_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'error_saving_data'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<List<AdminUserModel>> getUsersByRoles(List<String> roles) async {
    // دالة لجلب مستخدمي الإدارة حسب أدوارهم
    try {
      // بدء المحاولة
      List<AdminUserModel> allUsers = []; // قائمة لتجميع المستخدمين

      // جلب المدراء من جدول admins إذا كان الدور المطلوب يتضمن admin
      if (roles.contains('admin') ||
          roles.contains('super_admin') ||
          roles.contains('management')) {
        try {
          final adminResponse = await supabase.from('admins').select();
          allUsers.addAll(
            (adminResponse as List).map((data) {
              data['role'] = 'admin'; // تحديد الدور كمدير
              return AdminUserModel.fromJson(data);
            }),
          );
        } catch (e) {
        }
      }

      // جلب المنسقين وباقي الأدوار من جدول profiles
      final profileRoles = roles
          .where((r) => r != 'admin' && r != 'super_admin')
          .toList();
      if (profileRoles.isNotEmpty) {
        try {
          final profileResponse = await supabase
              .from('profiles')
              .select()
              .filter('role', 'in', profileRoles);
          
          // تحويل البيانات مع التأكد من عدم إضافة الطلاب هنا
          for (var data in profileResponse as List) {
             allUsers.add(AdminUserModel.fromJson(data));
          }
        } catch (e) {
        }
      }

      // إزالة التكرار بناءً على الـ ID (في حال وجد المستخدم في الجدولين)
      final ids = <String>{};
      allUsers.retainWhere((user) => ids.add(user.id));

      // ترتيب القائمة المدمجة حسب تاريخ الانضمام (الأحدث أولاً)
      allUsers.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));

      return allUsers; // إرجاع القائمة النهائية
    } catch (e) {
      // فشل
      Get.snackbar(
        'error'.tr,
        'failed_load_users'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      ); // إشعار فشل
      return []; // قائمة فارغة
    } // نهاية الخطأ
  } // نهاية دالة جلب المستخدمين حسب الأدوار

  Future<bool> createManagementUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String gender,
  }) async {
    // دالة لإضافة مستخدم إداري جديد عبر جانجو
    try {
      // بدء المحاولة
      final url = Uri.parse(
        "${AppConstants.djangoApiBaseUrl}/management/api/create_user/?format=json",
      ); // رابط الـ API لإنشاء المستخدم
      final response = await http.post(
        // إرسال طلب POST
        url, // الرابط
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.djangoApiKey,
        }, // الترويسات ومفتاح الحماية
        body: json.encode({
          'full_name': name,
          'email': email,
          'password': password,
          'role': role,
          'gender': gender,
        }), // بيانات المستخدم في جسم الطلب
      ); // انتظار الاستجابة

      if (response.statusCode == 200 || response.statusCode == 201) {
        // بمجرد الإنشاء، سنقوم بتحديث الرتبة في جدول profiles للجميع دون استثناء
        try {
           final data = json.decode(response.body);
           final userId = data['id'] ?? data['user_id'];
           if (userId != null) {
             // تحديث الرتبة في profiles لتكون مطابقة للرتبة المطلوبة
             // إذا كان admin سنضع رتبته admin في البروفايل أيضاً لضمان عدم ظهوره كطالب
             await supabase.from('profiles').update({'role': role}).eq('id', userId);
           }
        } catch (_) {}

        Get.snackbar(
          'success'.tr,
          'user_added_success'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        ); // إشعار نجاح
        return true; // نجاح
      } else {
        // إذا حدث خطأ من جهة السيرفر
        final data = json.decode(response.body); // تحليل رسالة الخطأ
        Get.snackbar(
          'error'.tr,
          data['message'] ?? 'failed_add_user'.tr,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        ); // إظهار رسالة الخطأ المستلمة
        return false; // فشل
      } // نهاية التحقق من الحالة
    } catch (e) {
      // فشل الاتصال بالسيرفر
      Get.snackbar(
        'error'.tr,
        'django_connection_error'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      ); // إشعار خطأ اتصال
      return false; // فشل
    } // نهاية الخطأ
  } // نهاية دالة إنشاء مستخدم إداري
} // نهاية تعريف الميكسين UsersModule
