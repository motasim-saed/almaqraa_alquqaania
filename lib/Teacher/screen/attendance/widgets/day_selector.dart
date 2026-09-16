import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../controller/daily_attendance_controller.dart';

class DaySelector extends StatelessWidget {
  final DailyAttendanceController controller;

  const DaySelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedDayIndex = controller.selectedDay.value;

      // الحصول على تاريخ اللحظة الحالية (اليوم الحقيقي)
      final now = DateTime.now();
      final isRealCurrentMonth =
          controller.selectedMonthIndex.value == now.month - 1;

      return Container(
        height: 85, // زيادة الارتفاع لمنع التداخل (Overflow)
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: controller.previousDay,
              icon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
            Expanded(
              child: ListView.builder(
                controller: controller.dayScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: controller.daysInMonth,
                itemBuilder: (context, index) {
                  // هل هذا اليوم هو الذي يراجعه المعلم حالياً؟
                  bool isSelected = selectedDayIndex == index;
                  // هل هذا اليوم هو "اليوم الحقيقي" في التقويم؟
                  bool isActualToday =
                      isRealCurrentMonth && (index + 1) == now.day;

                  // final isDark = Theme.of(context).brightness == Brightness.dark;
                  return GestureDetector(
                    onTap: () => controller.selectDay(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 50,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : (isActualToday
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withValues(alpha: 0.5)
                                    : Theme.of(context).dividerColor),
                          width: isSelected || isActualToday ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppDateUtils.getShortDayName(
                              DateTime(
                                controller.currentYear,
                                controller.selectedMonthIndex.value + 1,
                                index + 1,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimary.withValues(alpha: 0.9)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              onPressed: controller.nextDay,
              icon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );
    });
  }
}
