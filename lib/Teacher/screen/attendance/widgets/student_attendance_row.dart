import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/daily_attendance_controller.dart';
import '../../../models/daily_attendance_record_model.dart';
import 'attendance_utils.dart'; // We'll extract the status icon/color helpers here

/// صف جدول خاص بعرض بيانات الطالب في واجهة الحضور
class StudentAttendanceRow extends StatelessWidget {
  final DailyAttendanceController controller;
  final DailyAttendanceRecord record;
  final int studentIndex;

  const StudentAttendanceRow({
    super.key,
    required this.controller,
    required this.record,
    required this.studentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // مراقبة حالة حضور الطالب في اليوم المختار حالياً
      final AttendanceStatus status =
          record.dailyStatuses[controller.selectedDay.value];

      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      return Container(
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AttendanceUtils.getStatusColor(status).withValues(alpha: 0.1),// 
                  child: Icon(
                    AttendanceUtils.getStatusIcon(status),
                    color: AttendanceUtils.getStatusColor(status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.studentName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  width: 110,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AttendanceUtils.getStatusColor(status).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AttendanceUtils.getStatusColor(status).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AttendanceStatus>(
                      value: status,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: AttendanceUtils.getStatusColor(status)),
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(
                        color: AttendanceUtils.getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          controller.updateStatus(
                            studentIndex,
                            controller.selectedDay.value,
                            newValue,
                          );
                        }
                      },
                      items: AttendanceStatus.values
                          .where((s) {
                            if (s == AttendanceStatus.holiday) {
                              return controller.isTodayHoliday || status == AttendanceStatus.holiday;
                            }
                            return true;
                          })
                          .map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                AttendanceUtils.getStatusLabel(s),
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
