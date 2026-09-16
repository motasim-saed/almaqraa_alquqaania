/// نموذج يمثل الخطة السنوية للطالب في نظام المقرأة
class AnnualPlanModel {
  final String id;
  final String studentId;
  final int year;
  final String goalDescription;
  final DateTime createdAt;

  AnnualPlanModel({
    required this.id,
    required this.studentId,
    required this.year,
    required this.goalDescription,
    required this.createdAt,
  });

  factory AnnualPlanModel.fromJson(Map<String, dynamic> json) {
    return AnnualPlanModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      year: json['year'] ?? DateTime.now().year,
      goalDescription: json['goal_description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'student_id': studentId,
      'year': year,
      'goal_description': goalDescription,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }
}

/// نموذج يمثل الخطة الشهرية للطالب
class MonthlyPlanModel {
  final String id;
  final String studentId;
  final int year;
  final int month;
  final String goalDescription;
  final DateTime createdAt;

  MonthlyPlanModel({
    required this.id,
    required this.studentId,
    required this.year,
    required this.month,
    required this.goalDescription,
    required this.createdAt,
  });

  factory MonthlyPlanModel.fromJson(Map<String, dynamic> json) {
    return MonthlyPlanModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      year: json['year'] ?? DateTime.now().year,
      month: json['month'] ?? DateTime.now().month,
      goalDescription: json['goal_description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'student_id': studentId,
      'year': year,
      'month': month,
      'goal_description': goalDescription,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }
}

/// نموذج يمثل السجل اليومي لإنجاز الطالب
class DailyRecordModel {
  final String id;
  final String studentId;
  final DateTime date;
  final String? hifzContent;
  final String? revisionContent;
  final String? teacherNotes;
  final String status;
  final String attendanceStatus; 
  final DateTime createdAt;

  DailyRecordModel({
    required this.id,
    required this.studentId,
    required this.date,
    this.hifzContent,
    this.revisionContent,
    this.teacherNotes,
    required this.status,
    this.attendanceStatus = 'absent',
    required this.createdAt,
  });

  /// دالة لنسخ الكائن مع تعديل قيم محددة (لإصلاح خطأ السطر 119)
  DailyRecordModel copyWith({
    String? id,
    String? studentId,
    DateTime? date,
    String? hifzContent,
    String? revisionContent,
    String? teacherNotes,
    String? status,
    String? attendanceStatus,
    DateTime? createdAt,
  }) {
    return DailyRecordModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      hifzContent: hifzContent ?? this.hifzContent,
      revisionContent: revisionContent ?? this.revisionContent,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      status: status ?? this.status,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DailyRecordModel.fromJson(Map<String, dynamic> json) {
    return DailyRecordModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      hifzContent: json['hifz_content'],
      revisionContent: json['revision_content'],
      teacherNotes: json['teacher_notes'],
      status: json['status'] ?? 'pending',
      attendanceStatus: json['attendance_status'] ?? 'absent', 
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'student_id': studentId,
      'date': date.toIso8601String().split('T')[0],
      'hifz_content': hifzContent,
      'revision_content': revisionContent,
      'teacher_notes': teacherNotes,
      'status': status,
      'attendance_status': attendanceStatus,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }
}
