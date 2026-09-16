import 'package:get/get.dart'; // استيراد حزمة GetX لدعم القوائم المتفاعلة (Rx)

/// تعريف الحالات الممكنة لحضور الطالب في اليوم الواحد
enum AttendanceStatus { 
  present, // حالة الحضور: حاضر
  absent,  // حالة الحضور: غائب
  excused, // حالة الحضور: مستأذن (بعذر)
  holiday  // حالة الحضور: إجازة رسمية
}

/// نموذج يمثل سجل الحضور والغياب اليومي لطالب محدد خلال فترة معينة (مثل شهر)
class DailyAttendanceRecord {
  final String studentId; // المعرف الفريد للطالب في قاعدة البيانات
  final String studentName; // اسم الطالب كما يظهر في الكشوفات
  
  // قائمة حالات الحضور اليومية، تم استخدام RxList لتحديث واجهة المستخدم تلقائياً عند تغيير أي حالة
  final RxList<AttendanceStatus> dailyStatuses;

  /// منشئ الفئة (Constructor) لبناء كائن سجل الحضور
  DailyAttendanceRecord({
    required this.studentId, // يتطلب معرف الطالب
    required this.studentName, // يتطلب اسم الطالب
    required List<AttendanceStatus> dailyStatuses, // يتطلب قائمة الحالات الأولية
  }) : dailyStatuses = dailyStatuses.obs; // تحويل القائمة العادية إلى قائمة متفاعلة (Observable)

  /// دالة لتحويل البيانات القادمة من JSON (قاعدة البيانات) إلى كائن برمجى
  factory DailyAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceRecord(
      studentId: json['studentId'] ?? '', // جلب المعرف أو نص فارغ كافتراضي
      studentName: json['studentName'] ?? '', // جلب الاسم أو نص فارغ
      // تحويل قائمة النصوص القادمة من JSON إلى قائمة من نوع Enum (AttendanceStatus)
      dailyStatuses: (json['dailyStatuses'] as List?)
              ?.map((s) => AttendanceStatus.values.firstWhere(
                  (e) => e.name == s, // البحث عن الحالة المطابقة بالاسم
                  orElse: () => AttendanceStatus.present)) // افتراض "حاضر" في حال عدم المطابقة
              .toList() ??
          [], // إرجاع قائمة فارغة في حال عدم وجود بيانات
    );
  }

  /// دالة لتحويل كائن السجل إلى صيغة Map (JSON) لإرساله أو حفظه
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId, // حفظ معرف الطالب
      'studentName': studentName, // حفظ اسم الطالب
      'dailyStatuses': dailyStatuses.map((s) => s.name).toList(), // تحويل حالات Enum إلى نصوص للحفظ
    };
  }

}
