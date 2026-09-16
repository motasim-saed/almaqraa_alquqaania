import 'package:flutter/material.dart'; // استيراد مكتبة ماتيريال للواجهات والألوان
import 'package:get/get.dart'; // استيراد حزمة GetX لدعم الترجمة والرسائل المنبثقة
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيس للتفاعل مع قاعدة البيانات
import '../../../Student/models/student_models.dart'; // استيراد نماذج بيانات الطلاب (الخطط والسجلات)

// تعريف ميكسين (Mixin) يسمى ProgressModule مخصص للأدمن والمعلم للاطلاع على تقدم الطلاب وإدارته
mixin ProgressModule {
  // الحصول على نسخة من عميل سوبابيس (Supabase Client) للقيام بعمليات الاستعلام
  SupabaseClient get supabase => Supabase.instance.client;

  // جلب الخطط السنوية الخاصة بطالب معين
  Future<List<AnnualPlanModel>> getStudentAnnualPlans(String studentId) async {
    try {
      final response = await supabase
          .from('annual_plans')
          .select()
          .eq('student_id', studentId)
          .order('year', ascending: false);
      
      return (response as List)
          .map((data) => AnnualPlanModel.fromJson(data))
          .toList();
    } catch (e) {
      _showError();
      return [];
    }
  }

  // جلب الخطط الشهرية الخاصة بطالب معين
  Future<List<MonthlyPlanModel>> getStudentMonthlyPlans(String studentId) async {
    try {
      final response = await supabase
          .from('monthly_plans')
          .select()
          .eq('student_id', studentId)
          .order('year', ascending: false)
          .order('month', ascending: false);
      
      return (response as List)
          .map((data) => MonthlyPlanModel.fromJson(data))
          .toList();
    } catch (e) {
      _showError();
      return [];
    }
  }

  // حذف خطة سنوية (للمعلم/الأدمن)
  Future<void> deleteAnnualPlan(String planId) async {
    try {
      await supabase.from('annual_plans').delete().eq('id', planId);
    } catch (e) {
      rethrow;
    }
  }

  // حذف خطة شهرية (للمعلم/الأدمن)
  Future<void> deleteMonthlyPlan(String planId) async {
    try {
      await supabase.from('monthly_plans').delete().eq('id', planId);
    } catch (e) {
      rethrow;
    }
  }

  // تحديث خطة سنوية
  Future<void> updateAnnualPlan(AnnualPlanModel plan) async {
    try {
      await supabase
          .from('annual_plans')
          .update(plan.toJson())
          .eq('id', plan.id);
    } catch (e) {
      rethrow;
    }
  }

  // تحديث خطة شهرية
  Future<void> updateMonthlyPlan(MonthlyPlanModel plan) async {
    try {
      await supabase
          .from('monthly_plans')
          .update(plan.toJson())
          .eq('id', plan.id);
    } catch (e) {
      rethrow;
    }
  }

  // جلب سجلات الإنجاز اليومي
  Future<List<DailyRecordModel>> getStudentDailyRecords(String studentId) async {
    try {
      final response = await supabase
          .from('daily_records')
          .select()
          .eq('student_id', studentId)
          .order('date', ascending: false);
      
      return (response as List)
          .map((data) => DailyRecordModel.fromJson(data))
          .toList();
    } catch (e) {
      _showError();
      return [];
    }
  }

  void _showError() {
    Get.snackbar(
      'error'.tr,
      'failed_to_fetch_student_details'.tr,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
