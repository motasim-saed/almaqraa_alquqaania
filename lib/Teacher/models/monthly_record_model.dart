/// فئة تمثل السجل الشهري المتكامل للطالب (إحصائيات الحضور، الغياب، والدرجات)
class MonthlyRecord {
  final String studentId;
  final String studentName;
  final int attendanceDays;
  final int absenceDays;
  final int excusedDays;
  final int holidayDays;
  final int monthlyGrade;
  final double hifzScore;
  final double tajweedScore;
  final double tilawahScore;
  final int? month; // الشهر (1-12)
  final int? year;  // السنة

  MonthlyRecord({
    required this.studentId,
    required this.studentName,
    required this.attendanceDays,
    required this.absenceDays,
    required this.excusedDays,
    this.holidayDays = 0,
    required this.monthlyGrade,
    this.hifzScore = 0.0,
    this.tajweedScore = 0.0,
    this.tilawahScore = 0.0,
    this.month,
    this.year,
  });

  factory MonthlyRecord.fromJson(Map<String, dynamic> json) {
    return MonthlyRecord(
      studentId: json['student_id']?.toString() ?? '',
      studentName: (json['student']?['full_name'] ?? 
                    json['profiles']?['full_name'] ?? 
                    json['student_name'] ?? 
                    json['studentName'] ?? '').toString(),
      attendanceDays: json['attendance_days'] ?? 0,
      absenceDays: json['absence_days'] ?? 0,
      excusedDays: json['excused_days'] ?? 0,
      holidayDays: json['holiday_days'] ?? 0,
      monthlyGrade: json['monthly_grade'] ?? 0,
      hifzScore: double.tryParse(json['hifz_score']?.toString() ?? '0') ?? 0.0,
      tajweedScore: double.tryParse(json['tajweed_score']?.toString() ?? '0') ?? 0.0,
      tilawahScore: double.tryParse(json['tilawah_score']?.toString() ?? '0') ?? 0.0,
      month: json['month'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'attendance_days': attendanceDays,
      'absence_days': absenceDays,
      'excused_days': excusedDays,
      'holiday_days': holidayDays,
      'monthly_grade': monthlyGrade,
      'hifz_score': hifzScore,
      'tajweed_score': tajweedScore,
      'tilawah_score': tilawahScore,
      'month': month,
      'year': year,
    };
  }
}
