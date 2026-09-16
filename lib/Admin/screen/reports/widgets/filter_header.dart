import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/admin_models.dart';
import '../../../controller/reports/halaqa_reports_controller.dart';
import 'report_filter_card.dart';

// رأس الفلترة - FilterHeader
// يحتوي على بطاقات إحصائية تفاعلية تسمح للمسؤول بفلترة الحلقات حسب الجنس (بنين، بنات، الكل)
class FilterHeader extends StatelessWidget {
  final HalaqaReportsController controller;

  const FilterHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.calendar_today, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'select_year'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(width: 16),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: controller.selectedYear.value,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                      items: List.generate(10, (index) {
                        int year = DateTime.now().year - 5 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (year) {
                        if (year != null) {
                          controller.selectedYear.value = year;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
              children: [
                // بطاقة فلترة قسم البنين
                Expanded(
                  child: ReportFilterCard(
                    controller: controller,
                    targetGender: Gender.male,
                    title: 'boys_circles'.tr, 
                    value: controller.maleCirclesCount.toString(),
                    icon: Icons.male,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                // بطاقة فلترة قسم البنات
                Expanded(
                  child: ReportFilterCard(
                    controller: controller,
                    targetGender: Gender.female,
                    title: 'girls_circles'.tr, 
                    value: controller.femaleCirclesCount.toString(),
                    icon: Icons.female,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(width: 12),
                // بطاقة عرض كافة الحلقات (إلغاء الفلترة)
                Expanded(
                  child: ReportFilterCard(
                    controller: controller,
                    targetGender: Gender.all,
                    title: 'all_circles'.tr, 
                    value: controller.totalCirclesCount.toString(),
                    icon: Icons.all_inclusive,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
