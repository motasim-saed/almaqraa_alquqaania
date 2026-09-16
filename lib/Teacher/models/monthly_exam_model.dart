/// سجل الدرجات الشهرية لطالب محدد ويشمل درجات (الحفظ، التجويد، التلاوة)
class MonthlyExamRecord { // تعريف فئة سجل الاختبار الشهري
  final String studentId; // المعرف الفريد للطالب في قاعدة البيانات
  final String studentName; // اسم الطالب الكامل لعرضه في الكشوفات
  double hifzScore; // متغير لتخزين درجة الحفظ (عادة من 50)
  double tajweedScore; // متغير لتخزين درجة التجويد (عادة من 30)
  double tilawahScore; // متغير لتخزين درجة التلاوة أو التلقين (عادة من 20)

  /// منشئ الفئة (Constructor) لإنشاء كائن جديد من السجل الشهري
  MonthlyExamRecord({
    required this.studentId, // يتطلب معرف الطالب كمعامل إلزامي
    required this.studentName, // يتطلب اسم الطالب كمعامل إلزامي
    this.hifzScore = 0.0, // القيمة الافتراضية لدرجة الحفظ هي صفر
    this.tajweedScore = 0.0, // القيمة الافتراضية لدرجة التجويد هي صفر
    this.tilawahScore = 0.0, // القيمة الافتراضية لدرجة التلاوة هي صفر
  });

  /// خاصية (Getter) لحساب المجموع الكلي للدرجات الثلاث
  double get totalScore => hifzScore + tajweedScore + tilawahScore; // حاصل جمع الحفظ والتجويد والتلاوة

  /// دالة (Factory) لتحويل البيانات القادمة من JSON (مثل Supabase) إلى كائن برمجى [MonthlyExamRecord]
  factory MonthlyExamRecord.fromJson(Map<String, dynamic> json) { // تستقبل خريطة بيانات
    return MonthlyExamRecord( // إرجاع كائن جديد معبأ بالبيانات
      studentId: json['student_id']?.toString() ?? '', // تحويل المعرف لنص أو إرجاع نص فارغ
      studentName: // محاولة استخراج الاسم من عدة مفاتيح محتملة لضمان المرونة
          (json['student']?['full_name'] ?? // البحث في كائن الطالب المرتبط
                  json['profiles']?['full_name'] ?? // أو في كائن الملف الشخصي
                  json['studentName'] ?? // أو في مفتاح الاسم المباشر (تنسيق 1)
                  json['student_name'] ?? // أو في مفتاح الاسم المباشر (تنسيق 2)
                  '') // القيمة الافتراضية في حال عدم وجود أي منها
              .toString(), // تحويل النتيجة النهائية لنص
      hifzScore: double.tryParse(json['hifz_score']?.toString() ?? '0') ?? 0.0, // تحويل نص الدرجة إلى رقم عشري
      tajweedScore: // استخراج درجة التجويد مع معالجة الأخطاء
          double.tryParse(json['tajweed_score']?.toString() ?? '0') ?? 0.0, // التحويل لرقم عشري أو صفر
      tilawahScore: // استخراج درجة التلاوة مع دعم بديل (Fallback)
          double.tryParse(json['tilawah_score']?.toString() ?? '0') ?? // محاولة المفتاح الأول
          double.tryParse( // محاولة مفتاح "درجة التلقين" في حال غياب التلاوة
            json['talqeen_score']?.toString() ?? '0',
          ) ?? // في حال فشل كل المحاولات
          0.0, // القيمة الافتراضية صفر
    );
  }

  /// دالة لتحويل كائن السجل إلى صيغة Map (JSON) لإرساله إلى السيرفر
  Map<String, dynamic> toJson() { // تحويل الكائن لخريطة بيانات
    return { // إرجاع الخريطة بالمفاتيح المطلوبة في قاعدة البيانات
      'student_id': studentId, // حفظ معرف الطالب
      'student_name': studentName, // حفظ اسم الطالب
      'hifz_score': hifzScore, // حفظ درجة الحفظ
      'tajweed_score': tajweedScore, // حفظ درجة التجويد
      'tilawah_score': tilawahScore, // حفظ درجة التلاوة
    };
  }
}
