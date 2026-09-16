import 'package:al_maqraa/core/services/cache_service.dart'; // استيراد خدمة التخزين المؤقت لتحسين أداء الجلب
import 'package:flutter/material.dart'; // استيراد مكتبة ماتيريال لتنسيق الواجهات والألوان
import 'package:get/get.dart'; // استيراد حزمة GetX لدعم الترجمة والرسائل المنبثقة
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيس للتفاعل مع قاعدة البيانات
import '../../../Teacher/models/daily_attendance_record_model.dart'; // استيراد نموذج سجل الحضور اليومي
import '../../../Teacher/models/monthly_exam_model.dart'; // استيراد نموذج سجل الاختبار الشهري
import '../../../Teacher/models/monthly_record_model.dart'; // استيراد نموذج السجل الشهري المعتمد
import '../../models/yearly_record_model.dart'; // استيراد نموذج السجل السنوي التراكمي
import '../../../Student/models/student_models.dart'; // استيراد نماذج بيانات الطالب (خطط وسجلات)

// تعريف ميكسين (Mixin) يسمى ReportsModule لإدارة تقارير الحلقات والطلاب
mixin ReportsModule {
  // الحصول على نسخة من عميل سوبابيس للقيام بالعمليات
  SupabaseClient get supabase => Supabase.instance.client;
  // الوصول لخدمة الكاش المدارة عبر GetX
  CacheService get _cache => Get.find<CacheService>();

  // دالة لجلب تقرير حضور طلاب حلقة معينة خلال فترة محددة
  Future<List<DailyAttendanceRecord>> getCircleAttendance(
    String circleId, {
    int? month,
    int? year,
    Function(List<DailyAttendanceRecord>)? onRefresh,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'circle_attendance_${circleId}_${year ?? 0}_${month ?? 0}';

    Future<List<dynamic>> fetchFromServer() async {
      try {
        // جلب قائمة الطلاب في الحلقة مع أسمائهم وتاريخ الانضمام من ملفاتهم الشخصية
        final studentsRes = await supabase
            .from('circle_members')
            .select('student_id, student:profiles(full_name, created_at)')
            .eq('circle_id', circleId);

        // قائمة لتخزين تقارير الحضور لكل طالب
        List<DailyAttendanceRecord> reports = [];

        // جلب قائمة الإجازات مرة واحدة خارج اللوب لتسريع الاستعلام
        final holidayRes = await supabase.from('app_holidays').select();
        final holidaysArr = (holidayRes as List).map((h) {
          final date = h['date'] != null ? DateTime.parse(h['date']) : null;
          final endDate = h['end_date'] != null
              ? DateTime.parse(h['end_date'])
              : null;
          final dayOfWeek = h['day_of_week'] as int?;
          return {'date': date, 'end_date': endDate, 'day_of_week': dayOfWeek};
        }).toList();

        // تحديد السنة والشهر المستخدمين في المعالجة
        final int yearToUse = year ?? DateTime.now().year;
        final int monthToUse = month ?? DateTime.now().month;
        // حساب عدد الأيام في الشهر المختار
        final int daysInMonth = DateTime(yearToUse, monthToUse + 1, 0).day;

        // تحديد تاريخ اليوم الحالي للمقارنة
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // معالجة بيانات كل طالب على حدة
        for (var row in (studentsRes as List)) {
          // استخراج اسم الطالب أو وضع قيمة افتراضية
          final studentName = row['student'] != null
              ? row['student']['full_name']
              : 'Unknown';
          final studentId = row['student_id'];
          
          // استخراج تاريخ الانضمام للمنصة
          DateTime? joinDate;
          if (row['student'] != null && row['student']['created_at'] != null) {
            joinDate = DateTime.tryParse(row['student']['created_at'].toString());
          }

          // استعلام جلب سجلات الحضور اليومية للطالب
          var query = supabase
              .from('daily_records')
              .select()
              .eq('student_id', studentId);

          // تصفية السجلات بناءً على الشهر والسنة المحددين
          if (month != null && year != null) {
            final firstDay = DateTime(year, month, 1);
            final lastDay = DateTime(year, month + 1, 0);
            query = query
                .gte('date', firstDay.toIso8601String())
                .lte('date', lastDay.toIso8601String());
          } else if (year != null) {
            final firstDay = DateTime(year, 1, 1);
            final lastDay = DateTime(year, 12, 31);
            query = query
                .gte('date', firstDay.toIso8601String())
                .lte('date', lastDay.toIso8601String());
          }

          // تنفيذ الاستعلام وترتيب السجلات حسب التاريخ
          final recordsRes = await query.order('date');

          // توليد قائمة حالات الحضور لكل يوم في الشهر
          final statuses = List.generate(daysInMonth, (d) {
            final day = d + 1;
            final checkDate = DateTime(yearToUse, monthToUse, day);

            // البحث عن سجل حضور مسجل لهذا اليوم
            final rec = (recordsRes as List).firstWhereOrNull((r) {
              final rDate = DateTime.parse(r['date']);
              return rDate.year == yearToUse &&
                  rDate.month == monthToUse &&
                  rDate.day == day;
            });

            // إذا وجد سجل، يتم تحديد الحالة (حاضر، غائب، مستأذن)
            if (rec != null) {
              final s = rec['attendance_status'] ?? 'present';
              if (s == 'absent' || s == 'غ') return AttendanceStatus.absent;
              if (s == 'excused' || s == 'م') return AttendanceStatus.excused;
              if (s == 'holiday' || s == 'إ') return AttendanceStatus.holiday;
              return AttendanceStatus.present;
            }

            // التحقق إذا كان اليوم إجازة رسمية أو أسبوعية
            bool isHol = false;
            for (var h in holidaysArr) {
              final start = h['date'] as DateTime?;
              final end = h['end_date'] as DateTime?;
              final dow = h['day_of_week'] as int?;

              if (start != null) {
                final sDate = DateTime(start.year, start.month, start.day);
                if (end != null) {
                  final eDate = DateTime(end.year, end.month, end.day);
                  if ((checkDate.isAtSameMomentAs(sDate) ||
                          checkDate.isAfter(sDate)) &&
                      (checkDate.isAtSameMomentAs(eDate) ||
                          checkDate.isBefore(eDate))) {
                    isHol = true;
                    break;
                  }
                } else if (checkDate.isAtSameMomentAs(sDate)) {
                  isHol = true;
                  break;
                }
              }
              if (dow != null && checkDate.weekday == dow) {
                isHol = true;
                break;
              }
            }

            // إذا كان إجازة
            if (isHol) return AttendanceStatus.holiday;

            // إذا كان اليوم ماضياً ولم يسجل فيه حضور يعتبر غياباً
            if (checkDate.isBefore(today)) {
              if (joinDate != null) {
                final joinDayOnly = DateTime(joinDate.year, joinDate.month, joinDate.day);
                if (checkDate.isBefore(joinDayOnly)) {
                  return AttendanceStatus.holiday;
                }
              }
              return AttendanceStatus.absent;
            }
            
            // القيمة الافتراضية
            if (joinDate != null) {
              final joinDayOnly = DateTime(joinDate.year, joinDate.month, joinDate.day);
              if (checkDate.isBefore(joinDayOnly)) {
                return AttendanceStatus.holiday;
              }
            }
            return AttendanceStatus.present;
          });

          // إضافة تقرير الطالب للقائمة
          reports.add(
            DailyAttendanceRecord(
              studentId: studentId,
              studentName: studentName,
              dailyStatuses: statuses,
            ),
          );
        }
        return reports.map((e) => e.toJson()).toList();
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'failed_to_fetch_student_details'.tr,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return [];
      }
    }

    if (forceRefresh) {
      final freshData = await fetchFromServer();
      final decodedData = freshData.map((e) => DailyAttendanceRecord.fromJson(e)).toList();
      return decodedData;
    }

    final cached = await _cache.fetchWithCache(
      cacheKey: cacheKey,
      fetchFromServer: fetchFromServer,
      onData: (serverData) {
        if (onRefresh != null && serverData != null) {
          final freshRecords = (serverData as List)
              .map((e) => DailyAttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList();
          onRefresh(freshRecords);
        }
      },
    );

    if (cached == null) return [];
    return (cached as List)
        .map((e) => DailyAttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // دالة لجلب الدرجات والتقارير الشهرية لطلاب الحلقة (تعمل بنظام الكاش أولاً ثم التحديث التلقائي الصامت)
  Future<List<MonthlyRecord>> getCircleMonthlyGrades(
    String circleId, {
    int? month,
    int? year,
    Function(List<MonthlyRecord>)? onRefresh,
  }) async {
    final cacheKey = 'monthly_grades_${circleId}_${year ?? 0}_${month ?? 0}';

    Future<List<dynamic>> fetchFromServer() async {
      try {
        // جلب أعضاء الحلقة
        final studentsRes = await supabase
            .from('circle_members')
            .select('student_id, student:profiles(full_name)')
            .eq('circle_id', circleId);

        // قائمة لحفظ السجلات الشهرية
        List<MonthlyRecord> reports = [];

        // تحديد السنة والشهر واليوم الحاليين للمقارنة
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yearToUse = year ?? now.year;
        final monthToUse = month ?? now.month;

        // جلب الحضور لكل الحلقة مرة واحدة خارج اللوب بنظام forceRefresh لتجاهل الكاش الداخلي
        final attendance = await getCircleAttendance(
          circleId,
          month: monthToUse,
          year: yearToUse,
          forceRefresh: true, 
        );

        // جلب الاختبارات الشهرية لكل الحلقة مرة واحدة
        final exams = await getCircleExams(
          circleId,
          month: monthToUse,
          year: yearToUse,
        );

        // معالجة كل طالب
        for (var row in (studentsRes as List)) {
          final studentName = row['student'] != null
              ? row['student']['full_name']
              : 'Unknown';
          final studentId = row['student_id'];

          // جلب بيانات الحضور المحددة للطالب الحالي
          final studentAttendance = attendance.firstWhereOrNull(
            (a) => a.studentId == studentId,
          );

          // جلب نتائج الاختبار المحددة للطالب الحالي
          final studentExam = exams.firstWhereOrNull(
            (e) => e.studentId == studentId,
          );

          // جلب سجلات التقييم الشهري لهذا الطالب
          var query = supabase
              .from('monthly_records')
              .select()
              .eq('student_id', studentId)
              .eq('year', yearToUse)
              .eq('month', monthToUse);

          final recordRes = await query;
          Map<String, dynamic>? rec = (recordRes as List).isNotEmpty
              ? recordRes.first
              : null;

          // حساب أيام الحضور بشكل مباشر ودقيق من تقرير الحضور
          int p = 0;
          int a = 0;
          int e = 0;
          int h = 0;

          if (studentAttendance != null) {
            for (int i = 0; i < studentAttendance.dailyStatuses.length; i++) {
              final checkDate = DateTime(yearToUse, monthToUse, i + 1);

              // منطق التكامل التاريخي: نحسب فقط للأيام التي مرت أو اليوم الحالي
              if (yearToUse == now.year && monthToUse == now.month) {
                if (checkDate.isAfter(today)) break;
              }

              final status = studentAttendance.dailyStatuses[i];
              if (status == AttendanceStatus.present) {
                p++;
              } else if (status == AttendanceStatus.absent) {
                a++;
              } else if (status == AttendanceStatus.excused) {
                e++;
              } else if (status == AttendanceStatus.holiday) {
                h++;
              }
            }
          }

          // درجة الاختبار تُأخذ من السجل المسجل، إن لم يوجد فتؤخذ دمجاً من تقرير الاختبار الحي
          final monthlyGrade = rec != null
              ? ((rec['monthly_grade'] ?? 0) as num).toInt()
              : (studentExam?.totalScore.toInt() ?? 0);
          final hifz = rec != null
              ? (double.tryParse(rec['hifz_score']?.toString() ?? '0') ?? 0)
              : (studentExam?.hifzScore ?? 0);
          final tajweed = rec != null
              ? (double.tryParse(rec['tajweed_score']?.toString() ?? '0') ?? 0)
              : (studentExam?.tajweedScore ?? 0);
          final tilawah = rec != null
              ? (double.tryParse(rec['tilawah_score']?.toString() ?? '0') ?? 0)
              : (studentExam?.tilawahScore ?? 0);

          // إضافة سجل الطالب الشهري لتقرير الإدارة
          reports.add(
            MonthlyRecord(
              studentId: studentId,
              studentName: studentName,
              attendanceDays: p,
              absenceDays: a,
              excusedDays: e,
              holidayDays: h,
              monthlyGrade: monthlyGrade,
              hifzScore: hifz,
              tajweedScore: tajweed,
              tilawahScore: tilawah,
            ),
          );
        }
        return reports.map((e) => e.toJson()).toList();
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'failed_to_fetch_student_details'.tr,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return [];
      }
    }

    final cached = await _cache.fetchWithCache(
      cacheKey: cacheKey,
      fetchFromServer: fetchFromServer,
      onData: (serverData) {
        if (onRefresh != null && serverData != null) {
          final freshRecords = (serverData as List)
              .map((e) => MonthlyRecord.fromJson(e as Map<String, dynamic>))
              .toList();
          onRefresh(freshRecords);
        }
      },
    );

    if (cached == null) return [];
    return (cached as List)
        .map((e) => MonthlyRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // دالة لجلب السجلات اليومية (الحفظ والمراجعة) لطلاب حلقة معينة
  Future<List<DailyRecordModel>> getCircleDailyRecords(
    String circleId, {
    int? month,
    int? year,
  }) async {
    try {
      // جلب معرفات كافة الطلاب المنتمين للحلقة
      final studentsRes = await supabase
          .from('circle_members')
          .select('student_id')
          .eq('circle_id', circleId);

      // استخراج المعرفات في قائمة نصية
      final List<String> studentIds = (studentsRes as List)
          .map((s) => s['student_id'].toString())
          .toList();

      // جلب السجلات اليومية لهؤلاء الطلاب من جدول daily_records
      var query = supabase
          .from('daily_records')
          .select()
          .filter('student_id', 'in', studentIds);

      // التصفية حسب التاريخ إذا حدد المسؤول ذلك
      if (month != null && year != null) {
        final firstDay = DateTime(year, month, 1);
        final lastDay = DateTime(year, month + 1, 0);
        query = query
            .gte('date', firstDay.toIso8601String())
            .lte('date', lastDay.toIso8601String());
      }

      // جلب النتائج مرتبة تنازلياً حسب التاريخ
      final recordsRes = await query.order('date', ascending: false);
      // تحويل البيانات المسترجعة لنماذج برمجية
      return (recordsRes as List)
          .map((r) => DailyRecordModel.fromJson(r))
          .toList();
    } catch (e) {
      // إظهار رسالة خطأ في حال فشل جلب السجلات
      Get.snackbar(
        'error'.tr,
        'failed_to_fetch_student_details'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return [];
    }
  }

  // دالة لجلب الخطط السنوية المسجلة لطالب معين
  Future<List<AnnualPlanModel>> getStudentAnnualPlans(String studentId) async {
    try {
      // استعلام جلب الخطط السنوية مرتبة حسب السنة
      final res = await supabase
          .from('annual_plans')
          .select()
          .eq('student_id', studentId)
          .order('year');
      // تحويل النتائج لنماذج AnnualPlanModel
      return (res as List).map((p) => AnnualPlanModel.fromJson(p)).toList();
    } catch (e) {
      // إظهار تنبيه في حال الفشل
      Get.snackbar(
        'error'.tr,
        'failed_to_fetch_student_details'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return [];
    }
  }

  // دالة لجلب الخطط الشهرية المسجلة لطالب معين
  Future<List<MonthlyPlanModel>> getStudentMonthlyPlans(
    String studentId,
  ) async {
    try {
      // استعلام جلب الخطط الشهرية مرتبة حسب السنة ثم الشهر
      final res = await supabase
          .from('monthly_plans')
          .select()
          .eq('student_id', studentId)
          .order('year')
          .order('month');
      // تحويل النتائج لنماذج MonthlyPlanModel
      return (res as List).map((p) => MonthlyPlanModel.fromJson(p)).toList();
    } catch (e) {
      // إظهار تنبيه في حال الفشل
      Get.snackbar(
        'error'.tr,
        'failed_to_fetch_student_details'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return [];
    }
  }

  // دالة لجلب نتائج الاختبارات الشهرية لطلاب الحلقة
  Future<List<MonthlyExamRecord>> getCircleExams(
    String circleId, {
    int? month,
    int? year,
  }) async {
    try {
      // جلب قائمة أعضاء الحلقة مع أسمائهم
      final studentsRes = await supabase
          .from('circle_members')
          .select('student_id, student:profiles(full_name)')
          .eq('circle_id', circleId);

      // قائمة لنتائج اختبارات الطلاب
      List<MonthlyExamRecord> reports = [];
      // معالجة كل طالب
      for (var row in (studentsRes as List)) {
        final studentName = row['student'] != null
            ? row['student']['full_name']
            : 'Unknown';
        final studentId = row['student_id'];

        // جلب سجلات الاختبارات المسجلة للطالب
        var query = supabase
            .from('monthly_exams')
            .select()
            .eq('student_id', studentId);

        // تصفية السجلات حسب التاريخ
        if (month != null && year != null) {
          query = query.eq('month', month).eq('year', year);
        } else if (year != null) {
          query = query.eq('year', year);
        }

        // تنفيذ الاستعلام وترتيب السجلات تنازلياً
        final examsRes = await query
            .order('year', ascending: false)
            .order('month', ascending: false);

        double hifz = 0; // مجموع درجة الحفظ
        double tajweed = 0; // مجموع درجة التجويد
        double tilawah = 0; // مجموع درجة التلاوة

        // إذا وجد اختبار مسجل، يتم استخراج الدرجات منه
        if ((examsRes as List).isNotEmpty) {
          final ex = examsRes.first;
          hifz = double.tryParse(ex['hifz_score']?.toString() ?? '0') ?? 0.0;
          tajweed =
              double.tryParse(ex['tajweed_score']?.toString() ?? '0') ?? 0.0;
          // دعم حقل التلقين أو التلاوة حسب المتاح في السجل
          tilawah =
              double.tryParse(
                ex['tilawah_score']?.toString() ??
                    ex['talqeen_score']?.toString() ??
                    '0',
              ) ??
              0.0;
        }

        // إضافة سجل التقرير لقائمة التقارير
        reports.add(
          MonthlyExamRecord(
            studentId: studentId,
            studentName: studentName,
            hifzScore: hifz,
            tajweedScore: tajweed,
            tilawahScore: tilawah,
          ),
        );
      }
      return reports; // إرجاع القائمة النهائية
    } catch (e) {
      // تنبيه بالخطأ في حال الفشل
      Get.snackbar(
        'error'.tr,
        'failed_to_fetch_student_details'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return [];
    }
  }

  // دالة لجلب التقرير السنوي التراكمي لطلاب حلقة معينة
  Future<List<YearlyRecord>> getCircleYearlyGrades(
    String circleId, {
    int? year,
  }) async {
    try {
      // تحديد السنة المطلوبة للتقرير
      final currentYear = year ?? DateTime.now().year;
      final now = DateTime.now();

      // جلب قائمة طلاب الحلقة مع أسمائهم
      final studentsRes = await supabase
          .from('circle_members')
          .select('student_id, student:profiles(full_name)')
          .eq('circle_id', circleId);

      // قائمة التقارير السنوية النهائية
      List<YearlyRecord> reports = [];
      // معالجة كل طالب في الحلقة
      for (var row in (studentsRes as List)) {
        final studentName = row['student'] != null
            ? row['student']['full_name']
            : 'Unknown';
        final studentId = row['student_id'];

        // جلب كافة سجلات التقييم الشهري لهذا الطالب في السنة المحددة
        final recsRes = await supabase
            .from('monthly_records')
            .select()
            .eq('student_id', studentId)
            .eq('year', currentYear);

        Map<int, int> monthlyGrades = {};
        int totalGrade = 0;
        int monthsCount = 0;

        for (var monthRec in (recsRes as List)) {
          final int recMonth = monthRec['month'] as int;

          // معالجة الأشهر الماضية والحالية فقط في السنة الحالية، أو كل الأشهر في السنوات الماضية
          if (currentYear < now.year ||
              (currentYear == now.year && recMonth <= now.month)) {
            final grade = (monthRec['monthly_grade'] ?? 0) as int;
            monthlyGrades[recMonth] = grade;
            totalGrade += grade;
            monthsCount++;
          }
        }

        // حساب المتوسط السنوي للاختبارات الشهرية
        final average = monthsCount > 0 ? totalGrade / monthsCount : 0.0;

        // جلب نتيجة الاختبار السنوي النهائي
        final finalExamsRes = await supabase
            .from('final_exams')
            .select()
            .eq('student_id', studentId)
            .eq('circle_id', circleId)
            .eq('year', currentYear)
            .maybeSingle();

        double examinerTotal = 0.0;
        if (finalExamsRes != null) {
          final h =
              double.tryParse(finalExamsRes['hifz_score']?.toString() ?? '0') ??
              0.0;
          final t =
              double.tryParse(
                finalExamsRes['tajweed_score']?.toString() ?? '0',
              ) ??
              0.0;
          final l =
              double.tryParse(
                finalExamsRes['tilawah_score']?.toString() ?? '0',
              ) ??
              0.0;
          examinerTotal = h + t + l;
        }

        // إضافة السجل السنوي المكتمل
        reports.add(
          YearlyRecord(
            studentId: studentId,
            studentName: studentName,
            monthlyGrades: monthlyGrades,
            monthlyAverageExam: average,
            finalResult: examinerTotal > 0 ? examinerTotal : average,
            finalExamResult: examinerTotal,
          ),
        );
      }
      return reports;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_fetch_student_details'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return [];
    }
  }
}
