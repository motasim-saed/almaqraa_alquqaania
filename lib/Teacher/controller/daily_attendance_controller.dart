import 'package:flutter/material.dart'; 
import 'package:get/get.dart'; 
import 'package:get_storage/get_storage.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../core/utils/date_utils.dart'; 
import '../../Admin/models/admin_models.dart'; 
import '../models/daily_attendance_record_model.dart'; 
import '../repository/attendance_repository.dart'; 
import '../repository/supabase_attendance_repository.dart'; 

class DailyAttendanceController extends GetxController {
  final AttendanceRepository _repository = SupabaseAttendanceRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();

  // إضافة ScrollController للتحكم في تمرير شريط الأيام والشهور
  final ScrollController dayScrollController = ScrollController();
  final ScrollController monthScrollController = ScrollController();

  final int currentYear = DateTime.now().year;
  final RxInt selectedMonthIndex = 0.obs;
  final RxInt selectedDay = 0.obs;
  final RxBool isLoading = true.obs;

  final RxList<DailyAttendanceRecord> attendanceData = <DailyAttendanceRecord>[].obs;
  final RxList<HolidayModel> holidays = <HolidayModel>[].obs;

  int get daysInMonth => AppDateUtils.getDaysInMonth(currentYear, selectedMonthIndex.value + 1);
  
  String get selectedDayName => AppDateUtils.getDayName(
    DateTime(currentYear, selectedMonthIndex.value + 1, selectedDay.value + 1),
  );

  bool get isTodayHoliday {
    final date = DateTime(currentYear, selectedMonthIndex.value + 1, selectedDay.value + 1);
    return AppDateUtils.isHoliday(date, holidays);
  }

  @override
  void onInit() {
    super.onInit();
    _navigateToCurrentDate();
    loadAttendanceData();
    // تمرير تلقائي للشهر واليوم المختارين بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToSelectedMonth();
      scrollToSelectedDay();
    });
  }

  /// دالة للتمرير التلقائي للشهر المختار ليصبح في منتصف الشاشة
  void scrollToSelectedMonth() {
    if (monthScrollController.hasClients) {
      // حساب الإزاحة (عرض البطاقة 110 + الهامش 8)
      double offset = selectedMonthIndex.value * 118.0; 
      double screenWidth = Get.width;
      double targetOffset = offset - (screenWidth / 2) + 55; // 55 هو نصف عرض بطاقة الشهر

      monthScrollController.animateTo(
        targetOffset < 0 ? 0 : targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// دالة للتمرير التلقائي لليوم المختار ليصبح في منتصف الشاشة
  void scrollToSelectedDay() {
    if (dayScrollController.hasClients) {
      // حساب الإزاحة (عرض البطاقة 60 + الهوامش 10)
      double offset = selectedDay.value * 70.0; 
      // طرح نصف عرض الشاشة التقريبي لجعل العنصر في المنتصف
      double screenWidth = Get.width;
      double targetOffset = offset - (screenWidth / 2) + 35; // 35 هو نصف عرض البطاقة

      dayScrollController.animateTo(
        targetOffset < 0 ? 0 : targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToCurrentDate() {
    selectedMonthIndex.value = DateTime.now().month - 1;
    selectedDay.value = DateTime.now().day - 1;
  }

  void loadAttendanceData() async {
    try {
      if (attendanceData.isEmpty) {
        isLoading.value = true; // البدء بالتحميل فقط إذا كان الكاش فارغاً
      }
      final String? teacherId = _supabase.auth.currentUser?.id;
      if (teacherId == null) return;

      _loadDataFromCache(teacherId);

      final response = await _repository.getAttendanceData(
        teacherId: teacherId,
        year: currentYear,
        month: selectedMonthIndex.value + 1,
      );

      attendanceData.assignAll(response.records);
      holidays.assignAll(response.holidays);
      _saveDataToCache(teacherId);
      
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  void _loadDataFromCache(String teacherId) {
    final String cacheKey = 'attendance_${teacherId}_${currentYear}_${selectedMonthIndex.value + 1}';
    final cachedData = _storage.read(cacheKey);
    if (cachedData != null) {
      final List<dynamic> recordsJson = cachedData['records'] ?? [];
      final List<dynamic> holidaysJson = cachedData['holidays'] ?? [];
      attendanceData.assignAll(recordsJson.map((j) => DailyAttendanceRecord.fromJson(j)).toList());
      holidays.assignAll(holidaysJson.map((j) => HolidayModel.fromJson(j)).toList());
      isLoading.value = false;
    }
  }

  void _saveDataToCache(String teacherId) {
    final String cacheKey = 'attendance_${teacherId}_${currentYear}_${selectedMonthIndex.value + 1}';
    _storage.write(cacheKey, {
      'records': attendanceData.map((e) => e.toJson()).toList(),
      'holidays': holidays.map((e) => e.toJson()).toList(),
    });
  }

  void updateStatus(int studentIndex, int dayIndex, AttendanceStatus newStatus) {
    if (newStatus == AttendanceStatus.excused) {
      final student = attendanceData[studentIndex];
      int excusedCount = student.dailyStatuses.asMap().entries.where((e) => e.key != dayIndex && e.value == AttendanceStatus.excused).length;
      if (excusedCount >= 3) {
        Get.snackbar('alert'.tr, 'excused_limit_msg'.tr, backgroundColor: Colors.orange, colorText: Colors.white, duration: const Duration(seconds: 5));
        return;
      }
    }
    attendanceData[studentIndex].dailyStatuses[dayIndex] = newStatus;
    attendanceData.refresh();
    saveDayData(silent: true);
    final String? teacherId = _supabase.auth.currentUser?.id;
    if (teacherId != null) _saveDataToCache(teacherId);
  }

  void nextDay() {
    if (selectedDay.value < daysInMonth - 1) {
      selectedDay.value++;
      scrollToSelectedDay(); // تمرير عند التغيير
    } else if (selectedMonthIndex.value < 11) {
      selectMonth(selectedMonthIndex.value + 1);
    }
  }

  void previousDay() {
    if (selectedDay.value > 0) {
      selectedDay.value--;
      scrollToSelectedDay(); // تمرير عند التغيير
    } else if (selectedMonthIndex.value > 0) {
      int prevMonth = selectedMonthIndex.value - 1;
      selectedMonthIndex.value = prevMonth;
      selectedDay.value = AppDateUtils.getDaysInMonth(currentYear, prevMonth + 1) - 1;
      loadAttendanceData();
      Future.delayed(const Duration(milliseconds: 100), () => scrollToSelectedDay());
    }
  }

  void selectDay(int dayIndex) {
    selectedDay.value = dayIndex;
    scrollToSelectedDay(); // تمرير لليوم المختار
  }

  void selectMonth(int monthIndex) {
    selectedMonthIndex.value = monthIndex;
    selectedDay.value = 0;
    loadAttendanceData();
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollToSelectedMonth();
      scrollToSelectedDay();
    });
  }


  Future<void> saveDayData({bool silent = false}) async {
    try {
      if (attendanceData.isEmpty) return;
      final targetDate = DateTime(currentYear, selectedMonthIndex.value + 1, selectedDay.value + 1);
      final dateStr = targetDate.toIso8601String().split('T')[0];
      List<Map<String, dynamic>> records = attendanceData.map((s) => {'student_id': s.studentId, 'date': dateStr, 'attendance_status': _statusToString(s.dailyStatuses[selectedDay.value])}).toList();
      await _repository.saveMultipleAttendance(records: records, year: currentYear, month: selectedMonthIndex.value + 1);
      if (!silent) Get.snackbar('save'.tr, '${'saved_successfully'.tr} (${'day'.tr} ${selectedDay.value + 1})', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      if (!silent) Get.snackbar('error'.tr, e.toString());
    }
  }

  String _statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return 'present';
      case AttendanceStatus.absent: return 'absent';
      case AttendanceStatus.excused: return 'excused';
      case AttendanceStatus.holiday: return 'holiday';
    }
  }
}
