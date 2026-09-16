import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_constants.dart';

// ويدجت فلاتر التاريخ - DateFiltersWidget
class DateFiltersWidget extends StatelessWidget {
  final int currentMonth;
  final int currentYear;
  final String reportType;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;

  const DateFiltersWidget({
    super.key,
    required this.currentMonth,
    required this.currentYear,
    required this.reportType,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (reportType == 'yearly') {
      // Show only year selector for yearly reports
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('year'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? theme.dividerColor : Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: currentYear,
                isExpanded: true,
                dropdownColor: theme.cardColor,
                items: List.generate(10, (index) {
                  int year = DateTime.now().year - 5 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (val) {
                  if (val != null) onYearChanged(val);
                },
              ),
            ),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('month'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? theme.dividerColor : Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: currentMonth,
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        items: List.generate(12, (index) {
                          final monthNum = index + 1;
                          String monthName = AppConstants.gregorianMonths[index].tr;
                          return DropdownMenuItem(
                            value: monthNum,
                            child: Text('$monthName $currentYear'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) onMonthChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('year'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? theme.dividerColor : Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: currentYear,
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        items: List.generate(10, (index) {
                          int year = DateTime.now().year - 5 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) onYearChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
