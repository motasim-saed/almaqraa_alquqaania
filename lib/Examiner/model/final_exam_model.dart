/// كائن يمثل سجل الاختبار النهائي لطالب معين في النظام
class FinalExamRecord {
  final String studentId;   // المعرف الفريد للطالب في قاعدة البيانات (UUID)
  final String studentName; // الاسم الكامل للطالب المعروض في القائمة
  double hifzScore;         // درجة اختبار الحفظ (الحد الأقصى المسموح 50 درجة)
  double tajweedScore;      // درجة اختبار التجويد (الحد الأقصى المسموح 30 درجة)
  double tilawahScore;      // درجة اختبار التلاوة (الحد الأقصى المسموح 20 درجة)

  // مُنشئ الكائن لتهيئة البيانات الأساسية عند إنشاء نسخة جديدة
  FinalExamRecord({
    required this.studentId,   // المعرف حقل إلزامي لتمييز الطالب
    required this.studentName, // اسم الطالب حقل إلزامي للعرض
    this.hifzScore = 0.0,      // القيمة الافتراضية لدرجة الحفظ هي صفر
    this.tajweedScore = 0.0,   // القيمة الافتراضية لدرجة التجويد هي صفر
    this.tilawahScore = 0.0,   // القيمة الافتراضية لدرجة التلاوة هي صفر
  });

  // خاصية (Getter) تحسب المجموع الكلي للدرجات الثلاث تلقائياً
  double get totalScore => hifzScore + tajweedScore + tilawahScore;

  // دالة (Factory) لتحويل البيانات المستلمة من قاعدة البيانات (JSON) إلى كائن برمجي
  factory FinalExamRecord.fromJson(Map<String, dynamic> json) {
    return FinalExamRecord(
      // استخراج معرف الطالب وتحويله لنص مع التعامل مع القيم الفارغة
      studentId: json['student_id']?.toString() ?? '',
      // محاولة استخراج اسم الطالب من عدة حقول محتملة لضمان استقرار العرض
      studentName:
      (json['profiles']?['full_name'] ?? // جلب الاسم من العلاقة مع جدول البروفايلات
          json['studentName'] ??      // أو من حقل studentName المباشر
          json['student_name'] ??     // أو من حقل student_name
          '')                        // قيمة فارغة في حال عدم وجود أي منها
          .toString(),
      // تحويل درجة الحفظ من نص/ديناميكي إلى رقم عشري (double)
      hifzScore: double.tryParse(json['hifz_score']?.toString() ?? '0') ?? 0.0,
      // تحويل درجة التجويد من نص/ديناميكي إلى رقم عشري (double)
      tajweedScore: double.tryParse(json['tajweed_score']?.toString() ?? '0') ?? 0.0,
      // تحويل درجة التلاوة من نص/ديناميكي إلى رقم عشري (double)
      tilawahScore: double.tryParse(json['tilawah_score']?.toString() ?? '0') ?? 0.0,
    );
  }

  // دالة تحول بيانات الكائن إلى خريطة (Map) تمهيداً لحفظها في قاعدة البيانات السحابية
  Map<String, dynamic> toJson(String circleId, String teacherId, String examinerId) {
    return {
      'student_id': studentId,     // إرفاق معرف الطالب المستهدف
      'teacher_id': teacherId,     // إرفاق معرف معلم الحلقة
      'examiner_id': examinerId,   // إرفاق معرف المختبر الذي أجرى التقييم
      'circle_id': circleId,       // إرفاق معرف الحلقة التابع لها الطالب
      'hifz_score': hifzScore,     // إرسال درجة الحفظ المدخلة
      'tajweed_score': tajweedScore, // إرسال درجة التجويد المدخلة
      'tilawah_score': tilawahScore, // إرسال درجة التلاوة المدخلة
      'year': DateTime.now().year,  // تخزين السنة الحالية تلقائياً لأرشفة الاختبارات
    };
  }
}