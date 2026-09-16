import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/admin_models.dart';
import '../../controller/reports/halaqa_reports_controller.dart';
import 'widgets/filter_header.dart';
import 'widgets/circle_report_card.dart';

// شاشة تقارير الحلقات - HalaqaReportsScreen
// تعرض قائمة الحلقات مع إمكانية البحث والفلترة حسب الجنس
class HalaqaReportsScreen extends StatelessWidget {
  const HalaqaReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // التأكد من وجود متحكم تقارير الحلقات
    final HalaqaReportsController controller = Get.put(
      HalaqaReportsController(),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF9FAFF),
      body: Column(
        children: [
          // ويدجت البحث والفلترة العلوي
          FilterHeader(controller: controller),

          // قائمة الحلقات المفلترة
          Expanded(child: _buildFilteredList(controller)),
        ],
      ),
    );
  }

  // بناء قائمة الحلقات بناءً على البحث والفلترة المختارين
  Widget _buildFilteredList(HalaqaReportsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Obx(() {
        if (controller.isLoadingCircles.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final theme = Get.theme;

        // تطبيق الفلترة (الجنس + نص البحث)
        final filteredCircles = controller.quranCircles.where((c) {
          bool genderMatch =
              controller.selectedGenderFilter.value == Gender.all ||
              c.gender == controller.selectedGenderFilter.value;
          bool searchMatch =
              controller.searchQuery.value.isEmpty ||
              c.name.toLowerCase().contains(
                controller.searchQuery.value.toLowerCase(),
              ) ||
              c.teacherName.toLowerCase().contains(
                controller.searchQuery.value.toLowerCase(),
              );
          return genderMatch && searchMatch;
        }).toList();

        // عرض رسالة في حال عدم وجود نتائج
        if (filteredCircles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: theme.hintColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  controller.searchQuery.value.isNotEmpty
                      ? 'no_matching_circles'.tr
                      : 'no_circles_yet'.tr,
                  style: TextStyle(color: theme.hintColor),
                ),
              ],
            ),
          );
        }

        // استخدام GridView لعرض الحلقات بشكل شبكي مرن
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 2;
            double aspectRatio = 2.0; 

            // تعديل عدد الأعمدة ونسبة العرض للارتفاع لتجنب Overflow
           if (width < 900) {
              crossAxisCount = 2;
              aspectRatio = 2.2; 
            } else if (width < 1200) {
              crossAxisCount = 3;
              aspectRatio = 2.0; 
            } else {
              crossAxisCount = 4;
              aspectRatio = 1.8; 
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredCircles.length,
              itemBuilder: (context, index) {
                final circle = filteredCircles[index];
                return CircleReportCard(circle: circle, controller: controller);
              },
            );
          },
        );
      }),
    );
  }
}
