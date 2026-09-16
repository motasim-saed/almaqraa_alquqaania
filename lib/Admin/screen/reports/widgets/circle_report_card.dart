import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/admin_models.dart';
import '../../../controller/reports/halaqa_reports_controller.dart';
import 'report_action_button.dart';
import '../specific_report_view.dart';

// بطاقة تقرير الحلقة - CircleReportCard
class CircleReportCard extends StatelessWidget {
  final QuranCircleModel circle;
  final HalaqaReportsController controller;

  const CircleReportCard({
    super.key,
    required this.circle,
    required this.controller,
  });

  void _openReportDetails(String reportType, QuranCircleModel circle) {
    Get.dialog(
      SpecificReportView(circle: circle, reportType: reportType),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide(color: theme.dividerColor, width: 0.5) : BorderSide.none,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.indigo.withValues(alpha: 0.1),
              child: const Icon(Icons.group, color: Colors.indigo, size: 18),
            ),
            title: Text(
              circle.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${'teacher'.tr}: ${circle.teacherName}',
              style: TextStyle(
                color: isDark ? theme.textTheme.bodySmall?.color : Colors.grey[600],
                fontSize: 11,
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: isDark ? theme.dividerColor : Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReportActionButton(
                      icon: Icons.grading_outlined,
                      label: 'monthly_exams'.tr,
                      onTap: () => _openReportDetails('exams', circle),
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 6),
                    ReportActionButton(
                      icon: Icons.assignment_outlined,
                      label: 'monthly_records'.tr,
                      onTap: () => _openReportDetails('grades', circle),
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 6),
                    ReportActionButton(
                      icon: Icons.calendar_month_outlined,
                      label: 'yearly_records'.tr,
                      onTap: () => _openReportDetails('yearly', circle),
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
