import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/admin_layout_controller.dart';
import '../controller/home/admin_home_controller.dart';
import 'widgets/admin_top_nav_bar.dart';
import 'package:al_maqraa/components/app_exit_wrapper.dart';
import '../../core/controllers/global_batch_controller.dart';

class AdminMainLayout extends StatelessWidget {
  const AdminMainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminLayoutController>();
    final homeController = Get.find<AdminHomeController>();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f5): () {
          controller.refreshCurrentScreen();
        },
      },
      child: Focus(
        autofocus: true,
        child: AppExitWrapper(
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF121212)
                : const Color(0xFFF8F9FD),
            body: Column(
              children: [
                const AdminTopNavigationBar(),
                _buildSubAppBar(context, controller, homeController),
                Expanded(
                  child: Obx(
                    () => controller.screens[controller.currentIndex],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubAppBar(
    BuildContext context,
    AdminLayoutController controller,
    AdminHomeController homeController,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.indigo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.white10
                : Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Obx(() {
            if (controller.currentIndex == 15) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                  onPressed: () => controller.changeIndex(10),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return TextField(
                  controller: controller.searchController,
                  autofocus: true,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'search'.tr,
                    hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey),
                    prefixIcon: Icon(Icons.search, color: textColor),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => controller.updateSearchQuery(value),
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.screenTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    if (controller.screenCount.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          controller.screenCount,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ],
                  ],
                );
              }
            }),
          ),

          // شريط الأدوات: تحديث، بحث، تأكيد الفلترة، القائمة المنسدلة
          Row(
            children: [
              // زر التحديث
              Obx(() {
                final isRefreshing = controller.isRefreshing.value || homeController.isRefreshing.value;
                return IconButton(
                  tooltip: 'تحديث البيانات',
                  icon: isRefreshing 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
                    : Icon(Icons.refresh, color: textColor),
                  onPressed: isRefreshing ? null : () => controller.refreshCurrentScreen(),
                );
              }),
              
              // زر البحث
              IconButton(
                onPressed: () => controller.toggleSearch(),
                icon: Obx(() => Icon(
                  controller.isSearching.value ? Icons.close : Icons.search,
                  color: textColor,
                )),
                tooltip: 'search'.tr,
              ),

              const SizedBox(width: 8),

              // مجموعة فلترة الدفعات
              _buildBatchFilterGroup(context, textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchFilterGroup(BuildContext context, Color textColor) {
    return GetBuilder<GlobalBatchController>(
      init: GlobalBatchController(),
      builder: (batchCtrl) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر تأكيد الفلترة (الصح)
            Obx(() {
              final isModified = batchCtrl.selectedBatch.value != batchCtrl.stagedBatch.value;
              return Container(
                decoration: BoxDecoration(
                  color: isModified ? Colors.green.withValues(alpha: 0.1) : textColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.check_circle_rounded, 
                    color: isModified ? Colors.green : textColor.withValues(alpha: 0.3), 
                    size: 26
                  ),
                  onPressed: isModified ? () => batchCtrl.applyFilter() : null,
                  tooltip: 'تطبيق الفلترة',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              );
            }),

            const SizedBox(width: 10),

            // قائمة الدفعات المنسدلة
            Obx(() => Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: textColor.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: batchCtrl.stagedBatch.value,
                  icon: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Icon(Icons.filter_list_rounded, size: 18, color: textColor),
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('الجميع'),
                    ),
                    ...batchCtrl.availableBatches.map((batch) => DropdownMenuItem(
                      value: batch,
                      child: Text('الدفعة $batch'),
                    )),
                  ],
                  onChanged: (val) => batchCtrl.updateStagedBatch(val),
                ),
              ),
            )),

            const SizedBox(width: 12),
            
            // نص التسمية
            Text(
              'الفلترة على حسب الدفع',
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ],
        );
      },
    );
  }
}
