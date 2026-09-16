import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيس للتعامل مع قاعدة البيانات
import '../models/daily_attendance_record_model.dart'; // استيراد نموذج سجل الحضور اليومي
import '../../Admin/models/admin_models.dart'; // استيراد نماذج الإدارة مثل العطلات
import '../../core/utils/date_utils.dart'; // استيراد أدوات مساعدة للتعامل مع التواريخ
import 'attendance_repository.dart'; // استيراد الواجهة البرمجية لمستودع الحضور
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والاعتماديات
import '../../core/services/cache_service.dart'; // استيراد خدمة التخزين المؤقت

/// تنفيذ مستودع الحضور باستخدام قاعدة بيانات سوبابيس (Supabase)
class SupabaseAttendanceRepository implements AttendanceRepository {
  final SupabaseClient _supabase = Supabase.instance.client; // إنشاء مثيل من عميل سوبابيس
  final CacheService _cacheService = Get.find<CacheService>(); // الحصول على خدمة التخزين المؤقت عبر GetX

  @override
  /// دالة لجلب بيانات الحضور لطلاب معلم محدد خلال شهر وسنة معينة
  Future<AttendanceDataResponse> getAttendanceData({
    required String teacherId, // معرف المعلم
    required int year, // السنة المطلوبة
    required int month, // الشهر المطلوب
  }) async {
    // تكوين مفتاح التخزين المؤقت بناءً على المعلم والتاريخ
    final cacheKey = 'attendance_${teacherId}_${year}_$month';

    // محاولة جلب البيانات من التخزين المؤقت أو جلبها من السيرفر إذا لم توجد
    final cachedResult = await _cacheService.fetchWithCache(
      cacheKey: cacheKey,
      fetchFromServer: () async {
        // 1. جلب قائمة العطلات الرسمية من جدول 'app_holidays'
        final holidayRes = await _supabase.from('app_holidays').select();
        final List<HolidayModel> holidays = (holidayRes as List)
            .map((h) => HolidayModel.fromJson(h))
            .toList();

        // 2. جلب الحلقات (المجموعات) التي يديرها هذا المعلم
        final circles = await _supabase
            .from('circles')
            .select('id')
            .eq('teacher_id', teacherId);

        final circleIds = (circles as List).map((c) => c['id']).toList();
        // إذا لم يكن لدى المعلم حلقات، يتم إرجاع قائمة فارغة مع العطلات
        if (circleIds.isEmpty) {
          return {
            'records': [],
            'holidays': holidays.map((h) => h.toJson()).toList(),
          };
        }

        // 3. جلب جميع الطلاب المنضمين لهذه الحلقات مع تاريخ انضمامهم 
        // وتاريخ إنشاء حسابهم (created_at في profiles) كاحتياط
        final members = await _supabase
            .from('circle_members')
            .select('student_id, created_at, student:profiles(full_name, created_at)')
            .filter('circle_id', 'in', circleIds);

        final List<String> studentIds = (members as List)
            .map((m) => m['student_id'].toString())
            .toList();

        // 4. تحديد النطاق الزمني للشهر المطلوب (تاريخ البداية والنهاية)
        final startDate = DateTime(year, month, 1);
        final endDate = DateTime(year, month + 1, 1);

        // جلب سجلات الحضور اليومية لهؤلاء الطلاب في النطاق الزمني المحدد
        final dailyRecordsRes = await _supabase
            .from('daily_records')
            .select('student_id, date, attendance_status')
            .filter('student_id', 'in', studentIds)
            .gte('date', startDate.toIso8601String())
            .lt('date', endDate.toIso8601String());

        // تحويل سجلات قاعدة البيانات إلى خريطة (Map) لتسهيل الوصول إليها عبر معرف الطالب واليوم
        final Map<String, Map<int, AttendanceStatus>> attendanceMap = {};
        for (var rec in (dailyRecordsRes as List)) {
          final sId = rec['student_id'];
          final date = DateTime.parse(rec['date']);
          final statusStr = rec['attendance_status'] ?? 'present';

          attendanceMap.putIfAbsent(sId, () => {});
          attendanceMap[sId]![date.day - 1] = _stringToStatus(statusStr);
        }

        final int daysInMonth = AppDateUtils.getDaysInMonth(year, month); // معرفة عدد أيام الشهر
        List<Map<String, dynamic>> recordsJson = []; // قائمة لتخزين البيانات بصيغة JSON

        // بناء سجل الحضور الكامل لكل طالب لجميع أيام الشهر
        for (var member in members) {
          final studentId = member['student_id']?.toString() ?? '';
          final studentName =
              member['student']?['full_name'] ?? 'role_student'.tr;
              
          // استخدام تاريخ الإنشاء في جدول circle_members كبداية لاحتساب الحضور
          // أو تاريخ إنشاء الملف الشخصي إذا لم يتوفر الأول
          DateTime? joinDate;
          if (member['created_at'] != null) {
            joinDate = DateTime.tryParse(member['created_at'].toString());
          } else if (member['student']?['created_at'] != null) {
            joinDate = DateTime.tryParse(member['student']['created_at'].toString());
          }

          // توليد حالة الحضور لكل يوم في الشهر
          final statuses = List.generate(daysInMonth, (dayIndex) {
            final dateToCheck = DateTime(year, month, dayIndex + 1);
            
            // إذا كان اليوم قبل تاريخ انضمام الطالب للحلقة، نعتبره "إجازة" (لا يحسب غياباً)
            if (joinDate != null) {
              final joinDayOnly = DateTime(joinDate!.year, joinDate!.month, joinDate!.day);
              if (dateToCheck.isBefore(joinDayOnly)) {
                return 'holiday'; 
              }
            }

            // إذا كان هناك سجل موجود في الخريطة لهذا اليوم
            if (attendanceMap[studentId]?.containsKey(dayIndex) ?? false) {
              return _statusToString(attendanceMap[studentId]![dayIndex]!);
            }
            
            // إذا كان اليوم يوم عطلة رسمية
            if (AppDateUtils.isHoliday(dateToCheck, holidays)) {
              return 'holiday';
            }
            
            // للأيام الماضية التي ليس لها سجل (بعد تاريخ الانضمام)، نعتبرها "غياب" تلقائياً
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            if (dateToCheck.isBefore(today)) {
              return 'absent';
            }
            
            // الأيام الحالية والمستقبلية تعتبر "حضور" كحالة افتراضية
            return 'present'; 
          });

          // إضافة بيانات الطالب وحالاته للقائمة النهائية
          recordsJson.add({
            'student_id': studentId,
            'student_name': studentName,
            'daily_statuses': statuses,
          });
        }

        // إرجاع النتيجة النهائية للتخزين المؤقت
        return {
          'records': recordsJson,
          'holidays': holidays.map((h) => h.toJson()).toList(),
        };
      },
    );

    // إذا فشل جلب البيانات، إرجاع استجابة فارغة
    if (cachedResult == null) {
      return AttendanceDataResponse(records: [], holidays: []);
    }

    // تحويل البيانات من صيغة JSON إلى كائنات برمجية (Models)
    final List<DailyAttendanceRecord> records =
        (cachedResult['records'] as List)
            .map(
              (r) => DailyAttendanceRecord(
                studentId: r['student_id'],
                studentName: r['student_name'],
                dailyStatuses: (r['daily_statuses'] as List)
                    .map((s) => _stringToStatus(s.toString()))
                    .toList(),
              ),
            )
            .toList();

    final List<HolidayModel> holidays = (cachedResult['holidays'] as List)
        .map((h) => HolidayModel.fromJson(h))
        .toList();

    // إرجاع الكائن النهائي الذي يحتوي على السجلات والعطلات
    return AttendanceDataResponse(records: records, holidays: holidays);
  }

  @override
  /// دالة لحفظ حالة حضور طالب واحد في يوم محدد (تحديث أو إضافة)
  Future<bool> saveAttendance({
    required String studentId, // معرف الطالب
    required DateTime date, // التاريخ
    required AttendanceStatus status, // الحالة الجديدة
  }) async {
    try {
      // تحويل التاريخ إلى صيغة نصية (سنة-شهر-يوم)
      final dateStr = date.toIso8601String().split('T')[0];
      // تحديث أو إدراج السجل في جدول 'daily_records'
      await _supabase.from('daily_records').upsert({
        'student_id': studentId,
        'date': dateStr,
        'attendance_status': _statusToString(status),
      }, onConflict: 'student_id, date');

      // إعادة مزامنة الإحصائيات الشهرية للطالب بعد كل تعديل
      await _syncMonthlyTotals(studentId, date.year, date.month);
      return true; // نجاح العملية
    } catch (e) {
      return false; // فشل العملية
    }
  }

  @override
  /// دالة لحفظ سجلات حضور متعددة دفعة واحدة (Bulk Update)
  Future<bool> saveMultipleAttendance({
    required List<Map<String, dynamic>> records, // قائمة السجلات
    required int year, // السنة
    required int month, // الشهر
  }) async {
    try {
      // إرسال جميع السجلات دفعة واحدة لقاعدة البيانات
      await _supabase
          .from('daily_records')
          .upsert(records, onConflict: 'student_id, date');

      // استخراج معرفات الطلاب الفريدين لتحديث إحصائياتهم الشهرية
      final Set<String> studentIds = records
          .map((r) => r['student_id'].toString())
          .toSet();
      for (var sId in studentIds) {
        await _syncMonthlyTotals(sId, year, month);
      }
      return true; // نجاح العملية
    } catch (e) {
      return false; // فشل العملية
    }
  }

  /// دالة خاصة لحساب وتحديث مجموع الحضور والغياب الشهري للطالب
  Future<void> _syncMonthlyTotals(String studentId, int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    // جلب جميع السجلات اليومية للطالب خلال الشهر المحدد
    final dailyRecordsRes = await _supabase
        .from('daily_records')
        .select('attendance_status')
        .eq('student_id', studentId)
        .gte('date', startDate.toIso8601String())
        .lt('date', endDate.toIso8601String());

    int present = 0, absent = 0, excused = 0;
    // حساب عدد أيام الحضور، الغياب، والغياب بعذر
    for (var rec in (dailyRecordsRes as List)) {
      final status = rec['attendance_status'] ?? 'present';
      if (status == 'ح' || status == 'present') {
        present++;
      } else if (status == 'غ' || status == 'absent') {
        absent++;
      } else if (status == 'م' || status == 'excused') {
        excused++;
      }
    }

    // جلب بيانات السجل الشهري الحالي (إن وجد) للحفاظ على درجات الحفظ والتجويد
    final existing = await _supabase
        .from('monthly_records')
        .select()
        .eq('student_id', studentId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();

    // تحديث أو إنشاء السجل الشهري بالإحصائيات الجديدة
    await _supabase.from('monthly_records').upsert({
      'student_id': studentId,
      'year': year,
      'month': month,
      'attendance_days': present,
      'absence_days': absent,
      'excused_days': excused,
      'monthly_grade': existing?['monthly_grade'] ?? 0,
      'hifz_score': existing?['hifz_score'] ?? 0,
      'tajweed_score': existing?['tajweed_score'] ?? 0,
      'tilawah_score': existing?['tilawah_score'] ?? 0,
    }, onConflict: 'student_id, month, year');
  }

  /// تحويل النص المخزن في قاعدة البيانات إلى نوع AttendanceStatus البرمجي
  AttendanceStatus _stringToStatus(String status) {
    if (status == 'absent' || status == 'غ') return AttendanceStatus.absent;
    if (status == 'excused' || status == 'م') return AttendanceStatus.excused;
    if (status == 'holiday' || status == 'ج') return AttendanceStatus.holiday;
    return AttendanceStatus.present;
  }

  /// تحويل نوع AttendanceStatus البرمجي إلى نص لحفظه في قاعدة البيانات
  String _statusToString(AttendanceStatus status) {
    if (status == AttendanceStatus.absent) return 'absent';
    if (status == AttendanceStatus.excused) return 'excused';
    if (status == AttendanceStatus.holiday) return 'holiday';
    return 'present';
  }
}
