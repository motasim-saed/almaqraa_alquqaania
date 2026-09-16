import 'package:al_maqraa/core/controllers/global_batch_controller.dart';
import 'package:flutter/material.dart'; // استيراد مكتبة ماتيريال لتنسيق الألوان والواجهات
import 'package:get/get.dart'; // استيراد حزمة GetX لدعم الترجمة والرسائل المنبثقة
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيس للتفاعل مع قاعدة البيانات
import '../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن

// تعريف ميكسين (Mixin) يسمى HolidaysModule لإدارة وظائف الإجازات والعطلات
mixin HolidaysModule {
  // الحصول على نسخة من عميل سوبابيس (Supabase Client) للقيام بالعمليات
  SupabaseClient get supabase => Supabase.instance.client;

  // دالة لجلب قائمة الإجازات من جدول 'app_holidays'
  Future<List<HolidayModel>> getHolidays() async {
    try {
      // استعلام لجلب سجلات الإجازات وترتيبها تنازلياً حسب التاريخ
      var query = supabase
          .from('app_holidays') // تحديد جدول الإجازات
          .select(); // اختيار كافة الحقول

      // تطبيق فلتر الدفعة العالمي إذا كان مختاراً
      if (Get.isRegistered<GlobalBatchController>()) {
        final filter = Get.find<GlobalBatchController>().selectedBatch.value;
        if (filter != null) {
          query = query.eq('batch_number', filter);
        }
      }

      final response = await query.order(
        'date',
        ascending: false,
      ); // الترتيب من الأحدث للأقدم

      // تحويل البيانات الواردة إلى قائمة من كائنات HolidayModel
      return (response as List)
          .map((data) => HolidayModel.fromJson(data)) // تحويل كل عنصر إلى نموذج
          .toList(); // تحويل النتيجة النهائية إلى قائمة
    } catch (e) {
      // إظهار رسالة خطأ مترجمة للمستخدم في حال فشل الجلب
      Get.snackbar(
        'error'.tr, // عنوان الرسالة: "خطأ"
        'error_fetching_holidays'
            .tr, // نص الرسالة: "حدث خطأ أثناء جلب الإجازات"
        backgroundColor: Colors.redAccent, // لون الخلفية أحمر للتنبيه
        colorText: Colors.white, // لون النص أبيض
        snackPosition: SnackPosition.BOTTOM, // مكان ظهور الرسالة في الأسفل
      );
      // إرجاع قائمة فارغة لتجنب تعطل التطبيق
      return [];
    }
  }

  // دالة لإضافة إجازة جديدة إلى قاعدة البيانات
  Future<bool> addHoliday(HolidayModel holiday) async {
    try {
      // تحويل نموذج الإجازة إلى صيغة JSON
      final json = holiday.toJson();
      // تنفيذ عملية الإدراج في جدول 'app_holidays'
      await supabase.from('app_holidays').insert(json);
      // إظهار رسالة نجاح مترجمة للمستخدم
      Get.snackbar(
        'success'.tr, // عنوان الرسالة: "نجاح"
        'holiday_added_success'.tr, // نص الرسالة: "تم إضافة الإجازة بنجاح"
        backgroundColor: Colors.green, // لون الخلفية أخضر للنجاح
        colorText: Colors.white, // لون النص أبيض
        snackPosition: SnackPosition.BOTTOM, // مكان ظهور الرسالة في الأسفل
      );
      return true; // نجاح العملية
    } catch (e) {
      // إظهار رسالة خطأ مترجمة في حال فشل الإضافة
      Get.snackbar(
        'error'.tr, // عنوان الرسالة: "خطأ"
        'error_adding_holiday'.tr, // نص الرسالة: "حدث خطأ أثناء إضافة الإجازة"
        backgroundColor: Colors.redAccent, // لون الخلفية أحمر
        colorText: Colors.white, // لون النص أبيض
        snackPosition: SnackPosition.BOTTOM, // مكان ظهور الرسالة
      );
      return false; // فشل العملية
    }
  }

  // دالة لحذف سجل إجازة معين باستخدام المعرف (ID)
  Future<bool> deleteHoliday(String id) async {
    try {
      // حذف السجل من جدول 'app_holidays' بشرط مطابقة المعرف
      await supabase.from('app_holidays').delete().eq('id', id);
      // إظهار رسالة نجاح مترجمة عند الحذف
      Get.snackbar(
        'success'.tr, // عنوان الرسالة: "نجاح"
        'holiday_deleted_success'.tr, // نص الرسالة: "تم حذف الإجازة بنجاح"
        backgroundColor: Colors.green, // لون الخلفية أخضر
        colorText: Colors.white, // لون النص أبيض
        snackPosition: SnackPosition.BOTTOM, // مكان ظهور الرسالة
      );
      return true; // نجاح الحذف
    } catch (e) {
      // إظهار رسالة خطأ مترجمة في حال فشل الحذف
      Get.snackbar(
        'error'.tr, // عنوان الرسالة: "خطأ"
        'error_deleting_holiday'.tr, // نص الرسالة: "حدث خطأ أثناء حذف الإجازة"
        backgroundColor: Colors.redAccent, // لون الخلفية أحمر
        colorText: Colors.white, // لون النص أبيض
        snackPosition: SnackPosition.BOTTOM, // مكان ظهور الرسالة
      );
      return false; // فشل الحذف
    }
  }

  // دالة لتخصيص إجازة لطالب أو إنشاء عطلة عامة
  Future<bool> assignStudentLeave({
    String? studentId, // معرف الطالب (اختياري)
    required DateTime startDate, // تاريخ البداية
    required DateTime endDate, // تاريخ النهاية
    required String reason, // سبب الإجازة
  }) async {
    try {
      // قائمة لتخزين التواريخ بين البداية والنهاية
      List<DateTime> dates = [];
      // متغير للتحكم في الحلقة يبدأ من تاريخ البداية
      DateTime current = startDate;
      // تكرار الأيام حتى الوصول لتاريخ النهاية
      while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
        dates.add(current); // إضافة التاريخ للقائمة
        current = current.add(const Duration(days: 1)); // الانتقال لليوم التالي
      }

      if (studentId != null) {
        // حالة: الإجازة خاصة بطالب معين (تحديث سجلات الحضور)
        final List<Map<String, dynamic>> records = dates.map((d) {
          return {
            'student_id': studentId, // ربط السجل بالطالب
            'date': d.toIso8601String().split('T')[0], // تنسيق التاريخ
            'attendance_status': 'excused', // حالة الحضور: "مستأذن"
          };
        }).toList();

        // إدراج أو تحديث السجلات في جدول 'daily_records'
        await supabase
            .from('daily_records')
            .upsert(records, onConflict: 'student_id, date');
      } else {
        // حالة: الإجازة عامة لجميع الطلاب
        await supabase.from('app_holidays').insert({
          'reason': reason, // سبب العطلة
          'start_date': startDate.toIso8601String().split(
            'T',
          )[0], // تاريخ البدء
          'end_date': endDate.toIso8601String().split('T')[0], // تاريخ الانتهاء
          'date': startDate.toIso8601String().split('T')[0], // التاريخ المرجعي
        });
      }
      // إظهار رسالة نجاح مترجمة بعد الانتهاء
      Get.snackbar(
        'success'.tr, // عنوان الرسالة: "نجاح"
        'leave_assigned_success'.tr, // نص الرسالة: "تم تعيين الإجازة بنجاح"
        backgroundColor: Colors.green, // لون الخلفية أخضر
        colorText: Colors.white, // لون النص أبيض
        snackPosition: SnackPosition.BOTTOM, // مكان ظهور الرسالة
      );
      return true; // نجاح العملية
    } catch (e) {
      // إظهار رسالة خطأ مترجمة في حال الفشل
      Get.snackbar(
        'error'.tr, // عنوان الرسالة: "خطأ"
        'error_assigning_leave'.tr, // نص الرسالة: "حدث خطأ أثناء تعيين الإجازة"
        backgroundColor: Colors.redAccent, // لون الخلفية أحمر
        colorText: Colors.white, // لون النص أبيض
        snackPosition: SnackPosition.BOTTOM, // مكان ظهور الرسالة
      );
      return false; // فشل العملية
    }
  }
}
