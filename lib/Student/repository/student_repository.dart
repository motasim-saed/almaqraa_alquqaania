// استيراد نماذج بيانات الطالب التي ستُستخدم داخل مستودع البيانات
import '../models/student_models.dart';

/// واجهة تُعَّرف كافة العمليات الخاصة بقاعدة بيانات الطالب، سواء للتخزين المحلي أو السحابي
abstract class StudentRepository {
  /// جلب كافة الخطط السنوية المتعلقة بطالب محدد
  Future<List<AnnualPlanModel>> getAnnualPlans(String studentId);
  
  /// حفظ خطة سنوية جديدة خاصة بالطالب
  Future<void> saveAnnualPlan(AnnualPlanModel plan);

  /// جلب كافة الخطط الشهرية المتعلقة بطالب محدد
  Future<List<MonthlyPlanModel>> getMonthlyPlans(String studentId);
  
  /// حفظ خطة شهرية جديدة في قاعدة البيانات
  Future<void> saveMonthlyPlan(MonthlyPlanModel plan);

  /// جلب السجلات اليومية لتقدم الطالب 
  Future<List<DailyRecordModel>> getDailyRecords(String studentId);
  
  /// حفظ سجل يومي جديد لتقدم الطالب (مثل حفظ مقطع قرآن أو مراجعة)
  Future<void> saveDailyRecord(DailyRecordModel record);
  
  /// تحديث بيانات سجل يومي موجود بالفعل
  Future<void> updateDailyRecord(DailyRecordModel record);

  // الدوال المتبقية تتعلق بقسم المحادثة والتواصل (Chat)
  
  /// جلب جهات الاتصال الخاصة بالطالب للتراسل معهم، تعتمد على دور الشخص [role]
  /// مثل المعلم أو مشرف الحلقة
  Future<List<Map<String, dynamic>>> getChatContacts(
    String studentId,
    String role,
  );
  
  /// دالة للبحث وجلب أول مشرف/مسؤول متاح ليتمكن الطالب من التواصل معه
  Future<Map<String, dynamic>?> getFirstAdmin();

  /// جلب تفاصيل الطالب المعمقة (للمنسقين)
  Future<Map<String, dynamic>?> getStudentDetailedInfo(String studentId);
}
