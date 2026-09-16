import 'package:al_maqraa/core/controllers/global_batch_controller.dart';
import 'package:flutter/material.dart'; // استيراد مكتبة ماتيريال للألوان والواجهات
import 'package:get/get.dart'; // استيراد حزمة GetX لدعم الترجمة والرسائل المنبثقة
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيس للتفاعل مع قاعدة البيانات
import '../../../core/models/notification_model.dart'; // استيراد نموذج بيانات الإشعارات

// تعريف ميكسين (Mixin) يسمى NotificationModule لإدارة وظائف الإشعارات
mixin NotificationModule {
  // الحصول على نسخة من عميل سوبابيس (Supabase Client) للقيام بالعمليات
  SupabaseClient get supabase => Supabase.instance.client;

  // دالة لإرسال إشعار جديد وحفظه في قاعدة البيانات
  Future<bool> sendNotification(
    String title, // عنوان الإشعار
    String body, // نص الإشعار
    String targetRole, // الفئة المستهدفة (معلم، طالب، الخ)
  ) async {
    try {
      // الحصول على المعرف الفريد للمستخدم الحالي (الأدمن المرسل)
      final currentUserId = supabase.auth.currentUser?.id;

      // اختيار رقم الدفعة المختار حالياً لإرفاقه بالإشعار
      int? currentBatch;
      if (Get.isRegistered<GlobalBatchController>()) {
        currentBatch = Get.find<GlobalBatchController>().selectedBatch.value;
      }

      // تنفيذ عملية الإدراج في جدول 'notifications'
      await supabase.from('notifications').insert({
        'title': title, // تعيين العنوان
        'body': body, // تعيين نص
        'target_role': targetRole, // تعيين الفئة المستهدفة
        'sender_id': currentUserId, // تعيين معرف المرسل
        'created_at': DateTime.now().toIso8601String(), // تعيين تاريخ ووقت الإرسال
        'batch_number': currentBatch, // ربط الإشعار بالدفعة المختارة حالياً
      });

      // ملاحظة للمبرمج: لكي يصل الإشعار والتطبيق مغلق، يجب تفعيل Supabase Edge Function 
      // تستمع لعملية الـ Insert في جدول notifications وتقوم بالإرسال عبر Firebase Admin SDK.
      
      Get.snackbar(
        'success'.tr,
        'notification_sent_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'error_sending_notification'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // دالة لجلب قائمة كافة الإشعارات المرسلة (تم تعديلها لتظهر الكل للإدارة)
  Future<List<NotificationModel>> getSentNotifications() async {
    try {
      // استعلام لجلب كافة الإشعارات وترتيبها من الأحدث للأقدم
      // أزلنا شرط 'sender_id' لكي تظهر كافة الإشعارات السابقة في شاشة الإدارة
      var query = supabase
          .from('notifications')
          .select();

      // تطبيق فلتر الدفعة العالمي إذا كان مختاراً
      if (Get.isRegistered<GlobalBatchController>()) {
        final filter = Get.find<GlobalBatchController>().selectedBatch.value;
        if (filter != null) {
          query = query.eq('batch_number', filter);
        }
      }

      final response = await query.order(
        'created_at',
        ascending: false,
      ); 

      return (response as List)
          .map((data) => NotificationModel.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // دالة لتعديل بيانات إشعار موجود مسبقاً
  Future<bool> updateNotification(
    String id,
    String title,
    String body,
    String targetRole,
  ) async {
    try {
      await supabase
          .from('notifications')
          .update({
            'title': title,
            'body': body,
            'target_role': targetRole,
          })
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // دالة لحذف إشعار من قاعدة البيانات
  Future<bool> deleteNotification(String id) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
