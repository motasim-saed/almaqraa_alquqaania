import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/admin_models.dart';
import '../../controller/reports/halaqa_reports_controller.dart';
import 'widgets/date_filters_widget.dart';
import 'widgets/exams_table_widget.dart';
import 'widgets/grades_table_widget.dart';
import 'widgets/yearly_table_widget.dart';

// واجهة عرض التقرير المحدد - SpecificReportView
// تعرض نافذة حوار (Dialog) تحتوي على تفاصيل التقرير (اختبارات، درجات شهرية، أو سنوية) للحلقة المختارة
class SpecificReportView extends StatefulWidget {
  final QuranCircleModel circle;
  final String reportType;

  const SpecificReportView({
    super.key,
    required this.circle,
    required this.reportType,
  });

  @override
  State<SpecificReportView> createState() => _SpecificReportViewState();
}

class _SpecificReportViewState extends State<SpecificReportView> {
  final controller = Get.find<HalaqaReportsController>();
  late int currentYear = controller.selectedYear.value;
  int currentMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    // جلب البيانات بعد رسم الواجهة مباشرة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  // استدعاء دالة جلب البيانات من المتحكم بناءً على نوع التقرير
  void _fetchData() {
    if (widget.reportType == 'exams') {
      controller.fetchCircleExams(widget.circle.id, month: currentMonth, year: currentYear);
    } else if (widget.reportType == 'grades') {
      controller.fetchCircleMonthlyGrades(widget.circle.id, month: currentMonth, year: currentYear);
    } else if (widget.reportType == 'yearly') {
      controller.fetchCircleYearlyGrades(widget.circle.id, year: currentYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    IconData icon = Icons.report;
    Color color = Colors.indigo;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // تحديد العنوان والأيقونة واللون بناءً على نوع التقرير
    switch (widget.reportType) {
      case 'exams':
        title = 'monthly_exams'.tr;
        icon = Icons.grading_outlined;
        color = Colors.blue;
        break;
      case 'grades':
        title = 'monthly_records'.tr;
        icon = Icons.assignment_outlined;
        color = Colors.orange;
        break;
      case 'yearly':
        title = 'yearly_records'.tr;
        icon = Icons.calendar_month_outlined;
        color = Colors.deepPurple;
        break;
    }

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // رأس النافذة (العنوان، الأيقونة، أزرار الإجراءات)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.circle.name,
                          style: TextStyle(
                            color: isDark ? theme.textTheme.bodySmall?.color : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // زر تصدير التقرير إلى Excel
                    TextButton.icon(
                      onPressed: _exportReport,
                      icon: const Icon(Icons.download, size: 18),
                      label: Text('export_excel'.tr),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            // ويدجت فلاتر التاريخ (الشهر والسنة)
            DateFiltersWidget(
              currentMonth: currentMonth,
              currentYear: currentYear,
              reportType: widget.reportType,
              onMonthChanged: (val) {
                setState(() => currentMonth = val);
                _fetchData();
              },
              onYearChanged: (val) {
                setState(() => currentYear = val);
                _fetchData();
              },
            ),
            const SizedBox(height: 16),
            // محتوى التقرير (الجدول أو رسالة "لا توجد بيانات")
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? theme.cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? theme.dividerColor : Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildReportContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء المحتوى بناءً على نوع التقرير المختار
  Widget _buildReportContent() {
    return Obx(() {
      if (controller.isLoadingReports.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (widget.reportType == 'exams') {
        final records = controller.monthlyExams;
        if (records.isEmpty) return _buildEmptyState();
        return ExamsTableWidget(records: records);
      } else if (widget.reportType == 'grades') {
        final records = controller.monthlyRecords;
        if (records.isEmpty) return _buildEmptyState();
        return GradesTableWidget(records: records, month: currentMonth, year: currentYear);
      } else if (widget.reportType == 'yearly') {
        final records = controller.yearlyRecords;
        if (records.isEmpty) return _buildEmptyState();
        return YearlyTableWidget(records: records.toList());
      }

      return const SizedBox();
    });
  }

  // استدعاء دالة التصدير من المتحكم
  void _exportReport() {
    if (widget.reportType == 'exams') {
      controller.exportExamsReport(widget.circle.name);
    } else if (widget.reportType == 'grades') {
      controller.exportMonthlyReport(widget.circle.name);
    } else if (widget.reportType == 'yearly') {
      controller.exportYearlyReport(widget.circle.name);
    }
  }

  // عرض حالة "لا توجد بيانات"
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: theme.hintColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'no_data_available'.tr,
            style: TextStyle(color: theme.hintColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
