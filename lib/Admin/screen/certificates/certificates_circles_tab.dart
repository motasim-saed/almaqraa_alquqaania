import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/certificates/certificates_controller.dart';
import '../../models/admin_models.dart';
import '../../../core/services/certificate_service.dart';
import 'certificate_preview_screen.dart';

class CertificatesCirclesTab extends StatelessWidget {
  final Gender gender;

  const CertificatesCirclesTab({super.key, required this.gender});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CertificatesController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildCirclesList(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildCirclesList(BuildContext context, CertificatesController controller) {
    return Obx(() {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      final circles = controller.quranCircles
          .where((c) => c.gender == gender &&
                c.name.toLowerCase().contains(controller.searchQuery.value.toLowerCase()))
          .toList();

      if (circles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 64, color: theme.dividerColor),
              const SizedBox(height: 16),
              Text(
                gender == Gender.male ? 'no_boys_circles'.tr : 'no_girls_circles'.tr,
                style: TextStyle(color: theme.hintColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: circles.length,
        itemBuilder: (context, index) {
          final circle = circles[index];
          return Card(
            elevation: isDark ? 0 : 0.5,
            color: theme.cardColor,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? theme.dividerColor : theme.dividerColor.withValues(alpha: 0.1), width: 1),
            ),
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                iconColor: theme.primaryColor,
                collapsedIconColor: theme.hintColor,
                title: Text(
                  circle.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Text(
                        '${'teacher'.tr}: ${circle.teacherName}',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: (gender == Gender.male ? Colors.indigo : Colors.pink).withValues(alpha: 0.1),
                  child: Icon(
                    gender == Gender.male ? Icons.male_rounded : Icons.female_rounded,
                    color: gender == Gender.male ? Colors.indigo : Colors.pink,
                    size: 20,
                  ),
                ),
                onExpansionChanged: (expanded) {
                  if (expanded) controller.fetchRecords(circleId: circle.id);
                },
                children: [_buildStudentsList(context, controller, circle, isDark)],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildStudentsList(BuildContext context, CertificatesController controller, QuranCircleModel circle, bool isDark) {
    return Obx(() {
      final theme = Theme.of(context);
      final circleRecords = controller.cachedRecords[circle.id] ?? [];

      if (controller.isLoading.value && circleRecords.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
      }

      final results = circleRecords.where((r) => r.studentName.toLowerCase().contains(controller.searchQuery.value.toLowerCase())).toList();

      if (results.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text('no_certified_students'.tr, style: TextStyle(color: theme.hintColor)),
        );
      }

      final List<Map<String, dynamic>> validBatchData = [];
      for (var record in results) {
        final template = controller.templates.firstWhereOrNull((t) => t.gender == gender && record.finalResult >= t.minGrade && record.finalResult <= t.maxGrade);
        if (template != null) {
          validBatchData.add({'studentName': record.studentName, 'finalResult': record.finalResult, 'template': template});
        }
      }

      return Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            if (validBatchData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pdfBytes = await CertificateService.generateBatchCertificatesPdf(batchData: validBatchData, circleName: circle.name);
                    Get.to(() => CertificatePreviewScreen(pdfFuture: Future.value(pdfBytes), title: '${'preview_circle_certs'.tr} ${circle.name}'));
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text('${'preview_issue_all'.tr} (${validBatchData.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gender == Gender.male ? Colors.indigo : Colors.pink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final record = results[index];
                final template = controller.templates.firstWhereOrNull((t) => t.gender == gender && record.finalResult >= t.minGrade && record.finalResult <= t.maxGrade);
                final hasTemplate = template != null;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? theme.dividerColor : theme.dividerColor.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    title: Text(
                      record.studentName, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${'grade'.tr}: ${record.finalResult.toStringAsFixed(1)}', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                      ],
                    ),
                    trailing: TextButton.icon(
                      onPressed: hasTemplate ? () async {
                        final pdfBytes = await CertificateService.generateCertificatePdf(studentName: record.studentName, finalResult: record.finalResult, template: template);
                        Get.to(() => CertificatePreviewScreen(pdfFuture: Future.value(pdfBytes), title: '${'preview_student_cert'.tr} ${record.studentName}'));
                      } : null,
                      icon: Icon(hasTemplate ? Icons.workspace_premium : Icons.warning_amber_rounded, size: 16),
                      label: Text(hasTemplate ? 'issue'.tr : 'no_template'.tr, style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: hasTemplate ? Colors.green : theme.hintColor,
                        backgroundColor: hasTemplate ? Colors.green.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
