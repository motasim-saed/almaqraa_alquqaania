import 'package:flutter/material.dart'; 
import 'package:get/get.dart'; 
import '../../Admin/models/admin_models.dart'; 
import '../controller/student_monitoring_controller.dart'; 
import '../../Student/widget/plan_stats_widget.dart'; 
import '../../Student/pages/daily_progress_screen.dart';

class StudentDetailProgressScreen extends StatelessWidget {
  final StudentModel student;

  const StudentDetailProgressScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final StudentMonitoringController controller = Get.find<StudentMonitoringController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'student_progress'.trParams({'name': student.name}),
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            final currentStudent = controller.students.firstWhereOrNull((s) => s.id == student.id) ?? student;
            final isSup = currentStudent.isSupervisor;
            return IconButton(
              icon: Icon(
                isSup ? Icons.star_rounded : Icons.star_border_rounded,
                color: isSup ? Colors.amber : null,
              ),
              tooltip: isSup ? 'سحب صلاحية الإشراف' : 'تعيين كمشرف للحلقة',
              onPressed: () => controller.toggleCircleSupervisor(currentStudent),
            );
          }),
        ],
      ),
      body: Obx(() { 
        if (controller.isDetailLoading.value) { 
          return const Center(child: CircularProgressIndicator());
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar( 
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'daily_records'.tr, icon: const Icon(Icons.history)),
                  Tab(text: 'plans'.tr, icon: const Icon(Icons.assignment)),
                ],
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
              ),
              Expanded(
                child: TabBarView( 
                  children: [
                    DailyProgressScreen(studentId: student.id, isTeacherMode: true, showStats: false),
                    _buildPlansTab(controller),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPlansTab(StudentMonitoringController controller) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('annual_plan'.tr),
        ...controller.selectedStudentAnnualPlans.map(
          (p) => _buildPlanCard(
            context: Get.context!,
            title: '${'year_colon'.tr} ${p.year}',
            description: p.goalDescription,
            color: Colors.indigo,
            onDelete: () => _confirmDelete(Get.context!, () => controller.deleteAnnualPlan(student.id, p.id)),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('monthly_plans'.tr),
        ...controller.selectedStudentMonthlyPlans.map(
          (p) => _buildPlanCard(
            context: Get.context!,
            title: '${p.month}/${p.year}',
            description: p.goalDescription,
            color: Colors.teal,
            onDelete: () => _confirmDelete(Get.context!, () => controller.deleteMonthlyPlan(student.id, p.id)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({required BuildContext context, required String title, required String description, required Color color, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16, fontFamily: 'Cairo')),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red), tooltip: 'delete'.tr, onPressed: onDelete),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: PlanStatsWidget(description: description, isCompact: true, color: color)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    Get.dialog(AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('confirm_delete'.tr, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text('delete_plan_warning'.tr, style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr, style: const TextStyle(fontFamily: 'Cairo'))),
          TextButton(onPressed: () { onConfirm(); Get.back(); }, child: Text('delete'.tr, style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'))),
        ]));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo')));
  }
}
