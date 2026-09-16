// / شرح عمل الملف:
// / يحتوي هذا الملف على النماذج والأنواع المشتركة (Shared Models) المستخدمة في أجزاء مختلفة من التطبيق.
// / يهدف إلى توحيد تمثيل البيانات المتعلقة بالجنس (Gender) وبيانات المستخدمين في قائمة الدردشة (ChatUserModel).
//
// / تعريف أنواع الجنس (Gender) المستخدمة في التطبيق لتحديد فئة المستخدم أو الحلقة
enum Gender { 
  male,   // ذكر: للمستخدمين أو الحلقات الخاصة بالذكور
  female, // أنثى: للمستخدمين أو الحلقات الخاصة بالإناث
  all     // للكل: تستخدم أحياناً في عمليات الفلترة أو الإشعارات العامة التي تستهدف الجنسين
}

/// نموذج بيانات مستخدم الدردشة (ChatUserModel):
/// يمثل الهيكل الأساسي للبيانات التي تظهر في قائمة المحادثات، سواء كانت لمستخدم فردي أو لمجموعة حلقة.
class ChatUserModel {
  // المعرف الفريد للمستخدم أو للمجموعة (UUID من قاعدة البيانات)
  final String id;
  
  // الاسم المعروض (اسم الطالب، المعلم، أو اسم الحلقة)
  final String name;
  
  // دور المستخدم في النظام (مثل: 'student', 'teacher', 'admin', 'coordinator') 
  // أو نوع المحادثة (مثل: 'circle_group' للمجموعات)
  final String role; 
  
  // تحديد جنس المستخدم أو فئة الحلقة (ذكر أو أنثى)
  final Gender gender;
  
  // محتوى نص آخر رسالة تم إرسالها أو استقبالها في هذه المحادثة لعرضها في القائمة
  final String? lastMessage;
  
  // التاريخ والوقت الذي حدث فيه آخر تفاعل في المحادثة (لترتيب القائمة من الأحدث)
  final DateTime? updatedAt;
  
  // عدد الرسائل الجديدة التي لم يقم المستخدم الحالي بقراءتها بعد في هذه المحادثة
  final int unreadCount;
  
  // الرابط المباشر للصورة الشخصية (Avatar) للمستخدم أو أيقونة المجموعة
  final String? avatarUrl;

  // رقم الدفعة للمستخدم (للفلترة)
  final int? batchNumber;

  // رقم الهاتف للمستخدم (للتواصل عبر الواتساب)
  final String? phone;

  // مُنشئ الكائن (Constructor) لتهيئة البيانات عند إنشاء نسخة جديدة من النموذج
  ChatUserModel({
    required this.id,         // معرف المستخدم (إلزامي)
    required this.name,       // اسم المستخدم (إلزامي)
    required this.role,       // دور المستخدم (إلزامي)
    this.gender = Gender.male, // الجنس (افتراضياً ذكر إذا لم يحدد)
    this.lastMessage,          // نص آخر رسالة (اختياري)
    this.updatedAt,            // وقت آخر تحديث (اختياري)
    this.unreadCount = 0,      // عداد غير المقروء (يبدأ بصفر افتراضياً)
    this.avatarUrl,            // رابط الصورة (اختياري)
    this.batchNumber,          // رقم الدفعة (اختياري)
    this.phone,                // رقم الهاتف (اختياري)
  });

  /// دالة لنسخ الكائن مع تعديل بعض الحقول (بقاء الحقول الأخرى كما هي)
  ChatUserModel copyWith({
    String? id,
    String? name,
    String? role,
    Gender? gender,
    String? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
    String? avatarUrl,
    int? batchNumber,
    String? phone,
  }) {
    return ChatUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      batchNumber: batchNumber ?? this.batchNumber,
      phone: phone ?? this.phone,
    );
  }

  /// تحويل البيانات من JSON إلى كائن برمجي
  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id']?.toString() ?? '',
      name: json['full_name'] ?? json['name'] ?? '',
      role: json['role'] ?? '',
      gender: json['gender'] == 'female' ? Gender.female : Gender.male,
      lastMessage: json['lastMessage'],
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      unreadCount: json['unreadCount'] ?? 0,
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      batchNumber: json['batch_number'] ?? json['batchNumber'],
      phone: json['phone']?.toString() ?? json['phone_number']?.toString() ?? json['phoneNumber']?.toString(),
    );
  }

  /// تحويل الكائن إلى JSON لحفظه محلياً
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'gender': gender == Gender.female ? 'female' : 'male',
      'lastMessage': lastMessage,
      'updatedAt': updatedAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'avatarUrl': avatarUrl,
      'batch_number': batchNumber,
      'phone': phone,
    };
  }
}
