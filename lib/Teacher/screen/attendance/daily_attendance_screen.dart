import '../../controller/daily_attendance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'widgets/month_selector.dart';
import 'widgets/day_selector.dart';
import 'widgets/student_attendance_row.dart';
// import 'widgets/table_header.dart';

/// شاشة تسجيل الحضور اليومي لطلاب الحلقة (للمعلم)
class DailyAttendanceScreen extends StatelessWidget {
  const DailyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // تهيئة متحكم الحضور اليومي عند بناء الشاشة
    final controller = Get.put(DailyAttendanceController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'daily_attendance'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.isLoading.value || controller.isTodayHoliday
                  ? null
                  : controller.saveDayData,
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              tooltip: 'save'.tr,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          ); // مؤشر التحميل
        }

        return Column(
          children: [
            // أداة اختيار الشهر
            MonthSelector(controller: controller),

            // أداة اختيار اليوم
            DaySelector(controller: controller),

            const Divider(height: 1),

            // عرض حالة خلو السجلات في حال عدم وجود طلاب
            if (controller.attendanceData.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'no_students_found'.tr,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              // عرض جدول الحضور في حال وجود بيانات
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: controller.attendanceData.length,
                  itemBuilder: (context, index) {
                    // صف خاص لكل طالب لتحديد حالته
                    return StudentAttendanceRow(
                      controller: controller,
                      record: controller.attendanceData[index],
                      studentIndex: index,
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}
