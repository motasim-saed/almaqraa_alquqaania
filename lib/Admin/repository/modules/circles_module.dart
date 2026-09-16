import 'package:al_maqraa/core/controllers/global_batch_controller.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيس للتعامل مع قاعدة البيانات السحابية
import '../../models/admin_models.dart'; // استيراد نماذج البيانات (Models) الخاصة بالأدمن

// تعريف ميكسين (Mixin) يسمى CirclesModule لإدارة وظائف الحلقات القرانية
mixin CirclesModule {
  // الحصول على نسخة من عميل سوبابيس (Supabase Client) للقيام بالعمليات
  SupabaseClient get supabase => Supabase.instance.client;

  // دالة لتحديث حالة الطلاب (سواء تم توزيعهم على حلقات أم لا)
  Future<void> setStudentsDistributed(
    List<String> ids, // قائمة بمعرفات الطلاب (user_id)
    bool isDistributed, // القيمة الجديدة (موزع: true، غير موزع: false)
  ) async {
    // إذا كانت القائمة فارغة، نخرج من الدالة مباشرة لتوفير الموارد
    if (ids.isEmpty) return;

    // تحديث حقل 'is_distributed' في جدول الطلاب 'students'
    await supabase
        .from('students') // اسم الجدول
        .update({'is_distributed': isDistributed}) // البيانات المراد تحديثها
        .filter(
          'user_id',
          'in',
          ids,
        ); // تطبيق التحديث فقط على الطلاب الذين توجد معرفاتهم في القائمة
  }

  // دالة لنقل طالب من حلقة إلى حلقة أخرى
  Future<bool> transferStudent(String studentId, String newCircleId) async {
    // الخطوة الأولى: حذف الطالب من عضويته في حلقته الحالية في جدول 'circle_members'
    await supabase.from('circle_members').delete().eq('student_id', studentId);

    // الخطوة الثانية: إضافة الطالب إلى الحلقة الجديدة في نفس الجدول
    await supabase.from('circle_members').insert({
      'circle_id': newCircleId, // معرف الحلقة الجديدة
      'student_id': studentId, // معرف الطالب
    });

    // الخطوة الثالثة: التأكد من تحديث حالة الطالب كـ "موزع" في جدول بياناته الأساسي
    await setStudentsDistributed([studentId], true);

    return true; // إرجاع القيمة true للدلالة على نجاح العملية
  }

  // دالة لجلب قائمة بجميع الحلقات القرآنية مع تفاصيلها
  Future<List<QuranCircleModel>> getQuranCircles() async {
    // بناء الاستعلام لجلب بيانات الحلقة مع تفاصيل المعلم والمختبر والطلاب
    var query = supabase
        .from('circles') // جدول الحلقات الأساسي
        .select(
          '*, teacher:profiles!teacher_id(full_name, gender), examiner:profiles!examiner_id(full_name), students:circle_members(student_id, student:profiles(full_name))',
        ); // ربط الجداول لجلب: اسم المعلم، جنسه، اسم المختبر، وأسماء الطلاب المنضمين

    // تطبيق فلتر الدفعة العالمي إذا كان مختاراً
    if (Get.isRegistered<GlobalBatchController>()) {
      final filter = Get.find<GlobalBatchController>().selectedBatch.value;
      if (filter != null) {
        query = query.eq('batch_number', filter);
      }
    }

    // تنفيذ الاستعلام وترتيب الحلقات حسب تاريخ الإنشاء (الأحدث أولاً)
    final response = await query.order('created_at', ascending: false);

    // تحويل البيانات الخام (التي وصلت كقائمة) إلى قائمة من نماذج QuranCircleModel
    return (response as List)
        .map(
          (data) => QuranCircleModel.fromJson(Map<String, dynamic>.from(data)),
        )
        .toList(); // إرجاع القائمة النهائية
  }

  // دالة لتحديث المختبر المعين لحلقة معينة
  Future<void> updateCircleExaminer(String circleId, String? examinerId) async {
    // تحديث حقل 'examiner_id' في جدول الحلقات للمعرف المحدد
    await supabase
        .from('circles') // اسم الجدول
        .update({
          'examiner_id': examinerId,
        }) // تعيين معرف المختبر الجديد (أو null لحذفه)
        .eq('id', circleId); // الفلترة حسب معرف الحلقة
  }
}
