import '../../core/models/shared_models.dart'; // استيراد النماذج المشتركة من المجلد الأساسي
import '../../core/utils/quran_categories.dart'; // استيراد ثوابت وتوحيد فئات الحفظ
export '../../core/models/shared_models.dart'; // تصدير النماذج المشتركة لتوفير الوصول إليها

/// نموذج بيانات المعلم (TeacherModel)
class TeacherModel { // تعريف كلاس بيانات المعلم
  final String id; // المعرف الفريد للمعلم
  final String name; // اسم المعلم الكامل
  final String email; // البريد الإلكتروني للمعلم
  final String academicNumber; // الرقم الأكاديمي للمعلم
  final String privateCode; // كود الدخول الخاص بالمعلم
  final String specialization; // تخصص المعلم (حفظ/تجويد)
  final String date; // تاريخ الانضمام للنظام
  final Gender gender; // جنس المعلم (ذكر/أنثى)
  final bool canCoverBalance; // هل يمكنه تغطية الرصيد
  final String status; // حالة الحساب (مقبول/معلق)
  final String phone; // رقم هاتف المعلم
  final int? age; // عمر المعلم (اختياري)
  final String? academicQualification; // المؤهل الأكاديمي
  final String? eligibilityProof; // إثبات الأهلية أو الشهادات
  final String? pledgeFileUrl; // رابط ملف التعهد
  final double? sponsorshipAmount; // مبلغ الكفالة
  final String? packageType; // نوع الباقة المشترك بها
  final int? batchNumber; // رقم الدفعة المرتبط بها

  /// مشيد الكلاس لتهيئة الحقول
  TeacherModel({ // مشيد الكلاس لتهيئة الحقول
    required this.id, // المعرف مطلوب
    required this.name, // الاسم مطلوب
    required this.email, // البريد مطلوب
    required this.academicNumber, // الرقم الأكاديمي مطلوب
    required this.privateCode, // الكود مطلوب
    required this.specialization, // التخصص مطلوب
    required this.date, // التاريخ مطلوب
    required this.gender, // الجنس مطلوب
    required this.canCoverBalance, // تغطية الرصيد مطلوبة
    required this.status, // الحالة مطلوبة
    required this.phone, // الهاتف مطلوب
    this.age, // العمر اختياري
    this.academicQualification, // المؤهل اختياري
    this.eligibilityProof, // الإثبات اختياري
    this.pledgeFileUrl, // رابط التعهد اختياري
    this.sponsorshipAmount, // مبلغ الكفالة اختياري
    this.packageType, // نوع الباقة اختياري
    this.batchNumber, // رقم الدفعة اختياري
  }); // نهاية المشيد

  /// دالة إنشاء كائن من بيانات JSON
  factory TeacherModel.fromJson(Map<String, dynamic> json) { // إنشاء كائن من بيانات JSON
    return TeacherModel( // إرجاع كائن المعلم
      id: json['id']?.toString() ?? '', // استخراج المعرف
      name: json['full_name'] ?? json['name'] ?? 'بدون اسم', // استخراج الاسم
      email: json['email'] ?? '', // استخراج البريد
      phone: json['phone'] ?? json['phone_number'] ?? '', // استخراج الهاتف
      academicNumber: json['academic_number'] ?? '', // استخراج الرقم الأكاديمي
      privateCode: json['private_code'] ?? '', // استخراج الكود
      specialization: json['specialization'] ?? '', // استخراج التخصص
      date: json['joined_at'] ?? json['created_at'] ?? json['date'] ?? '', // استخراج التاريخ
      gender: json['gender'] == 'female' ? Gender.female : Gender.male, // استخراج الجنس
      canCoverBalance: json['can_cover_balance'] ?? true, // استخراج تغطية الرصيد
      status: json['status'] ?? 'accepted', // استخراج الحالة
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null, // تحويل العمر لرقم
      academicQualification: json['academic_qualification'], // استخراج المؤهل
      eligibilityProof: json['eligibility_proof'], // استخراج إثبات الأهلية
      pledgeFileUrl: json['pledge_file_url'], // استخراج رابط التعهد
      sponsorshipAmount: json['sponsorship_amount'] != null // استخراج مبلغ الكفالة
          ? double.tryParse(json['sponsorship_amount'].toString()) // تحويل المبلغ لرقم عشري
          : null, // تعيين null إذا لم يوجد
      packageType: json['package_type']?.toString(), // استخراج نوع الباقة
      batchNumber: json['batch_number'] != null ? int.tryParse(json['batch_number'].toString()) : null, // استخراج رقم الدفعة
    ); // نهاية كائن المعلم
  } // نهاية دالة fromJson

  /// تحويل الكائن لبيانات JSON
  Map<String, dynamic> toJson() { // تحويل الكائن لبيانات JSON
    return { // إرجاع خريطة البيانات
      'id': id, // المعرف
      'name': name, // الاسم
      'email': email, // البريد
      'phone': phone, // الهاتف
      'academic_number': academicNumber, // الرقم الأكاديمي
      'private_code': privateCode, // الكود
      'specialization': specialization, // التخصص
      'date': date, // التاريخ
      'gender': gender == Gender.female ? 'female' : 'male', // الجنس
      'can_cover_balance': canCoverBalance, // تغطية الرصيد
      'status': status, // الحالة
      'age': age, // العمر
      'academic_qualification': academicQualification, // المؤهل
      'eligibility_proof': eligibilityProof, // الإثبات
      'pledge_file_url': pledgeFileUrl, // رابط التعهد
      'sponsorship_amount': sponsorshipAmount, // مبلغ الكفالة
      'package_type': packageType, // نوع الباقة
      'batch_number': batchNumber, // رقم الدفعة
    }; // نهاية الخريطة
  } // نهاية دالة toJson
} // نهاية كلاس TeacherModel

/// نموذج بيانات الطالب (StudentModel)
class StudentModel { // تعريف كلاس بيانات الطالب
  final String id; // المعرف الفريد للطالب
  final String name; // اسم الطالب الكامل
  final String email; // البريد الإلكتروني للطالب
  final String academicNumber; // الرقم الأكاديمي للطالب
  final String privateCode; // كود الدخول الخاص بالطالب
  final String level; // مستوى الحفظ للطالب
  final String date; // تاريخ التسجيل في النظام
  final Gender gender; // جنس الطالب (ذكر/أنثى)
  final bool isDistributed; // هل تم توزيعه على حلقة
  final String status; // حالة الحساب (مقبول/معلق)
  final String phone; // رقم هاتف الطالب
  final int? age; // عمر الطالب
  final String? academicQualification; // المؤهل الأكاديمي
  final String? pledgeFileUrl; // رابط ملف التعهد
  final String? circleName; // اسم الحلقة المنضم إليها
  final int? batchNumber; // رقم الدفعة المرتبط بها
  final bool isSupervisor; // هل الطالب مشرف/متابع على الحلقة
  final String? circleId; // معرف الحلقة
  final String? avatarUrl; // رابط الصورة الشخصية

  /// مشيد كائن الطالب
  StudentModel({ // مشيد الكلاس لتهيئة الحقول
    required this.id, // المعرف مطلوب
    required this.name, // الاسم مطلوب
    required this.email, // البريد مطلوب
    required this.academicNumber, // الرقم الأكاديمي مطلوب
    required this.privateCode, // الكود مطلوب
    required this.level, // المستوى مطلوب
    required this.date, // التاريخ مطلوب
    required this.gender, // الجنس مطلوب
    required this.isDistributed, // حالة التوزيع مطلوبة
    required this.status, // الحالة مطلوبة
    required this.phone, // الهاتف مطلوب
    this.age, // العمر اختياري
    this.academicQualification, // المؤهل اختياري
    this.pledgeFileUrl, // رابط التعهد اختياري
    required this.circleName, // اسم الحلقة مطلوب
    this.batchNumber, // رقم الدفعة اختياري
    this.isSupervisor = false, // الحالة الافتراضية
    this.circleId, // معرف الحلقة اختياري
    this.avatarUrl, // رابط الصورة اختياري
  }); // نهاية المشيد

  /// تحويل بيانات JSON لكائن طالب
  factory StudentModel.fromJson(Map<String, dynamic> json) { // إنشاء كائن من بيانات JSON
    return StudentModel( // إرجاع كائن الطالب
      id: json['id']?.toString() ?? '', // استخراج المعرف
      name: json['full_name'] ?? json['name'] ?? 'بدون اسم', // استخراج الاسم
      email: json['email'] ?? '', // استخراج البريد
      phone: json['phone'] ?? json['phone_number'] ?? '', // استخراج الهاتف
      academicNumber: json['academic_number'] ?? '', // استخراج الرقم الأكاديمي
      privateCode: json['private_code'] ?? '', // استخراج الكود
      level: normalizeCategory(json['hifz_level'] ?? json['level'] ?? ''), // استخراج المستوى مع توحيد الصيغة
      date: json['joined_at'] ?? json['created_at'] ?? json['date'] ?? '', // استخراج التاريخ
      gender: json['gender'] == 'female' ? Gender.female : Gender.male, // استخراج الجنس
      isDistributed: json['is_distributed'] ?? json['isDistributed'] ?? false, // استخراج حالة التوزيع
      status: json['status'] ?? 'accepted', // استخراج الحالة
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null, // تحويل العمر لرقم
      academicQualification: json['academic_qualification'], // استخراج المؤهل
      pledgeFileUrl: json['pledge_file_url'], // استخراج رابط التعهد
      circleName: json['circle_name'], // استخراج اسم الحلقة
      batchNumber: json['batch_number'] != null ? int.tryParse(json['batch_number'].toString()) : null, // استخراج رقم الدفعة
      isSupervisor: json['is_supervisor'] == true || json['isSupervisor'] == true || json['is_circle_supervisor'] == true, // استخراج حالة الإشراف
      circleId: json['circle_id']?.toString(), // استخراج معرف الحلقة
      avatarUrl: json['avatar_url']?.toString(), // استخراج رابط الصورة الشخصية
    ); // نهاية كائن الطالب
  } // نهاية دالة fromJson

  /// تحويل الكائن لبيانات JSON
  Map<String, dynamic> toJson() { // تحويل الكائن لبيانات JSON
    return { // إرجاع خريطة البيانات
      'id': id, // المعرف
      'name': name, // الاسم
      'email': email, // البريد
      'phone': phone, // الهاتف
      'academic_number': academicNumber, // الرقم الأكاديمي
      'private_code': privateCode, // الكود
      'level': level, // المستوى
      'date': date, // التاريخ
      'gender': gender == Gender.female ? 'female' : 'male', // الجنس
      'is_distributed': isDistributed, // حالة التوزيع
      'status': status, // الحالة
      'age': age, // العمر
      'academic_qualification': academicQualification, // المؤهل
      'pledge_file_url': pledgeFileUrl, // رابط التعهد
      'circle_name': circleName, // اسم الحلقة
      'batch_number': batchNumber, // رقم الدفعة
      'is_supervisor': isSupervisor, // حالة الإشراف
      'circle_id': circleId, // معرف الحلقة
      'avatar_url': avatarUrl, // رابط الصورة الشخصية
    }; // نهاية الخريطة
  } // نهاية دالة toJson

  /// نسخ كائن الطالب مع إمكانية تعديل حقول معينة
  StudentModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? academicNumber,
    String? privateCode,
    String? level,
    String? date,
    Gender? gender,
    bool? isDistributed,
    String? status,
    int? age,
    String? academicQualification,
    String? pledgeFileUrl,
    String? circleName,
    int? batchNumber,
    bool? isSupervisor,
    String? circleId,
    String? avatarUrl,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      academicNumber: academicNumber ?? this.academicNumber,
      privateCode: privateCode ?? this.privateCode,
      level: level ?? this.level,
      date: date ?? this.date,
      gender: gender ?? this.gender,
      isDistributed: isDistributed ?? this.isDistributed,
      status: status ?? this.status,
      age: age ?? this.age,
      academicQualification: academicQualification ?? this.academicQualification,
      pledgeFileUrl: pledgeFileUrl ?? this.pledgeFileUrl,
      circleName: circleName ?? this.circleName,
      batchNumber: batchNumber ?? this.batchNumber,
      isSupervisor: isSupervisor ?? this.isSupervisor,
      circleId: circleId ?? this.circleId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
} // نهاية كلاس StudentModel

/// نموذج بيانات حلقة القرآن (QuranCircleModel)
class QuranCircleModel { // تعريف كلاس بيانات حلقة القرآن
  final String id; // معرف الحلقة الفريد
  final String name; // اسم الحلقة
  final List<String> teacherIds; // قائمة معرفات المعلمين
  final List<String> teacherNames; // قائمة أسماء المعلمين
  final Gender gender; // جنس الحلقة (بنين/بنات)
  final List<String> studentIds; // قائمة معرفات الطلاب
  final List<String> studentNames; // قائمة أسماء الطلاب
  final DateTime createdAt; // تاريخ إنشاء الحلقة
  final String? examinerId; // معرف المختبر المعين
  final String? examinerName; // اسم المختبر المعين
  final int? batchNumber; // رقم الدفعة المرتبط
  final String? backgroundUrl; // رابط خلفية الحلقة

  /// مشيد كائن حلقة القرآن
  QuranCircleModel({ // مشيد الكلاس لتهيئة الحقول
    required this.id, // المعرف مطلوب
    required this.name, // الاسم مطلوب
    required this.teacherIds, // معرفات المعلمين مطلوبة
    required this.teacherNames, // أسماء المعلمين مطلوبة
    required this.gender, // الجنس مطلوب
    required this.studentIds, // معرفات الطلاب مطلوبة
    required this.studentNames, // أسماء الطلاب مطلوبة
    required this.createdAt, // تاريخ الإنشاء مطلوب
    this.examinerId, // معرف المختبر اختياري
    this.examinerName, // اسم المختبر اختياري
    this.batchNumber, // رقم الدفعة اختياري
    this.backgroundUrl, // خلفية الحلقة اختيارية
  }); // نهاية المشيد

  /// الحصول على اسم المعلمين مدمجين
  String get teacherName => // الحصول على اسم المعلم المدمج
      teacherNames.isNotEmpty ? teacherNames.join(' & ') : ''; // دمج الأسماء بفاصل
  /// الحصول على معرف المعلم الأساسي
  String get teacherId => teacherIds.isNotEmpty ? teacherIds.first : ''; // الحصول على المعلم الأول

  /// عدد الطلاب في الحلقة
  int get studentCount => studentIds.length; // الحصول على عدد الطلاب

  /// تحويل بيانات JSON لكائن حلقة
  factory QuranCircleModel.fromJson(Map<String, dynamic> json) { // إنشاء كائن من بيانات JSON
    final teachersList = json['teachers'] as List? ?? []; // استخراج قائمة المعلمين
    List<String> tIds = []; // قائمة معرفات مؤقتة
    List<String> tNames = []; // قائمة أسماء مؤقتة

    if (teachersList.isNotEmpty) { // التحقق من وجود قائمة معلمين
      for (var t in teachersList) { // المرور على كل معلم
        if (t is Map<String, dynamic>) { // إذا كانت البيانات خريطة
          tIds.add(t['id']?.toString() ?? ''); // إضافة المعرف
          tNames.add(t['full_name'] ?? t['name'] ?? ''); // إضافة الاسم
        } // نهاية التحقق من الخريطة
      } // نهاية المرور على المعلمين
    } else { // في حالة عدم وجود القائمة، استخدام الحقول الفردية
      if (json['teacher_id'] != null) { // التحقق من وجود معرف معلم
        tIds.add(json['teacher_id'].toString()); // إضافة المعرف
        tNames.add(json['teacher']?['full_name'] ?? json['teacher_name'] ?? ''); // إضافة الاسم
      } // نهاية التحقق من المعرف الفردي
    } // نهاية معالجة المعلمين

    final teacherGender = // تحديد جنس الحلقة
        json['gender'] == 'female' || json['teacher']?['gender'] == 'female' 
        ? Gender.female 
        : Gender.male; // افتراض بنين إذا لم يحدد

    final membersList = json['students'] as List? ?? []; // استخراج قائمة الطلاب
    final studentIds = membersList // تحويل القائمة لمعرفات الطلاب
        .map(
          (m) => (m is Map<String, dynamic> ? m['student_id'] : m)?.toString(), 
        ) // نهاية التحويل
        .whereType<String>() // استبقاء النصوص فقط
        .toList(); // تحويل لقائمة

    final studentNames = membersList // تحويل القائمة لأسماء الطلاب
        .map(
          (m) =>
              (m is Map<String, dynamic>
                      ? (m['student']?['full_name'] ?? m['student_name'] ?? '') 
                      : '')
                  .toString(),
        ) // نهاية التحويل
        .where((name) => name.isNotEmpty) // استبقاء الأسماء غير الفارغة
        .toList(); // تحويل لقائمة

    return QuranCircleModel( // إنشاء كائن الحلقة
      id: json['id']?.toString() ?? '', // استخراج المعرف
      name: json['name'] ?? '', // استخراج الاسم
      teacherIds: tIds, // تعيين معرفات المعلمين
      teacherNames: tNames, // تعيين أسماء المعلمين
      gender: teacherGender, // تعيين الجنس
      studentIds: studentIds, // تعيين معرفات الطلاب
      studentNames: studentNames, // تعيين أسماء الطلاب
      createdAt: DateTime.parse( // تحليل تاريخ الإنشاء
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ), // نهاية التاريخ
      examinerId: json['examiner_id']?.toString(), // استخراج معرف المختبر
      examinerName: json['examiner']?['full_name'] ?? json['examiner_name'], // استخراج اسم المختبر
      batchNumber: json['batch_number'] != null ? int.tryParse(json['batch_number'].toString()) : null, // استخراج رقم الدفعة
    ); // نهاية كائن الحلقة
  } // نهاية دالة fromJson

  /// تحويل كائن الحلقة لبيانات JSON
  Map<String, dynamic> toJson() { // تحويل كائن الحلقة لبيانات JSON
    return { // إرجاع خريطة البيانات
      'id': id, // المعرف
      'name': name, // الاسم
      'teacher_ids': teacherIds, // معرفات المعلمين
      'teacher_names': teacherNames, // أسماء المعلمين
      'gender': gender == Gender.female ? 'female' : 'male', // الجنس
      'student_ids': studentIds, // معرفات الطلاب
      'student_names': studentNames, // أسماء الطلاب
      'created_at': createdAt.toIso8601String(), // تاريخ الإنشاء
      'examiner_id': examinerId, // معرف المختبر
      'examiner_name': examinerName, // اسم المختبر
    }; // نهاية الخريطة
  } // نهاية دالة toJson
} // نهاية كلاس QuranCircleModel

/// نموذج بيانات مستخدم الإدارة (AdminUserModel)
class AdminUserModel { // تعريف كلاس بيانات مستخدم الإدارة
  final String id; // المعرف الفريد للمستخدم
  final String name; // اسم المستخدم الكامل
  final String email; // البريد الإلكتروني
  final String role; // دور المستخدم (مدير/منسق)
  final DateTime joinedAt; // تاريخ الانضمام للنظام

  /// مشيد كائن مستخدم الإدارة
  AdminUserModel({ // مشيد كلاس مستخدم الإدارة
    required this.id, // المعرف مطلوب
    required this.name, // الاسم مطلوب
    required this.email, // البريد مطلوب
    required this.role, // الدور مطلوب
    required this.joinedAt, // التاريخ مطلوب
  }); // نهاية المشيد

  /// تحويل بيانات JSON لمستخدم إدارة
  factory AdminUserModel.fromJson(Map<String, dynamic> json) { // إنشاء كائن من بيانات JSON
    return AdminUserModel( // إرجاع كائن المستخدم
      id: json['id']?.toString() ?? '', // استخراج المعرف
      name: json['full_name'] ?? json['name'] ?? 'بدون اسم', // استخراج الاسم
      email: json['email'] ?? '', // استخراج البريد
      role: json['role'] ?? 'admin', // استخراج الدور
      joinedAt: DateTime.parse( // تحليل تاريخ الانضمام
        json['joined_at'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      ), // نهاية التاريخ
    ); // نهاية كائن المستخدم
  } // نهاية دالة fromJson

  /// تحويل كائن المستخدم لبيانات JSON
  Map<String, dynamic> toJson() { // تحويل المستخدم لبيانات JSON
    return { // إرجاع خريطة البيانات
      'id': id, // المعرف
      'full_name': name, // الاسم الكامل
      'email': email, // البريد
      'role': role, // الدور
      'created_at': joinedAt.toIso8601String(), // تاريخ الإنشاء
    }; // نهاية الخريطة
  } // نهاية دالة toJson
} // نهاية كلاس AdminUserModel

/// نموذج بيانات المحادثة (ChatModel)
class ChatModel { // تعريف كلاس بيانات المحادثة
  final String id; // معرف المحادثة الفريد
  final String userId; // معرف الطرف الآخر في المحادثة
  final String userName; // اسم الطرف الآخر
  final String? userAvatar; // رابط صورة الطرف الآخر
  final String lastMessage; // نص آخر رسالة مرسلة
  final DateTime updatedAt; // تاريخ آخر تحديث للمحادثة
  final String type; // نوع المحادثة (خاصة/مجموعة)
  final String userRole; // دور الطرف الآخر (طالب/معلم)
  final String lastSenderId; // معرف مرسل آخر رسالة
  final Gender gender; // جنس الطرف الآخر
  final int unreadCount; // عدد الرسائل غير المقروءة
  final int? batchNumber; // حقل رقم الدفعة المضاف حديثاً للفلترة

  /// مشيد كائن المحادثة
  ChatModel({ // مشيد كلاس المحادثة
    required this.id, // المعرف مطلوب
    required this.userId, // معرف المستخدم مطلوب
    required this.userName, // الاسم مطلوب
    this.userAvatar, // الصورة اختياري
    required this.lastMessage, // آخر رسالة مطلوبة
    required this.updatedAt, // التاريخ مطلوب
    required this.type, // النوع مطلوب
    required this.userRole, // الدور مطلوب
    required this.lastSenderId, // معرف المرسل مطلوب
    this.gender = Gender.male, // الجنس افتراضياً ذكر
    this.unreadCount = 0, // العداد يبدأ بصفر
    this.batchNumber, // رقم الدفعة اختياري
  }); // نهاية المشيد

  /// تحويل المحادثة لخريطة بيانات
  Map<String, dynamic> toMap() { // تحويل المحادثة إلى خريطة بيانات
    return { // إرجاع خريطة البيانات
      'id': id, // المعرف
      'user_id': userId, // معرف المستخدم
      'user_name': userName, // اسم المستخدم
      'user_avatar': userAvatar, // صورة المستخدم
      'last_message': lastMessage, // آخر رسالة
      'last_sender_id': lastSenderId, // مرسل آخر رسالة
      'updated_at': updatedAt.toIso8601String(), // تاريخ التحديث
      'type': type, // النوع
      'user_role': userRole, // دور المستخدم
      'gender': gender == Gender.female ? 'female' : 'male', // الجنس
      'unread_count': unreadCount, // عدد غير المقروء
      'batch_number': batchNumber, // رقم الدفعة
    }; // نهاية الخريطة
  } // نهاية دالة toMap

  /// تحويل بيانات JSON لمحادثة
  factory ChatModel.fromJson(Map<String, dynamic> json) { // إنشاء كائن من بيانات JSON
    return ChatModel( // إرجاع كائن المحادثة
      id: json['id']?.toString() ?? '', // استخراج المعرف
      userId: (json['user_id'] ?? json['student_id'] ?? json['teacher_id'] ?? '').toString(), // استخراج معرف المستخدم
      userName: json['user_name'] ?? 'Unknown User', // استخراج الاسم
      userAvatar: json['user_avatar'] ?? json['avatar_url'], // استخراج الصورة
      lastMessage: json['last_message'] ?? '', // استخراج آخر رسالة
      lastSenderId: json['last_sender_id']?.toString() ?? '', // استخراج مرسل آخر رسالة
      updatedAt: DateTime.parse( // تحليل تاريخ التحديث
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ), // نهاية التاريخ
      type: json['type'] ?? 'chat', // استخراج النوع
      userRole: json['user_role'] ?? 'student', // استخراج الدور
      gender: json['gender'] == 'female' ? Gender.female : Gender.male, // استخراج الجنس
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0, // تحليل عدد غير المقروء
      batchNumber: json['batch_number'] != null ? int.tryParse(json['batch_number'].toString()) : null, // استخراج رقم الدفعة
    ); // نهاية كائن المحادثة
  } // نهاية دالة fromJson

  /// نسخ المحادثة مع تعديلات
  ChatModel copyWith({ // دالة لنسخ المحادثة مع تعديلات
    String? id, // المعرف الجديد
    String? userId, // معرف المستخدم الجديد
    String? userName, // الاسم الجديد
    String? userAvatar, // الصورة الجديدة
    String? lastMessage, // آخر رسالة جديدة
    DateTime? updatedAt, // تاريخ تحديث جديد
    String? type, // نوع جديد
    String? userRole, // دور جديد
    String? lastSenderId, // معرف مرسل جديد
    Gender? gender, // جنس جديد
    int? unreadCount, // عداد جديد
    int? batchNumber, // رقم دفعة جديد
  }) { // بداية دالة النسخ
    return ChatModel( // إرجاع نسخة جديدة
      id: id ?? this.id, // استخدام القيمة الجديدة أو الحالية
      userId: userId ?? this.userId, // استخدام القيمة الجديدة أو الحالية
      userName: userName ?? this.userName, // استخدام القيمة الجديدة أو الحالية
      userAvatar: userAvatar ?? this.userAvatar, // استخدام القيمة الجديدة أو الحالية
      lastMessage: lastMessage ?? this.lastMessage, // استخدام القيمة الجديدة أو الحالية
      updatedAt: updatedAt ?? this.updatedAt, // استخدام القيمة الجديدة أو الحالية
      type: type ?? this.type, // استخدام القيمة الجديدة أو الحالية
      userRole: userRole ?? this.userRole, // استخدام القيمة الجديدة أو الحالية
      lastSenderId: lastSenderId ?? this.lastSenderId, // استخدام القيمة الجديدة أو الحالية
      gender: gender ?? this.gender, // استخدام القيمة الجديدة أو الحالية
      unreadCount: unreadCount ?? this.unreadCount, // استخدام القيمة الجديدة أو الحالية
      batchNumber: batchNumber ?? this.batchNumber, // استخدام القيمة الجديدة أو الحالية
    ); // نهاية النسخة الجديدة
  } // نهاية دالة copyWith
} // نهاية كلاس ChatModel

/// نموذج بيانات الرسالة (MessageModel)
class MessageModel { // تعريف كلاس بيانات الرسالة
  final String id; // معرف الرسالة الفريد
  final String chatID; // معرف المحادثة التابعة لها
  final String senderId; // معرف مرسل الرسالة
  final String text; // نص الرسالة النصية
  final String? audioUrl; // رابط الملف الصوتي
  final int? audioDuration; // مدة الملف الصوتي بالثواني
  final String? imageUrl; // رابط الصورة المرفقة
  final String? videoUrl; // رابط الفيديو المرفق
  final String? fileUrl; // رابط الملف المرفق
  final bool isEdited; // هل تم تعديل الرسالة سابقاً
  final bool isDeleted; // هل تم حذف محتوى الرسالة
  final DateTime createdAt; // تاريخ ووقت إرسال الرسالة
  final String? senderName; // اسم مرسل الرسالة
  final int helpCount; // عدد طلبات المساعدة للذكاء الاصطناعي
  final DateTime? readAt; // تاريخ ووقت قراءة الرسالة
  final String? receiverId; // معرف مستلم الرسالة (خاص)
  final bool isPending; // هل الرسالة قيد الإرسال حالياً
  final String? localAudioPath; // المسار المحلي لملف الصوت
  final String? localImagePath; // المسار المحلي لملف الصورة
  final String? localVideoPath; // المسار المحلي لملف الفيديو
  final String? localFilePath; // المسار المحلي للملف المرفق
  final String? chatType; // نوع المحادثة (فردية/مجموعة)

  /// مشيد كائن الرسالة
  MessageModel({ // مشيد كلاس الرسالة لتهيئة الحقول
    required this.id, // المعرف مطلوب
    required this.chatID, // معرف المحادثة مطلوب
    required this.senderId, // معرف المرسل مطلوب
    required this.text, // النص مطلوب
    this.audioUrl, // رابط الصوت اختياري
    this.audioDuration, // مدة الصوت اختياري
    this.imageUrl, // رابط الصورة اختياري
    this.videoUrl, // رابط الفيديو اختياري
    this.fileUrl, // رابط الملف اختياري
    this.isEdited = false, // القيمة الافتراضية كاذبة
    this.isDeleted = false, // القيمة الافتراضية كاذبة
    required this.createdAt, // التاريخ مطلوب
    this.senderName, // الاسم اختياري
    this.helpCount = 0, // العداد يبدأ بصفر
    this.readAt, // تاريخ القراءة اختياري
    this.receiverId, // معرف مستلم اختياري
    this.isPending = false, // الحالة الافتراضية ليست قيد الانتظار
    this.localAudioPath, // المسار المحلي اختياري
    this.localImagePath, // المسار المحلي اختياري
    this.localVideoPath, // المسار المحلي اختياري
    this.localFilePath, // المسار المحلي اختياري
    this.chatType, // النوع اختياري
  }); // نهاية المشيد

  /// تحويل بيانات JSON لرسالة
  factory MessageModel.fromJson(Map<String, dynamic> json) { // إنشاء كائن من بيانات JSON
    final senderData = json['sender']; // استخراج بيانات المرسل
    Map<String, dynamic>? senderMap; // خريطة بيانات المرسل
    
    if (senderData is Map) { // إذا كانت البيانات خريطة مباشرة
      senderMap = Map<String, dynamic>.from(senderData); // تحويلها لخريطة
    } else if (senderData is List && senderData.isNotEmpty) { // إذا كانت قائمة من كائن واحد
      senderMap = Map<String, dynamic>.from(senderData.first); // أخذ العنصر الأول
    } // نهاية معالجة بيانات المرسل

    return MessageModel( // إرجاع كائن الرسالة الجديد
      id: json['id']?.toString() ?? '', // استخراج المعرف
      chatID: json['chat_id']?.toString() ?? '', // استخراج معرف المحادثة
      senderId: json['sender_id']?.toString() ?? '', // استخراج معرف المرسل
      text: json['text'] ?? '', // استخراج النص
      audioUrl: json['audio_url'], // استخراج رابط الصوت
      audioDuration: json['audio_duration'], // استخراج مدة الصوت
      imageUrl: json['image_url'], // استخراج رابط الصورة
      videoUrl: json['video_url'], // استخراج رابط الفيديو
      fileUrl: json['file_url'], // استخراج رابط الملف
      isEdited: json['is_edited'] ?? false, // استخراج حالة التعديل
      isDeleted: json['is_deleted'] ?? false, // استخراج حالة الحذف
      createdAt: DateTime.parse( // تحليل تاريخ الإنشاء
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ), // نهاية التاريخ
      senderName: senderMap?['full_name'] ?? senderMap?['name'], // استخراج اسم المرسل
      helpCount: json['help_count'] ?? 0, // استخراج عداد المساعدة
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null, // تحليل تاريخ القراءة
      receiverId: json['receiver_id']?.toString(), // استخراج معرف مستلم الرسالة
      chatType: json['chat_type'], // استخراج نوع المحادثة
    ); // نهاية كائن الرسالة
  } // نهاية دالة fromJson

  /// إنشاء رسالة معلقة من خريطة بيانات
  factory MessageModel.fromPendingMap(Map<String, dynamic> map) { // إنشاء رسالة معلقة من خريطة بيانات
    return MessageModel( // إرجاع كائن الرسالة
      id: "pending_${map['id']}", // تعيين معرف مؤقت
      chatID: map['chat_id'], // معرف المحادثة
      senderId: map['sender_id'], // معرف المرسل
      text: map['text'], // النص
      createdAt: DateTime.parse(map['created_at']), // وقت الإنشاء
      isPending: true, // تفعيل حالة الانتظار
      localAudioPath: map['local_audio_path'], // مسار الصوت المحلي
      audioDuration: map['audio_duration'], // مدة الصوت
      localImagePath: map['local_image_path'], // مسار الصورة المحلية
      localVideoPath: map['local_video_path'], // مسار الفيديو المحلي
      localFilePath: map['local_file_path'], // مسار الملف المحلي
      fileUrl: map['file_url'], // رابط الملف
      helpCount: map['help_count'] ?? 0, // عداد المساعدة
      chatType: map['chat_type'], // نوع المحادثة
      receiverId: map['receiver_id'], // معرف المستلم
    ); // نهاية كائن الرسالة المعلقة
  } // نهاية دالة fromPendingMap

  /// تحويل كائن الرسالة لخريطة بيانات متوافقة مع جدول pending_messages
  Map<String, dynamic> toPendingMap() {
    return {
      'chat_id': chatID,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      'local_audio_path': localAudioPath,
      'local_image_path': localImagePath,
      'local_video_path': localVideoPath,
      'local_file_path': localFilePath,
      'file_url': fileUrl,
      'chat_type': chatType,
      'audio_duration': audioDuration,
      'help_count': helpCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// تحويل كائن الرسالة لخريطة بيانات
  Map<String, dynamic> toMap() { // تحويل كائن الرسالة لخريطة بيانات
    return { // إرجاع خريطة البيانات
      'id': id, // المعرف
      'chat_id': chatID, // معرف المحادثة
      'sender_id': senderId, // معرف المرسل
      'text': text, // النص
      'audio_url': audioUrl, // رابط الصوت
      'audio_duration': audioDuration, // مدة الصوت
      'image_url': imageUrl, // رابط الصورة
      'video_url': videoUrl, // رابط الفيديو
      'file_url': fileUrl, // رابط الملف
      'local_audio_path': localAudioPath, // المسار المحلي للصوت
      'local_image_path': localImagePath, // المسار المحلي للصورة
      'local_video_path': localVideoPath, // المسار المحلي للفيديو
      'local_file_path': localFilePath, // المسار المحلي للملف
      'is_edited': isEdited, // هل عدلت
      'is_deleted': isDeleted, // هل حذفت
      'created_at': createdAt.toIso8601String(), // تاريخ الإرسال
      'sender_name': senderName, // اسم المرسل
      'help_count': helpCount, // عداد المساعدة
      'read_at': readAt?.toIso8601String(), // تاريخ القراءة
      'receiver_id': receiverId, // معرف المستلم
      'chat_type': chatType, // نوع المحادثة
    }; // نهاية الخريطة
  } // نهاية دالة toMap

  /// نسخ الرسالة مع تعديل حقول محددة
  MessageModel copyWith({ // دالة لنسخ الرسالة مع تعديل حقول محددة
    String? id, // المعرف الجديد
    String? chatID, // معرف المحادثة الجديد
    String? senderId, // معرف مرسل جديد
    String? text, // نص جديد
    String? audioUrl, // رابط صوت جديد
    int? audioDuration, // مدة صوت جديدة
    String? imageUrl, // رابط صورة جديد
    String? videoUrl, // رابط فيديو جديد
    String? fileUrl, // رابط ملف جديد
    bool? isEdited, // حالة تعديل جديدة
    bool? isDeleted, // حالة حذف جديدة
    DateTime? createdAt, // تاريخ جديد
    String? senderName, // اسم مرسل جديد
    int? helpCount, // عداد مساعدة جديد
    DateTime? readAt, // تاريخ قراءة جديد
    bool? isPending, // حالة انتظار جديدة
    String? localAudioPath, // مسار صوت محلي جديد
    String? localImagePath, // مسار صورة محلي جديد
    String? localVideoPath, // مسار فيديو محلي جديد
    String? localFilePath, // مسار ملف محلي جديد
    String? chatType, // نوع محادثة جديد
    String? receiverId, // معرف مستلم جديد
  }) { // بداية دالة النسخ
    return MessageModel( // إرجاع كائن رسالة جديد
      id: id ?? this.id, // استخدام القيمة الجديدة أو الحالية
      chatID: chatID ?? this.chatID, // استخدام القيمة الجديدة أو الحالية
      senderId: senderId ?? this.senderId, // استخدام القيمة الجديدة أو الحالية
      text: text ?? this.text, // استخدام القيمة الجديدة أو الحالية
      audioUrl: audioUrl ?? this.audioUrl, // استخدام القيمة الجديدة أو الحالية
      audioDuration: audioDuration ?? this.audioDuration, // استخدام القيمة الجديدة أو الحالية
      imageUrl: imageUrl ?? this.imageUrl, // استخدام القيمة الجديدة أو الحالية
      videoUrl: videoUrl ?? this.videoUrl, // استخدام القيمة الجديدة أو الحالية
      fileUrl: fileUrl ?? this.fileUrl, // استخدام القيمة الجديدة أو الحالية
      isEdited: isEdited ?? this.isEdited, // استخدام القيمة الجديدة أو الحالية
      isDeleted: isDeleted ?? this.isDeleted, // استخدام القيمة الجديدة أو الحالية
      createdAt: createdAt ?? this.createdAt, // استخدام القيمة الجديدة أو الحالية
      senderName: senderName ?? this.senderName, // استخدام القيمة الجديدة أو الحالية
      helpCount: helpCount ?? this.helpCount, // استخدام القيمة الجديدة أو الحالية
      readAt: readAt ?? this.readAt, // استخدام القيمة الجديدة أو الحالية
      isPending: isPending ?? this.isPending, // استخدام القيمة الجديدة أو الحالية
      localAudioPath: localAudioPath ?? this.localAudioPath, // استخدام القيمة الجديدة أو الحالية
      localImagePath: localImagePath ?? this.localImagePath, // استخدام القيمة الجديدة أو الحالية
      localVideoPath: localVideoPath ?? this.localVideoPath, // استخدام القيمة الجديدة أو الحالية
      localFilePath: localFilePath ?? this.localFilePath, // استخدام القيمة الجديدة أو الحالية
      chatType: chatType ?? this.chatType, // استخدام القيمة الجديدة أو الحالية
      receiverId: receiverId ?? this.receiverId, // استخدام القيمة الجديدة أو الحالية
    ); // نهاية النسخة الجديدة
  } // نهاية دالة copyWith
} // نهاية كلاس MessageModel

/// نموذج بيانات الإجازة (HolidayModel)
class HolidayModel { // تعريف كلاس بيانات الإجازة أو العطلة
  final String? id; // المعرف الفريد للإجازة
  final DateTime? date; // تاريخ بداية الإجازة
  final DateTime? endDate; // تاريخ نهاية الإجازة (للنطاق الزمني)
  final int? dayOfWeek; // اليوم المحدد من الأسبوع (رقمياً)
  final String reason; // سبب أو وصف الإجازة
  final int? batchNumber; // رقم الدفعة المرتبط بهذه الإجازة

  /// مشيد كائن الإجازة
  HolidayModel({ // مشيد كلاس الإجازة لتهيئة الحقول
    this.id, // المعرف اختياري
    this.date, // تاريخ البداية اختياري
    this.endDate, // تاريخ النهاية اختياري
    this.dayOfWeek, // يوم الأسبوع اختياري
    required this.reason, // السبب مطلوب
    this.batchNumber, // رقم الدفعة اختياري
  }); // نهاية المشيد

  /// تحويل بيانات JSON لإجازة
  factory HolidayModel.fromJson(Map<String, dynamic> json) { // إنشاء كائن إجازة من بيانات JSON
    return HolidayModel( // إرجاع كائن الإجازة
      id: json['id']?.toString(), // استخراج المعرف
      date: json['date'] != null // التحقق من وجود تاريخ مفرد
          ? DateTime.parse(json['date']) // تحليل التاريخ
          : (json['start_date'] != null // التحقق من وجود تاريخ بداية
                ? DateTime.parse(json['start_date']) // تحليل تاريخ البداية
                : null), // تعيين null إذا لم يوجد
      endDate: json['end_date'] != null // التحقق من وجود تاريخ نهاية
          ? DateTime.parse(json['end_date']) // تحليل تاريخ النهاية
          : null, // تعيين null إذا لم يوجد
      dayOfWeek: json['day_of_week'], // استخراج يوم الأسبوع
      reason: json['reason'] ?? '', // استخراج السبب أو تعيين نص فارغ
      batchNumber: json['batch_number'] != null ? int.tryParse(json['batch_number'].toString()) : null, // استخراج رقم الدفعة
    ); // نهاية كائن الإجازة
  } // نهاية دالة fromJson

  /// تحويل نموذج الإجازة لخريطة بيانات JSON
  Map<String, dynamic> toJson() { // تحويل كائن الإجازة لخريطة بيانات JSON
    final Map<String, dynamic> data = { // تهيئة خريطة البيانات
      'reason': reason, // إضافة السبب
      'batch_number': batchNumber, // إضافة رقم الدفعة
    }; // نهاية الخريطة الأساسية

    if (id != null && id!.isNotEmpty) { // التحقق من وجود معرف
      data['id'] = id; // إضافة المعرف للخريطة
    } // نهاية التحقق من المعرف

    if (date != null) { // التحقق من وجود تاريخ بداية
      final dateStr = date!.toIso8601String().split('T')[0]; // تنسيق التاريخ ليكون YYYY-MM-DD
      data['date'] = dateStr; // إضافة التاريخ للحقل العام
      data['start_date'] = dateStr; // إضافة التاريخ لحقل البداية
    } // نهاية معالجة التاريخ

    if (endDate != null) { // التحقق من وجود تاريخ نهاية
      data['end_date'] = endDate!.toIso8601String().split('T')[0]; // تنسيق وإضافة تاريخ النهاية
    } // نهاية معالجة تاريخ النهاية

    if (dayOfWeek != null) { // التحقق من وجود يوم محدد للأسبوع
      data['day_of_week'] = dayOfWeek; // إضافة يوم الأسبوع للخريطة
    } // نهاية معالجة يوم الأسبوع

    return data; // إرجاع خريطة البيانات النهائية
  } // نهاية دالة toJson
} // نهاية كلاس HolidayModel
