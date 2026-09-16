// / شرح عمل الملف:
// / هذا الملف يمثل "نموذج بيانات الإشعار" (NotificationModel).
// / وظيفته الأساسية هي تحديد هيكل وشكل البيانات الخاص بالإشعارات داخل التطبيق،
// / كما يوفر دوال (Methods) لتحويل هذه البيانات من وإلى صيغة JSON للتعامل
// / بسهولة مع قاعدة بيانات Supabase أو التخزين المحلي.

class NotificationModel {
  // المعرف الفريد للإشعار (Unique ID) المخزن في قاعدة البيانات
  final String id;
  
  // عنوان الإشعار الذي يظهر للمستخدم في الأعلى (مثال: تنبيه جديد)
  final String title;
  
  // نص أو محتوى الإشعار التفصيلي (مثال: تم إضافة حلقة جديدة)
  final String body;
  
  // الدور المستهدف الذي يجب أن يصله الإشعار (مثل: 'teacher', 'student', 'admin', 'all')
  final String targetRole; 
  
  // معرف الشخص أو النظام الذي قام بإرسال هذا الإشعار (اختياري)
  final String? senderId;
  
  // تاريخ ووقت إنشاء هذا الإشعار في النظام
  final DateTime createdAt;

  // رقم الدفعة المرتبط بالإشعار (اختياري)
  final int? batchNumber;

  // مُنشئ الكائن (Constructor) لإنشاء نسخة جديدة من النموذج ببيانات محددة
  NotificationModel({
    required this.id, // يتطلب معرف الإشعار
    required this.title, // يتطلب العنوان
    required this.body, // يتطلب نص الرسالة
    required this.targetRole, // يتطلب تحديد الفئة المستهدفة
    this.senderId, // معرف المرسل اختياري
    required this.createdAt, // يتطلب تاريخ الإنشاء
    this.batchNumber, // رقم الدفعة اختياري
  });

  /// دالة (Factory) تستخدم لتحويل البيانات القادمة من قاعدة البيانات (Map/JSON) إلى كائن برمجى (Object).
  /// [json]: خريطة البيانات القادمة من Supabase.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      // تحويل قيمة id إلى نص (String) لضمان عدم حدوث خطأ في الأنواع
      id: json['id'].toString(),
      
      // جلب العنوان من الـ JSON، وفي حال كان فارغاً نضع نصاً فارغاً
      title: json['title'] ?? '',
      
      // جلب نص الإشعار، وفي حال كان فارغاً نضع نصاً فارغاً
      body: json['body'] ?? '',
      
      // جلب الدور المستهدف، وإذا لم يوجد نفترض أنه موجه للجميع 'all'
      targetRole: json['target_role'] ?? 'all',
      
      // جلب معرف المرسل إذا كان موجوداً وتحويله لنص
      senderId: json['sender_id']?.toString(),
      
      // محاولة تحويل نص التاريخ القادم من قاعدة البيانات إلى كائن DateTime
      // في حال فشل التحويل أو كان فارغاً، نستخدم الوقت الحالي للجهاز كبديل
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      
      // جلب رقم الدفعة من الـ JSON
      batchNumber: json['batch_number'] != null ? int.tryParse(json['batch_number'].toString()) : null,
    );
  }

  /// دالة تقوم بتحويل الكائن البرمجي الحالي إلى خريطة بيانات (Map) بصيغة JSON.
  /// تُستخدم هذه الدالة عند الرغبة في حفظ الإشعار محلياً أو إرساله للخادم.
  Map<String, dynamic> toJson() {
    return {
      // تعيين عنوان الإشعار في حقل 'title'
      'title': title,
      
      // تعيين نص الإشعار في حقل 'body'
      'body': body,
      
      // تعيين الفئة المستهدفة في حقل 'target_role'
      'target_role': targetRole,
      
      // إضافة معرف المرسل للبيانات فقط إذا لم يكن فارغاً (لتوفير المساحة)
      if (senderId != null) 'sender_id': senderId,
      
      // تحويل كائن التاريخ إلى صيغة نصية معيارية (ISO8601) تفهمها قواعد البيانات
      'created_at': createdAt.toIso8601String(),
      
      // إضافة رقم الدفعة للبيانات
      'batch_number': batchNumber,
    };
  }
}
