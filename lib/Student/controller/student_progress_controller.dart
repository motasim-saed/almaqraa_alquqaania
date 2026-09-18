import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:quran/quran.dart' as quran;

import '../models/student_models.dart';
import '../repository/student_repository.dart';
import '../repository/supabase_student_repository.dart';
import '../../Admin/models/admin_models.dart';
import '../../Admin/repository/admin_repository.dart';
import '../../Admin/repository/supabase_admin_repository.dart';
import '../../Teacher/models/monthly_record_model.dart';
import '../../Examiner/model/final_exam_model.dart';
import '../../core/services/local_database_service.dart';

class StudentProgressController extends GetxController {
  final StudentRepository _repository = SupabaseStudentRepository();
  final AdminRepository _adminRepository = SupabaseAdminRepository();
  final _localDb = Get.find<LocalDatabaseService>();
  final _supabase = Supabase.instance.client;

  final String? manualStudentId;
  final int? initialMonth;
  final int? initialYear;

  StudentProgressController({
    this.manualStudentId,
    this.initialMonth,
    this.initialYear,
  });

  String get studentId =>
      manualStudentId ?? _supabase.auth.currentUser?.id ?? '';

  var annualPlans = <AnnualPlanModel>[].obs;
  var monthlyPlans = <MonthlyPlanModel>[].obs;
  var dailyRecords = <DailyRecordModel>[].obs;
  var officialMonthlyRecords = <MonthlyRecord>[].obs;
  var finalExamRecord = Rxn<FinalExamRecord>();
  var holidays = <HolidayModel>[].obs;

  var _rawDatabaseRecords = <DailyRecordModel>[];
  RealtimeChannel? _gradesSubscription;

  late var selectedMonth = (initialMonth ?? DateTime.now().month).obs;
  late var selectedYear = (initialYear ?? DateTime.now().year).obs;

  // إحصائيات الشهر المختار (لشاشة السجل اليومي)
  var presentCount = 0.obs;
  var absentCount = 0.obs;
  var excusedCount = 0.obs;
  var holidayCount = 0.obs;

  // إحصائيات السنة كاملة (لشاشة درجاتي)
  var totalPresent = 0.obs;
  var totalAbsent = 0.obs;
  var totalExcused = 0.obs;
  var totalHoliday = 0.obs;

  final ScrollController monthScrollController = ScrollController();

  var isLoading = false.obs;
  var isSaving = false.obs;
  var showFilters = false.obs;
  var showStats = true.obs;

  // قائمة أسماء السور المترجمة
  final List<String> translatedSurahNames = List.generate(
    114,
    (i) => 'surah_${i + 1}'.tr,
  );

  @override
  void onInit() {
    super.onInit();
    if (studentId.isNotEmpty) {
      _loadCachedData();
      fetchInitialData();
      _listenToGradesUpdates();
    }
  }

  @override
  void onReady() {
    super.onReady();
    scrollToSelectedMonth();
  }

  @override
  void onClose() {
    _gradesSubscription?.unsubscribe();
    monthScrollController.dispose();
    super.onClose();
  }

  /// توسيط الشهر المختار في شريط الشهور الأفقي
  void scrollToSelectedMonth({int retry = 0, bool animate = true}) {
    Future.delayed(Duration(milliseconds: retry == 0 ? 150 : 250), () {
      if (monthScrollController.hasClients) {
        final index = selectedMonth.value - 1; // 0 ليناير، 8 لسبتمبر
        const double itemWidth = 105.0; // 95 عرض البطاقة + 10 الهامش
        final double screenWidth = Get.width;
        double offset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
        if (offset < 0) offset = 0;
        if (offset > monthScrollController.position.maxScrollExtent) {
          offset = monthScrollController.position.maxScrollExtent;
        }

        if (animate) {
          monthScrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        } else {
          monthScrollController.jumpTo(offset);
        }
      } else if (retry < 5) {
        scrollToSelectedMonth(retry: retry + 1, animate: animate);
      }
    });
  }

  void _listenToGradesUpdates() {
    _gradesSubscription = _supabase
        .channel('public:grades_attendance_updates_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'monthly_records',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            fetchOfficialGrades();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'final_exams',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            fetchFinalExamRecord();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_records',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            fetchDailyRecords();
          },
        )
        .subscribe();
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
    if (showFilters.value) {
      scrollToSelectedMonth(animate: true);
    }
  }

  void toggleStats() => showStats.value = !showStats.value;

  void changeSelectedMonth(int month) {
    selectedMonth.value = month;
    _updateDisplayRecords();
    scrollToSelectedMonth(animate: true);
  }

  Future<void> _loadCachedData() async {
    try {
      final records = await _localDb.query(
        'daily_records',
        where: 'student_id = ?',
        whereArgs: [studentId],
      );
      _rawDatabaseRecords = records
          .map((e) => DailyRecordModel.fromJson(e))
          .toList();
      _updateDisplayRecords();
      calculateYearlyStats();

      final reports = await _localDb.query(
        'monthly_reports',
        where: 'student_id = ?',
        whereArgs: [studentId],
      );
      officialMonthlyRecords.assignAll(
        reports.map((e) => MonthlyRecord.fromJson(e)).toList(),
      );

      final finalExamData = await _localDb.query(
        'final_exams',
        where: 'student_id = ?',
        whereArgs: [studentId],
        orderBy: 'year DESC',
      );
      if (finalExamData.isNotEmpty) {
        finalExamRecord.value = FinalExamRecord.fromJson(finalExamData.first);
      }

      // تحميل الخطط محلياً للظهور الفوري
      final localAnnualPlans = await _localDb.query(
        'plans',
        where: 'student_id = ? AND type = ?',
        whereArgs: [studentId, 'annual'],
      );
      if (localAnnualPlans.isNotEmpty) {
        annualPlans.assignAll(
          localAnnualPlans.map((e) => AnnualPlanModel.fromJson(e)).toList(),
        );
      }

      final localMonthlyPlans = await _localDb.query(
        'plans',
        where: 'student_id = ? AND type = ?',
        whereArgs: [studentId, 'monthly'],
      );
      if (localMonthlyPlans.isNotEmpty) {
        monthlyPlans.assignAll(
          localMonthlyPlans.map((e) => MonthlyPlanModel.fromJson(e)).toList(),
        );
      }

      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> fetchInitialData() async {
    // تفعيل التحميل فقط إذا لم يكن هناك بيانات محملة من الكاش مسبقاً
    if (dailyRecords.isEmpty && officialMonthlyRecords.isEmpty) {
      isLoading.value = true;
    }
    try {
      // جلب الإجازات أولاً لضمان دقة حسابات الغياب التلقائي
      await fetchHolidays();
      await Future.wait([
        fetchDailyRecords(),
        fetchOfficialGrades(),
        fetchFinalExamRecord(),
        fetchPlans(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPlans() async {
    try {
      final aPlans = await _repository.getAnnualPlans(studentId);
      annualPlans.assignAll(aPlans);
      final mPlans = await _repository.getMonthlyPlans(studentId);
      monthlyPlans.assignAll(mPlans);
    } catch (e) {}
  }

  Future<void> fetchOfficialGrades() async {
    try {
      final response = await _supabase
          .from('monthly_records')
          .select()
          .eq('student_id', studentId);
      final List data = response as List;
      final reports = data.map((e) => MonthlyRecord.fromJson(e)).toList();
      officialMonthlyRecords.assignAll(reports);

      for (var r in reports) {
        await _localDb.insertOrUpdate('monthly_reports', r.toJson());
      }
    } catch (e) {}
  }

  Future<void> fetchFinalExamRecord() async {
    try {
      // جلب أحدث سجل للطالب (الأحدث سنة) لضمان ظهور النتيجة النهائية الصادرة
      // مع تحديد (limit=1) بدلاً من maybeSingle لتجنب الخطأ عند تعدد السجلات عبر السنوات/الحلقات
      final List data = await _supabase
          .from('final_exams')
          .select('*, profiles(full_name)')
          .eq('student_id', studentId)
          .order('year', ascending: false)
          .limit(1);

      if (data.isNotEmpty) {
        final record = FinalExamRecord.fromJson(data.first);
        finalExamRecord.value = record;
        // ملاحظة: لا نضيف student_name لأن جدول final_exams المحلي لا يحتوي هذا العمود
        await _localDb.insertOrUpdate('final_exams', {
          'student_id': record.studentId,
          'hifz_score': record.hifzScore,
          'tajweed_score': record.tajweedScore,
          'tilawah_score': record.tilawahScore,
          'year': DateTime.now().year,
        });
      }
    } catch (e) {}
  }

  /// حساب الإحصائيات الحقيقية لكل شهر بناءً على سجلات الحضور والغياب اليومية
  Map<String, int> getCalculatedStatsForMonth(int month, int year) {
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int p = 0;
    int a = 0;
    int e = 0;
    int h = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.isAfter(today)) break;

      final record = _rawDatabaseRecords.firstWhereOrNull(
        (r) =>
            r.date.year == year && r.date.month == month && r.date.day == day,
      );

      if (record != null) {
        switch (record.attendanceStatus.toLowerCase()) {
          case 'present':
            p++;
            break;
          case 'absent':
            a++;
            break;
          case 'excused':
            e++;
            break;
          case 'holiday':
            h++;
            break;
          default:
            a++;
        }
      } else {
        if (_isHoliday(date)) {
          h++;
        } else {
          a++;
        }
      }
    }

    return {'present': p, 'absent': a, 'excused': e, 'holiday': h};
  }

  /// حساب إحصائيات الحضور والغياب للسنة كاملة
  void calculateYearlyStats() {
    int p = 0;
    int a = 0;
    int e = 0;
    int h = 0;
    final int currentYear = DateTime.now().year;

    // نمر على كل الأشهر التي مرت في السنة الحالية
    for (int m = 1; m <= DateTime.now().month; m++) {
      // البحث أولاً عن سجل رسمي من المعلم لاستخدامه كمصدر موثوق
      final official = officialMonthlyRecords.firstWhereOrNull(
        (r) => r.month == m && (r.year == null || r.year == currentYear),
      );

      if (official != null) {
        p += official.attendanceDays;
        a += official.absenceDays;
        e += official.excusedDays;
        h += official.holidayDays;
      } else {
        // إذا لم يوجد سجل رسمي، يتم الحساب محلياً كمعاينة
        final stats = getCalculatedStatsForMonth(m, currentYear);
        p += stats['present'] ?? 0;
        a += stats['absent'] ?? 0;
        e += stats['excused'] ?? 0;
        h += stats['holiday'] ?? 0;
      }
    }

    totalPresent.value = p;
    totalAbsent.value = a;
    totalExcused.value = e;
    totalHoliday.value = h;
  }

  void _updateDisplayRecords() {
    final filledRecords = _fillDaysForSelectedMonth(_rawDatabaseRecords);
    dailyRecords.assignAll(filledRecords);
    _calculateAttendanceStats(filledRecords);
  }

  void _calculateAttendanceStats(List<DailyRecordModel> records) {
    int p = 0;
    int a = 0;
    int e = 0;
    int h = 0;
    for (var r in records) {
      if (r.status == 'future') continue;
      switch (r.attendanceStatus.toLowerCase()) {
        case 'present':
          p++;
          break;
        case 'absent':
          a++;
          break;
        case 'excused':
          e++;
          break;
        case 'holiday':
          h++;
          break;
      }
    }
    presentCount.value = p;
    absentCount.value = a;
    excusedCount.value = e;
    holidayCount.value = h;
  }

  List<DailyRecordModel> _fillDaysForSelectedMonth(
    List<DailyRecordModel> existingRecords,
  ) {
    final result = <DailyRecordModel>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int year = selectedYear.value;
    final int month = selectedMonth.value;
    final int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final Map<String, DailyRecordModel> recordsMap = {};
    for (var r in existingRecords) {
      recordsMap[DateFormat('yyyy-MM-dd').format(r.date)] = r;
    }
    for (int day = 1; day <= lastDayOfMonth; day++) {
      final date = DateTime(year, month, day);
      final key = DateFormat('yyyy-MM-dd').format(date);
      bool isHoliday = _isHoliday(date);

      if (recordsMap.containsKey(key)) {
        // السجل موجود في قاعدة البيانات - يشمل أيام الاستئذان المستقبلية
        result.add(recordsMap[key]!);
      } else if (date.isAfter(today)) {
        // يوم مستقبلي بدون سجل - تجاهله (فقط عرض الاستئذان المسجل في DB)
        continue;
      } else if (date.isAtSameMomentAs(today)) {
        if (isHoliday) {
          result.add(
            DailyRecordModel(
              id: 'h_$key',
              studentId: studentId,
              date: date,
              status: 'holiday',
              attendanceStatus: 'holiday',
              createdAt: date,
            ),
          );
        }
      } else {
        // يوم ماضٍ بدون سجل - يُعتبر غائباً أو إجازة
        result.add(
          DailyRecordModel(
            id: 'd_$key',
            studentId: studentId,
            date: date,
            status: isHoliday ? 'holiday' : 'absent',
            attendanceStatus: isHoliday ? 'holiday' : 'absent',
            createdAt: date,
          ),
        );
      }
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  bool _isHoliday(DateTime date) {
    for (var h in holidays) {
      if (h.date != null &&
          DateFormat('yyyy-MM-dd').format(h.date!) ==
              DateFormat('yyyy-MM-dd').format(date)) {
        return true;
      }
      if (h.dayOfWeek != null && h.dayOfWeek == date.weekday) return true;
    }
    return false;
  }

  Future<void> fetchDailyRecords() async {
    _rawDatabaseRecords = await _repository.getDailyRecords(studentId);
    _updateDisplayRecords();
    calculateYearlyStats();
  }

  Future<void> fetchHolidays() async {
    try {
      holidays.assignAll(await _adminRepository.getHolidays());
    } catch (e) {}
  }

  int calculatePagesInRange(int startSurah, int endSurah) {
    int startPage = quran.getPageNumber(startSurah, 1);
    int lastVerse = quran.getVerseCount(endSurah);
    int endPage = quran.getPageNumber(endSurah, lastVerse);
    return (endPage - startPage).abs() + 1;
  }

  Future<String?> addDailyRecord({
    required String hifz,
    required String revision,
  }) async {
    isSaving.value = true;
    try {
      final now = DateTime.now();

      // التحقق مما إذا كان هناك سجل مسبق لهذا اليوم لتجنب خطأ التكرار
      bool recordExists = _rawDatabaseRecords.any(
        (r) =>
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day,
      );

      if (recordExists) {
        return 'record_exists_today'.tr;
      }

      final record = DailyRecordModel(
        id: '',
        studentId: studentId,
        date: now,
        hifzContent: hifz,
        revisionContent: revision,
        status: 'pending',
        attendanceStatus: 'present',
        createdAt: now,
      );
      await _repository.saveDailyRecord(record);
      await fetchDailyRecords();
      return null;
    } catch (e) {
      return 'unexpected_error'.tr;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateTeacherReview({
    required DateTime date,
    required String status,
    required String notes,
  }) async {
    isSaving.value = true;
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      await _supabase
          .from('daily_records')
          .update({'status': status, 'teacher_notes': notes})
          .eq('student_id', studentId)
          .eq('date', dateStr);
      Get.snackbar(
        'success'.tr,
        'saved_successfully'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await fetchDailyRecords();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'unexpected_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> savePlanWithRange({
    required bool isAnnual,
    required int year,
    int? month,
    required int startSurah,
    required int endSurah,
    String? customNote,
  }) async {
    isSaving.value = true;
    try {
      int totalPages = calculatePagesInRange(startSurah, endSurah);
      String rate = "";
      if (isAnnual) {
        rate = (totalPages / 12).toStringAsFixed(1);
      } else {
        int planMonth = month ?? DateTime.now().month;
        int daysInMonth = DateTime(year, planMonth + 1, 0).day;
        rate = (totalPages / daysInMonth).toStringAsFixed(1);
      }

      String description =
          'STRUCT_V1|$startSurah|$endSurah|$totalPages|$rate|${customNote ?? ''}';

      if (isAnnual) {
        if (annualPlans.any((p) => p.year == year)) {
          Get.snackbar(
            'alert'.tr,
            'plan_exists_year'.tr,
            backgroundColor: Colors.orange.shade800,
            colorText: Colors.white,
          );
          isSaving.value = false;
          return;
        }

        final plan = AnnualPlanModel(
          id: '',
          studentId: studentId,
          year: year,
          goalDescription: description,
          createdAt: DateTime.now(),
        );
        await _repository.saveAnnualPlan(plan);
      } else {
        final planMonth = month ?? DateTime.now().month;

        if (monthlyPlans.any((p) => p.year == year && p.month == planMonth)) {
          Get.snackbar(
            'alert'.tr,
            'plan_exists_month'.tr,
            backgroundColor: Colors.orange.shade800,
            colorText: Colors.white,
          );
          isSaving.value = false;
          return;
        }

        final plan = MonthlyPlanModel(
          id: '',
          studentId: studentId,
          year: year,
          month: planMonth,
          goalDescription: description,
          createdAt: DateTime.now(),
        );
        await _repository.saveMonthlyPlan(plan);
      }
      Get.back();
      Get.snackbar(
        'success'.tr,
        'plan_saved_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchPlans();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'unexpected_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }
}
