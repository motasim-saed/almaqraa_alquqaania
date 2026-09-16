import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Teacher/models/monthly_exam_model.dart';

// جدول الاختبارات الشهرية - ExamsTableWidget
class ExamsTableWidget extends StatelessWidget {
  final List<MonthlyExamRecord> records;

  const ExamsTableWidget({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : Colors.grey.shade50,
          ),
          columns: [
            DataColumn(
              label: Text(
                'student_name'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'hifz_score_label'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'tajweed_score_label'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'tilawah_score_label'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'total_score_label'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: records
              .map(
                (r) => DataRow(
                  cells: [
                    DataCell(Text(r.studentName)),
                    DataCell(Text(r.hifzScore.toString())),
                    DataCell(Text(r.tajweedScore.toString())),
                    DataCell(Text(r.tilawahScore.toString())),
                    DataCell(
                      Text(
                        '${r.totalScore}/100',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.greenAccent : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
