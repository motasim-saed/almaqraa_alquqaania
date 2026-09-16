import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import '../controller/student_progress_controller.dart';
import '../widget/plan_stats_widget.dart';

/// شاشة الخطط الدراسية (PlansScreen)
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // تم تغيير Get.put إلى Get.find بفضل وجود الـ Binding
    final StudentProgressController controller =
        Get.find<StudentProgressController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'study_plans'.tr,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      // زر عائم لإضافة خطة شهرية سريعة من الأسفل
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlanDialog(context, isAnnual: false),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        label: Text(
          'add_monthly_plan'.tr,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.add_rounded),
      ),
      body: Obx(() {
        // حالة التحميل: عرض مؤشر انتظار
        if (controller.isLoading.value) {
          return  Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          );
        }

        // حالة عدم وجود بيانات: عرض شاشة ترحيبية أو زر للإضافة
        if (controller.annualPlans.isEmpty && controller.monthlyPlans.isEmpty) {
          return _buildEmptyState(context);
        }

        // عرض قائمة الخطط المنظمة
        return _buildPlansList(context, controller);
      }),
    );
  }

  /// بناء واجهة الحالة الفارغة (عند عدم وجود خطط)
  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // أيقونة تعبيرية كبيرة
        Icon(
          Icons.auto_stories_rounded,
          size: 100,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 24),
        // رسالة توضيحية للمستخدم
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'no_plans_yet'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).hintColor,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        const SizedBox(height: 32),
        // زر يحفز الطالب على إضافة أول خطة له
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () => _showAddPlanDialog(context, isAnnual: true),
          child: Text(
            'add_your_first_plan'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// بناء القائمة الرئيسية المقسمة للخطط السنوية والشهرية
  Widget _buildPlansList(
    BuildContext context,
    StudentProgressController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      children: [
        // --- عنوان قسم الخطط السنوية ---
        _buildSectionHeader(
          context,
          title: 'annual_plan'.tr,
          icon: Icons.calendar_today_rounded,
          color: Theme.of(context).colorScheme.primary,
          onAdd: () => _showAddPlanDialog(context, isAnnual: true),
        ),
        const SizedBox(height: 10),
        if (controller.annualPlans.isEmpty)
          _buildEmptyMiniHint(context, 'no_annual_plans'.tr),
        ...controller.annualPlans.map(
          (plan) => _buildPlanCard(
            context,
            plan.year.toString(),
            plan.goalDescription,
            Theme.of(context).colorScheme.primary,
            isAnnual: true,
          ),
        ),

        const SizedBox(height: 35),

        // --- عنوان قسم الخطط الشهرية ---
        _buildSectionHeader(
          context,
          title: 'monthly_plans'.tr,
          icon: Icons.calendar_month_rounded,
          color: Theme.of(context).colorScheme.primary,
          onAdd: () => _showAddPlanDialog(context, isAnnual: false),
        ),
        const SizedBox(height: 10),
        if (controller.monthlyPlans.isEmpty)
          _buildEmptyMiniHint(context, 'no_monthly_plans'.tr),
        ...controller.monthlyPlans.map(
          (plan) => _buildPlanCard(
            context,
            '${_getMonthName(plan.month)} ${plan.year}',
            plan.goalDescription,
            Theme.of(context).colorScheme.primary,
            isAnnual: false,
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  /// تصميم بطاقة عرض الخطة باستخدام الودجت الموحد
  Widget _buildPlanCard(BuildContext context, String title, String description, Color color, {bool isAnnual = false}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).cardColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: color, width: 6)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 18,
              fontFamily: 'Cairo',
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: PlanStatsWidget(
              description: description,
              isCompact: true,
              color: color,
              isAnnual: isAnnual,
            ),
          ),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(Icons.menu_book_rounded, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onAdd,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onAdd,
          icon: Icon(Icons.add_circle_outline, color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyMiniHint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).hintColor,
          fontStyle: FontStyle.italic,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  String _getMonthName(int month) => 'month_$month'.tr;

  void _showAddPlanDialog(BuildContext context, {required bool isAnnual}) {
    final controller = Get.find<StudentProgressController>();
    final noteController = TextEditingController();

    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    var startSurah = 1.obs;
    var endSurah = 114.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Icon(
              isAnnual ? Icons.auto_awesome : Icons.edit_calendar_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              isAnnual ? 'add_annual_plan'.tr : 'add_monthly_plan'.tr,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: InputDecoration(
                    labelText: 'the_year'.tr,
                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                    prefixIcon: Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
                  ),
                  items:
                      List.generate(5, (index) => DateTime.now().year + index)
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text(y.toString()),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => selectedYear = val!,
                ),
                const SizedBox(height: 16),
                if (!isAnnual)
                  DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'the_month'.tr,
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      prefixIcon: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                    ),
                    items: List.generate(12, (index) => index + 1)
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(_getMonthName(m)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => selectedMonth = val!,
                  ),

                const Divider(height: 40, thickness: 1),

                Obx(
                  () => DropdownButtonFormField<int>(
                    value: startSurah.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:
                          '${'from_surah'.tr} (${'page'.tr} ${quran.getPageNumber(startSurah.value, 1)})',
                      labelStyle: TextStyle(
                        fontFamily: 'Cairo',
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    items: List.generate(114, (i) => i + 1)
                        .map(
                          (id) => DropdownMenuItem(
                            value: id,
                            child: Text(
                              controller.translatedSurahNames[id - 1],
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => startSurah.value = val!,
                  ),
                ),

                const SizedBox(height: 16),

                Obx(
                  () => DropdownButtonFormField<int>(
                    value: endSurah.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:
                          '${'to_surah'.tr} (${'page'.tr} ${quran.getPageNumber(endSurah.value, quran.getVerseCount(endSurah.value))})',
                      labelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    items: List.generate(114, (i) => i + 1)
                        .map(
                          (id) => DropdownMenuItem(
                            value: id,
                            child: Text(
                              controller.translatedSurahNames[id - 1],
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => endSurah.value = val!,
                  ),
                ),

                const SizedBox(height: 25),
                Obx(() {
                  int pages = controller.calculatePagesInRange(
                    startSurah.value,
                    endSurah.value,
                  );

                  // الإحصائيات (صفحات بالشهر أو صفحات باليوم)
                  String statsText = "";
                  if (isAnnual) {
                    final pagesPerMonth = (pages / 12).toStringAsFixed(1);
                    statsText = 'pages_per_month'.tr.replaceAll(
                      '@pages',
                      pagesPerMonth,
                    );
                  } else {
                    final int daysInMonth = DateTime(
                      selectedYear,
                      selectedMonth + 1,
                      0,
                    ).day;
                    final pagesPerDay = (pages / daysInMonth).toStringAsFixed(
                      1,
                    );
                    statsText = 'pages_per_day'.tr.replaceAll(
                      '@pages',
                      pagesPerDay,
                    );
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${'total_pages'.tr}: $pages',
                          style:  TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 18,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${'from_page'.tr} ${quran.getPageNumber(startSurah.value, 1)} ${'to_page'.tr} ${quran.getPageNumber(endSurah.value, quran.getVerseCount(endSurah.value))}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statsText,
                            style:  TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'plan_description'.tr,
                    hintText: 'plan_note_hint'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: Theme.of(context).hintColor, fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () => controller.savePlanWithRange(
              isAnnual: isAnnual,
              year: selectedYear,
              month: isAnnual ? null : selectedMonth,
              startSurah: startSurah.value,
              endSurah: endSurah.value,
              customNote: noteController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'save'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}
