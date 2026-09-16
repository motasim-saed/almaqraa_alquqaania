import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/admin_models.dart';
import '../../../controller/reports/halaqa_reports_controller.dart';
import '../../widgets/admin_stat_card.dart';

// بطاقة فلترة التقارير - ReportFilterCard
class ReportFilterCard extends StatelessWidget {
  final HalaqaReportsController controller;
  final Gender targetGender;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ReportFilterCard({
    super.key,
    required this.controller,
    required this.targetGender,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      
      // التحقق مما إذا كان هذا الخيار هو المختار حالياً
      final isSelected = controller.selectedGenderFilter.value == targetGender;
      
      return InkWell(
        onTap: () => controller.selectedGenderFilter.value = targetGender,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : (isDark ? theme.dividerColor : Colors.transparent),
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: AdminStatCard(
            title: title,
            value: value,
            icon: icon,
            color: isSelected ? color : theme.hintColor,
            isSmall: true,
          ),
        ),
      );
    });
  }
}
