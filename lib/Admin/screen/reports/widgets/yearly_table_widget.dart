import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/yearly_record_model.dart';

// جدول المتابعة السنوية المطور - YearlyTableWidget
class YearlyTableWidget extends StatelessWidget {
  final List<YearlyRecord> records;

  const YearlyTableWidget({super.key, required this.records});

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
          columnSpacing: 20,
          columns: [
            DataColumn(
              label: Text(
                'student_name'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
            ),
            ...List.generate(12, (index) {
              int month = index + 1;
              return DataColumn(
                label: Text(
                  'month_$month'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
                ),
              );
            }),
            DataColumn(
              label: Text(
                'monthly_average'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.indigoAccent : Colors.indigo,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'final_exam'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.blueGrey[200] : Colors.blueGrey,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'final_result'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.blueAccent : Colors.blue,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
          rows: records
              .map(
                (r) => DataRow(
                  cells: [
                    DataCell(Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ...List.generate(12, (index) {
                      int month = index + 1;
                      int? grade = r.monthlyGrades[month];
                      return DataCell(
                        Center(
                          child: Text(
                            grade != null ? '$grade' : '-',
                            style: TextStyle(
                              color: grade != null 
                                  ? (isDark ? theme.textTheme.bodyLarge?.color : Colors.black87)
                                  : (isDark ? theme.disabledColor : Colors.grey.shade300),
                              fontWeight: grade != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                    DataCell(
                      Center(
                        child: Text(
                          r.monthlyAverageExam.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.indigoAccent : Colors.indigo,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          r.finalExamResult.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blueGrey[200] : Colors.blueGrey,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          r.finalResult.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blueAccent : Colors.blue,
                            fontSize: 15,
                          ),
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
