import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Teacher/models/monthly_record_model.dart';
import '../../../controller/reports/halaqa_reports_controller.dart';
import '../../../../Student/pages/daily_progress_screen.dart';
import '../../../../Student/widget/plan_stats_widget.dart';

// جدول المتابعة الشهرية - GradesTableWidget
class GradesTableWidget extends StatelessWidget {
  final List<MonthlyRecord> records;
  final HalaqaReportsController controller =
      Get.find<HalaqaReportsController>();

  final int month;
  final int year;

  GradesTableWidget({super.key, required this.records, required this.month, required this.year});

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
            isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  )
                : Colors.grey.shade50,
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
                'attendance_count'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'absence_count'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'excused_count'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'holiday'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'monthly_grade_label'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'details'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: records
              .map(
                (r) => DataRow(
                  cells: [
                    DataCell(Text(r.studentName)),
                    DataCell(
                      Text(
                        '${r.attendanceDays}',
                        style: TextStyle(
                          color: isDark ? Colors.tealAccent : Colors.teal,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${r.absenceDays}',
                        style: TextStyle(
                          color: isDark ? Colors.redAccent : Colors.red,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${r.excusedDays}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.blueGrey[200]
                              : Colors.blueGrey,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${r.holidayDays}',
                        style: TextStyle(
                          color: isDark ? Colors.orangeAccent : Colors.orange,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${r.monthlyGrade}/100',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.indigoAccent : Colors.indigo,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _showStudentDetails(context, r),
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

  void _showStudentDetails(BuildContext context, MonthlyRecord record) {
    controller.fetchStudentDetails(record.studentId);
    final theme = Theme.of(context);

    Get.dialog(
      Dialog(
        // ignore: deprecated_member_use
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${'student_plans_and_records'.tr}: ${record.studentName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingStudentDetails.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Colors.blue,
                          unselectedLabelColor: theme.hintColor,
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                          indicatorColor: Colors.blue,
                          tabs: [
                            Tab(
                              text: 'daily_records'.tr,
                              icon: const Icon(Icons.history),
                            ),
                            Tab(
                              text: 'plans'.tr,
                              icon: const Icon(Icons.assignment),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              DailyProgressScreen(
                                studentId: record.studentId,
                                isTeacherMode: true,
                                showStats: false,
                                initialMonth: month,
                                initialYear: year,
                              ),
                              _buildPlansTab(theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlansTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('annual_plans'.tr),
        if (controller.selectedStudentAnnualPlans.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'no_annual_plans'.tr,
              style: TextStyle(color: theme.hintColor, fontFamily: 'Cairo'),
            ),
          ),
        ...controller.selectedStudentAnnualPlans.map(
          (p) => _buildPlanCard(
            title: '${'year_colon'.tr} ${p.year}',
            description: p.goalDescription,
            color: Colors.indigo,
            isAnnual: true,
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('monthly_plans'.tr),
        if (controller.selectedStudentMonthlyPlans.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'no_monthly_plans'.tr,
              style: TextStyle(color: theme.hintColor, fontFamily: 'Cairo'),
            ),
          ),
        ...controller.selectedStudentMonthlyPlans.map(
          (p) => _buildPlanCard(
            title: '${p.month}/${p.year}',
            description: p.goalDescription,
            color: Colors.teal,
            isAnnual: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String description,
    required Color color,
    bool isAnnual = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: PlanStatsWidget(
              description: description,
              isCompact: true,
              color: color,
              isAnnual: isAnnual,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
