import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Admin/models/admin_models.dart';
import '../../Admin/controller/quran_circles_controller.dart';
import '../../core/controllers/global_batch_controller.dart';
import '../../Admin/screen/quran_circles/widgets/circle_details_dialog.dart';
import '../../Admin/controller/accepted/accepted_students_controller.dart';

class CoordinatorCirclesScreen extends StatelessWidget {
  const CoordinatorCirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // نهيئ المتحكم إذا لم يكن موجوداً ونجلبه
    final controller = Get.put(QuranCirclesController());
    Get.lazyPut(() => AcceptedStudentsController());
    
    // نجلب متحكم الدفعات العام للفلترة
    GlobalBatchController? globalBatchController;
    if (Get.isRegistered<GlobalBatchController>()) {
      globalBatchController = Get.find<GlobalBatchController>();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('circles_system'.tr),
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchField(context, controller),
          Expanded(child: _buildFilteredList(controller, globalBatchController)),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, QuranCirclesController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => controller.searchQuery.value = value,
          decoration: InputDecoration(
            hintText: 'search_circles'.tr,
            hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredList(QuranCirclesController controller, GlobalBatchController? globalBatchController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // جلب قيم الفلترة من المتحكم العالمي
        final int? batchFilter = globalBatchController?.selectedBatch.value;
        final Gender genderFilter = globalBatchController?.selectedGender.value ?? Gender.all;

        final filteredCircles = controller.quranCircles.where((c) {
          // فلترة حسب الجنس
          bool genderMatch = genderFilter == Gender.all || c.gender == genderFilter;
          // فلترة حسب الدفعة
          bool batchMatch = batchFilter == null || c.batchNumber == batchFilter;
          // فلترة حسب البحث
          bool searchMatch = controller.searchQuery.value.isEmpty ||
              c.name.toLowerCase().contains(controller.searchQuery.value.toLowerCase()) ||
              c.teacherName.toLowerCase().contains(controller.searchQuery.value.toLowerCase());
              
          return genderMatch && batchMatch && searchMatch;
        }).toList();

        if (filteredCircles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.searchQuery.value.isNotEmpty
                      ? 'no_matching_circles'.tr
                      : 'no_circles_yet'.tr,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 2;
            double aspectRatio = 1.0;

            if (width < 600) {
              crossAxisCount = 2;
              aspectRatio = 0.85;
            } else if (width < 900) {
              crossAxisCount = 3;
              aspectRatio = 1.0;
            } else if (width < 1200) {
              crossAxisCount = 4;
              aspectRatio = 1.1;
            } else {
              crossAxisCount = 5;
              aspectRatio = 1.2;
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredCircles.length,
              itemBuilder: (context, index) {
                return _buildCircleCard(context, filteredCircles[index]);
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildCircleCard(BuildContext context, QuranCircleModel circle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // إضافة الحواف هنا
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.indigo.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      elevation: isDark ? 0 : 2,
      child: InkWell(
        onTap: () {
          Get.dialog(CircleDetailsDialog(circle: circle, isAdmin: false));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                child: const Icon(Icons.group, color: Colors.indigo, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                circle.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${'teacher'.tr}: ${circle.teacherName}',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              if (circle.batchNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${'batch_number'.tr}: ${circle.batchNumber}',
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${circle.studentIds.length} ${'students'.tr}',
                      style: TextStyle(color: theme.hintColor, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
