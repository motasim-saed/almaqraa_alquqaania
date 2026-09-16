class SystemSettingModel { // تعريف كلاس (نموذج) لإعدادات النظام
  final bool studentRegistrationEnabled; // متغير لتحديد ما إذا كان تسجيل الطلاب متاحاً أم لا
  final String batchMode; // متغير لتحديد وضع الدفعة (سواء للطالب أو للأدمن)
  final int defaultBatchNumber; // متغير لتخزين رقم الدفعة الافتراضي

  SystemSettingModel({ // مشيد الكلاس لتهيئة الإعدادات عند إنشاء كائن جديد
    required this.studentRegistrationEnabled, // جعل خاصية تفعيل التسجيل مطلوبة عند الإنشاء
    required this.batchMode, // جعل خاصية وضع الدفعة مطلوبة عند الإنشاء
    required this.defaultBatchNumber, // جعل خاصية رقم الدفعة الافتراضي مطلوبة عند الإنشاء
  }); // نهاية مشيد الكلاس

  factory SystemSettingModel.fromJson(Map<String, dynamic> json) { // دالة (مصنع) لإنشاء كائن من بيانات JSON مستلمة
    return SystemSettingModel( // إرجاع كائن جديد مهيأ بالبيانات المستلمة
      studentRegistrationEnabled: json['student_registration_enabled'] == true, // جلب حالة تفعيل التسجيل والتحقق من قيمتها
      batchMode: json['batch_mode'] ?? 'student', // جلب وضع الدفعة أو استخدام 'student' كقيمة افتراضية
      defaultBatchNumber: json['default_batch_number'] ?? 1, // جلب رقم الدفعة أو استخدام 1 كقيمة افتراضية
    ); // نهاية إنشاء الكائن من الـ JSON
  } // نهاية دالة fromJson

  Map<String, dynamic> toJson() { // دالة لتحويل كائن البيانات إلى خريطة (Map) لتسهيل تخزينه أو إرساله
    return { // بداية إرجاع هيكل الـ Map
      'student_registration_enabled': studentRegistrationEnabled, // ربط مفتاح تفعيل التسجيل بقيمته الحالية
      'batch_mode': batchMode, // ربط مفتاح وضع الدفعة بقيمته الحالية
      'default_batch_number': defaultBatchNumber, // ربط مفتاح رقم الدفعة بقيمته الحالية
    }; // نهاية هيكل الـ Map
  } // نهاية دالة toJson
} // نهاية تعريف الكلاس SystemSettingModel
