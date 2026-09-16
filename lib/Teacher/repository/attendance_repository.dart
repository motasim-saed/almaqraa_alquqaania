import '../models/daily_attendance_record_model.dart'; // استيراد نموذج سجل الحضور اليومي
import '../../Admin/models/admin_models.dart'; // استيراد نماذج بيانات الإدارة (مثل العطلات)

/// فئة تمثل استجابة بيانات الحضور، تحتوي على قائمة السجلات وقائمة العطلات
class AttendanceDataResponse {
  final List<DailyAttendanceRecord> records; // قائمة بسجلات الحضور اليومية
  final List<HolidayModel> holidays; // قائمة بالعطلات الرسمية

  // منشئ الفئة مع تحديد الحقول المطلوبة
  AttendanceDataResponse({required this.records, required this.holidays});
}

/// واجهة مستودع بيانات الحضور (Interface) لتحديد العمليات المطلوبة
abstract class AttendanceRepository {
  // دالة لجلب بيانات الحضور بناءً على المعلم، السنة، والشهر
  Future<AttendanceDataResponse> getAttendanceData({
    required String teacherId, // معرف المعلم
    required int year, // السنة المطلوبة
    required int month, // الشهر المطلوب
  });

  // دالة لحفظ حالة حضور طالب واحد في تاريخ محدد
  Future<bool> saveAttendance({
    required String studentId, // معرف الطالب
    required DateTime date, // تاريخ الحضور
    required AttendanceStatus status, // حالة الحضور (حاضر، غائب، إلخ)
  });

  // دالة لحفظ سجلات حضور متعددة دفعة واحدة لشهر وسنة محددين
  Future<bool> saveMultipleAttendance({
    required List<Map<String, dynamic>> records, // قائمة السجلات بتنسيق مفتاح وقيمة
    required int year, // السنة
    required int month, // الشهر
  });
}
