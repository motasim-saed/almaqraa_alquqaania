import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/daily_attendance_controller.dart';
import '../../../../core/utils/app_constants.dart';

/// أداة اختيار الشهر في واجهة الحضور اليومي للمعلم مع تمييز الشهر الحالي
class MonthSelector extends StatelessWidget {
  final DailyAttendanceController controller;

  const MonthSelector({super.key, required this.controller});

  // قائمة أسماء الشهور المأخوذة من الثوابت العامة للتطبيقات
  static const List<String> months = AppConstants.gregorianMonths;

  @override
  Widget build(BuildContext context) {
    // الحصول على الشهر الحالي (الفعلي) من النظام
    final now = DateTime.now();
    final actualMonthIndex = now.month - 1;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(() {
        // مراقبة الشهر المختار للتصفح
        final selectedIndex = controller.selectedMonthIndex.value;
        return ListView.builder(
          controller: controller.monthScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: months.length,
          itemBuilder: (context, index) {
            // final isDark = Theme.of(context).brightness == Brightness.dark;
            // هل هذا هو الشهر الذي يتصفحه المعلم حالياً؟
            bool isSelected = selectedIndex == index;
            // هل هذا هو "الشهر الفعلي" الآن في التقويم؟
            bool isActualMonth = actualMonthIndex == index;

            return GestureDetector(
              onTap: () => controller.selectMonth(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 110,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (isActualMonth
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.5)
                              : Theme.of(context).dividerColor),
                    width: isActualMonth || isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    months[index].tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
