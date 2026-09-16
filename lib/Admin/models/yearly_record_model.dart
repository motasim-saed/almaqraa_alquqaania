class YearlyRecord { // تعريف كلاس (نموذج) للسجل السنوي المطور للطالب
  final String studentId; // المعرف الفريد للطالب صاحب السجل
  final String studentName; // اسم الطالب صاحب السجل
  final Map<int, int> monthlyGrades; // خريطة تخزن درجات كل شهر (الشهر: الدرجة)
  final double monthlyAverageExam; // متغير لتخزين متوسط درجات الاختبارات الشهرية
  final double finalResult; // متغير لتخزين النتيجة النهائية الإجمالية للطالب
  final double finalExamResult; // متغير لتخزين درجة الاختبار النهائي من لجنة الاختبار

  YearlyRecord({ // مشيد الكلاس لتهيئة البيانات عند إنشاء كائن جديد
    required this.studentId, // جعل معرف الطالب حقلاً مطلوباً
    required this.studentName, // جعل اسم الطالب حقلاً مطلوباً
    required this.monthlyGrades, // جعل خريطة الدرجات الشهرية حقلاً مطلوباً
    required this.monthlyAverageExam, // جعل متوسط الاختبارات حقلاً مطلوباً
    required this.finalResult, // جعل النتيجة النهائية حقلاً مطلوباً
    required this.finalExamResult, // جعل نتيجة الاختبار النهائي حقلاً مطلوباً
  }); // نهاية مشيد الكلاس

  factory YearlyRecord.fromJson(Map<String, dynamic> json) { // دالة مصنع لإنشاء الكائن من بيانات بصيغة JSON
    // معالجة درجات الشهور من JSON إذا كانت مخزنة كخريطة
    Map<int, int> grades = {}; // تعريف خريطة فارغة لتخزين الدرجات المعالجة
    if (json['monthly_grades'] != null) { // التحقق من أن حقل الدرجات الشهرية ليس فارغاً في البيانات المستلمة
      (json['monthly_grades'] as Map).forEach((key, value) { // الدوران على عناصر الخريطة المستلمة
        grades[int.parse(key.toString())] = int.parse(value.toString()); // تحويل المفتاح والقيمة إلى أرقام صحيحة وإضافتها للخريطة
      }); // نهاية عملية الدوران
    } // نهاية التحقق من البيانات

    return YearlyRecord( // إرجاع كائن جديد من نوع YearlyRecord
      studentId: json['student_id']?.toString() ?? '', // استخراج معرف الطالب أو وضع نص فارغ كقيمة افتراضية
      studentName: (json['student']?['full_name'] ?? // محاولة جلب الاسم الكامل من كائن الطالب
                    json['profiles']?['full_name'] ?? // أو محاولة جلبه من كائن الملف الشخصي
                    json['student_name'] ?? '').toString(), // أو من الحقل المباشر، وتحويله في النهاية لنص
      monthlyGrades: grades, // تعيين خريطة الدرجات التي تمت معالجتها
      monthlyAverageExam: (json['monthly_average_exam'] ?? 0).toDouble(), // استخراج المتوسط وتحويله لرقم عشري
      finalResult: (json['final_result'] ?? 0).toDouble(), // استخراج النتيجة النهائية وتحويلها لرقم عشري
      finalExamResult: (json['final_exam_result'] ?? 0).toDouble(), // استخراج نتيجة الاختبار النهائي وتحويلها لرقم عشري
    ); // نهاية بناء الكائن
  } // نهاية دالة fromJson

  Map<String, dynamic> toJson() { // دالة لتحويل الكائن إلى خريطة بيانات (Map) لتسهيل إرسالها أو تخزينها
    return { // بداية إرجاع الخريطة
      'student_id': studentId, // إضافة معرف الطالب للخريطة
      'student_name': studentName, // إضافة اسم الطالب للخريطة
      'monthly_grades': monthlyGrades.map((k, v) => MapEntry(k.toString(), v)), // تحويل مفاتيح الشهور لنصوص لتتوافق مع صيغة JSON
      'monthly_average_exam': monthlyAverageExam, // إضافة متوسط الاختبارات للخريطة
      'final_result': finalResult, // إضافة النتيجة النهائية للخريطة
      'final_exam_result': finalExamResult, // إضافة نتيجة الاختبار النهائي للخريطة
    }; // نهاية الخريطة
  } // نهاية دالة toJson
} // نهاية تعريف الكلاس YearlyRecord
