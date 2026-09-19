import 'package:flutter/material.dart';

/// مستويات التقييم الشهري المعتمدة (اختيار وليس كتابة)
/// كل مستوى يحمل رسالة موحدة تظهر للطالب — وهذا يتيح لاحقاً
/// معالجة جماعية: "كل الطلاب الذين يحملون تقييم معين تصلهم رسالته".
class MonthlyRatingLevel {
  final String key;
  final String titleAr;
  final String titleEn;
  final String messageAr;
  final String messageEn;
  final Color color;
  final IconData icon;
  final int stars;

  const MonthlyRatingLevel({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.messageAr,
    required this.messageEn,
    required this.color,
    required this.icon,
    required this.stars,
  });

  static const List<MonthlyRatingLevel> values = [
    MonthlyRatingLevel(
      key: 'excellent',
      titleAr: 'ممتاز',
      titleEn: 'Excellent',
      messageAr:
          'ما شاء الله تبارك الله! التزامك استثنائي هذا الشهر، استمر على هذا التميز فأنت قدوة لزملائك.',
      messageEn:
          'Mashallah! Your commitment this month is exceptional. Keep up this excellence, you are a role model.',
      color: Color(0xFF2E7D32),
      icon: Icons.emoji_events_rounded,
      stars: 5,
    ),
    MonthlyRatingLevel(
      key: 'very_good',
      titleAr: 'جيد جداً',
      titleEn: 'Very Good',
      messageAr:
          'أحسنت! أداؤك جيد جداً والتزامك واضح، خطوة واحدة تفصلك عن الامتياز، واصل التقدم.',
      messageEn:
          'Well done! Your performance is very good and your commitment is clear. One step away from excellence.',
      color: Color(0xFF1565C0),
      icon: Icons.thumb_up_rounded,
      stars: 4,
    ),
    MonthlyRatingLevel(
      key: 'good',
      titleAr: 'جيد',
      titleEn: 'Good',
      messageAr:
          'عمل جيد! أنت على الطريق الصحيح، حاول زيادة تركيزك على الحفظ والمراجعة اليومية لتحقق الأفضل.',
      messageEn:
          'Good work! You are on the right track. Try to focus more on daily memorization and revision.',
      color: Color(0xFF00838F),
      icon: Icons.check_circle_rounded,
      stars: 3,
    ),
    MonthlyRatingLevel(
      key: 'acceptable',
      titleAr: 'مقبول',
      titleEn: 'Acceptable',
      messageAr:
          'اجتهادك مقبول لكن بإمكانك تقديم الأفضل بكثير، نظّم وقتك والتزم بالخطة الشهرية وسنكون بجانبك.',
      messageEn:
          'Your effort is acceptable but you can do much better. Organize your time and stick to the monthly plan.',
      color: Color(0xFFEF6C00),
      icon: Icons.info_rounded,
      stars: 2,
    ),
    MonthlyRatingLevel(
      key: 'needs_improvement',
      titleAr: 'يحتاج متابعة',
      titleEn: 'Needs Follow-up',
      messageAr:
          'نلاحظ تعثر التزامك هذا الشهر، لا تقلق فنحن معك. تواصل مع معلمك لوضع خطة دعم مناسبة ولنبدأ من جديد.',
      messageEn:
          'We noticed your commitment declined this month. Do not worry, we are with you. Contact your teacher for a support plan.',
      color: Color(0xFFC62828),
      icon: Icons.priority_high_rounded,
      stars: 1,
    ),
  ];

  static MonthlyRatingLevel fromKey(String? key) {
    return tryFromKey(key) ?? values[2];
  }

  /// إرجاع المستوى إن كان المفتاح معروفاً، وإلا null (بدون افتراض "جيد")
  /// يُستخدم لرسائل التقييم حتى لا يظهر "جيد" خطأً عند غياب المعلومة
  static MonthlyRatingLevel? tryFromKey(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    for (final e in values) {
      if (e.key == key) return e;
    }
    return null;
  }

  String title(bool isArabic) => isArabic ? titleAr : titleEn;
  String message(bool isArabic) => isArabic ? messageAr : messageEn;
}

/// سجل تقييم شهري واحد لطالب
class MonthlyRating {
  final String? id;
  final String studentId;
  final String? teacherId;
  final int month;
  final int year;
  final String rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MonthlyRating({
    this.id,
    required this.studentId,
    this.teacherId,
    required this.month,
    required this.year,
    required this.rating,
    this.createdAt,
    this.updatedAt,
  });

  MonthlyRatingLevel get level => MonthlyRatingLevel.fromKey(rating);

  factory MonthlyRating.fromJson(Map<String, dynamic> json) {
    return MonthlyRating(
      id: json['id']?.toString(),
      studentId: json['student_id']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString(),
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      rating: json['rating']?.toString() ?? 'good',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      if (teacherId != null) 'teacher_id': teacherId,
      'month': month,
      'year': year,
      'rating': rating,
    };
  }

  MonthlyRating copyWith({String? rating, int? month, int? year}) {
    return MonthlyRating(
      id: id,
      studentId: studentId,
      teacherId: teacherId,
      month: month ?? this.month,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
